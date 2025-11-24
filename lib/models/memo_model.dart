import 'package:cloud_firestore/cloud_firestore.dart';

class Memo {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;

  Memo({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
  });

  factory Memo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Memo(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }
}
