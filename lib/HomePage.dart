import 'package:flutter/material.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/screens/create_event_page.dart';
import 'package:uok_events/screens/profile_page.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/widgets/event_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  void _navigateToCreateEvent(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UoK Events'),
        actions: [
          if (user != null)
            StreamBuilder<UserModel>(
              stream: firestoreService.getUserStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.profilePictureUrl.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => _navigateToProfile(context),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(snapshot.data!.profilePictureUrl),
                      ),
                    ),
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.account_circle, size: 30),
                    tooltip: 'Profile',
                    onPressed: () => _navigateToProfile(context),
                  );
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: firestoreService.getEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No upcoming events.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }
          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
          );
        },
      ),
      floatingActionButton: user != null
          ? StreamBuilder<UserModel>(
              stream: firestoreService.getUserStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.role == 'staff') {
                  return FloatingActionButton(
                    onPressed: () => _navigateToCreateEvent(context),
                    child: const Icon(Icons.add),
                    tooltip: 'Create Event',
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : null,
    );
  }
}
