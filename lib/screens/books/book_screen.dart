import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final BookService _bookService = BookService();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Good', 'Midlevel'];
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
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
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
          style: GoogleFonts.poppins(fontSize: 14),
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
        if (books.isEmpty) {
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
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: books.length,
          itemBuilder: (context, index) => _BookCard(book: books[index]),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: book.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: book.imageUrl,
                    width: 74,
                    height: 96,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 74,
                        height: 96,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.menu_book, color: Colors.grey)),
                    errorWidget: (_, __, ___) => Container(
                        width: 74,
                        height: 96,
                        color: AppTheme.green.withValues(alpha: 0.1),
                        child: const Icon(Icons.menu_book,
                            color: AppTheme.green)),
                  )
                : Container(
                    width: 74,
                    height: 96,
                    color: AppTheme.green.withValues(alpha: 0.1),
                    child: const Icon(Icons.menu_book,
                        color: AppTheme.green, size: 30),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(
                    '${book.author}${book.sellerName.isNotEmpty ? ' · Seller: ${book.sellerName}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text('${book.rating}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Text('(${book.reviewCount})',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('৳${book.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.green)),
                    if (book.originalPrice > book.price) ...[
                      const SizedBox(width: 6),
                      Text('৳${book.originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough)),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(book.condition,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.green)),
                    ),
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
