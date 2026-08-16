import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
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
import 'book_detail_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final BookService _bookService = BookService();
  final ImagePicker _picker = ImagePicker();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Good', 'Midlevel'];
  String _searchQuery = '';
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

  Color _conditionColor(String c) {
    switch (c) {
      case 'New':    return AppTheme.green;
      case 'Good':   return AppTheme.primary;
      default:       return AppTheme.orange;
    }
  }

  void _showAddBookDialog() {
    final titleCtrl    = TextEditingController();
    final authorCtrl   = TextEditingController();
    final priceCtrl    = TextEditingController();
    final origPriceCtrl = TextEditingController();
    final phoneCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    String selectedCondition = 'Good';
    XFile? selectedImage;
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
                Center(
                  child: Container(
                    width: 44, height: 4,
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
                        color: AppTheme.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book, color: AppTheme.green, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Book বিক্রি করো',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (img != null) setModal(() => selectedImage = img);
                  },
                  child: Container(
                    width: double.infinity, height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.green.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(selectedImage!.path), fit: BoxFit.cover))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 40, color: AppTheme.green.withValues(alpha: 0.6)),
                            const SizedBox(height: 8),
                            Text('Book-এর ছবি দিন',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.green, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
                const SizedBox(height: 14),
                _buildField(titleCtrl, 'Book-এর নাম *', Icons.menu_book_outlined),
                const SizedBox(height: 10),
                _buildField(authorCtrl, 'লেখকের নাম', Icons.person_outline),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildField(priceCtrl, 'দাম (৳) *', Icons.attach_money, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(origPriceCtrl, 'আগের দাম (৳)', Icons.money_off, type: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                _buildField(phoneCtrl, 'Phone Number *', Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 10),
                _buildField(descCtrl, 'বিস্তারিত (Description)', Icons.description_outlined),
                const SizedBox(height: 14),
                Text('Condition:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['New', 'Good', 'Midlevel'].map((c) {
                    final sel = selectedCondition == c;
                    final col = _conditionColor(c);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setModal(() => selectedCondition = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? col : col.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: col.withValues(alpha: 0.4)),
                          ),
                          child: Text(c,
                              style: GoogleFonts.poppins(
                                  color: sel ? Colors.white : col,
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('বইয়ের নাম ও দাম দেওয়া আবশ্যক!')));
                        return;
                      }
                      setModal(() => isLoading = true);
                      try {
                        final nav = Navigator.of(ctx);
                        final user = FirebaseAuth.instance.currentUser;
                        final book = BookModel(
                          id: '', title: titleCtrl.text.trim(), author: authorCtrl.text.trim(),
                          price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                          originalPrice: double.tryParse(origPriceCtrl.text.trim()) ?? 0,
                          condition: selectedCondition, phone: phoneCtrl.text.trim(),
                          userId: user?.uid ?? 'guest', sellerName: _userName,
                          imageUrl: '', description: descCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await _bookService.addBook(
                          book,
                          image: selectedImage != null ? File(selectedImage!.path) : null,
                        );
                        PostService().createPost(
                          caption: '📚 Book for sale: ${book.title} by ${book.author} — ৳${book.price.toInt()}. Call: ${book.phone}',
                          type: 'book',
                        ).catchError((_) {});
                        if (ctx.mounted) nav.pop();
                      } catch (e) {
                        setModal(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Post করা যায়নি: $e')));
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Post Book',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.green, size: 20),
        filled: true, fillColor: AppTheme.green.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.green, width: 1.5)),
      ),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      SlideUpRoute(page: const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor  = isDark ? Colors.white60 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  color: cardColor,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppTheme.green, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.green.withValues(alpha: 0.15),
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null
                                ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold, color: AppTheme.green))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_userName.isNotEmpty ? _userName : 'Student',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                                Text(_userDept.isNotEmpty ? _userDept : 'Student',
                                    style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
                              ],
                            ),
                          ),
                          // Home button
                          GestureDetector(
                            onTap: _goHome,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.home_rounded, color: AppTheme.green, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search book name, author...',
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

                // ── Filter chips ──────────────────────────────────────────
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      final sel = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.green : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel ? AppTheme.green : Colors.grey.shade300),
                            ),
                            child: Text(f,
                                style: GoogleFonts.poppins(
                                    color: sel ? Colors.white : subColor,
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Book Grid ─────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<BookModel>>(
                    stream: _selectedFilter == 'All'
                        ? _bookService.getBooks()
                        : _bookService.getBooksByCondition(_selectedFilter),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerList(count: 4, itemHeight: 220);
                      }
                      var books = snapshot.data ?? [];
                      if (_searchQuery.isNotEmpty) {
                        books = books.where((b) =>
                            b.title.toLowerCase().contains(_searchQuery) ||
                            b.author.toLowerCase().contains(_searchQuery)).toList();
                      }
                      if (books.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('কোনো book নেই',
                                  style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.green,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12))),
                                onPressed: _showAddBookDialog,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text('Book Add করো',
                                    style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) =>
                            _BookGridCard(book: books[index], isDark: isDark),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Bottom Nav ────────────────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
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
                onFabTap: _showAddBookDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book Grid Card ─────────────────────────────────────────────────────────
class _BookGridCard extends StatelessWidget {
  final BookModel book;
  final bool isDark;
  const _BookGridCard({required this.book, required this.isDark});

  Color _conditionColor(String c) {
    switch (c) {
      case 'New':    return AppTheme.green;
      case 'Good':   return AppTheme.primary;
      default:       return AppTheme.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final col = _conditionColor(book.condition);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          SlideUpRoute(page: BookDetailScreen(book: book))),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book image
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    book.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.imageUrl, fit: BoxFit.cover,
                            placeholder: (c, u) => Container(color: Colors.grey.shade100),
                            errorWidget: (c, u, e) => _noImage(),
                          )
                        : _noImage(),
                    // Condition badge
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: col, borderRadius: BorderRadius.circular(10)),
                        child: Text(book.condition,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              // Book info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.bold, color: titleColor)),
                    const SizedBox(height: 2),
                    // Stars
                    Row(children: [
                      ...List.generate(4, (_) => const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 13)),
                      const Icon(Icons.star_half_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 4),
                      Text('${book.reviewCount}',
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('৳${book.price.toInt()}',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
                      if (book.originalPrice > book.price) ...[
                        const SizedBox(width: 5),
                        Text('৳${book.originalPrice.toInt()}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough)),
                      ],
                      const Spacer(),
                      Icon(Icons.bookmark_border_rounded,
                          color: Colors.grey.shade400, size: 18),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noImage() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.green.withValues(alpha: 0.15), AppTheme.green.withValues(alpha: 0.05)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: Icon(Icons.menu_book_rounded, color: AppTheme.green, size: 44)),
  );
}
