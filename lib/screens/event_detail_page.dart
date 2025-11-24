import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;

  const EventDetailPage({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: Center(
        child: Text('Details for Event ID: $eventId'),
      ),
    );
  }
}
