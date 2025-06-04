import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  final String id;
  final String hymnId;
  final String userId;
  final bool isFavorite;
  final DateTime? scheduledDate;
  final String? note;

  Bookmark({
    required this.id,
    required this.hymnId,
    required this.userId,
    this.isFavorite = false,
    this.scheduledDate,
    this.note,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map, String id) {
    return Bookmark(
      id: id,
      hymnId: map['hymn_id'] as String,
      userId: map['user_id'] as String,
      isFavorite: map['is_favorite'] as bool? ?? false,
      scheduledDate: map['scheduled_date'] != null
          ? (map['scheduled_date'] as Timestamp).toDate()
          : null,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hymn_id': hymnId,
      'user_id': userId,
      'is_favorite': isFavorite,
      'scheduled_date': scheduledDate != null
          ? Timestamp.fromDate(scheduledDate!)
          : null,
      'note': note,
    };
  }
} 