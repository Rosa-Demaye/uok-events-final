import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String mediaUrl; // Renamed from imageUrl
  final String mediaType; // New field: 'image' or 'video'
  final String category;
  final DateTime dateTime;
  final String organizer;
  final String organizerId;
  final List<String> attendees;
  final List<String> likes;
  final int commentCount;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.mediaUrl,
    required this.mediaType,
    required this.category,
    required this.dateTime,
    required this.organizer,
    required this.organizerId,
    required this.attendees,
    required this.likes,
    required this.commentCount,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'] ?? '', // Handle old field name for backwards compatibility
      mediaType: data['mediaType'] ?? 'image', // Default to 'image'
      category: data['category'] ?? 'General',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      organizer: data['organizer'] ?? '',
      organizerId: data['organizerId'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }
}
