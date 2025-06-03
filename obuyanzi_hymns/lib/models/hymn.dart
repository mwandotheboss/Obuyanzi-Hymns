class Hymn {
  final String id;
  final String title;
  final String englishLyrics;
  final String luhyaLyrics;
  final String? category;
  final int hymnNumber;

  Hymn({
    required this.id,
    required this.title,
    required this.englishLyrics,
    required this.luhyaLyrics,
    this.category,
    required this.hymnNumber,
  });

  factory Hymn.fromMap(Map<String, dynamic> map) {
    return Hymn(
      id: map['id'] as String,
      title: map['title'] as String,
      englishLyrics: map['englishLyrics'] as String,
      luhyaLyrics: map['luhyaLyrics'] as String,
      category: map['category'] as String?,
      hymnNumber: map['hymnNumber'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'englishLyrics': englishLyrics,
      'luhyaLyrics': luhyaLyrics,
      'category': category,
      'hymnNumber': hymnNumber,
    };
  }
} 