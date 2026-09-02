import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/smart_image.dart';
import 'book_detail_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filters = ['All', 'New', 'Good', 'Midlevel'];
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
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildSearch(isDark),
            _buildFilters(isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildBookList()),
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
                color: AppTheme.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.green, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.green.withValues(alpha: 0.15),
            backgroundImage: imageProviderFor(_photoUrl),
            child: _photoUrl == null
                ? Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: AppTheme.green),
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
            hintText: 'Search book name,author...',
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final f = _filters[index];
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppTheme.green : Colors.grey.shade300),
                ),
                child: Text(f,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey.shade600)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBookDialog() {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCondition = 'Good';
    bool isLoading = false;
    File? imageFile;

    Future<void> pickImage() async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) imageFile = File(img.path);
    }

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
                          color: AppTheme.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.menu_book, color: AppTheme.green, size: 20)),
                  const SizedBox(width: 10),
                  Text('Sell a Book',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _field(titleCtrl, 'Book Title *', Icons.title),
                const SizedBox(height: 10),
                _field(authorCtrl, 'Author *', Icons.person_outline),
                const SizedBox(height: 10),
                _field(priceCtrl, 'Price (৳) *', Icons.attach_money, type: TextInputType.number),
                const SizedBox(height: 10),
                _field(phoneCtrl, 'Contact Phone', Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 10),
                _field(descCtrl, 'Description', Icons.description_outlined),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async { await pickImage(); setModal(() {}); },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: imageFile != null ? null : AppTheme.green.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.green.withValues(alpha: 0.15)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageFile != null
                        ? AspectRatio(aspectRatio: 1.4, child: Image.file(imageFile!, fit: BoxFit.cover))
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Add image (optional)', style: GoogleFonts.poppins(color: AppTheme.green)),
                            ]),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Condition:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['New', 'Good', 'Midlevel'].map((c) {
                    final sel = selectedCondition == c;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedCondition = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.green : AppTheme.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16)),
                        child: Text(c,
                            style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppTheme.green,
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
                      backgroundColor: AppTheme.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: isLoading ? null : () async {
                      if (titleCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title, author and price are required!')));
                        return;
                      }
                      setModal(() => isLoading = true);
                      try {
                        final book = BookModel(
                          id: '',
                          title: titleCtrl.text.trim(),
                          author: authorCtrl.text.trim(),
                          price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                          condition: selectedCondition,
                          phone: phoneCtrl.text.trim(),
                          userId: '',
                          sellerName: '',
                          description: descCtrl.text.trim(),
                        );
                        await _bookService.addBook(book, image: imageFile);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModal(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Could not post book: $e')));
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Post Book', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.green, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBookList() {
    final stream = _selectedFilter == 'All'
        ? _bookService.getBooks()
        : _bookService.getBooksByCondition(_selectedFilter);
    return StreamBuilder<List<BookModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerList(count: 4, itemHeight: 140);
        }
        final books = snapshot.data ?? [];
        final filtered = _searchQuery.isEmpty
            ? books
            : books
                .where((b) =>
                    b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    b.author.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('কোনো book নেই',
                    style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _BookCard(book: filtered[index]),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  child: book.imageUrl.isNotEmpty
                      ? SmartImage(book.imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: AppTheme.green.withValues(alpha: 0.1),
                          child: const Icon(Icons.menu_book,
                              color: AppTheme.green, size: 32),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 2),
            Text(
                '${book.author}${book.sellerName.isNotEmpty ? ' · ${book.sellerName}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                const SizedBox(width: 2),
                Text('${book.rating}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                Text('(${book.reviewCount})',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('৳${book.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.green)),
                if (book.originalPrice > book.price) ...[
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '৳${book.originalPrice.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(book.condition,
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
