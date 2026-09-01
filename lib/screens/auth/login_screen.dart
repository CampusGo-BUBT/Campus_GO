import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'student_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;
  String? _error;

  late AnimationController _c;
  late Animation<double>   _logoScale;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _formFade  = CurvedAnimation(
        parent: _c, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _c, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final error = await Provider.of<AuthService>(context, listen: false)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
    if (mounted) setState(() { _loading = false; _error = error; });
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    final error = await Provider.of<AuthService>(context, listen: false)
        .signInWithGoogle();
    if (mounted) setState(() { _loading = false; _error = error; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Header Graphic / Title (Matching Screenshot 1) ──
              ScaleTransition(
                scale: _logoScale,
                child: Column(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFFFF6B7D)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 18),
                    Text('Get Started', style: GoogleFonts.poppins(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('Everything You Need In One App', style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Form Section ──
              FadeTransition(
                opacity: _formFade,
                child: SlideTransition(
                  position: _formSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      _buildTextField(
                        controller: _emailCtrl,
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _buildTextField(
                        controller: _passwordCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey.shade400, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      // Error message container
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: GoogleFonts.poppins(
                                color: Colors.red.shade700, fontSize: 12))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Log In Button
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                              : Text('Log In', style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Google sign-in ──
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _loading ? null : _loginWithGoogle,
                          icon: Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 20, height: 20, errorBuilder:
                                (_, __, ___) => const Icon(Icons.g_mobiledata,
                                    color: Color(0xFF1E293B), size: 28),
                          ),
                          label: Text('Continue with Google',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign In / Register Option
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const StudentRegisterScreen())),
                          child: Text('Create Account / Sign Up', style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          filled: true, fillColor: Colors.white,
        ),
      ),
    );
  }
}
