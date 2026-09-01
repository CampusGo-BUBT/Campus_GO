import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final AdminService _admin = AdminService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _admin.pendingItems();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(String kind, String id, String action) async {
    await _admin.moderate(kind, id, action);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text('Pending Requests',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text('No pending requests',
                      style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _ReviewCard(item: item, onAction: _act);
                  },
                ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(String, String, String) onAction;
  const _ReviewCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final kind = item['kind'] ?? 'post';
    final title = item['title'] ?? item['caption'] ?? item['name'] ?? 'Untitled';
    final author = item['authorName'] ?? item['posterName'] ?? item['ownerName'] ?? 'Unknown';
    final desc = item['description'] ?? item['caption'] ?? item['location'] ?? '';
    final kindColor = {
      'post': AppTheme.green,
      'job': AppTheme.primary,
      'hostel': AppTheme.secondary,
      'tutor': AppTheme.orange,
    }[kind] ?? AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(kind.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kindColor)),
              ),
              const Spacer(),
              Text('${item['applicantCount'] ?? ''}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('By: $author',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => onAction(kind, item['id'], 'approve'),
                  child: Text('Approve',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => onAction(kind, item['id'], 'reject'),
                  child: Text('Reject',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
