import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/job_model.dart';
import '../../services/job_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_transitions.dart';
import '../tutor/tutor_screen.dart';
import '../books/book_screen.dart';
import '../study_group/study_group_screen.dart';
import '../hostel/hostel_screen.dart';
import '../notice/notice_screen.dart';
import '../messages/inbox_screen.dart';
import '../saved/saved_posts_screen.dart';
import '../profile/profile_screen.dart';
import 'job_detail_screen.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final JobService _jobService = JobService();
  final Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _jobService.seedJobsIfEmpty();
  }

  void _showAddJobDialog() {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'Full Time';
    String selectedWorkplace = 'On-site';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: StatefulBuilder(
          builder: (context, setModal) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.work_outline, color: AppTheme.red, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Job Circular Post (Add Job)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                _buildField(titleCtrl, 'Job Role (e.g. UI/UX Designer) *', Icons.work_outline),
                const SizedBox(height: 10),
                _buildField(companyCtrl, 'Company Name *', Icons.business_outlined),
                const SizedBox(height: 10),
                _buildField(locationCtrl, 'Location (e.g. Dhaka, Bangladesh) *', Icons.location_on_outlined),
                const SizedBox(height: 10),
                _buildField(salaryCtrl, 'Salary Range (e.g. Tk15,000 - 25,000 / mo)', Icons.attach_money),
                const SizedBox(height: 10),
                _buildField(emailCtrl, 'Contact Email *', Icons.email_outlined, type: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _buildField(descCtrl, 'Job Description', Icons.description_outlined),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job Type:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: ['Full Time', 'Part Time'].map((t) {
                              final sel = selectedType == t;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setModal(() => selectedType = t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: sel ? AppTheme.red : AppTheme.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      t,
                                      style: GoogleFonts.poppins(
                                        color: sel ? Colors.white : AppTheme.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty || companyCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('পদ ও কোম্পানির নাম দেওয়া আবশ্যক!')),
                              );
                              return;
                            }
                            setModal(() => isLoading = true);
                            final nav = Navigator.of(context);

                            final user = FirebaseAuth.instance.currentUser;
                            String posterName = 'Recruiter';
                            if (user != null) {
                              final data = await UserService.instance.getUser(user.uid);
                              posterName = data['name'] ?? 'Recruiter';
                            }

                            final job = JobModel(
                              id: '',
                              title: titleCtrl.text.trim(),
                              company: companyCtrl.text.trim(),
                              location: locationCtrl.text.trim(),
                              salary: salaryCtrl.text.trim().isNotEmpty ? salaryCtrl.text.trim() : 'Negotiable',
                              type: selectedType,
                              workplaceType: selectedWorkplace,
                              description: descCtrl.text.trim(),
                              contactEmail: emailCtrl.text.trim(),
                              userId: user?.uid ?? 'guest',
                              posterName: posterName,
                              createdAt: DateTime.now(),
                            );
                            await _jobService.addJob(job);
                            await PostService().createPost(
                              caption: '💼 Job Opportunity: ${job.title} at ${job.company} — Salary: ${job.salary}. Contact: ${job.contactEmail}',
                              type: 'job',
                            );
                            if (mounted) nav.pop();
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Post Job', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.red, size: 20),
        filled: true,
        fillColor: AppTheme.red.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
        ),
      ),
    );
  }

  void _navigateToCategory(int index) {
    final pages = [
      const TutorScreen(),
      const BookScreen(),
      const StudyGroupScreen(),
      const HostelScreen(),
      const JobScreen(),
      const NoticeScreen(),
    ];
    if (index == 4) return; // Already on Job
    Navigator.pushReplacement(context, SlideUpRoute(page: pages[index]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header + Categories (Matching Screenshot 5)
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFEBF3FE),
                            child: Icon(Icons.person, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student_name',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                'Dept of CSE, Bubt',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBF3FE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A1A), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category Circle Icons (Job active red highlight matching Screenshot 5)
                      SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCatCircle(1, Icons.menu_book_outlined, 'Books', false),
                            _buildCatCircle(2, Icons.group_outlined, 'Study group', false),
                            _buildCatCircle(3, Icons.king_bed_outlined, 'Hostel', false),
                            _buildCatCircle(4, Icons.work, 'Job', true), // ACTIVE
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Find the job you love" Banner matching Screenshot 5
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEDE7F6), Color(0xFFE1BEE7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find the job you\nlove',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C0B4F),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Explore top opportunities and build your career',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.purple.shade900),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                onPressed: _showAddJobDialog,
                                child: Text('Explore Jobs', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recommended for you header matching Screenshot 5
                        Row(
                          children: [
                            Text(
                              'Recommended for you',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              'View All',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Job Cards Stream
                        StreamBuilder<List<JobModel>>(
                          stream: _jobService.getJobs(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const ShimmerList(count: 2, itemHeight: 180);
                            }
                            final jobs = snapshot.data ?? [];
                            if (jobs.isEmpty) {
                              return Center(
                                child: Text(
                                  'কোনো job পাওয়া যায়নি',
                                  style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                                ),
                              );
                            }
                            return Column(
                              children: jobs.map((job) {
                                final isSaved = _savedJobIds.contains(job.id);
                                return _buildJobCard(context, job, isSaved, isDark);
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Navigation Bar
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
                onFabTap: _showAddJobDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatCircle(int index, IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () => _navigateToCategory(index),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.red : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppTheme.red : AppTheme.red.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: isActive ? Colors.white : AppTheme.red, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.red : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, bool isSaved, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Icon Avatar + Title + Bookmark matching Screenshot 5
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      job.company.isNotEmpty ? job.company[0].toUpperCase() : 'C',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        job.company,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            job.location,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSaved) {
                        _savedJobIds.remove(job.id);
                      } else {
                        _savedJobIds.add(job.id);
                      }
                    });
                  },
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: isSaved ? AppTheme.red : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tags (Full Time, On-site) matching Screenshot 5
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.type,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.workplaceType,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Salary & Posted Time Row matching Screenshot 5
            Row(
              children: [
                Text(
                  job.salary,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Text(
                  '2h ago',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
