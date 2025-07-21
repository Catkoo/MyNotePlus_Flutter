import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String ownerUid;
  final DateTime lastEdited;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerUid,
    required this.lastEdited,
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      lastEdited: (map['lastEdited'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'ownerUid': ownerUid,
      'lastEdited': Timestamp.fromDate(lastEdited),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? ownerUid,
    DateTime? lastEdited,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      ownerUid: ownerUid ?? this.ownerUid,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $content, ownerUid: $ownerUid, lastEdited: $lastEdited)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.ownerUid == ownerUid &&
        other.lastEdited == lastEdited;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        ownerUid.hashCode ^
        lastEdited.hashCode;
  }
}
