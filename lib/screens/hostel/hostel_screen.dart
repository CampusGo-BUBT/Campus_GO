import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../models/hostel_model.dart';
import '../../services/hostel_service.dart';
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
import 'hostel_detail_screen.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final HostelService _hostelService = HostelService();
  final ImagePicker _picker = ImagePicker();
  String _selectedFilter = 'All';

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

  void _showAddHostelDialog() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final rentCtrl = TextEditingController();
    final facilitiesCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'Boys';
    String selectedGender = 'Boys';
    XFile? selectedImage;
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
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_work, color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hostel/Mess Add করো',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 70);
                    if (img != null) setModal(() => selectedImage = img);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: AppTheme.secondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 6),
                              Text(
                                'Hostel-এর ছবি দিন (Optional)',
                                style: GoogleFonts.poppins(color: AppTheme.secondary, fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildField(nameCtrl, 'Hostel/Mess এর নাম *', Icons.home_outlined),
                const SizedBox(height: 10),
                _buildField(locationCtrl, 'ঠিকানা *', Icons.location_on_outlined),
                const SizedBox(height: 10),
                _buildField(rentCtrl, 'মাসিক ভাড়া (৳) *', Icons.attach_money, type: TextInputType.number),
                const SizedBox(height: 10),
                _buildField(facilitiesCtrl, 'Facilities (Wifi, AC, Study, Laundry, Parking)', Icons.star_outline),
                const SizedBox(height: 10),
                _buildField(phoneCtrl, 'Phone Number *', Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 10),
                _buildField(descCtrl, 'বিস্তারিত বিবরণ (Description)', Icons.description_outlined),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('কার জন্য:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: ['Boys', 'Girls'].map((g) {
                              final sel = selectedGender == g;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setModal(() => selectedGender = g),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: sel ? AppTheme.red : AppTheme.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      g,
                                      style: GoogleFonts.poppins(
                                        color: sel ? Colors.white : AppTheme.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
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
                            if (nameCtrl.text.trim().isEmpty || locationCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('নাম ও ঠিকানা দেওয়া আবশ্যক!')),
                              );
                              return;
                            }
                            setModal(() => isLoading = true);
                            final nav = Navigator.of(context);
                            final user = FirebaseAuth.instance.currentUser;
                            String ownerName = 'Owner';
                            if (user != null) {
                              final data = await UserService.instance.getUser(user.uid);
                              ownerName = data['name'] ?? 'Owner';
                            }

                            final hostel = HostelModel(
                              id: '',
                              name: nameCtrl.text.trim(),
                              type: selectedType,
                              location: locationCtrl.text.trim(),
                              rent: double.tryParse(rentCtrl.text.trim()) ?? 0,
                              facilities: facilitiesCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              userId: user?.uid ?? 'guest',
                              ownerName: ownerName,
                              gender: selectedGender,
                              imageUrl: '',
                              description: descCtrl.text.trim(),
                              createdAt: DateTime.now(),
                            );
                            await _hostelService.addHostel(
                              hostel,
                              image: selectedImage != null ? File(selectedImage!.path) : null,
                            );
                            await PostService().createPost(
                              caption: '🏠 ${hostel.name} available in ${hostel.location}. Rent: ৳${hostel.rent.toInt()}/mo.',
                              type: 'hostel',
                            );
                            if (mounted) nav.pop();
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Post Hostel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        prefixIcon: Icon(icon, color: AppTheme.secondary, size: 20),
        filled: true,
        fillColor: AppTheme.secondary.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
        context, SlideUpRoute(page: const HomeScreen()), (r) => false);
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
                // Top Header + Categories (Matching Screenshot 4)
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppTheme.secondary, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null
                                ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold, color: AppTheme.secondary))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_userName.isNotEmpty ? _userName : 'Student',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15, fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                                Text(_userDept.isNotEmpty ? _userDept : 'Student',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _goHome,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                              child: const Icon(Icons.home_rounded,
                                  color: AppTheme.secondary, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() {}),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search hostel name, location...',
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

                // Filter Buttons Row (Near me, Boys, Girls matching Screenshot 4)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _filterBtn('Near me', Icons.near_me_rounded, 'All'),
                      const SizedBox(width: 8),
                      _filterBtn('Boys', Icons.male_rounded, 'Boys'),
                      const SizedBox(width: 8),
                      _filterBtn('Girls', Icons.female_rounded, 'Girls'),
                    ],
                  ),
                ),

                // Nearby Hostels Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nearby Hostels',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Hostel List View matching Screenshot 4
                Expanded(
                  child: StreamBuilder<List<HostelModel>>(
                    stream: _selectedFilter == 'All'
                        ? _hostelService.getHostels()
                        : _hostelService.getHostelsByGender(_selectedFilter),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerList(count: 3, itemHeight: 260);
                      }
                      final hostels = snapshot.data ?? [];
                      if (hostels.isEmpty) {
                        return Center(
                          child: Text(
                            'কোনো hostel পাওয়া যায়নি',
                            style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: hostels.length,
                        itemBuilder: (context, index) {
                          final h = hostels[index];
                          return _buildHostelCard(context, h, isDark);
                        },
                      );
                    },
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
                onFabTap: _showAddHostelDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, IconData icon, String filterVal) {
    final sel = _selectedFilter == filterVal;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.red : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: sel ? Colors.white : Colors.black87),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: sel ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostelCard(BuildContext context, HostelModel h, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HostelDetailScreen(hostel: h)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hostel Cover Image
              SizedBox(
                height: 160,
                width: double.infinity,
                child: h.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: h.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: Colors.grey.shade200),
                        errorWidget: (ctx, url, err) => Container(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          child: const Icon(Icons.home_work, color: AppTheme.secondary, size: 50),
                        ),
                      )
                    : Container(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(Icons.home_work_rounded, color: AppTheme.secondary, size: 55),
                        ),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Price Row matching Screenshot 4
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Text(
                          'TK ${h.rent.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '/mo',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          h.distance,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rating, Badges & Book Now Button Row matching Screenshot 4
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${h.rating}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text('🚹 ${h.gender}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Text('📶 Wifi', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => HostelDetailScreen(hostel: h)),
                              );
                            },
                            child: Text(
                              'Book Now',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
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
