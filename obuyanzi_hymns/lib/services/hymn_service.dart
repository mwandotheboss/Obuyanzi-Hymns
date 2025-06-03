import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';

class HymnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'hymns';

  Stream<List<Hymn>> getHymns() {
    return _firestore
        .collection(_collection)
        .orderBy('hymnNumber')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Hymn.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<Hymn?> getHymn(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Hymn.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }
} 