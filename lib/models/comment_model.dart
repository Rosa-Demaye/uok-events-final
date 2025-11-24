import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final Timestamp timestamp;
  final String? replyTo;
  final int replyCount;
  final List<String> likes; // Added this line

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.replyTo,
    this.replyCount = 0,
    this.likes = const [], // Initialize with an empty list
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      replyTo: data['replyTo'] as String?,
      replyCount: data['replyCount'] ?? 0,
      likes: List<String>.from(data['likes'] ?? []),
    );
  }
}
