import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/conversation_model.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../saved/saved_posts_screen.dart';
import '../profile/profile_screen.dart';
import '../post/create_post_screen.dart';
import '../study_group/direct_chat_screen.dart';
import '../../widgets/app_transitions.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat('hh:mm a').format(time);
    if (diff.inDays < 7) return DateFormat('EEE').format(time);
    return DateFormat('dd MMM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header (Matching Screenshot 2) ──────────────────
                FadeTransition(
                  opacity: _animCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Back Button (#EBF3FE circular box)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBF3FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF1A1A1A),
                                  size: 20,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Messages',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            // Notification Bell (#EBF3FE circular box)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEBF3FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF1A1A1A),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Search Bar (With mic icon matching Screenshot 2) ──
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v.toLowerCase()),
                                  style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Search here..',
                                    hintStyle: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.mic_none, color: Colors.grey.shade400, size: 22),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Horizontal User Stories Bar (Matching Screenshot 2) ──
                        SizedBox(
                          height: 64,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Add story button
                              Container(
                                width: 58,
                                height: 58,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey.shade300,
                                      style: BorderStyle.solid,
                                      width: 1.5),
                                ),
                                child: const Icon(Icons.add, color: Colors.grey, size: 26),
                              ),
                              // Demo story avatars
                              _buildStoryAvatar('https://images.unsplash.com/photo-1534528741775-53994a69daeb', Colors.amber),
                              _buildStoryAvatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d', Colors.grey),
                              _buildStoryAvatar('https://images.unsplash.com/photo-1500648767791-00dcc994a43e', Colors.grey),
                              _buildStoryAvatar('https://images.unsplash.com/photo-1494790108377-be9c29b29330', Colors.grey),
                              _buildStoryAvatar('https://images.unsplash.com/photo-1522075469751-3a6694fb2f61', Colors.blue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // ── Conversation List ────────────────────────────
                Expanded(
                  child: StreamBuilder<List<ConversationModel>>(
                    stream: _chatService.getInbox(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmer(isDark);
                      }

                      final conversations = snapshot.data ?? [];

                      if (conversations.isEmpty) {
                        return _buildEmptyState(isDark);
                      }

                      final filtered = conversations.where((c) {
                        if (_searchQuery.isEmpty) return true;
                        final otherId = c.otherUserId(myUid);
                        return otherId.toLowerCase().contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90, top: 8),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _AnimatedTile(
                          index: i,
                          child: _ConversationTile(
                            conversation: filtered[i],
                            myUid: myUid,
                            isDark: isDark,
                            textColor: textColor,
                            subColor: subColor,
                            cardColor: cardColor,
                            formatTime: _formatTime,
                            searchQuery: _searchQuery,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Floating Curved Blue Bottom Navigation Bar (Screenshot 2) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavBar(
                currentIndex: 1, // Messages active
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushAndRemoveUntil(context,
                        SlideUpRoute(page: const HomeScreen()), (r) => false);
                  } else if (index == 2) {
                    Navigator.push(context, SlideUpRoute(page: const SavedPostsScreen()));
                  } else if (index == 3) {
                    Navigator.push(context, SlideUpRoute(page: const ProfileScreen()));
                  }
                },
                onFabTap: () => Navigator.push(context, SlideUpRoute(page: const CreatePostScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(String url, Color borderColor) {
    return Container(
      width: 58,
      height: 58,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: CircleAvatar(
        backgroundImage: NetworkImage(url),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline,
                size: 38, color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'কোনো Message নেই',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'কারো post-এ Send বাটন চাপলে\nএখানে conversation দেখাবে।',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final shimmerColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String myUid;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final Color cardColor;
  final String Function(DateTime) formatTime;
  final String searchQuery;

  const _ConversationTile({
    required this.conversation,
    required this.myUid,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
    required this.formatTime,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final otherUid = conversation.otherUserId(myUid);
    if (otherUid.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: UserService.instance.getUser(otherUid),
      builder: (context, snap) {
        final data = snap.data;
        final name = (data?['name'] ?? data?['fullName'] ?? 'User') as String;
        final photoUrl = data?['photoUrl'] as String?;
        final isMe = conversation.lastSenderId == myUid;
        final previewText =
            isMe ? 'You: ${conversation.lastMessage}' : conversation.lastMessage;
        final timeStr = formatTime(conversation.lastMessageTime);

        if (searchQuery.isNotEmpty && !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DirectChatScreen(
                otherUserId: otherUid,
                otherUserName: name,
                otherUserPhotoUrl: photoUrl,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: subColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedTile({required this.index, required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: (widget.index * 55).clamp(0, 320)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
