import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/reference_note.dart';
import 'package:sc300_prep/theme/app_theme.dart';

class ReferenceLibraryScreen extends StatefulWidget {
  const ReferenceLibraryScreen({super.key});

  @override
  State<ReferenceLibraryScreen> createState() => _ReferenceLibraryScreenState();
}

class _ReferenceLibraryScreenState extends State<ReferenceLibraryScreen> {
  bool _loading = true;
  List<ReferenceNote> _notes = [];
  String? _selectedDomain;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await AppDatabase.instance.getAllReferenceNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  List<String> get _availableDomains {
    final present = _notes.map((n) => n.domain).toSet();
    final ordered = ExamConstants.allDomains.where(present.contains).toList();
    for (final d in present) {
      if (!ordered.contains(d)) ordered.add(d);
    }
    return ordered;
  }

  Map<String, List<ReferenceNote>> get _grouped {
    final filtered = _selectedDomain == null
        ? _notes
        : _notes.where((n) => n.domain == _selectedDomain).toList();
    final map = <String, List<ReferenceNote>>{};
    final domainsToGroup = <String>{...ExamConstants.allDomains, ...filtered.map((n) => n.domain)};
    for (final domain in domainsToGroup) {
      final inDomain = filtered.where((n) => n.domain == domain).toList();
      if (inDomain.isNotEmpty) map[domain] = inDomain;
    }
    return map;
  }

  Future<void> _openNote(ReferenceNote note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReferenceNoteDetailScreen(note: note)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reference Library')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No reference notes found yet. Check back once the library is seeded.'),
                  ),
                )
              : Column(
                  children: [
                    _buildDomainFilter(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  Widget _buildDomainFilter() {
    final domains = _availableDomains;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: _selectedDomain == null,
              onSelected: (_) => setState(() => _selectedDomain = null),
            ),
          ),
          for (final domain in domains)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(domain),
                selected: _selectedDomain == domain,
                selectedColor: AppTheme.domainColor(domain).withAlpha(90),
                onSelected: (_) => setState(() => _selectedDomain = domain),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + AppTheme.safeBottomInset(context)),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.domainColor(entry.key),
              ),
            ),
          ),
          for (final note in entry.value) _buildNoteCard(note),
        ],
      ],
    );
  }

  Widget _buildNoteCard(ReferenceNote note) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.domainColor(note.domain).withAlpha(60),
          child: const Icon(Icons.menu_book, size: 20),
        ),
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(note.topic),
        trailing: note.bookmarked
            ? const Icon(Icons.bookmark, color: AppTheme.xpColor, size: 20)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openNote(note),
      ),
    );
  }
}

class ReferenceNoteDetailScreen extends StatefulWidget {
  final ReferenceNote note;
  const ReferenceNoteDetailScreen({super.key, required this.note});

  @override
  State<ReferenceNoteDetailScreen> createState() => _ReferenceNoteDetailScreenState();
}

class _ReferenceNoteDetailScreenState extends State<ReferenceNoteDetailScreen> {
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.note.bookmarked;
    AppDatabase.instance.markReferenceNoteAsRead(widget.note.id);
  }

  Future<void> _toggleBookmark() async {
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    await AppDatabase.instance.toggleReferenceNoteBookmark(widget.note.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return Scaffold(
      appBar: AppBar(
        title: Text(note.topic),
        actions: [
          IconButton(
            icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
            color: _bookmarked ? AppTheme.xpColor : null,
            onPressed: _toggleBookmark,
            tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark this note',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + AppTheme.safeBottomInset(context)),
          children: [
            Chip(
              label: Text(note.domain, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppTheme.domainColor(note.domain).withAlpha(50),
            ),
            const SizedBox(height: 12),
            Text(note.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SelectableText(note.body, style: const TextStyle(fontSize: 15, height: 1.4)),
            if (note.sourceUrl != null && note.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Source', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        SelectableText(
                          note.sourceUrl!,
                          style: const TextStyle(fontSize: 13, color: Colors.lightBlueAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
