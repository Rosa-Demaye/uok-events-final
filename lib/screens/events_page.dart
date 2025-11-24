import 'package:flutter/material.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/models/notification_model.dart';
import 'package:uok_events/screens/notifications_page.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/widgets/event_card.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UoK Events'),
        actions: [
          if (userId != null)
            StreamBuilder<List<NotificationModel>>(
              stream: _firestoreService.getNotificationsStream(userId),
              builder: (context, snapshot) {
                final hasUnread = snapshot.hasData && snapshot.data!.any((n) => !n.read);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsPage()));
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).canvasColor,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _firestoreService.getEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No events found.'));
                }

                final List<Event> allEvents = snapshot.data!;
                final List<Event> filteredEvents = _searchQuery.isEmpty
                    ? allEvents
                    : allEvents.where((event) {
                        final titleMatch = event.title.toLowerCase().contains(_searchQuery.toLowerCase());
                        final categoryMatch = event.category.toLowerCase().contains(_searchQuery.toLowerCase());
                        return titleMatch || categoryMatch;
                      }).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(child: Text('No events match your search.'));
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: filteredEvents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
