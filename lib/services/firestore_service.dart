import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uok_events/models/comment_model.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/models/memo_model.dart';
import 'package:uok_events/models/notification_model.dart';
import 'package:uok_events/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER METHODS ---
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String role,
    String? regNo,
    String? staffCode,
    required String faculty,
    required String department,
    String? position,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'registrationNumber': regNo,
      'staffCode': staffCode,
      'faculty': faculty,
      'department': department,
      'position': position,
      'profilePictureUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUserToken(String uid, String token) async {
    final userTokensRef = _db.collection('users').doc(uid).collection('tokens').doc(token);
    await userTokensRef.set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  }

  Future<UserModel> getCurrentUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User not found in Firestore');
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) => UserModel.fromFirestore(snapshot));
  }

  Future<void> updateUserProfilePicture(String uid, String imageUrl) async {
    await _db.collection('users').doc(uid).update({'profilePictureUrl': imageUrl});
  }

  // --- NOTIFICATION METHODS ---
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _db.collection('users').doc(userId).collection('notifications').doc(notificationId).update({'read': true});
  }

  // --- EVENT METHODS ---
  Stream<List<Event>> getEventsStream() {
    return _db.collection('events').orderBy('dateTime', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Stream<List<Event>> getPostedEventsForUser(String uid) {
    return _db.collection('events').where('organizerId', isEqualTo: uid).orderBy('dateTime', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Stream<List<Event>> getEventsForUser(String uid) {
    return _db.collection('events').where('attendees', arrayContains: uid).orderBy('dateTime', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Future<void> addEvent(Event event) async {
    await _db.collection('events').add({
      'title': event.title,
      'description': event.description,
      'location': event.location,
      'mediaUrl': event.mediaUrl,
      'mediaType': event.mediaType,
      'category': event.category,
      'dateTime': event.dateTime,
      'organizer': event.organizer,
      'organizerId': event.organizerId,
      'attendees': [],
      'likes': [],
      'commentCount': 0,
    });
  }

  Future<void> updateEvent(Event event) async {
    await _db.collection('events').doc(event.id).update({
      'title': event.title,
      'description': event.description,
      'location': event.location,
      'category': event.category,
      'dateTime': event.dateTime,
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  Future<void> toggleEventRsvp(String eventId, String userId, bool isCurrentlyAttending) async {
    final eventRef = _db.collection('events').doc(eventId);
    await eventRef.update({'attendees': isCurrentlyAttending ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])});
  }

  Future<void> toggleEventLike(String eventId, String userId, bool isCurrentlyLiked) async {
    final eventRef = _db.collection('events').doc(eventId);
    await eventRef.update({'likes': isCurrentlyLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])});
  }

  // --- EVENT COMMENT METHODS ---
  Future<void> addComment(String eventId, String text, String userId, String userName, {String? parentCommentId}) async {
    final eventRef = _db.collection('events').doc(eventId);
    final commentRef = eventRef.collection('comments').doc();
    WriteBatch batch = _db.batch();
    batch.set(commentRef, {
      'text': text,
      'userId': userId,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': parentCommentId,
      'replyCount': 0,
      'likes': [],
    });
    if (parentCommentId != null) {
      final parentRef = eventRef.collection('comments').doc(parentCommentId);
      batch.update(parentRef, {'replyCount': FieldValue.increment(1)});
    }
    batch.update(eventRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    final eventRef = _db.collection('events').doc(eventId);
    final commentRef = eventRef.collection('comments').doc(commentId);
    await _db.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) return;
      final commentData = commentSnapshot.data()!;
      final parentId = commentData['replyTo'] as String?;
      transaction.update(eventRef, {'commentCount': FieldValue.increment(-1)});
      if (parentId != null) {
        final parentRef = eventRef.collection('comments').doc(parentId);
        transaction.update(parentRef, {'replyCount': FieldValue.increment(-1)});
      }
      transaction.delete(commentRef);
    });
  }

  Stream<List<Comment>> getCommentsStream(String eventId) {
    return _db.collection('events').doc(eventId).collection('comments').orderBy('timestamp', descending: false).snapshots().map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  Future<void> toggleCommentLike(String eventId, String commentId, String userId, bool isCurrentlyLiked) async {
    final commentRef = _db.collection('events').doc(eventId).collection('comments').doc(commentId);
    await commentRef.update({'likes': isCurrentlyLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])});
  }

  // --- MEMO METHODS ---
  Future<void> addMemo({required String title, required String content, required String authorId, required String authorName}) async {
    await _db.collection('memos').add({
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'commentCount': 0,
    });
  }

  Stream<List<Memo>> getMemosStream() {
    return _db.collection('memos').orderBy('timestamp', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Memo.fromFirestore(doc)).toList());
  }

  Future<void> toggleMemoLike(String memoId, String userId, bool isCurrentlyLiked) async {
    final memoRef = _db.collection('memos').doc(memoId);
    await memoRef.update({'likes': isCurrentlyLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])});
  }

  // --- MEMO COMMENT METHODS ---
  Future<void> addMemoComment(String memoId, String text, String userId, String userName, {String? parentCommentId}) async {
    final memoRef = _db.collection('memos').doc(memoId);
    final commentRef = memoRef.collection('comments').doc();
    WriteBatch batch = _db.batch();
    batch.set(commentRef, {
      'text': text,
      'userId': userId,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': parentCommentId,
      'replyCount': 0,
      'likes': [],
    });
    if (parentCommentId != null) {
      final parentRef = memoRef.collection('comments').doc(parentCommentId);
      batch.update(parentRef, {'replyCount': FieldValue.increment(1)});
    }
    batch.update(memoRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }
  
  Stream<List<Comment>> getMemoCommentsStream(String memoId) {
    return _db.collection('memos').doc(memoId).collection('comments').orderBy('timestamp', descending: false).snapshots().map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  Future<void> deleteMemoComment(String memoId, String commentId) async {
    final memoRef = _db.collection('memos').doc(memoId);
    final commentRef = memoRef.collection('comments').doc(commentId);
    await _db.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) return;
      final commentData = commentSnapshot.data()!;
      final parentId = commentData['replyTo'] as String?;
      transaction.update(memoRef, {'commentCount': FieldValue.increment(-1)});
      if (parentId != null) {
        final parentRef = memoRef.collection('comments').doc(parentId);
        transaction.update(parentRef, {'replyCount': FieldValue.increment(-1)});
      }
      transaction.delete(commentRef);
    });
  }

  Future<void> toggleMemoCommentLike(String memoId, String commentId, String userId, bool isCurrentlyLiked) async {
    final commentRef = _db.collection('memos').doc(memoId).collection('comments').doc(commentId);
    await commentRef.update({'likes': isCurrentlyLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])});
  }
}
