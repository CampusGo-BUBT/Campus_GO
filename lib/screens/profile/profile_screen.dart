import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/theme_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_image.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _uploading = false;

  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _loadProfile();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiClient.instance.get('/auth/user/');
      if (mounted) {
        setState(() {
          _userData = Map<String, dynamic>.from(data as Map);
          _loading = false;
        });
        _c.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfileFields() async {
    final nameCtrl = TextEditingController(text: _userData?['name'] ?? '');
    final univCtrl = TextEditingController(text: _userData?['university'] ?? '');
    final idCtrl = TextEditingController(text: _userData?['studentId'] ?? '');
    final phoneCtrl = TextEditingController(text: _userData?['phone'] ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editField(nameCtrl, 'Name'),
            _editField(univCtrl, 'University'),
            _editField(idCtrl, 'Student ID'),
            _editField(phoneCtrl, 'Phone'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = await ProfileService().updateProfileFields(
                name: nameCtrl.text.trim(),
                university: univCtrl.text.trim(),
                studentId: idCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (!mounted) return;
              setState(() => _userData = data);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    setState(() => _uploading = true);
    try {
      // Upload through the backend -> Firebase Storage, then update the profile.
      final data = await ApiClient.instance.patchMultipart(
        '/auth/user/profile/',
        files: {'photo': File(img.path)},
      );
      if (mounted) {
        setState(() {
          _userData = Map<String, dynamic>.from(data as Map);
          _uploading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context, listen: false);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final name    = _userData?['name']     ?? 'Student';
    final email   = _userData?['email']    ?? '';
    final uid     = _userData?['studentId'] ?? '';
    final univ    = _userData?['university'] ?? '';
    final phone   = _userData?['phone']    ?? '';
    final type    = _userData?['userType'] ?? 'student';
    final photoUrl= _userData?['photoUrl'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Profile', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logoutAndGoToLogin();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero Header ──────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFFF7A8A)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: GestureDetector(
                              onTap: _pickAndUploadAvatar,
                              child: Container(
                                width: 96, height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 12)],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _uploading
                                    ? const CircularProgressIndicator(color: AppTheme.primary)
                                    : photoUrl != null
                                    ? SmartImage(photoUrl, fit: BoxFit.cover)
                                    : Center(child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: GoogleFonts.poppins(
                                        fontSize: 36, fontWeight: FontWeight.bold,
                                        color: AppTheme.primary))),
                              ),
                            ),
                          ),
                          Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(email, style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type == 'student' ? '🎓 Student' : '👨‍👩‍👧 Guardian',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Info Cards ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (uid.isNotEmpty) _infoTile('Student ID', uid, Icons.badge_outlined),
                      if (univ.isNotEmpty) _infoTile('University', univ, Icons.school_outlined),
                      if (phone.isNotEmpty) _infoTile('Phone', phone, Icons.phone_outlined),
                      _infoTile('Email', email, Icons.email_outlined),

                      const SizedBox(height: 16),

                      // ── Content management shortcuts ──
                      _actionTile(
                        'My Listings',
                        'Edit or delete your posts, books, jobs & more',
                        Icons.category_outlined,
                        AppTheme.primary,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        'Edit Profile Info',
                        'Update your name, university, id & phone',
                        Icons.edit_outlined,
                        AppTheme.green,
                        _editProfileFields,
                      ),
                      const SizedBox(height: 16),

                      // Dark mode toggle
                      Consumer<ThemeService>(
                        builder: (context, ts, _) => _settingsTile(
                          'Dark Mode',
                          Icons.dark_mode_outlined,
                          isDark ? Colors.amber : Colors.grey.shade600,
                          trailing: Switch(
                            value: ts.isDarkMode,
                            onChanged: (_) => ts.toggleTheme(),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Logout
                      GestureDetector(
                        onTap: () async {
                          await auth.logoutAndGoToLogin();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text('Logout', style: GoogleFonts.poppins(
                                  color: Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(String label, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ]),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _settingsTile(String label, IconData icon, Color iconColor,
      {required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
        trailing,
      ]),
    );
  }
}
