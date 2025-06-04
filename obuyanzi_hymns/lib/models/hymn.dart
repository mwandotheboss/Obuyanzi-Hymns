import 'package:cloud_firestore/cloud_firestore.dart';

class Hymn {
  final String id;
  final String number;
  final String titleLuhya;
  final String? titleEnglish;
  final String language;
  final List<String> tags;
  final bool hasChangingChorus;
  final DateTime createdAt;
  final String? audioUrl;
  final String? videoUrl;
  final List<Verse> verses;
  final List<Chorus> choruses;

  Hymn({
    required this.id,
    required this.number,
    required this.titleLuhya,
    required this.titleEnglish,
    required this.language,
    required this.tags,
    required this.hasChangingChorus,
    required this.createdAt,
    this.audioUrl,
    this.videoUrl,
    required this.verses,
    required this.choruses,
  });

  factory Hymn.fromMap(Map<String, dynamic> map, String id) {
    return Hymn(
      id: id,
      number: map['number'] as String,
      titleLuhya: map['title_luhya'] as String,
      titleEnglish: map['title_english'] as String?,
      language: map['language'] as String,
      tags: List<String>.from(map['tags'] as List),
      hasChangingChorus: map['has_changing_chorus'] as bool,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      audioUrl: map['audio_url'] as String?,
      videoUrl: map['video_url'] as String?,
      verses: [], // Will be populated separately
      choruses: [], // Will be populated separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'title_luhya': titleLuhya,
      'title_english': titleEnglish,
      'language': language,
      'tags': tags,
      'has_changing_chorus': hasChangingChorus,
      'created_at': Timestamp.fromDate(createdAt),
      'audio_url': audioUrl,
      'video_url': videoUrl,
    };
  }
}

class Verse {
  final String id;
  final int verseNumber;
  final String contentLuhya;
  final String? contentEnglish;
  final String? chorusRef;

  Verse({
    required this.id,
    required this.verseNumber,
    required this.contentLuhya,
    required this.contentEnglish,
    this.chorusRef,
  });

  factory Verse.fromMap(Map<String, dynamic> map, String id) {
    return Verse(
      id: id,
      verseNumber: map['verse_number'] as int,
      contentLuhya: map['content_luhya'] as String,
      contentEnglish: map['content_english'] as String?,
      chorusRef: map['chorus_ref'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verse_number': verseNumber,
      'content_luhya': contentLuhya,
      'content_english': contentEnglish,
      'chorus_ref': chorusRef,
    };
  }
}

class Chorus {
  final String id;
  final String type;
  final int chorusNumber;
  final String contentLuhya;
  final String contentEnglish;

  Chorus({
    required this.id,
    required this.type,
    required this.chorusNumber,
    required this.contentLuhya,
    required this.contentEnglish,
  });

  factory Chorus.fromMap(Map<String, dynamic> map, String id) {
    return Chorus(
      id: id,
      type: map['type'] as String,
      chorusNumber: map['chorus_number'] as int,
      contentLuhya: map['content_luhya'] as String,
      contentEnglish: map['content_english'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'chorus_number': chorusNumber,
      'content_luhya': contentLuhya,
      'content_english': contentEnglish,
    };
  }
} 