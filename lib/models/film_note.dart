class FilmNote {
  final String id;
  final String title;
  final String year;
  final String? media;
  final int episodeWatched;
  final bool isFinished;
  final String ownerUid;
  final DateTime lastEdited; // ✅ Tambahan

  FilmNote({
    required this.id,
    required this.title,
    required this.year,
    this.media,
    this.episodeWatched = 0,
    this.isFinished = false,
    required this.ownerUid,
    required this.lastEdited, // ✅ Tambahan
  });

  factory FilmNote.fromMap(Map<String, dynamic> data, String id) {
    return FilmNote(
      id: id,
      title: data['title'] ?? '',
      year: data['year'] ?? '',
      media: data['media'],
      episodeWatched: data['episodeWatched'] ?? 0,
      isFinished: data['finished'] ?? data['isFinished'] ?? false,
      ownerUid: data['ownerUid'] ?? '',
      lastEdited:
          DateTime.tryParse(data['lastEdited'] ?? '') ?? DateTime.now(), // ✅
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'year': year,
      'media': media,
      'episodeWatched': episodeWatched,
      'finished': isFinished,
      'ownerUid': ownerUid,
      'lastEdited': lastEdited.toIso8601String(), // ✅
    };
  }

  FilmNote copyWith({
    String? id,
    String? title,
    String? year,
    String? media,
    int? episodeWatched,
    bool? isFinished,
    String? ownerUid,
    DateTime? lastEdited, // ✅
  }) {
    return FilmNote(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      media: media ?? this.media,
      episodeWatched: episodeWatched ?? this.episodeWatched,
      isFinished: isFinished ?? this.isFinished,
      ownerUid: ownerUid ?? this.ownerUid,
      lastEdited: lastEdited ?? this.lastEdited, // ✅
    );
  }
}
