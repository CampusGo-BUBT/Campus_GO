import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminItemsScreen extends StatefulWidget {
  final String kind;
  const AdminItemsScreen({super.key, required this.kind});

  @override
  State<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends State<AdminItemsScreen> {
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
      final items = await _admin.listItems(widget.kind);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    await _admin.moderate(widget.kind, id, 'delete');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text('${widget.kind[0].toUpperCase()}${widget.kind.substring(1)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text('No items',
                      style: GoogleFonts.poppins(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final title = item['title'] ??
                        item['caption'] ??
                        item['name'] ??
                        'Untitled';
                    final author = item['authorName'] ??
                        item['posterName'] ??
                        item['ownerName'] ??
                        'Unknown';
                    final status = item['status'] ?? 'approved';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B))),
                                const SizedBox(height: 4),
                                Text('By: $author',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text('Status: $status',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: status == 'approved'
                                            ? AppTheme.green
                                            : (status == 'pending'
                                                ? AppTheme.orange
                                                : Colors.red))),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _delete(item['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
