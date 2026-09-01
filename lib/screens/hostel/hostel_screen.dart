import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/hostel_model.dart';
import '../../services/hostel_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/smart_image.dart';
import 'hostel_detail_screen.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final HostelService _hostelService = HostelService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _userName = 'Student';
  String _userDept = '';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        onPressed: _showAddHostelDialog,
        child: const Icon(Icons.add),
      ),
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

  void _showAddHostelDialog() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final rentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedGender = 'Boys';
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
                          color: AppTheme.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.home_work, color: AppTheme.secondary, size: 20)),
                  const SizedBox(width: 10),
                  Text('Post a Hostel',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _hfield(nameCtrl, 'Hostel Name *', Icons.home_work),
                const SizedBox(height: 10),
                _hfield(locationCtrl, 'Location *', Icons.location_on),
                const SizedBox(height: 10),
                _hfield(rentCtrl, 'Rent (৳/month) *', Icons.attach_money, type: TextInputType.number),
                const SizedBox(height: 10),
                _hfield(phoneCtrl, 'Contact Phone', Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 10),
                _hfield(descCtrl, 'Description', Icons.description_outlined),
                const SizedBox(height: 14),
                Text('Gender:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Boys', 'Girls', 'Family'].map((g) {
                    final sel = selectedGender == g;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedGender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.secondary : AppTheme.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16)),
                        child: Text(g,
                            style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppTheme.secondary,
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
                      backgroundColor: AppTheme.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: isLoading ? null : () async {
                      if (nameCtrl.text.trim().isEmpty || locationCtrl.text.trim().isEmpty || rentCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name, location and rent are required!')));
                        return;
                      }
                      setModal(() => isLoading = true);
                      try {
                        final hostel = HostelModel(
                          id: '',
                          name: nameCtrl.text.trim(),
                          type: selectedGender,
                          location: locationCtrl.text.trim(),
                          rent: double.tryParse(rentCtrl.text.trim()) ?? 0,
                          facilities: '',
                          phone: phoneCtrl.text.trim(),
                          userId: '',
                          ownerName: '',
                          gender: selectedGender,
                          distance: '',
                          description: descCtrl.text.trim(),
                        );
                        await _hostelService.addHostel(hostel);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModal(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Could not post hostel: $e')));
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Post Hostel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hfield(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.secondary, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            backgroundImage: imageProviderFor(_photoUrl),
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
          controller: _searchCtrl,
          style: GoogleFonts.poppins(fontSize: 14),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
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
        final filtered = _searchQuery.isEmpty
            ? hostels
            : hostels
                .where((h) =>
                    h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    h.location.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
        if (filtered.isEmpty) {
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
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _HostelCard(hostel: filtered[index]),
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HostelDetailScreen(hostel: hostel)),
      ),
      child: Container(
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
                ? SmartImage(hostel.imageUrl, fit: BoxFit.cover)
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
      ),
    );
  }
}
