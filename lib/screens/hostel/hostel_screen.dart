import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/hostel_model.dart';
import '../../services/hostel_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final HostelService _hostelService = HostelService();
  String _selectedFilter = 'All';
  String _userName = 'Student';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildSearch(isDark),
            _buildFilters(isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildHostelList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
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
                ? Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: AppTheme.secondary),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text(_userDept.isNotEmpty ? _userDept : 'Student',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.notifications_none_rounded,
              color: isDark ? Colors.white : const Color(0xFF1E293B), size: 24),
        ],
      ),
    );
  }

  Widget _buildSearch(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
        child: TextField(
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search hostel name,location...',
            hintStyle: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    final filters = [
      ('Near me', Icons.near_me_rounded, 'All'),
      ('Boys', Icons.male_rounded, 'Boys'),
      ('Girls', Icons.female_rounded, 'Girls'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (label, icon, val) = filters[index];
          final selected = _selectedFilter == val;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected
                          ? AppTheme.secondary
                          : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 14,
                        color: selected ? Colors.white : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHostelList() {
    final stream = _selectedFilter == 'All'
        ? _hostelService.getHostels()
        : _hostelService.getHostelsByGender(_selectedFilter);
    return StreamBuilder<List<HostelModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerList(count: 3, itemHeight: 240);
        }
        final hostels = snapshot.data ?? [];
        if (hostels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('কোনো hostel পাওয়া যায়নি',
                    style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: hostels.length,
          itemBuilder: (context, index) => _HostelCard(hostel: hostels[index]),
        );
      },
    );
  }
}

class _HostelCard extends StatelessWidget {
  final HostelModel hostel;
  const _HostelCard({required this.hostel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 160,
            width: double.infinity,
            child: hostel.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: hostel.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        child: const Icon(Icons.home_work,
                            color: AppTheme.secondary, size: 50)),
                  )
                : Container(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    child: const Icon(Icons.home_work_rounded,
                        color: AppTheme.secondary, size: 55),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(hostel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                    Text('TK ${hostel.rent.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary)),
                    Text('/mo',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: Colors.grey.shade500, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(hostel.distance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${hostel.rating}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('(${hostel.reviewCount} reviews)',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(width: 10),
                    Text('🚹 ${hostel.gender}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(width: 10),
                    if (hostel.facilitiesList.isNotEmpty)
                      Text('📶 ${hostel.facilitiesList.first}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
