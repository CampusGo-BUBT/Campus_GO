import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'admin_review_screen.dart';
import 'admin_users_screen.dart';
import 'admin_items_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _admin = AdminService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _admin.dashboard();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pending requests banner
                  _pendingBanner(_data?['pendingRequests'] ?? 0),
                  const SizedBox(height: 16),
                  Text('Summary',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('Users', _data?['users'] ?? 0, Icons.people,
                          AppTheme.primary, 'users'),
                      const SizedBox(width: 12),
                      _statCard('Posts', _data?['posts'] ?? 0, Icons.feed,
                          AppTheme.green, 'post'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('Jobs', _data?['jobs'] ?? 0, Icons.work,
                          AppTheme.primary, 'job'),
                      const SizedBox(width: 12),
                      _statCard('Hostels', _data?['hostels'] ?? 0,
                          Icons.home_work, AppTheme.secondary, 'hostel'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('Tutions', _data?['tutors'] ?? 0,
                          Icons.person_search, AppTheme.orange, 'tutor'),
                      const SizedBox(width: 12),
                      _statCard('Users Mgmt', _data?['users'] ?? 0,
                          Icons.manage_accounts, AppTheme.cyan, 'users_mgmt'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _pendingBanner(int count) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminReviewScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count pending request${count == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Review & approve job / hostel / tuition posts',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, dynamic value, IconData icon, Color color,
      String target) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (target == 'users_mgmt') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          } else if (target == 'users') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminItemsScreen(kind: target)));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text('$value',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
