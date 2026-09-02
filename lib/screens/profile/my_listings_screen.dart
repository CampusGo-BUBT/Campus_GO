import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/book_service.dart';
import '../../models/book_model.dart';
import '../../services/hostel_service.dart';
import '../../services/job_service.dart';
import '../../services/notice_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../services/study_group_service.dart';
import '../../services/tutor_service.dart';
import '../../theme/app_theme.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profile = ProfileService();
  late TabController _tab;

  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _profile.myListings();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _list(String key) => (_data[key] as List?) ?? [];

  Future<void> _delete(String kind, String id) async {
    try {
      switch (kind) {
        case 'post':
          await PostService().deletePost(id);
          break;
        case 'book':
          await BookService().deleteBook(id);
          break;
        case 'job':
          await JobService().deleteJob(id);
          break;
        case 'hostel':
          await HostelService().deleteHostel(id);
          break;
        case 'notice':
          await NoticeService().deleteNotice(id);
          break;
        case 'tutor':
          await TutorService().deleteTutor(id);
          break;
        case 'group':
          await StudyGroupService().deleteGroup(id);
          break;
      }
      _load();
    } catch (_) {}
  }

  void _editPost(Map<String, dynamic> item) {
    final ctrl = TextEditingController(text: item['caption'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(controller: ctrl, maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await PostService().updatePost(item['id'], caption: ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editSingle(String kind, String id, String field, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient.instance.patch('/${_path(kind)}/$id/',
                    body: {field: ctrl.text.trim()});
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String _path(String kind) {
    switch (kind) {
      case 'post': return 'posts';
      case 'book': return 'books';
      case 'job': return 'jobs';
      case 'hostel': return 'hostels';
      case 'notice': return 'notices';
      case 'tutor': return 'tutors';
      case 'group': return 'study-groups';
      default: return 'posts';
    }
  }

  void _editBook(Map<String, dynamic> b) {
    final titleCtrl = TextEditingController(text: b['title'] ?? '');
    final authorCtrl = TextEditingController(text: b['author'] ?? '');
    final priceCtrl = TextEditingController(text: (b['price'] ?? '').toString());
    final conditionCtrl = TextEditingController(text: b['condition'] ?? 'Good');
    final phoneCtrl = TextEditingController(text: b['phone'] ?? '');
    final descCtrl = TextEditingController(text: b['description'] ?? '');
    File? imageFile;

    Future<void> pickImage() async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) imageFile = File(img.path);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Book'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
            const SizedBox(height: 8),
            TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: 'Condition')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact phone')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: () async { await pickImage(); setSt((){}); }, icon: const Icon(Icons.photo), label: const Text('Change image (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            try {
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              final book = BookModel(
                id: b['id'],
                title: titleCtrl.text.trim(),
                author: authorCtrl.text.trim(),
                price: price,
                originalPrice: (b['originalPrice'] as num?)?.toDouble() ?? 0.0,
                condition: conditionCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                userId: b['userId'] ?? '',
                sellerName: b['sellerName'] ?? '',
                imageUrl: b['imageUrl'] ?? '',
                description: descCtrl.text.trim(),
              );
              await BookService().updateBook(b['id'], book, image: imageFile);
            } catch (_) {}
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          }, child: const Text('Save')),
        ],
      )),
    );
  }
  void _editJob(Map<String, dynamic> j) {
    final titleCtrl = TextEditingController(text: j['title'] ?? '');
    final companyCtrl = TextEditingController(text: j['company'] ?? '');
    final locationCtrl = TextEditingController(text: j['location'] ?? '');
    final salaryCtrl = TextEditingController(text: j['salary']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: j['contactEmail'] ?? '');
    final descCtrl = TextEditingController(text: j['description'] ?? '');
    File? imageFile;

    Future<void> pickImage() async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) imageFile = File(img.path);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Job'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: 8),
            TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 8),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 8),
            TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Contact Email')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: () async { await pickImage(); setSt((){}); }, icon: const Icon(Icons.photo), label: const Text('Change image (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            try {
              final job = JobModel(
                id: j['id'],
                title: titleCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                location: locationCtrl.text.trim(),
                salary: salaryCtrl.text.trim(),
                description: descCtrl.text.trim(),
                contactEmail: emailCtrl.text.trim(),
                phone: j['phone'] ?? '',
                userId: j['userId'] ?? '',
                posterName: j['posterName'] ?? '',
                imageUrl: j['imageUrl'] ?? '',
              );
              await JobService().updateJob(j['id'], job, image: imageFile);
            } catch (_) {}
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          }, child: const Text('Save')),
        ],
      )),
    );
  }

  void _editHostel(Map<String, dynamic> h) {
    final nameCtrl = TextEditingController(text: h['name'] ?? '');
    final locationCtrl = TextEditingController(text: h['location'] ?? '');
    final rentCtrl = TextEditingController(text: (h['rent'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: h['phone'] ?? '');
    final descCtrl = TextEditingController(text: h['description'] ?? '');
    String selectedGender = h['gender'] ?? 'Boys';
    File? imageFile;

    Future<void> pickImage() async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) imageFile = File(img.path);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Hostel'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Hostel Name')),
            const SizedBox(height: 8),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 8),
            TextField(controller: rentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rent')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: ['Boys','Girls','Family'].map((g) {
              final sel = selectedGender == g;
              return GestureDetector(onTap: () => setSt(() => selectedGender = g), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: sel ? AppTheme.secondary : AppTheme.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Text(g, style: TextStyle(color: sel ? Colors.white : AppTheme.secondary))));
            }).toList()),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: () async { await pickImage(); setSt((){}); }, icon: const Icon(Icons.photo), label: const Text('Change image (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            try {
              final hostel = HostelModel(
                id: h['id'],
                name: nameCtrl.text.trim(),
                type: selectedGender,
                location: locationCtrl.text.trim(),
                rent: double.tryParse(rentCtrl.text.trim()) ?? 0,
                facilities: h['facilities'] ?? '',
                phone: phoneCtrl.text.trim(),
                userId: h['userId'] ?? '',
                ownerName: h['ownerName'] ?? '',
                gender: selectedGender,
                distance: h['distance'] ?? '',
                description: descCtrl.text.trim(),
              );
              await HostelService().updateHostel(h['id'], hostel, image: imageFile);
            } catch (_) {}
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          }, child: const Text('Save')),
        ],
      )),
    );
  }
  void _editNotice(Map<String, dynamic> n) => _editSingle('notice', n['id'], 'title', n['title'] ?? '');
  void _editTutor(Map<String, dynamic> t) => _editSingle('tutor', t['id'], 'title', t['title'] ?? '');
  void _editGroup(Map<String, dynamic> g) => _editSingle('group', g['id'], 'name', g['name'] ?? '');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text('My Listings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Books'),
            Tab(text: 'Jobs'),
            Tab(text: 'Hostels'),
            Tab(text: 'Notices'),
            Tab(text: 'Tuition'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _PostTab(items: _list('posts'), onEdit: _editPost, onDelete: _delete),
                _BookTab(items: _list('books'), onEdit: _editBook, onDelete: _delete),
                _JobTab(items: _list('jobs'), onEdit: _editJob, onDelete: _delete),
                _HostelTab(items: _list('hostels'), onEdit: _editHostel, onDelete: _delete),
                _NoticeTab(items: _list('notices'), onEdit: _editNotice, onDelete: _delete),
                _TutorTab(items: _list('tutors'), onEdit: _editTutor, onDelete: _delete),
                _GroupTab(items: _list('studyGroups'), onEdit: _editGroup, onDelete: _delete),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
        child: Text('Nothing here yet',
            style: GoogleFonts.poppins(color: Colors.grey.shade500)),
      );
}

