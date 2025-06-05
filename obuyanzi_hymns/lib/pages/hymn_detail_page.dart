import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../models/bookmark.dart';
import '../services/hymn_service.dart';
import '../services/bookmark_service.dart';
import '../models/language_preference.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

class HymnDetailPage extends StatefulWidget {
  final String hymnId;
  final String userId;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HymnDetailPage({
    super.key,
    required this.hymnId,
    required this.userId,
    required this.onToggleTheme,
    required this.themeMode,
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

  ja.AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
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

  Future<void> _initAudio(String url) async {
    _audioPlayer ??= ja.AudioPlayer();
    try {
      await _audioPlayer!.setUrl(url);
    } catch (e) {}
  }

  Future<void> _initVideo(String url) async {
    if (_videoController == null || _currentVideoUrl != url) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _currentVideoUrl = url;
      setState(() {
        _videoInitialized = true;
      });
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
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

          // Initialize video controller if needed
          if (hymn.videoUrl != null && hymn.videoUrl!.isNotEmpty) {
            _initVideo(hymn.videoUrl!);
          }

          final sortedVerses = [...hymn.verses]..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 32,
              vertical: isMobile ? 12 : 24,
            ),
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
                // Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.95),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 32,
                      vertical: isMobile ? 20 : 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hymn ${hymn.number}',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hymn.titleLuhya,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if ((hymn.titleEnglish ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            hymn.titleEnglish ?? '',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.85),
                            ),
                          ),
                        ],
                        if (hymn.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: hymn.tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(thickness: 2),
                const SizedBox(height: 8),
                Text('Verses', style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                )),
                const SizedBox(height: 12),
                ...sortedVerses.asMap().entries.expand((entry) {
                  final index = entry.key;
                  final verse = entry.value;
                  final List<Widget> widgets = [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: isMobile ? 14 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                                  child: Text(
                                    verse.verseNumber.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Verse ${verse.verseNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 16 : 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _languagePreference == LanguagePreference.english
                                  ? (verse.contentEnglish ?? '')
                                  : _languagePreference == LanguagePreference.luhya
                                      ? verse.contentLuhya
                                      : (verse.contentEnglish ?? '') + '\n' + verse.contentLuhya,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                  if (verse.chorusRef != null) {
                    Chorus? chorus;
                    try {
                      chorus = hymn.choruses.firstWhere((c) => c.id == verse.chorusRef);
                    } catch (e) {
                      chorus = null;
                    }
                    if (chorus != null) {
                      widgets.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : 16,
                                vertical: isMobile ? 10 : 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.music_note, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chorus',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontSize: isMobile ? 15 : 17,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _languagePreference == LanguagePreference.english
                                              ? (chorus.contentEnglish ?? '')
                                              : _languagePreference == LanguagePreference.luhya
                                                  ? chorus.contentLuhya
                                                  : (chorus.contentEnglish ?? '') + '\n' + chorus.contentLuhya,
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontSize: isMobile ? 15 : 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  return widgets;
                }).toList(),
                // Place audio/video preview at the bottom, audio first, then video
                if (hymn.audioUrl != null || hymn.videoUrl != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      Widget audioWidget = const SizedBox.shrink();
                      Widget videoWidget = const SizedBox.shrink();
                      // AUDIO
                      if (hymn.audioUrl != null && hymn.audioUrl!.isNotEmpty) {
                        if (kIsWeb) {
                          // Use audioplayers for web, fallback to external link
                          audioWidget = SizedBox(
                            width: double.infinity,
                            child: Card(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.audiotrack, color: Theme.of(context).colorScheme.secondary, size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _WebAudioPlayerWidget(url: hymn.audioUrl!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Use just_audio for mobile/desktop
                          audioWidget = FutureBuilder(
                            future: _initAudio(hymn.audioUrl!),
                            builder: (context, snapshot) {
                              return SizedBox(
                                width: double.infinity,
                                child: Card(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.audiotrack, color: Theme.of(context).colorScheme.secondary, size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _audioPlayer != null
                                              ? StreamBuilder<ja.PlayerState>(
                                                  stream: _audioPlayer!.playerStateStream,
                                                  builder: (context, snap) {
                                                    final playing = snap.data?.playing ?? false;
                                                    return Row(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 20),
                                                          onPressed: () {
                                                            if (playing) {
                                                              _audioPlayer!.pause();
                                                            } else {
                                                              _audioPlayer!.play();
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.open_in_new, size: 20),
                                                          tooltip: 'Open externally',
                                                          onPressed: () async {
                                                            await launchUrl(Uri.parse(hymn.audioUrl!), mode: LaunchMode.externalApplication);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }
                      // VIDEO
                      if (hymn.videoUrl != null && hymn.videoUrl!.isNotEmpty) {
                        videoWidget = SizedBox(
                          width: double.infinity,
                          child: Card(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                await launchUrl(Uri.parse(hymn.videoUrl!), mode: LaunchMode.externalApplication);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Open Video',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          audioWidget,
                          const SizedBox(height: 12),
                          videoWidget,
                        ],
                      );
                    },
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

class _WebAudioPlayerWidget extends StatefulWidget {
  final String url;
  const _WebAudioPlayerWidget({required this.url});
  @override
  State<_WebAudioPlayerWidget> createState() => _WebAudioPlayerWidgetState();
}

class _WebAudioPlayerWidgetState extends State<_WebAudioPlayerWidget> {
  late ap.AudioPlayer _player;
  bool _playing = false;
  @override
  void initState() {
    super.initState();
    _player = ap.AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playing = state == ap.PlayerState.playing;
      });
    });
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 20),
          onPressed: () async {
            if (_playing) {
              await _player.pause();
            } else {
              await _player.play(ap.UrlSource(widget.url));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new, size: 20),
          tooltip: 'Open externally',
          onPressed: () async {
            await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }
} 