import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/screens/event_details_page.dart';
import 'package:video_player/video_player.dart';

class SmallEventCard extends StatefulWidget {
  final Event event;

  const SmallEventCard({super.key, required this.event});

  @override
  State<SmallEventCard> createState() => _SmallEventCardState();
}

class _SmallEventCardState extends State<SmallEventCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.event.mediaType == 'video' && widget.event.mediaUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.event.mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {}); // Update UI once controller is initialized
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(event: widget.event),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                height: 110,
                width: double.infinity,
                color: Colors.grey[200],
                child: _buildMedia(),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(widget.event.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4.0),
            Text(DateFormat('MMM d, yyyy').format(widget.event.dateTime), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.event.mediaType == 'video') {
      if (_controller != null && _controller!.value.isInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)),
            Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.7), size: 40),
          ],
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      return Image.network(
        widget.event.mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }
  }
}
