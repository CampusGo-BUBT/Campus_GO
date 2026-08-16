import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});
  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _idCtrl       = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _univCtrl     = TextEditingController();
  bool _agreeTerms    = false;
  bool _loading       = false;
  bool _obscure       = true;
  String? _error;

  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _c, curve: const Interval(0.2, 1.0, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_agreeTerms) {
      setState(() => _error = 'Please agree to Terms and Conditions');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final error = await Provider.of<AuthService>(context, listen: false).registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      studentId: _idCtrl.text.trim(),
      university: _univCtrl.text.trim().isEmpty ? 'BUBT' : _univCtrl.text.trim(),
    );
    if (mounted) {
      setState(() { _loading = false; _error = error; });
      if (error == null) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header Graphic & Title (Matching Screenshot 1) ──
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 48),
                ),
                const SizedBox(height: 14),
                Text(
                  'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by creating a free account.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Form Inputs (Matching Screenshot 1) ──
                _buildField(_nameCtrl, 'Full name', Icons.person_outline),
                const SizedBox(height: 14),
                _buildField(_emailCtrl, 'Enter your email', Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField(_idCtrl, 'Student id number', Icons.badge_outlined,
                    type: TextInputType.number),
                const SizedBox(height: 14),
                _buildField(_passCtrl, 'Strong Password', Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade400, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                const SizedBox(height: 14),
                _buildField(_univCtrl, 'University Name (e.g. BUBT)', Icons.school_outlined),
                const SizedBox(height: 16),

                // ── Terms & Conditions Checkbox (Screenshot 1) ──
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'By checking the box you agree to our ',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions.',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: GoogleFonts.poppins(
                          color: Colors.red.shade700, fontSize: 12))),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Next > Red Button (Screenshot 1) ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next', style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom link: Already a member? Log In
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already a member? ',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                      children: [
                        TextSpan(
                          text: 'Log In',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: c, keyboardType: type, obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: suffix,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      ),
    );
  }
}
