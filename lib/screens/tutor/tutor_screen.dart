import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/tutor_model.dart';
import '../../services/tutor_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../services/saved_posts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/smart_image.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../messages/inbox_screen.dart';
import '../notice/notice_screen.dart';
import '../saved/saved_posts_screen.dart';
import '../profile/profile_screen.dart';
import '../study_group/direct_chat_screen.dart';
import '../../widgets/app_transitions.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});
  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TutorService _tutorService = TutorService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _userName = 'Student_name';
  String _userDept = 'Dept of CSE, Bubt';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await UserService.instance.getUser(uid);
    if (!mounted) return;
    if (data.isNotEmpty) {
      setState(() {
        _userName = data['name'] ?? 'Student_name';
        _userDept = data['department'] ?? 'Dept of CSE, Bubt';
        _photoUrl = data['photoUrl'];
      });
    }
  }

  void _showAddTutorDialog() {
    final titleCtrl = TextEditingController(text: 'Tutor Needed For Class 6');
    final locationCtrl = TextEditingController(text: 'Mirpur-2, Dhaka');
    final subLocCtrl =
        TextEditingController(text: 'Near Mirpur National Stadium');
    final classCtrl = TextEditingController(text: 'Class 6');
    final subjectCtrl = TextEditingController(text: 'Science');
    final daysCtrl = TextEditingController(text: '4 Days/Week');
    final salaryCtrl = TextEditingController(text: '6,000 Tk/Month');
    final reqCtrl = TextEditingController(
        text:
            'Looking for an experienced and punctual tutor who has great knowledge of mathematics, science and English grammar. Daily 2 hours lesson requested.');
    final phoneCtrl = TextEditingController();

    String selectedType = 'Home Tutoring';
    String selectedMedium = 'English Version';
    String selectedPreferred = 'Male';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Color(0xFFFF4D4D), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Post a Tuition Job',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModalField(titleCtrl, 'Job Title', Icons.title_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalField(
                          locationCtrl, 'Location', Icons.location_on_outlined),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModalField(
                          subLocCtrl, 'Nearby Landmark', Icons.place_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Tutoring Type',
                        selectedType,
                        ['Home Tutoring', 'Online', 'Coaching'],
                        (val) => setModal(() => selectedType = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        'Medium',
                        selectedMedium,
                        ['English Version', 'Bangla Medium', 'English Medium'],
                        (val) => setModal(() => selectedMedium = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalField(
                          classCtrl, 'Class', Icons.school_outlined),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        'Preferred Tutor',
                        selectedPreferred,
                        ['Male', 'Female', 'Any'],
                        (val) => setModal(() => selectedPreferred = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalField(
                          subjectCtrl, 'Subject', Icons.menu_book_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModalField(
                          daysCtrl, 'Days Weekly', Icons.calendar_month_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalField(
                          salaryCtrl, 'Salary Offer', Icons.monetization_on_outlined),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModalField(phoneCtrl, 'Contact Phone',
                          Icons.phone_outlined,
                          type: TextInputType.phone),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reqCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Requirements / Details',
                    hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty) return;
                            setModal(() => isSubmitting = true);
                            try {
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              final jobId =
                                  '544${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                              final double rateNum = double.tryParse(salaryCtrl
                                      .text
                                      .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                  6000;

                              final tutor = TutorModel(
                                id: '',
                                jobId: jobId,
                                title: titleCtrl.text.trim(),
                                tutoringType: selectedType,
                                location: locationCtrl.text.trim(),
                                subLocation: subLocCtrl.text.trim(),
                                medium: selectedMedium,
                                studentClass: classCtrl.text.trim(),
                                preferredTutor: selectedPreferred,
                                subject: subjectCtrl.text.trim(),
                                daysPerWeek: daysCtrl.text.trim(),
                                salary: salaryCtrl.text.trim(),
                                hourlyRate: rateNum,
                                requirements: reqCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                userId: uid,
                                posterName: _userName,
                                postedAt: DateTime.now(),
                              );

                              // 1. Save to tutors collection
                              await _tutorService.addTutor(tutor);

                              // 2. Also post to home feed (fire-and-forget, don't block)
                              PostService().createPost(
                                caption:
                                    '📌 ${tutor.title}\n📍 ${tutor.location} (${tutor.subLocation})\n💰 ${tutor.salary} | 🗓️ ${tutor.daysPerWeek}\n📚 ${tutor.medium} - ${tutor.studentClass} (${tutor.subject})\n👤 Preferred: ${tutor.preferredTutor}\n${tutor.requirements}',
                                type: 'tuition',
                              ).catchError((_) {});

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Tuition job posted successfully! ✓',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModal(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Post করা যায়নি। আবার চেষ্টা করো।\n$e',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Post Tuition Job',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(
      TextEditingController c, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFFF4D4D), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.black87,
              fontWeight: FontWeight.w500),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header Bar (Avatar + Name + Dept + Notification) ──
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                SlideUpRoute(
                                    page: const ProfileScreen())),
                            child: Hero(
                              tag: 'profile_avatar',
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.12),
                                backgroundImage: imageProviderFor(_photoUrl),
                                child: _photoUrl == null
                                    ? Text(
                                        _userName.isNotEmpty
                                            ? _userName[0].toUpperCase()
                                            : 'S',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  _userDept,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          // Notification Bell
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                SlideUpRoute(page: const NoticeScreen())),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEBF3FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF1A1A1A),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Search Bar + Filter Icon Button ──
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search class, subject',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade400),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey.shade400, size: 20),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Icon(Icons.format_list_bulleted_rounded,
                                color: Colors.grey.shade500, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Tuition Jobs Stream List ──
                Expanded(
                  child: StreamBuilder<List<TutorModel>>(
                    stream: _searchQuery.isEmpty
                        ? _tutorService.getTutors()
                        : _tutorService.searchTutors(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ShimmerList(count: 4, itemHeight: 220);
                      }
                      final tutors = snapshot.data ?? [];
                      if (tutors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No tuition jobs available right now.\nTap + to post a tuition job!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 95, top: 4, left: 16, right: 16),
                        itemCount: tutors.length,
                        itemBuilder: (context, index) => _AnimatedTuitionCard(
                          tutor: tutors[index],
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Floating Blue Bottom Bar ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavBar(
                currentIndex: 0,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushAndRemoveUntil(
                      context, SlideUpRoute(page: const HomeScreen()), (r) => false);
                  } else if (index == 1) {
                    Navigator.push(
                        context, SlideUpRoute(page: const InboxScreen()));
                  } else if (index == 2) {
                    Navigator.push(context,
                        SlideUpRoute(page: const SavedPostsScreen()));
                  } else if (index == 3) {
                    Navigator.push(
                        context, SlideUpRoute(page: const ProfileScreen()));
                  }
                },
                onFabTap: _showAddTutorDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Wrapper for Tuition Card ──
class _AnimatedTuitionCard extends StatefulWidget {
  final TutorModel tutor;
  final int index;
  const _AnimatedTuitionCard({required this.tutor, required this.index});

  @override
  State<_AnimatedTuitionCard> createState() => _AnimatedTuitionCardState();
}

class _AnimatedTuitionCardState extends State<_AnimatedTuitionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(
        Duration(milliseconds: (widget.index * 50).clamp(0, 300)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _TuitionCardItem(tutor: widget.tutor),
      ),
    );
  }
}

// ── Tuition Card Item Matching Screenshot 1 Design ──
class _TuitionCardItem extends StatelessWidget {
  final TutorModel tutor;
  const _TuitionCardItem({required this.tutor});

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'a day ago';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      return DateFormat('MMM dd, yyyy').format(dt);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} mins ago';
    }
    return 'Just now';
  }

  void _openDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TuitionDetailsModal(tutor: tutor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedService = Provider.of<SavedPostsService>(context);
    final isSaved = savedService.isSaved(tutor.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final postedDateStr = tutor.postedAt != null
        ? 'Posted at: ${DateFormat('MMM dd, yyyy').format(tutor.postedAt!)}'
        : 'Posted recently';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Location Pin + Location Name + Job ID Pill + Bookmark ──
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFF4D4D), size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tutor.location,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Job ID: ${tutor.jobId}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => savedService.toggleSave(tutor.id),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? const Color(0xFFFF4D4D) : const Color(0xFFFF4D4D),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Title ──
          Text(
            tutor.title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          // ── Tag Row (Home Tutoring / Online Tutoring + Time ago) ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tutor.tutoringType.contains('Online')
                          ? Icons.laptop_chromebook_rounded
                          : Icons.home_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tutor.tutoringType,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: Colors.grey.shade600, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _formatTimeAgo(tutor.postedAt),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // ── 2-Column Specs Grid (Screenshot 1 matching) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Medium & Subject
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGridSpecItem(
                      Icons.language_rounded,
                      'Medium:',
                      tutor.medium,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildGridSpecItem(
                      Icons.menu_book_rounded,
                      'Subject:',
                      tutor.subject,
                      isBadge: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Column 2: Class & Preferred Tutor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGridSpecItem(
                      Icons.school_rounded,
                      'Class:',
                      tutor.studentClass,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildGridSpecItem(
                      Icons.person_outline_rounded,
                      'Preferred Tutor:',
                      tutor.preferredTutor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Card Footer: Posted date on left + View Details button on right ──
          Row(
            children: [
              Text(
                postedDateStr,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D4D),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openDetailsModal(context),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridSpecItem(
    IconData icon,
    String label,
    String value, {
    bool isBadge = false,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            isBadge
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}

// ── Tuition Details Bottom Sheet Modal Matching Screenshots 2 & 3 Design ──
class _TuitionDetailsModal extends StatelessWidget {
  final TutorModel tutor;
  const _TuitionDetailsModal({required this.tutor});

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'a day ago';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    return 'Just now';
  }

  void _showApplyBottomSheet(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && tutor.userId == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own tuition posting!')),
      );
      return;
    }

    final phoneCtrl = TextEditingController(text: tutor.phone);
    final noteCtrl = TextEditingController(
        text:
            'Hello! I am interested in tutoring for this post. I have relevant experience and would love to discuss further.');
    bool isApplying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFFFF4D4D), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Apply for Tuition',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Job ID: ${tutor.jobId} - ${tutor.title}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Your Contact Phone',
                  prefixIcon:
                      const Icon(Icons.phone, color: Color(0xFFFF4D4D), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Qualifications & Note to Poster',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D4D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isApplying
                      ? null
                      : () async {
                          setModalState(() => isApplying = true);
                          try {
                            await TutorService().applyForTuition(
                              tuitionId: tutor.id,
                              note: noteCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showSuccessDialog(context, tutor);
                            }
                          } catch (e) {
                            setModalState(() => isApplying = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                  child: isApplying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm & Submit Application',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, TutorModel tutor) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Application Sent!',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your tuition application has been saved to Firebase and sent to ${tutor.posterName}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFFF4D4D)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectChatScreen(
                              otherUserId: tutor.userId,
                              otherUserName: tutor.posterName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFFF4D4D), size: 18),
                      label: Text(
                        'Message',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFFFF4D4D),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D4D),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (tutor.phone.isNotEmpty) {
                          final uri = Uri(scheme: 'tel', path: tutor.phone);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.phone,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Call Now',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final hasApplied =
        currentUid != null && tutor.applicants.contains(currentUid);
    final savedService = Provider.of<SavedPostsService>(context);
    final isSaved = savedService.isSaved(tutor.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            // ── Drag Handle Bar ──
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // ── Top Row: Job ID Badge + Time Ago ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Job ID: ${tutor.jobId}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: const Color(0xFFFF4D4D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          size: 15, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(tutor.postedAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Title ──
                  Text(
                    tutor.title,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Home Tutoring Tag ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tutor.tutoringType.contains('Online')
                                ? Icons.laptop_chromebook_rounded
                                : Icons.home_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tutor.tutoringType,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Location Box (Matching Screenshot 2 & 3) ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEBEB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFFF4D4D), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tutoring Location',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tutor.location,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              if (tutor.subLocation.isNotEmpty)
                                Text(
                                  tutor.subLocation,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section Title: TUITION SPECIFICATION ──
                  Text(
                    'TUITION SPECIFICATION',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 6 Cards Specification Grid (2 columns x 3 rows) ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecBox(
                          Icons.language_rounded,
                          'Medium:',
                          tutor.medium,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSpecBox(
                          Icons.school_rounded,
                          'Class:',
                          tutor.studentClass,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecBox(
                          Icons.person_outline_rounded,
                          'Preferred Tutor:',
                          tutor.preferredTutor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSpecBox(
                          Icons.menu_book_rounded,
                          'Subject:',
                          tutor.subject,
                          isRedBadge: true,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecBox(
                          Icons.calendar_month_rounded,
                          'DAYS WEEKLY',
                          tutor.daysPerWeek,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSpecBox(
                          Icons.monetization_on_outlined,
                          'Salary offer',
                          tutor.salary,
                          isSalaryText: true,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Section Title: REQUIREMENT / DETAILS ──
                  Text(
                    'REQUIREMENT / DETAILS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Requirement Detail Box (Screenshot 3 matching) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tutor.requirements,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Modal Bottom Action Bar (Bookmark Button + Apply Button) ──
            Row(
              children: [
                // Bookmark Icon Box
                GestureDetector(
                  onTap: () => savedService.toggleSave(tutor.id),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: const Color(0xFF475569),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Main Apply Action Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasApplied
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFFF4D4D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showApplyBottomSheet(context),
                      child: Text(
                        hasApplied
                            ? 'Applied Successfully ✓'
                            : 'Apply For This Tuition →',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBox(
    IconData icon,
    String label,
    String value, {
    bool isRedBadge = false,
    bool isSalaryText = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                if (isRedBadge)
                  UnconstrainedBox(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isSalaryText)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value.split('/')[0],
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF4D4D),
                          ),
                        ),
                        if (value.contains('/'))
                          TextSpan(
                            text: '/${value.split('/')[1]}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
