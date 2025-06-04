import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../models/bookmark.dart';
import '../services/hymn_service.dart';
import '../services/bookmark_service.dart';
import '../models/language_preference.dart';

class HymnDetailPage extends StatefulWidget {
  final String hymnId;
  final String userId;

  const HymnDetailPage({
    super.key,
    required this.hymnId,
    required this.userId,
  });

  @override
  State<HymnDetailPage> createState() => _HymnDetailPageState();
}

class _HymnDetailPageState extends State<HymnDetailPage> {
  final HymnService _hymnService = HymnService();
  final BookmarkService _bookmarkService = BookmarkService();
  LanguagePreference _languagePreference = LanguagePreference.both;
  bool _isFavorite = false;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    final bookmark = await _bookmarkService.getBookmark(
      widget.userId,
      widget.hymnId,
    );
    if (mounted) {
      setState(() {
        _isFavorite = bookmark?.isFavorite ?? false;
        _scheduledDate = bookmark?.scheduledDate;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _bookmarkService.toggleFavorite(widget.userId, widget.hymnId);
    await _loadBookmarkStatus();
  }

  Future<void> _showScheduleDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TextEditingController noteController = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Note (Optional)'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: 'Enter a note for this scheduled hymn',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Schedule'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _bookmarkService.scheduleHymn(
          widget.userId,
          widget.hymnId,
          pickedDate,
          note: noteController.text.isNotEmpty ? noteController.text : null,
        );
        await _loadBookmarkStatus();
      }
    }
  }

  Future<void> _removeSchedule() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Schedule'),
        content: const Text('Are you sure you want to remove this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookmarkService.removeSchedule(widget.userId, widget.hymnId);
      await _loadBookmarkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hymn Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              _scheduledDate != null ? Icons.event : Icons.event_available,
              color: _scheduledDate != null ? Colors.blue : null,
            ),
            onPressed: _scheduledDate != null ? _removeSchedule : _showScheduleDialog,
          ),
          DropdownButton<LanguagePreference>(
            value: _languagePreference,
            items: const [
              DropdownMenuItem(
                value: LanguagePreference.english,
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: LanguagePreference.luhya,
                child: Text('Luhya'),
              ),
              DropdownMenuItem(
                value: LanguagePreference.both,
                child: Text('Both'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _languagePreference = value;
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Hymn?>(
        future: _hymnService.getHymn(widget.hymnId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final hymn = snapshot.data;
          if (hymn == null) {
            return const Center(
              child: Text('Hymn not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_scheduledDate != null) ...[
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled for ${_scheduledDate!.toString().split(' ')[0]}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Hymn ${hymn.number}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _languagePreference == LanguagePreference.english
                      ? hymn.titleEnglish ?? ''
                      : _languagePreference == LanguagePreference.luhya
                          ? hymn.titleLuhya
                          : '${hymn.titleEnglish ?? ''}\n${hymn.titleLuhya}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                Wrap(
                  spacing: 8,
                  children: hymn.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                ...hymn.verses.map((verse) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verse ${verse.verseNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _languagePreference == LanguagePreference.english
                            ? verse.contentEnglish ?? ''
                            : _languagePreference == LanguagePreference.luhya
                                ? verse.contentLuhya
                                : '${verse.contentEnglish ?? ''}\n${verse.contentLuhya}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      if (verse.chorusRef != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Chorus',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _languagePreference == LanguagePreference.english
                              ? hymn.choruses
                                  .firstWhere((c) => c.id == verse.chorusRef)
                                  .contentEnglish ?? ''
                              : _languagePreference == LanguagePreference.luhya
                                  ? hymn.choruses
                                      .firstWhere((c) => c.id == verse.chorusRef)
                                      .contentLuhya
                                  : '${hymn.choruses.firstWhere((c) => c.id == verse.chorusRef).contentEnglish}\n${hymn.choruses.firstWhere((c) => c.id == verse.chorusRef).contentLuhya}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }).toList(),

                if (hymn.audioUrl != null || hymn.videoUrl != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hymn.audioUrl != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement audio playback
                          },
                          icon: const Icon(Icons.audio_file),
                          label: const Text('Play Audio'),
                        ),
                      if (hymn.audioUrl != null && hymn.videoUrl != null)
                        const SizedBox(width: 16),
                      if (hymn.videoUrl != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement video playback
                          },
                          icon: const Icon(Icons.video_library),
                          label: const Text('Watch Video'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 