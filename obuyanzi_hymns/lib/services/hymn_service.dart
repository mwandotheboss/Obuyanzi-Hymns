import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';

class HymnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'hymns';

  Stream<List<Hymn>> getHymns() {
    return _firestore
        .collection(_collection)
        .orderBy('number')
        .snapshots()
        .asyncMap((snapshot) async {
      final hymns = <Hymn>[];
      for (var doc in snapshot.docs) {
        final hymn = Hymn.fromMap(doc.data(), doc.id);
        // Fetch verses
        final versesSnapshot = await doc.reference.collection('verses').get();
        final verses = versesSnapshot.docs
            .map((verseDoc) => Verse.fromMap(verseDoc.data(), verseDoc.id))
            .toList();
        
        // Fetch choruses
        final chorusesSnapshot = await doc.reference.collection('choruses').get();
        final choruses = chorusesSnapshot.docs
            .map((chorusDoc) => Chorus.fromMap(chorusDoc.data(), chorusDoc.id))
            .toList();
        
        hymns.add(Hymn(
          id: hymn.id,
          number: hymn.number,
          titleLuhya: hymn.titleLuhya,
          titleEnglish: hymn.titleEnglish,
          language: hymn.language,
          tags: hymn.tags,
          hasChangingChorus: hymn.hasChangingChorus,
          createdAt: hymn.createdAt,
          audioUrl: hymn.audioUrl,
          videoUrl: hymn.videoUrl,
          verses: verses,
          choruses: choruses,
        ));
      }
      return hymns;
    });
  }

  Future<Hymn?> getHymn(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    final hymn = Hymn.fromMap(doc.data()!, doc.id);
    
    // Fetch verses
    final versesSnapshot = await doc.reference.collection('verses').get();
    final verses = versesSnapshot.docs
        .map((verseDoc) => Verse.fromMap(verseDoc.data(), verseDoc.id))
        .toList();
    
    // Fetch choruses
    final chorusesSnapshot = await doc.reference.collection('choruses').get();
    final choruses = chorusesSnapshot.docs
        .map((chorusDoc) => Chorus.fromMap(chorusDoc.data(), chorusDoc.id))
        .toList();
    
    return Hymn(
      id: hymn.id,
      number: hymn.number,
      titleLuhya: hymn.titleLuhya,
      titleEnglish: hymn.titleEnglish,
      language: hymn.language,
      tags: hymn.tags,
      hasChangingChorus: hymn.hasChangingChorus,
      createdAt: hymn.createdAt,
      audioUrl: hymn.audioUrl,
      videoUrl: hymn.videoUrl,
      verses: verses,
      choruses: choruses,
    );
  }

  Future<void> addHymn(Hymn hymn) async {
    final docRef = _firestore.collection(_collection).doc();
    
    // Add main hymn document
    await docRef.set(hymn.toMap());
    
    // Add verses
    for (var verse in hymn.verses) {
      await docRef.collection('verses').doc(verse.id).set(verse.toMap());
    }
    
    // Add choruses
    for (var chorus in hymn.choruses) {
      await docRef.collection('choruses').doc(chorus.id).set(chorus.toMap());
    }
  }

  Future<void> updateHymn(Hymn hymn) async {
    final docRef = _firestore.collection(_collection).doc(hymn.id);
    
    // Update main hymn document
    await docRef.update(hymn.toMap());
    
    // Update verses
    for (var verse in hymn.verses) {
      await docRef.collection('verses').doc(verse.id).set(verse.toMap());
    }
    
    // Update choruses
    for (var chorus in hymn.choruses) {
      await docRef.collection('choruses').doc(chorus.id).set(chorus.toMap());
    }
  }

  Future<void> deleteHymn(String id) async {
    final docRef = _firestore.collection(_collection).doc(id);
    
    // Delete verses
    final versesSnapshot = await docRef.collection('verses').get();
    for (var doc in versesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Delete choruses
    final chorusesSnapshot = await docRef.collection('choruses').get();
    for (var doc in chorusesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Delete main hymn document
    await docRef.delete();
  }
} 