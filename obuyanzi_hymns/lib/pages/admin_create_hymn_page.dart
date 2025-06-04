import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';

class AdminCreateHymnPage extends StatefulWidget {
  final String userId;
  final String? userRole;
  final String? userName;
  const AdminCreateHymnPage({super.key, required this.userId, this.userRole, this.userName});

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
      builder: (context) => _VerseDialog(),
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
      return const Scaffold(
        body: Center(child: Text('Access denied. Admins only.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Create Hymn (Admin)${widget.userName != null ? ' - ${widget.userName}' : ''}')),
      body: Padding(
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
              Text('Verses', style: Theme.of(context).textTheme.titleMedium),
              ..._verses.map((v) => ListTile(
                    title: Text('Verse ${v.verseNumber}'),
                    subtitle: Text(v.contentLuhya),
                  )),
              TextButton.icon(
                onPressed: _addVerse,
                icon: const Icon(Icons.add),
                label: const Text('Add Verse'),
              ),
              const SizedBox(height: 16),
              Text('Choruses', style: Theme.of(context).textTheme.titleMedium),
              ..._choruses.map((c) => ListTile(
                    title: Text('Chorus ${c.chorusNumber}'),
                    subtitle: Text(c.contentLuhya),
                  )),
              TextButton.icon(
                onPressed: _addChorus,
                icon: const Icon(Icons.add),
                label: const Text('Add Chorus'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Hymn'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseDialog extends StatefulWidget {
  @override
  State<_VerseDialog> createState() => _VerseDialogState();
}

class _VerseDialogState extends State<_VerseDialog> {
  final _verseNumberController = TextEditingController();
  final _contentLuhyaController = TextEditingController();
  final _contentEnglishController = TextEditingController();
  final _chorusRefController = TextEditingController();

  @override
  void dispose() {
    _verseNumberController.dispose();
    _contentLuhyaController.dispose();
    _contentEnglishController.dispose();
    _chorusRefController.dispose();
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
            TextField(
              controller: _contentLuhyaController,
              decoration: const InputDecoration(labelText: 'Content (Luhya)'),
            ),
            TextField(
              controller: _contentEnglishController,
              decoration: const InputDecoration(labelText: 'Content (English, optional)'),
            ),
            TextField(
              controller: _chorusRefController,
              decoration: const InputDecoration(labelText: 'Chorus Ref (optional)'),
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
              chorusRef: _chorusRefController.text.isNotEmpty ? _chorusRefController.text : null,
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
            TextField(
              controller: _contentLuhyaController,
              decoration: const InputDecoration(labelText: 'Content (Luhya)'),
            ),
            TextField(
              controller: _contentEnglishController,
              decoration: const InputDecoration(labelText: 'Content (English, optional)'),
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