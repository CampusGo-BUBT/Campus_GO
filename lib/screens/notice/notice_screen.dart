import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/notice_model.dart';
import '../../services/notice_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_transitions.dart';
import '../home/home_screen.dart';
import '../messages/inbox_screen.dart';
import '../saved/saved_posts_screen.dart';
import '../profile/profile_screen.dart';
import 'notice_detail_screen.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});
  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final NoticeService _noticeService = NoticeService();
  String _selectedCategory = 'All Notices';
  final List<String> _categories = ['All Notices', 'Academic', 'Exams', 'Events'];
  String _userName = '';
  String _userDept = '';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await UserService.instance.getUser(uid);
    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Student';
      _userDept = data['department'] ?? '';
      _photoUrl = data['photoUrl'];
    });
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
        context, SlideUpRoute(page: const HomeScreen()), (r) => false);
  }

  void _showAddNoticeDialog() {
    final titleCtrl   = TextEditingController();
    final contentCtrl = TextEditingController();
    final pdfCtrl     = TextEditingController();
    String selectedCategory = 'Academic';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20, right: 20, top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppTheme.cyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.campaign, color: AppTheme.cyan, size: 20)),
                  const SizedBox(width: 10),
                  Text('Notice Publish করো',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _buildField(titleCtrl, 'Notice Title *', Icons.title_outlined),
                const SizedBox(height: 10),
                _buildField(contentCtrl, 'Notice Content *', Icons.description_outlined),
                const SizedBox(height: 10),
                _buildField(pdfCtrl, 'Attachment (e.g. Routine.pdf)', Icons.picture_as_pdf_outlined),
                const SizedBox(height: 14),
                Text('Category:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Important', 'Academic', 'Exams', 'Events'].map((cat) {
                    final sel = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.cyan : AppTheme.cyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16)),
                        child: Text(cat,
                            style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppTheme.cyan,
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: isLoading ? null : () async {
                      if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('নোটিশের শিরোনাম ও বিস্তারিত দিন!')));
                        return;
                      }
                      setModal(() => isLoading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        final notice = NoticeModel(
                          id: '', title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          category: selectedCategory,
                          dateStr: 'Today',
                          attachmentName: pdfCtrl.text.trim(),
                          userId: user?.uid ?? 'admin',
                          authorName: _userName.isNotEmpty ? _userName : 'Admin',
                          createdAt: DateTime.now(),
                        );
                        await _noticeService.addNotice(notice);
                        PostService().createPost(
                          caption: '📢 [${notice.category}]: ${notice.title} — ${notice.content}',
                          type: 'notice',
                        ).catchError((_) {});
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModal(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Publish করা যায়নি: $e')));
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Publish Notice',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.cyan, size: 20),
        filled: true, fillColor: AppTheme.cyan.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor  = isDark ? Colors.white60 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  color: cardColor,
                  child: Column(
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.cyan, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.cyan.withValues(alpha: 0.15),
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null
                              ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, color: AppTheme.cyan))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_userName.isNotEmpty ? _userName : 'Student',
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                            Text(_userDept.isNotEmpty ? _userDept : 'Student',
                                style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
                          ]),
                        ),
                        GestureDetector(
                          onTap: _goHome,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.home_rounded, color: AppTheme.cyan, size: 22),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                // ── Category Filter Pills ────────────────────────────────
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((cat) {
                      final sel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.primary : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel ? AppTheme.primary : Colors.grey.shade300)),
                            child: Text(cat,
                                style: GoogleFonts.poppins(
                                    color: sel ? Colors.white : subColor,
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Notice List ──────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<NoticeModel>>(
                    stream: _selectedCategory == 'All Notices'
                        ? _noticeService.getNotices()
                        : _noticeService.getNoticesByCategory(_selectedCategory),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerList(count: 3, itemHeight: 180);
                      }
                      final notices = snapshot.data ?? [];
                      if (notices.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('কোনো notice নেই',
                                style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                          ]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: notices.length,
                        itemBuilder: (context, index) =>
                            _NoticeCard(notice: notices[index], isDark: isDark),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Bottom Nav ─────────────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: CustomBottomNavBar(
                currentIndex: 0,
                onTap: (index) {
                  if (index == 0) {
                    _goHome();
                  } else if (index == 1) {
                    Navigator.push(context, SlideUpRoute(page: const InboxScreen()));
                  } else if (index == 2) {
                    Navigator.push(context, SlideUpRoute(page: const SavedPostsScreen()));
                  } else if (index == 3) {
                    Navigator.push(context, SlideUpRoute(page: const ProfileScreen()));
                  }
                },
                onFabTap: _showAddNoticeDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notice Card Widget ─────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final bool isDark;
  const _NoticeCard({required this.notice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isImportant = notice.category == 'Important' || notice.category == 'Exams';
    final accentColor = isImportant ? AppTheme.primary : AppTheme.blue;
    final cardBg = isDark
        ? const Color(0xFF1E293B)
        : (isImportant ? const Color(0xFFFFF5F5) : const Color(0xFFEBF3FE));
    final borderColor = isImportant
        ? AppTheme.primary.withValues(alpha: 0.35)
        : AppTheme.blue.withValues(alpha: 0.3);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor  = isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: category pill + date + bookmark
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Text(notice.category,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.bold, color: accentColor)),
            ),
            const Spacer(),
            Text(notice.dateStr,
                style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
            const SizedBox(width: 8),
            Icon(Icons.bookmark_border_rounded, color: accentColor, size: 18),
          ]),
          const SizedBox(height: 12),

          // Icon + title + content
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(
                isImportant ? Icons.campaign_rounded : Icons.calendar_month_rounded,
                color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notice.title,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(notice.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: subColor, height: 1.4)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),

          // Attachment + View Details
          Row(children: [
            if (notice.attachmentName.isNotEmpty) ...[
              Icon(Icons.insert_drive_file_outlined, size: 13, color: subColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(notice.attachmentName,
                    style: GoogleFonts.poppins(fontSize: 11, color: subColor),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  SlideUpRoute(page: NoticeDetailScreen(notice: notice))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View Details',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: Colors.white),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
