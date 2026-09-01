import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/feed_post.dart';
import '../../models/study_group_model.dart';
import '../../services/study_group_service.dart';
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
import 'chat_screen.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key});
  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  final StudyGroupService _groupService = StudyGroupService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _userName = '';
  String _userDept = '';
  String? _photoUrl;
  late List<FeedPost> _studyPosts;
  StreamSubscription? _postsSubscription;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _postsSubscription = PostService().postsStream().listen((posts) {
      if (!mounted) return;
      setState(() => _studyPosts = posts.where((p) => p.type == 'study').toList());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  // _postsSubscription declared below

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

  void _showCreateGroupDialog() {
    final nameCtrl     = TextEditingController();
    final subjectCtrl  = TextEditingController();
    final descCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    final timeCtrl     = TextEditingController();
    int maxMembers = 5;
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
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.group, color: AppTheme.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Study Group বানাও',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _buildField(nameCtrl, 'Group এর নাম *', Icons.group_outlined),
                const SizedBox(height: 10),
                _buildField(subjectCtrl, 'Subject *', Icons.menu_book_outlined),
                const SizedBox(height: 10),
                _buildField(descCtrl, 'Description', Icons.description_outlined),
                const SizedBox(height: 10),
                _buildField(locationCtrl, 'কোথায় পড়বে?', Icons.location_on_outlined),
                const SizedBox(height: 10),
                _buildField(timeCtrl, 'কখন পড়বে?', Icons.access_time_outlined),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.people_outline, color: AppTheme.orange, size: 20),
                    const SizedBox(width: 8),
                    Text('সর্বোচ্চ সদস্য:', style: GoogleFonts.poppins(fontSize: 13)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () { if (maxMembers > 2) setModal(() => maxMembers--); },
                      child: Container(width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.remove, size: 16, color: AppTheme.orange)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('$maxMembers',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    GestureDetector(
                      onTap: () { if (maxMembers < 50) setModal(() => maxMembers++); },
                      child: Container(width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.add, size: 16, color: AppTheme.orange)),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: isLoading ? null : () async {
                      if (nameCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) return;
                      setModal(() => isLoading = true);
                      try {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final group = StudyGroupModel(
                          id: '', name: nameCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          time: timeCtrl.text.trim(),
                          maxMembers: maxMembers, members: [uid],
                          creatorId: uid, creatorName: _userName,
                        );
                        await _groupService.createGroup(group);
                        PostService().createPost(
                          caption: '📚 ${group.name} — Study group for ${group.subject}. ${group.description}',
                          type: 'study',
                        ).catchError((_) {});
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModal(() => isLoading = false);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Create Group',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
        prefixIcon: Icon(icon, color: AppTheme.orange, size: 20),
        filled: true, fillColor: AppTheme.orange.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.orange, width: 1.5)),
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                              color: AppTheme.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.orange, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.orange.withValues(alpha: 0.15),
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null
                              ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, color: AppTheme.orange))
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
                              color: AppTheme.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.home_rounded, color: AppTheme.orange, size: 22),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // Search
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: bgColor, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200)),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search group name, subject...',
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Group List ───────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<StudyGroupModel>>(
                    stream: _groupService.getGroups(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerList(count: 3, itemHeight: 200);
                      }
                      var groups = snapshot.data ?? [];
                      if (_searchQuery.isNotEmpty) {
                        groups = groups.where((g) =>
                            g.name.toLowerCase().contains(_searchQuery) ||
                            g.subject.toLowerCase().contains(_searchQuery)).toList();
                      }
                      if (groups.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('কোনো group নেই',
                                style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.critical(12)),
                              ),
                              onPressed: _showCreateGroupDialog,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text('Group বানাও',
                                  style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: groups.length,
                        itemBuilder: (context, index) => _AnimatedGroupCard(
                          group: groups[index], index: index,
                          currentUid: currentUid, groupService: _groupService, isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),

                // ── Study Group Posts ───────────────────────────────────────
                final showPosts = _studyPosts.isNotEmpty;
                if (showPosts) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Related Posts',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.orange),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _studyPosts.length,
                            itemBuilder: (context, index) {
                              final p = _studyPosts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.orange.withValues(alpha: 0.1),
                                    child: Text(p.authorName.isNotEmpty ? p.authorName[0].toUpperCase() : 'U',
                                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.orange)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(p.caption,
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, height: 1.2)),
                                      Text('by ${p.authorName}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                                    ]),
                                  ),
                                ]),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),

                // ── Bottom Nav ────────────────────────────────────────────────
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
                onFabTap: _showCreateGroupDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Group Card ────────────────────────────────────────────────────
class _AnimatedGroupCard extends StatefulWidget {
  final StudyGroupModel group;
  final int index;
  final String currentUid;
  final StudyGroupService groupService;
  final bool isDark;
  const _AnimatedGroupCard({
    required this.group, required this.index, required this.currentUid,
    required this.groupService, required this.isDark,
  });
  @override
  State<_AnimatedGroupCard> createState() => _AnimatedGroupCardState();
}

