import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uok_events/services/firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initNotifications(String userId) async {
    // Request permission from the user
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final String? fcmToken = await _firebaseMessaging.getToken();

    if (fcmToken != null) {
      // Save the token to the user's document in Firestore
      await _firestoreService.saveUserToken(userId, fcmToken);

      // When the token refreshes, save the new one
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _firestoreService.saveUserToken(userId, newToken);
      });
    }

    // Subscribe the user to topics for general announcements
    await _firebaseMessaging.subscribeToTopic('new_events');
    await _firebaseMessaging.subscribeToTopic('new_memos'); // NEW
  }
}
