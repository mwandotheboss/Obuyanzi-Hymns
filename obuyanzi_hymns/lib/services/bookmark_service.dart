import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookmarks';

  Stream<List<Bookmark>> getBookmarks(String userId) {
    return _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Bookmark.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Bookmark>> getFavorites(String userId) {
    return _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .where('is_favorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Bookmark.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Bookmark>> getScheduledHymns(String userId) {
    return _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .where('scheduled_date', isNotEqualTo: null)
        .orderBy('scheduled_date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Bookmark.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Bookmark?> getBookmark(String userId, String hymnId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .where('hymn_id', isEqualTo: hymnId)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Bookmark.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<void> toggleFavorite(String userId, String hymnId) async {
    final bookmark = await getBookmark(userId, hymnId);
    if (bookmark == null) {
      // Create new bookmark
      await _firestore.collection(_collection).add(Bookmark(
        id: '',
        hymnId: hymnId,
        userId: userId,
        isFavorite: true,
      ).toMap());
    } else {
      // Toggle existing bookmark
      await _firestore
          .collection(_collection)
          .doc(bookmark.id)
          .update({'is_favorite': !bookmark.isFavorite});
    }
  }

  Future<void> scheduleHymn(
    String userId,
    String hymnId,
    DateTime date, {
    String? note,
  }) async {
    final bookmark = await getBookmark(userId, hymnId);
    if (bookmark == null) {
      // Create new bookmark with schedule
      await _firestore.collection(_collection).add(Bookmark(
        id: '',
        hymnId: hymnId,
        userId: userId,
        scheduledDate: date,
        note: note,
      ).toMap());
    } else {
      // Update existing bookmark
      await _firestore.collection(_collection).doc(bookmark.id).update({
        'scheduled_date': Timestamp.fromDate(date),
        if (note != null) 'note': note,
      });
    }
  }

  Future<void> removeSchedule(String userId, String hymnId) async {
    final bookmark = await getBookmark(userId, hymnId);
    if (bookmark != null) {
      await _firestore
          .collection(_collection)
          .doc(bookmark.id)
          .update({'scheduled_date': null});
    }
  }

  Future<void> deleteBookmark(String userId, String hymnId) async {
    final bookmark = await getBookmark(userId, hymnId);
    if (bookmark != null) {
      await _firestore.collection(_collection).doc(bookmark.id).delete();
    }
  }
} 