import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _captionCtrl = TextEditingController();
  String _selectedType = 'general';
  File? _imageFile;
  bool _loading = false;

  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final List<_TypeOption> _types = const [
    _TypeOption('general', '💬 General',  AppTheme.primary),
    _TypeOption('job',     '💼 Job',       AppTheme.red),
    _TypeOption('notice',  '📢 Notice',    AppTheme.cyan),
    _TypeOption('tuition', '📚 Tuition',   Color(0xFFE67E22)),
    _TypeOption('sales',   '🛒 Sales',     Color(0xFF27AE60)),
    _TypeOption('study',   '📖 Study',     Color(0xFF8E44AD)),
    _TypeOption('hostel',  '🏠 Hostel',    Color(0xFF2E86C1)),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _imageFile = File(img.path));
  }

  Future<void> _submit() async {
    if (_captionCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final nav = Navigator.of(context);
      await PostService().createPost(
        caption: _captionCtrl.text.trim(),
        type: _selectedType,
        imageFile: _imageFile,
      );
      if (mounted) nav.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _types.firstWhere((t) => t.value == _selectedType);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: selectedOption.color,
        title: Text(
          'Post তৈরি করো',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Text(
              'Post',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Type',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final sel = _selectedType == t.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = t.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? t.color : t.color.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: t.color.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          t.label,
                          style: GoogleFonts.poppins(
                            color: sel ? Colors.white : t.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: TextField(
                    controller: _captionCtrl,
                    maxLines: 6,
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'কী বলতে চাও?',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400, fontSize: 15),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _imageFile != null
                          ? null
                          : selectedOption.color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selectedOption.color.withValues(alpha: 0.3)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageFile != null
                        ? Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.4,
                          child:
                          Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 32),
                      child: Column(children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: selectedOption.color.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'ছবি যোগ করো (optional)',
                          style: GoogleFonts.poppins(
                              color: selectedOption.color, fontSize: 13),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeOption {
  final String value;
  final String label;
  final Color color;
  const _TypeOption(this.value, this.label, this.color);
}
