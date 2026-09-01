import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/study_group_model.dart';
import '../../services/study_group_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key});

  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  final StudyGroupService _groupService = StudyGroupService();
  String _userName = 'Student';
  String _userDept = '';
  String? _photoUrl;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
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
            const SizedBox(height: 8),
            Expanded(child: _buildGroupList()),
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
                color: AppTheme.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.orange, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.orange.withValues(alpha: 0.15),
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null
                ? Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: AppTheme.orange),
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
            hintText: 'Search group name, subject..',
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

  Widget _buildGroupList() {
    return StreamBuilder<List<StudyGroupModel>>(
      stream: _groupService.getGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerList(count: 3, itemHeight: 150);
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('কোনো study group নেই',
                    style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: groups.length,
          itemBuilder: (context, index) =>
              _GroupCard(group: groups[index], myUid: _myUid),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final StudyGroupModel group;
  final String? myUid;
  const _GroupCard({required this.group, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final isMember = myUid != null && group.members.contains(myUid);
    final isCreator = myUid != null && group.creatorId == myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppTheme.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    Text('${group.members.length}/${group.maxMembers} members',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(group.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(group.location,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          if (isCreator)
            Row(
              children: [
                Expanded(
                  child: _actionButton('Chat', Icons.chat_bubble_outline,
                      AppTheme.orange, () {}),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton('Leave', Icons.logout,
                      Colors.grey, () {}),
                ),
              ],
            )
          else if (isMember)
            Row(
              children: [
                Expanded(
                  child: _actionButton('Chat', Icons.chat_bubble_outline,
                      AppTheme.orange, () {}),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton('Leave', Icons.logout,
                      Colors.grey, () {}),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: _actionButton('Join Group', Icons.add,
                  AppTheme.orange, () {}),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
