import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/post_service.dart';
import '../../services/tutor_service.dart';
import '../../services/user_service.dart';
import '../../services/theme_service.dart';
import '../../models/feed_post.dart';
import '../../models/tutor_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_transitions.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/post_card.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../tutor/tutor_screen.dart';
import '../books/book_screen.dart';
import '../study_group/study_group_screen.dart';
import '../hostel/hostel_screen.dart';
import '../jobs/job_screen.dart';
import '../notice/notice_screen.dart';
import '../profile/profile_screen.dart';
import '../post/create_post_screen.dart';
import '../saved/saved_posts_screen.dart';
import '../messages/inbox_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Student';
  String _userDept = '';
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await UserService.instance.getUser(uid);
    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Student';
      _userDept = data['department'] ?? '';
      _userType = data['userType'] ?? 'student';
    });
  }

  // Quick access items config matching Screenshot 3 & 4
  final List<_QuickItem> _quickItems = const [
    _QuickItem(Icons.person_search, 'Tuition',    AppTheme.primary),
    _QuickItem(Icons.menu_book,     'Books',       AppTheme.green),
    _QuickItem(Icons.group,         'Study group', AppTheme.orange),
    _QuickItem(Icons.home_work,     'Hostel',      AppTheme.secondary),
    _QuickItem(Icons.work_outline,  'Job',         AppTheme.red),
    _QuickItem(Icons.campaign,      'Notice',      AppTheme.cyan),
  ];

  void _navigateTo(int index) {
    final pages = [
      const TutorScreen(),
      const BookScreen(),
      const StudyGroupScreen(),
      const HostelScreen(),
      const JobScreen(),
      const NoticeScreen(),
    ];
    Navigator.push(context, SlideUpRoute(page: pages[index]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Section ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App Name
                            Text(
                              'CampusGo',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // User Name
                            Text(
                              _userName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // User dept / type
                            Text(
                              _userDept.isNotEmpty ? _userDept : 'Student',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Theme toggle button
                      if (_userType == 'admin') ...[
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminDashboardScreen()),
                          ),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: () => themeService.toggleTheme(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── All content in a single scrollable area ───────────────
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Quick Access label
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          child: Text(
                            'Quick Access',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      // Quick Access Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _StaggeredQuickItem(
                              item: _quickItems[index],
                              index: index,
                              isDark: isDark,
                              onTap: () => _navigateTo(index),
                            ),
                            childCount: _quickItems.length,
                          ),
                        ),
                      ),

                      // Tuition Preview Section
                      SliverToBoxAdapter(
                        child: _TuitionPreviewSection(isDark: isDark),
                      ),

                      // Recent Posts label
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            'Recent Posts',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      // Feed
                      StreamBuilder<List<FeedPost>>(
                        stream: PostService().postsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: ShimmerList(count: 3, itemHeight: 200),
                            );
                          }
                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.dynamic_feed_outlined,
                                        size: 56, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text(
                                      'এখনো কোনো post নেই।\n+ button দিয়ে প্রথম post করো!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade500,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == posts.length) {
                                  return const SizedBox(height: 100);
                                }
                                return _AnimatedPostCard(
                                  post: posts[index],
                                  index: index,
                                );
                              },
                              childCount: posts.length + 1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Navigation Bar ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                if (index == 1) {
                  Navigator.push(context, SlideUpRoute(page: const InboxScreen()));
                } else if (index == 2) {
                  Navigator.push(context, SlideUpRoute(page: const SavedPostsScreen()));
                } else if (index == 3) {
                  Navigator.push(context, SlideUpRoute(page: const ProfileScreen()));
                }
              },
              onFabTap: () => Navigator.push(context, SlideUpRoute(page: const CreatePostScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick access item model ────────────────────────────────
class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickItem(this.icon, this.label, this.color);
}

// ── Staggered quick-access grid card ──────────────────────────
class _StaggeredQuickItem extends StatefulWidget {
  final _QuickItem item;
  final int index;
  final bool isDark;
  final VoidCallback onTap;
  const _StaggeredQuickItem({
    required this.item,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StaggeredQuickItem> createState() => _StaggeredQuickItemState();
}

class _StaggeredQuickItemState extends State<_StaggeredQuickItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final start = widget.index * 0.07;
    final interval = Interval(start, (start + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutBack);
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: interval));
    _fade = CurvedAnimation(parent: _c, curve: interval);
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final labelColor = widget.isDark ? Colors.white70 : const Color(0xFF374151);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.item.icon,
                      color: widget.item.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Post card with fade-in per item ───────────────────────
class _AnimatedPostCard extends StatefulWidget {
  final FeedPost post;
  final int index;
  const _AnimatedPostCard({required this.post, required this.index});

  @override
  State<_AnimatedPostCard> createState() => _AnimatedPostCardState();
}

class _AnimatedPostCardState extends State<_AnimatedPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(
        Duration(milliseconds: (widget.index * 60).clamp(0, 300)),
            () {
          if (mounted) _c.forward();
        });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
        position: _slide, child: PostCard(post: widget.post)),
  );
}

