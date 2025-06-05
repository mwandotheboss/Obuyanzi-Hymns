import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';

class AdminCreateHymnPage extends StatefulWidget {
  final String userId;
  final String? userRole;
  final String? userName;
  final bool showAppBar;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const AdminCreateHymnPage({
    super.key,
    required this.userId,
    this.userRole,
    this.userName,
    this.showAppBar = true,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<AdminCreateHymnPage> createState() => _AdminCreateHymnPageState();
}

class _AdminCreateHymnPageState extends State<AdminCreateHymnPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _titleLuhyaController = TextEditingController();
  final _titleEnglishController = TextEditingController();
  final _languageController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _hasChangingChorus = false;
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  List<Verse> _verses = [];
  List<Chorus> _choruses = [];

  // Admin check now uses userRole
  bool get isAdmin => widget.userRole == 'admin';

  final HymnService _hymnService = HymnService();

  @override
  void dispose() {
    _numberController.dispose();
    _titleLuhyaController.dispose();
    _titleEnglishController.dispose();
    _languageController.dispose();
    _tagsController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _addVerse() async {
    final verse = await showDialog<Verse>(
      context: context,
      builder: (context) => _VerseDialog(choruses: _choruses),
    );
    if (verse != null) {
      setState(() {
        _verses.add(verse);
      });
    }
  }

  void _addChorus() async {
    final chorus = await showDialog<Chorus>(
      context: context,
      builder: (context) => _ChorusDialog(),
    );
    if (chorus != null) {
      setState(() {
        _choruses.add(chorus);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final hymn = Hymn(
        id: '', // Firestore will generate the ID
        number: _numberController.text,
        titleLuhya: _titleLuhyaController.text,
        titleEnglish: _titleEnglishController.text.isNotEmpty ? _titleEnglishController.text : null,
        language: _languageController.text,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        hasChangingChorus: _hasChangingChorus,
        createdAt: DateTime.now(),
        audioUrl: _audioUrlController.text.isNotEmpty ? _audioUrlController.text : null,
        videoUrl: _videoUrlController.text.isNotEmpty ? _videoUrlController.text : null,
        verses: _verses,
        choruses: _choruses,
      );
      try {
        await _hymnService.addHymn(hymn);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hymn saved successfully!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _verses = [];
          _choruses = [];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save hymn: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return widget.showAppBar
        ? const Scaffold(
            body: Center(child: Text('Access denied. Admins only.')),
          )
        : const Center(child: Text('Access denied. Admins only.'));
    }
    final formContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Hymn Number'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _titleLuhyaController,
              decoration: const InputDecoration(labelText: 'Title (Luhya)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _titleEnglishController,
              decoration: const InputDecoration(labelText: 'Title (English, optional)'),
            ),
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(labelText: 'Language'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            SwitchListTile(
              title: const Text('Has Changing Chorus'),
              value: _hasChangingChorus,
              onChanged: (v) => setState(() => _hasChangingChorus = v),
            ),
            TextFormField(
              controller: _audioUrlController,
              decoration: const InputDecoration(labelText: 'Audio URL (optional)'),
            ),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(labelText: 'Video URL (optional)'),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ..._verses.map((v) => ListTile(
                          title: Text('Verse ${v.verseNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.contentLuhya, maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (v.chorusRef != null)
                                Text(
                                  'Chorus: ' + (() {
                                    try {
                                      return _choruses.firstWhere((c) => c.id == v.chorusRef).chorusNumber.toString();
                                    } catch (e) {
                                      return v.chorusRef!;
                                    }
                                  })(),
                                  style: const TextStyle(fontSize: 12, color: Colors.amber),
                                ),
                            ],
                          ),
                        )),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addVerse,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Verse'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choruses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ..._choruses.map((c) => ListTile(
                          title: Text('Chorus ${c.chorusNumber}'),
                          subtitle: Text(c.contentLuhya, maxLines: 2, overflow: TextOverflow.ellipsis),
                        )),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addChorus,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Chorus'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit Hymn'),
            ),
          ],
        ),
      ),
    );
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Create Hymn (Admin)${widget.userName != null ? ' - ${widget.userName}' : ''}'),
          actions: [
            IconButton(
              icon: Icon(
                widget.themeMode == ThemeMode.system
                    ? Icons.brightness_auto
                    : widget.themeMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.dark_mode,
              ),
              tooltip: widget.themeMode == ThemeMode.system
                  ? 'System Theme'
                  : widget.themeMode == ThemeMode.light
                      ? 'Light Theme'
                      : 'Dark Theme',
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        body: formContent,
      );
    } else {
      return formContent;
    }
  }
}

class _VerseDialog extends StatefulWidget {
  final List<Chorus> choruses;
  const _VerseDialog({Key? key, required this.choruses}) : super(key: key);
  @override
  State<_VerseDialog> createState() => _VerseDialogState();
}

class _VerseDialogState extends State<_VerseDialog> {
  final _verseNumberController = TextEditingController();
  final _contentLuhyaController = TextEditingController();
  final _contentEnglishController = TextEditingController();
  String? _selectedChorusId;

  @override
  void dispose() {
    _verseNumberController.dispose();
    _contentLuhyaController.dispose();
    _contentEnglishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Verse'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _verseNumberController,
              decoration: const InputDecoration(labelText: 'Verse Number'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _contentLuhyaController,
              decoration: const InputDecoration(labelText: 'Content (Luhya)'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
              controller: _contentEnglishController,
              decoration: const InputDecoration(labelText: 'Content (English, optional)'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedChorusId,
              decoration: const InputDecoration(labelText: 'Chorus (optional)'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Chorus'),
                ),
                ...widget.choruses.map((chorus) => DropdownMenuItem<String>(
                      value: chorus.id,
                      child: Text('Chorus ${chorus.chorusNumber} - ${chorus.type.isNotEmpty ? chorus.type : ''}'),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedChorusId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final verse = Verse(
              id: UniqueKey().toString(),
              verseNumber: int.tryParse(_verseNumberController.text) ?? 1,
              contentLuhya: _contentLuhyaController.text,
              contentEnglish: _contentEnglishController.text.isNotEmpty ? _contentEnglishController.text : null,
              chorusRef: _selectedChorusId,
            );
            Navigator.pop(context, verse);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ChorusDialog extends StatefulWidget {
  @override
  State<_ChorusDialog> createState() => _ChorusDialogState();
}

class _ChorusDialogState extends State<_ChorusDialog> {
  final _chorusNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _contentLuhyaController = TextEditingController();
  final _contentEnglishController = TextEditingController();

  @override
  void dispose() {
    _chorusNumberController.dispose();
    _typeController.dispose();
    _contentLuhyaController.dispose();
    _contentEnglishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Chorus'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _chorusNumberController,
              decoration: const InputDecoration(labelText: 'Chorus Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextFormField(
              controller: _contentLuhyaController,
              decoration: const InputDecoration(labelText: 'Content (Luhya)'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
              controller: _contentEnglishController,
              decoration: const InputDecoration(labelText: 'Content (English, optional)'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final chorus = Chorus(
              id: UniqueKey().toString(),
              type: _typeController.text,
              chorusNumber: int.tryParse(_chorusNumberController.text) ?? 1,
              contentLuhya: _contentLuhyaController.text,
              contentEnglish: _contentEnglishController.text,
            );
            Navigator.pop(context, chorus);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
} 