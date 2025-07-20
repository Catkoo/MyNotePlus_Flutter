class Note {
  final String id;
  final String title;
  final String content;
  final String ownerUid;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerUid,
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'content': content, 'ownerUid': ownerUid};
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? ownerUid,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      ownerUid: ownerUid ?? this.ownerUid,
    );
  }

  @override
  String toString() {
    return 'Note(id: \$id, title: \$title, content: \$content, ownerUid: \$ownerUid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.ownerUid == ownerUid;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ content.hashCode ^ ownerUid.hashCode;
  }
}