// ── Tuition Preview Section for Home ─────────────────────────────────────────
class _TuitionPreviewSection extends StatelessWidget {
  final bool isDark;
  const _TuitionPreviewSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Section header: label + "See all" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Latest Tuitions',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  SlideUpRoute(page: const TutorScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'See all →',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable tuition cards
        SizedBox(
          height: 178,
          child: StreamBuilder<List<TutorModel>>(
            stream: TutorService().getTutors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 3,
                  itemBuilder: (context, i) => Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }

              final tutors = snapshot.data ?? [];
              if (tutors.isEmpty) {
                return Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      SlideUpRoute(page: const TutorScreen()),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined,
                            size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 6),
                        Text(
                          'No tuitions yet. Tap to post one!',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // show max 6 latest
              final preview = tutors.take(6).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: preview.length,
                itemBuilder: (context, index) => _HomeTuitionCard(
                  tutor: preview[index],
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

// ── Compact horizontal tuition card for Home preview ─────────────────────────
class _HomeTuitionCard extends StatelessWidget {
  final TutorModel tutor;
  final bool isDark;
  const _HomeTuitionCard({required this.tutor, required this.isDark});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HomeDetailSheet(tutor: tutor, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: type badge + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tutor.tutoringType.contains('Online')
                            ? Icons.laptop_chromebook_rounded
                            : Icons.home_rounded,
                        size: 11,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tutor.tutoringType.contains('Online')
                            ? 'Online'
                            : 'Home',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(tutor.postedAt),
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: subtitleColor),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              tutor.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Location row
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 13, color: AppTheme.primary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    tutor.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: subtitleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Class + Subject chips
            Row(
              children: [
                _chip(tutor.studentClass, isDark),
                const SizedBox(width: 6),
                _chip(tutor.subject, isDark, highlight: true),
              ],
            ),

            const Spacer(),

            // Salary
            Row(
              children: [
                Icon(Icons.monetization_on_outlined,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  tutor.salary,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isDark, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: highlight
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Quick detail bottom sheet opened from Home tuition card ──────────────────
class _HomeDetailSheet extends StatelessWidget {
  final TutorModel tutor;
  final bool isDark;
  const _HomeDetailSheet({required this.tutor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final specBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
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

          // Job ID + time
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Job ID: ${tutor.jobId}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                () {
                  if (tutor.postedAt == null) return '';
                  final diff = DateTime.now().difference(tutor.postedAt!);
                  if (diff.inDays >= 1) {
                    return '${diff.inDays}d ago';
                  } else if (diff.inHours >= 1) {
                    return '${diff.inHours}h ago';
                  }
                  return 'just now';
                }(),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            tutor.title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Type tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
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
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  tutor.tutoringType,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Location box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: specBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tutoring Location',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: subColor)),
                      Text(
                        tutor.location,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (tutor.subLocation.isNotEmpty)
                        Text(tutor.subLocation,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: subColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Specs: 2 column row
          Row(
            children: [
              Expanded(child: _specTile(Icons.language_rounded, 'Medium', tutor.medium, specBg, textColor, subColor)),
              const SizedBox(width: 10),
              Expanded(child: _specTile(Icons.school_rounded, 'Class', tutor.studentClass, specBg, textColor, subColor)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _specTile(Icons.person_outline_rounded, 'Preferred', tutor.preferredTutor, specBg, textColor, subColor)),
              const SizedBox(width: 10),
              Expanded(child: _specTile(Icons.monetization_on_outlined, 'Salary', tutor.salary, specBg, textColor, subColor, isSalary: true)),
            ],
          ),
          const SizedBox(height: 20),

          // View Full Details button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  SlideUpRoute(page: const TutorScreen()),
                );
              },
              child: Text(
                'View Full Details & Apply →',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specTile(IconData icon, String label, String value, Color bg,
      Color textColor, Color subColor,
      {bool isSalary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: subColor)),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSalary ? AppTheme.primary : textColor,
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
