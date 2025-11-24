import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/screens/event_details_page.dart';
import 'package:video_player/video_player.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.event.mediaType == 'video' && widget.event.mediaUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.event.mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            _controller!..setLooping(true)..setVolume(0.0)..play();
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(event: widget.event),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedia(),
            _buildCardInfo(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.event.mediaType == 'video') {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Container(
          height: 200,
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }
    } else {
      return Image.network(
        widget.event.mediaUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (context, error, stack) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildCardInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This is the updated Chip widget
          Chip(
            label: Text(widget.event.category),
            labelStyle: TextStyle(
              color: theme.colorScheme.primary.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(height: 12.0),
          Text(
            widget.event.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8.0),
              Text(
                DateFormat('EEE, MMM d, yyyy \'at\' h:mm a').format(widget.event.dateTime),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  widget.event.location,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