class _PostTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _PostTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: (p['caption'] ?? '').isEmpty ? 'Post' : p['caption'],
          subtitle: 'Post',
          onEdit: () => onEdit(p),
          onDelete: () => onDelete('post', p['id']),
        );
      },
    );
  }
}

class _BookTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _BookTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final b = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: b['title'] ?? 'Book',
          subtitle: 'Book',
          onEdit: () => onEdit(b),
          onDelete: () => onDelete('book', b['id']),
        );
      },
    );
  }
}

class _JobTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _JobTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final j = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: j['title'] ?? 'Job',
          subtitle: 'Job',
          onEdit: () => onEdit(j),
          onDelete: () => onDelete('job', j['id']),
        );
      },
    );
  }
}

class _HostelTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _HostelTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final h = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: h['name'] ?? 'Hostel',
          subtitle: 'Hostel',
          onEdit: () => onEdit(h),
          onDelete: () => onDelete('hostel', h['id']),
        );
      },
    );
  }
}

class _NoticeTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _NoticeTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final n = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: n['title'] ?? 'Notice',
          subtitle: 'Notice',
          onEdit: () => onEdit(n),
          onDelete: () => onDelete('notice', n['id']),
        );
      },
    );
  }
}

class _TutorTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _TutorTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final t = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: t['title'] ?? 'Tuition',
          subtitle: 'Tuition',
          onEdit: () => onEdit(t),
          onDelete: () => onDelete('tutor', t['id']),
        );
      },
    );
  }
}

class _GroupTab extends StatelessWidget {
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String, String) onDelete;
  const _GroupTab({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final g = Map<String, dynamic>.from(items[i] as Map);
        return _Tile(
          title: g['name'] ?? 'Study Group',
          subtitle: 'Study Group',
          onEdit: () => onEdit(g),
          onDelete: () => onDelete('group', g['id']),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _Tile({required this.title, required this.subtitle, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
          if (onDelete != null)
            IconButton(
              onPressed: () => onDelete!(),
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
        ],
      ),
    );
  }
}
