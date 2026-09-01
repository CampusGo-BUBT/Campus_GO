import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _admin = AdminService();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _admin.users();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final uid = user['id'];
    final banned = user['isBanned'] == true;
    if (banned) {
      await _admin.unbanUser(uid);
    } else {
      await _admin.banUser(uid);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text('Users',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = Map<String, dynamic>.from(_users[index] as Map);
                final name = user['name'] ?? 'Unknown';
                final email = user['email'] ?? '';
                final type = user['userType'] ?? 'student';
                final banned = user['isBanned'] == true;
                final isAdmin = type == 'admin';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B))),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('ADMIN',
                                        style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary)),
                                  ),
                                ],
                              ],
                            ),
                            Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey.shade500)),
                            Text(type,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      if (!isAdmin)
                        banned
                            ? OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.green),
                                onPressed: () => _toggleBan(user),
                                child: const Text('Unban'),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => _toggleBan(user),
                                child: const Text('Ban'),
                              ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