class _AnimatedGroupCardState extends State<_AnimatedGroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 300)),
        () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g        = widget.group;
    final isMember = g.members.contains(widget.currentUid);
    final isFull   = g.members.length >= g.maxMembers;
    final isOwner  = g.creatorId == widget.currentUid;
    final cardBg   = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor  = widget.isDark ? Colors.white54 : Colors.grey.shade500;

    // Banner gradient colors per subject
    final List<List<Color>> gradients = [
      [const Color(0xFF1E3A5F), const Color(0xFF2D6A9F)],
      [const Color(0xFF2D3A1F), const Color(0xFF4A7C40)],
      [const Color(0xFF3A1F2D), const Color(0xFF8C3060)],
      [const Color(0xFF1F2D3A), const Color(0xFF2D5F8C)],
    ];
    final grad = gradients[widget.index % gradients.length];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.07),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner with gradient + title overlay (matching screenshot)
              GestureDetector(
                onTap: () => Navigator.push(context,
                    SlideUpRoute(page: _GroupDetailScreen(
                        group: g, currentUid: widget.currentUid,
                        groupService: widget.groupService, isDark: widget.isDark))),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad,
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(g.name,
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        // Views / members
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${g.members.length * 3}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                        const SizedBox(width: 14),
                        const Icon(Icons.people_outline, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${g.members.length}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                        const Spacer(),
                        // Bookmark
                        const Icon(Icons.bookmark_border_rounded,
                            color: Colors.white70, size: 18),
                      ]),
                    ],
                  ),
                ),
              ),

              // Card body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Creator row
                    Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.orange.withValues(alpha: 0.15),
                        child: Text(g.creatorName.isNotEmpty ? g.creatorName[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.orange)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g.creatorName,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          Row(children: [
                            Container(width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: AppTheme.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(g.subject,
                                style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
                          ]),
                        ]),
                      ),
                      // Member count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFull
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppTheme.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${g.members.length}/${g.maxMembers}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: isFull ? Colors.red : AppTheme.green)),
                      ),
                    ]),

                    if (g.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(g.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, color: subColor, height: 1.4)),
                    ],

                    if (g.location.isNotEmpty || g.time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        if (g.location.isNotEmpty) ...[
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Flexible(child: Text(g.location,
                              style: GoogleFonts.poppins(fontSize: 11, color: subColor),
                              overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 12),
                        ],
                        if (g.time.isNotEmpty) ...[
                          Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Flexible(child: Text(g.time,
                              style: GoogleFonts.poppins(fontSize: 11, color: subColor),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ]),
                    ],

                    const SizedBox(height: 12),
                    // Action buttons row
                    Row(children: [
                      if (isMember) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: AppTheme.orange),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.push(context,
                                SlideUpRoute(page: ChatScreen(group: g))),
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: AppTheme.orange, size: 16),
                            label: Text('Chat',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (!isOwner)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMember ? Colors.red.shade400 : AppTheme.orange,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (isFull && !isMember) ? null : () async {
                              if (isMember) {
                                await widget.groupService.leaveGroup(g.id);
                              } else {
                                await widget.groupService.joinGroup(g.id);
                              }
                            },
                            child: Text(isMember ? 'Leave' : 'Join Group',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                            child: Center(
                              child: Text('Your Group',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.orange, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Group Detail Screen ────────────────────────────────────────────────────
class _GroupDetailScreen extends StatelessWidget {
  final StudyGroupModel group;
  final String currentUid;
  final StudyGroupService groupService;
  final bool isDark;

  const _GroupDetailScreen({
    required this.group, required this.currentUid,
    required this.groupService, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMember = group.members.contains(currentUid);
    final isOwner  = group.creatorId == currentUid;
    final isFull   = group.members.length >= group.maxMembers;
    final bgColor  = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor  = isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Blue gradient header (matching screenshot 3)
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    top: 8, left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Group icon + info centered
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(group.name,
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(group.subject,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 10),
                        // Member avatars
                        SizedBox(
                          height: 32,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(
                                group.members.length.clamp(0, 5),
                                (i) => Container(
                                  width: 28, height: 28,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5)),
                                  child: const Icon(Icons.person, color: Colors.white, size: 14),
                                ),
                              ),
                              if (group.members.length > 5)
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('+${group.members.length - 5}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About This Group',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(group.description.isNotEmpty ? group.description : 'No description provided.',
                      style: GoogleFonts.poppins(fontSize: 13, color: subColor, height: 1.5)),
                  const SizedBox(height: 20),
                  // Spec row
                  Row(children: [
                    _specItem(Icons.category_outlined, 'Category', group.subject, textColor, subColor),
                    _specItem(Icons.access_time_outlined, 'Time', group.time.isNotEmpty ? group.time : '—', textColor, subColor),
                    _specItem(Icons.people_outline, 'Members', '${group.members.length}', textColor, subColor),
                    _specItem(Icons.location_on_outlined, 'Location', group.location.isNotEmpty ? group.location : '—', textColor, subColor),
                  ]),
                  const SizedBox(height: 24),
                  Text('What We Do',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 10),
                  ...['Share class notes & resources', 'Solve practice questions together',
                      'Discuss important topics', 'Prepare for exams together']
                      .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(item, style: GoogleFonts.poppins(fontSize: 13, color: subColor)),
                        ]),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200)),
              child: const Icon(Icons.bookmark_border_rounded,
                  color: AppTheme.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwner
                        ? AppTheme.orange
                        : (isMember ? Colors.red.shade400 : AppTheme.orange),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (isMember && !isOwner) {
                      groupService.leaveGroup(group.id);
                      Navigator.pop(context);
                    } else if (!isMember && !isFull) {
                      groupService.joinGroup(group.id);
                      Navigator.pop(context);
                    } else if (isOwner) {
                      Navigator.push(context, SlideUpRoute(page: ChatScreen(group: group)));
                    }
                  },
                  child: Text(
                    isOwner ? 'Open Group Chat →'
                        : (isMember ? 'Leave Group' : 'Join The Class →'),
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _specItem(IconData icon, String label, String value,
      Color textColor, Color subColor) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 22, color: subColor),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: subColor)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ]),
    );
  }
}
