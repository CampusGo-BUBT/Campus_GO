import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/feed_post.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../screens/study_group/direct_chat_screen.dart';
import 'smart_image.dart';

class PostCard extends StatefulWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
    _likeScale =
        CurvedAnimation(parent: _likeController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _animateLike() {
    _likeController.forward().then((_) => _likeController.reverse());
  }

  void _openAuthorChat(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (widget.post.authorId.isEmpty || widget.post.authorId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নিজের post-এ message পাঠানো যাবে না')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          otherUserId: widget.post.authorId,
          otherUserName: widget.post.authorName,
        ),
      ),
    );
  }

  void _editPost(BuildContext context) {
    final ctrl = TextEditingController(text: widget.post.caption);
    String editType = widget.post.type;
    File? imageFile;

    Future<void> pickImage() async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) imageFile = File(img.path);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Post'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Caption'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: editType,
              items: ['general','job','notice','tuition','sales','study','hostel','book']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setSt(() => editType = v ?? editType),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: () async { await pickImage(); setSt((){}); }, icon: const Icon(Icons.photo), label: const Text('Change image (optional)')),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await PostService().updatePost(widget.post.id,
                  caption: ctrl.text.trim(), type: editType, imageFile: imageFile);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = uid != null && widget.post.likedBy.contains(uid);
    final isSaved = uid != null && widget.post.savedBy.contains(uid);
    final postService = PostService();
    final typeMeta = _postTypeMeta(widget.post.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final caption = widget.post.caption;
    final isLongCaption = caption.length > 120;
    final displayCaption =
        (isLongCaption && !_expanded) ? '${caption.substring(0, 120)}…' : caption;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colored Top Strip ──────────────────────────
            Container(
              height: 4,
              color: typeMeta.color,
            ),

            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeMeta.color.withValues(alpha: 0.12),
                    backgroundImage: widget.post.authorPhotoUrl != null &&
                            widget.post.authorPhotoUrl!.isNotEmpty
                        ? NetworkImage(widget.post.authorPhotoUrl!)
                        : null,
                    child: widget.post.authorPhotoUrl == null ||
                            widget.post.authorPhotoUrl!.isEmpty
                        ? Text(
                      widget.post.authorName.isNotEmpty
                          ? widget.post.authorName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: typeMeta.color),
                    )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.authorName,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A))),
                        Text(widget.post.authorHandle,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (widget.post.authorId == uid)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 20, color: Colors.grey.shade500),
                      onSelected: (v) {
                        if (v == 'edit') {
                          _editPost(context);
                        } else if (v == 'delete') {
                          PostService().deletePost(widget.post.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  // Type Badge
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeMeta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeMeta.icon, size: 11, color: typeMeta.color),
                        const SizedBox(width: 4),
                        Text(
                          typeMeta.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: typeMeta.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Caption ──────────────────────────────────────
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayCaption,
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            height: 1.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.88)
                                : Colors.grey.shade800)),
                    if (isLongCaption)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _expanded ? 'See less' : 'See more',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: typeMeta.color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // ── Image ──────────────────────────────────────
            if (widget.post.imageUrl != null &&
                widget.post.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.4,
                      child: SmartImage(widget.post.imageUrl!, fit: BoxFit.cover),
                    ),
                    // Action bar overlay
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mode_comment_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text('${widget.post.commentCount}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                _animateLike();
                                postService.toggleLike(
                                    widget.post.id, isLiked);
                              },
                              child: ScaleTransition(
                                scale: _likeScale,
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked
                                      ? AppTheme.primary
                                      : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${widget.post.likedBy.length}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _openAuthorChat(context),
                              child: const Icon(Icons.send_outlined,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => postService.toggleSave(
                                  widget.post.id, isSaved),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  key: ValueKey(isSaved),
                                  color: isSaved
                                      ? AppTheme.primary
                                      : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
            // Text-only post actions
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _animateLike();
                        postService.toggleLike(widget.post.id, isLiked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _likeScale,
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 19,
                                color: isLiked
                                    ? AppTheme.primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${widget.post.likedBy.length}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.mode_comment_outlined,
                          size: 17, color: Colors.grey.shade400),
                      label: Text('${widget.post.commentCount}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Message',
                      onPressed: () => _openAuthorChat(context),
                      icon: Icon(Icons.send_outlined,
                          size: 19, color: Colors.grey.shade400),
                    ),
                    GestureDetector(
                      onTap: () =>
                          postService.toggleSave(widget.post.id, isSaved),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey(isSaved),
                          size: 19,
                          color: isSaved
                              ? typeMeta.color
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  _PostTypeMeta _postTypeMeta(String type) {
    switch (type) {
      case 'job':
        return _PostTypeMeta('Job', AppTheme.red, Icons.work_outline);
      case 'notice':
        return _PostTypeMeta('Notice', AppTheme.cyan, Icons.campaign_outlined);
      case 'tuition':
        return _PostTypeMeta('Tuition', AppTheme.primary, Icons.person_search);
      case 'study':
        return _PostTypeMeta(
            'Study Group', AppTheme.orange, Icons.groups_outlined);
      case 'hostel':
        return _PostTypeMeta('Hostel', AppTheme.secondary, Icons.home_work_outlined);
      case 'book':
        return _PostTypeMeta('Book', AppTheme.green, Icons.menu_book_outlined);
      default:
        return _PostTypeMeta('General', const Color(0xFF64748B), Icons.feed_outlined);
    }
  }
}

class _PostTypeMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _PostTypeMeta(this.label, this.color, this.icon);
}
