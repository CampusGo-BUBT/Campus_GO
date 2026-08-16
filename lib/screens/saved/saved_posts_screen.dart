import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/post_service.dart';
import '../../models/feed_post.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/shimmer_loader.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Saved Posts', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<FeedPost>>(
        stream: PostService().savedPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList(count: 4, itemHeight: 200);
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('কোনো saved post নেই',
                      style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Posts-এ bookmark করলে এখানে দেখা যাবে',
                      style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: posts.length,
            itemBuilder: (context, index) => _AnimatedSavedCard(
                post: posts[index], index: index),
          );
        },
      ),
    );
  }
}

class _AnimatedSavedCard extends StatefulWidget {
  final FeedPost post;
  final int index;
  const _AnimatedSavedCard({required this.post, required this.index});

  @override
  State<_AnimatedSavedCard> createState() => _AnimatedSavedCardState();
}

class _AnimatedSavedCardState extends State<_AnimatedSavedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>  _fade;
  late Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 300)),
            () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _fade,
      child: SlideTransition(
          position: _slide, child: PostCard(post: widget.post)));
}
