import 'package:flutter/material.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/widgets/event_card.dart';

class EventSearchDelegate extends SearchDelegate<Event?> {
  final List<Event> allEvents;

  EventSearchDelegate({required this.allEvents});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.primary,
        iconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = allEvents.where((event) {
      final titleMatch = event.title.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = event.category.toLowerCase().contains(query.toLowerCase());
      return titleMatch || categoryMatch;
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No events found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return EventCard(event: results[index]);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // For this simple search, suggestions can be the same as the final results.
    return buildResults(context);
  }
}
