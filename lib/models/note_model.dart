import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String ownerUid;
  final DateTime lastEdited;
  final bool isPinned;
  final String? pin; // ✅
  final bool isLocked; // ✅

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerUid,
    required this.lastEdited,
    this.isPinned = false,
    this.pin,
    this.isLocked = false, // ✅ default
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      lastEdited: (map['lastEdited'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: map['isPinned'] ?? false,
      pin: map['pin'], // ✅
      isLocked: map['isLocked'] is bool ? map['isLocked'] : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'ownerUid': ownerUid,
      'lastEdited': Timestamp.fromDate(lastEdited),
      'isPinned': isPinned,
      'pin': pin, // ✅
      'isLocked': isLocked, // ✅
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? ownerUid,
    DateTime? lastEdited,
    bool? isPinned,
    String? pin,
    bool? isLocked,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      ownerUid: ownerUid ?? this.ownerUid,
      lastEdited: lastEdited ?? this.lastEdited,
      isPinned: isPinned ?? this.isPinned,
      pin: pin ?? this.pin,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $content, ownerUid: $ownerUid, lastEdited: $lastEdited, isPinned: $isPinned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.ownerUid == ownerUid &&
        other.lastEdited == lastEdited &&
        other.isPinned == isPinned;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        ownerUid.hashCode ^
        lastEdited.hashCode ^
        isPinned.hashCode;
  }
}
