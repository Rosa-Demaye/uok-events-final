import 'package:flutter/material.dart';
import 'package:uok_events/models/notification_model.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see your notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firestoreService.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no new notifications.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  notification.read ? Icons.notifications_none : Icons.notifications_active,
                  color: notification.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
                title: Text(notification.title, style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(notification.body),
                onTap: () {
                  if (!notification.read) {
                    _firestoreService.markNotificationAsRead(userId, notification.id);
                  }
                  // TODO: Navigate to related event if relatedEventId exists
                },
              );
            },
          );
        },
      ),
    );
  }
}
