import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/comment_model.dart';
import 'package:uok_events/models/event_model.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/screens/edit_event_page.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';
import 'package:uok_events/services/storage_service.dart';
import 'package:uok_events/widgets/event_card.dart';
import 'package:video_player/video_player.dart';

// Helper class to manage the nested comment structure
class _CommentNode {
  final Comment comment;
  final int level;
  _CommentNode(this.comment, this.level);
}

class EventDetailsPage extends StatefulWidget {
  final Event event;
  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();

  bool _isAttending = false;
  int _attendeeCount = 0;
  bool _isLiked = false;
  int _likeCount = 0;
  Comment? _replyingTo;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _isAttending = widget.event.attendees.contains(userId);
      _isLiked = widget.event.likes.contains(userId);
    }
    _attendeeCount = widget.event.attendees.length;
    _likeCount = widget.event.likes.length;

    if (widget.event.mediaType == 'video' && widget.event.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.event.mediaUrl))
        ..initialize().then((_) {
          if (mounted) setState(() => _isVideoInitialized = true);
        });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _handleBooking() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    final originalIsAttending = _isAttending;
    final originalAttendeeCount = _attendeeCount;
    setState(() {
      _isAttending = !originalIsAttending;
      if (_isAttending) _attendeeCount++;
      else if (_attendeeCount > 0) _attendeeCount--;
    });
    try {
      await _firestoreService.toggleEventRsvp(widget.event.id, userId, originalIsAttending);
    } catch (e) {
      setState(() {
        _isAttending = originalIsAttending;
        _attendeeCount = originalAttendeeCount;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed. Please try again.')));
    }
  }

  void _handleLike() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    final originalIsLiked = _isLiked;
    final originalLikeCount = _likeCount;
    setState(() {
      _isLiked = !originalIsLiked;
      if (_isLiked) _likeCount++;
      else if (_likeCount > 0) _likeCount--;
    });
    try {
      await _firestoreService.toggleEventLike(widget.event.id, userId, originalIsLiked);
    } catch (e) {
      setState(() {
        _isLiked = originalIsLiked;
        _likeCount = originalLikeCount;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed. Please try again.')));
    }
  }

  void _postComment() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _commentController.text.isEmpty) return;
    try {
      final userModel = await _firestoreService.getCurrentUserModel(userId);
      final userName = userModel.fullName;
      final parentId = _replyingTo?.id;
      await _firestoreService.addComment(widget.event.id, _commentController.text, userId, userName, parentCommentId: parentId);
      _commentController.clear();
      if (mounted) {
        setState(() { _replyingTo = null; });
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: ${e.toString()}')));
      }
    }
  }

  void _handleCommentLike(String commentId, bool isCurrentlyLiked) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    _firestoreService.toggleCommentLike(widget.event.id, commentId, userId, isCurrentlyLiked);
  }

  void _handleDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment?'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _firestoreService.deleteComment(widget.event.id, commentId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // --- NEW METHODS FOR EVENT EDIT/DELETE ---
  void _handleDeleteEvent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: const Text('Are you sure you want to permanently delete this event? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firestoreService.deleteEvent(widget.event.id);
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleEditEvent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: widget.event),
      ),
    );
  }


  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.isNegative) return '0s ago';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat.yMd().format(dateTime);
  }

  List<_CommentNode> _flattenComments(List<Comment> allComments) {
    final flattenedList = <_CommentNode>[];
    final childrenMap = <String?, List<Comment>>{};
    for (final comment in allComments) {
      childrenMap.putIfAbsent(comment.replyTo, () => []).add(comment);
    }
    final topLevelComments = childrenMap[null] ?? [];
    final reversedTopLevel = topLevelComments.reversed.toList();
    void addReplies(String parentId, int level) {
      final children = childrenMap[parentId] ?? [];
      for (final child in children) {
        flattenedList.add(_CommentNode(child, level));
        addReplies(child.id, level + 1);
      }
    }
    for (final topLevelComment in reversedTopLevel) {
      flattenedList.add(_CommentNode(topLevelComment, 0));
      addReplies(topLevelComment.id, 1);
    }
    return flattenedList;
  }

  void _showComments() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return DraggableScrollableSheet(
            expand: false, initialChildSize: 0.8, maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Scaffold(
                appBar: AppBar(title: const Text('Comments'), automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())]),
                body: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Comment>>(
                        stream: _firestoreService.getCommentsStream(widget.event.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          if (snapshot.data!.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));
                          final flattenedComments = _flattenComments(snapshot.data!);
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: flattenedComments.length,
                            itemBuilder: (context, index) {
                              final node = flattenedComments[index];
                              return Padding(
                                padding: EdgeInsets.only(left: 20.0 * node.level),
                                child: _buildCommentItem(node.comment, setModalState),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_replyingTo != null) Container(padding: const EdgeInsets.all(8.0), color: Colors.grey[200], child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Replying to ${_replyingTo!.userName}'), IconButton(icon: Icon(Icons.close, size: 16), onPressed: () => setModalState(() => _replyingTo = null))])),
                          Row(children: [Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Write a comment...'), autofocus: _replyingTo != null)), IconButton(icon: const Icon(Icons.send), onPressed: _postComment)]),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    }
    );
  }

  Widget _buildCommentItem(Comment comment, StateSetter setModalState) {
    final currentUserId = _authService.currentUser?.uid;
    final isOwner = currentUserId == comment.userId;
    return StreamBuilder<UserModel>(
      stream: _firestoreService.getUserStream(comment.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(leading: CircleAvatar(radius: 20, backgroundColor: Colors.grey[200]), title: Container(height: 16, width: 100, color: Colors.grey[200]));
        }
        final userModel = snapshot.data!;
        final isLiked = currentUserId != null && comment.likes.contains(currentUserId);
        return ListTile(
          leading: CircleAvatar(radius: 20, backgroundColor: Colors.grey[300], backgroundImage: userModel.profilePictureUrl.isNotEmpty ? NetworkImage(userModel.profilePictureUrl) : null, child: userModel.profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null),
          title: Wrap(spacing: 8.0, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(userModel.fullName, style: const TextStyle(fontWeight: FontWeight.bold)), if (userModel.role == 'staff' && userModel.position != null && userModel.position!.isNotEmpty) Text('• ${userModel.position!}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))]),
          trailing: isOwner ? PopupMenuButton<String>(onSelected: (value) {if (value == 'delete') {_handleDeleteComment(comment.id);}}, itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'delete', child: Text('Delete'))]) : null,
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comment.text), const SizedBox(height: 4.0), Row(children: [Text(_formatRelativeTime(comment.timestamp.toDate()), style: Theme.of(context).textTheme.bodySmall), const SizedBox(width: 12.0), InkWell(onTap: () => setModalState(() => _replyingTo = comment), child: const Text('Reply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))), const SizedBox(width: 12.0), InkWell(onTap: () => _handleCommentLike(comment.id, isLiked), child: Row(children: [Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 16.0), const SizedBox(width: 4.0), Text(comment.likes.length.toString(), style: TextStyle(color: Colors.grey))]))])]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOrganizer = _authService.currentUser?.uid == widget.event.organizerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title), 
        elevation: 0,
        actions: [
          if (isOrganizer)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _handleEditEvent();
                } else if (value == 'delete') {
                  _handleDeleteEvent();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit Event')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete Event')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _handleBooking, icon: Icon(_isAttending ? Icons.check_circle : Icons.bookmark_add_outlined), label: Text(_isAttending ? 'BOOKED' : 'BOOK EVENT'), backgroundColor: _isAttending ? Colors.green : theme.colorScheme.secondary),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.event.mediaType == 'video' && _videoController != null && _isVideoInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                    });
                  },
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Image.network(widget.event.mediaUrl, fit: BoxFit.cover, height: 250, loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 250, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())), errorBuilder: (context, error, stack) => Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 60))),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event.title, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 16.0),
                  _buildDetailRow(theme, Icons.calendar_today_outlined, DateFormat("MMMM d, yyyy 'at' h:mm a").format(widget.event.dateTime)),
                  const SizedBox(height: 12.0),
                  _buildDetailRow(theme, Icons.location_on_outlined, widget.event.location),
                  const SizedBox(height: 12.0),
                  _buildDetailRow(theme, Icons.person_outline, 'Organized by ${widget.event.organizer}'),
                  const SizedBox(height: 12.0),
                  _buildDetailRow(theme, Icons.people_outline, '$_attendeeCount people are attending'),
                  const Divider(height: 40.0, thickness: 1),
                  Text('About this Event', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  Text(widget.event.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(icon: _isLiked ? Icons.favorite : Icons.favorite_border, label: '$_likeCount Likes', onTap: _handleLike, color: _isLiked ? Colors.redAccent : Colors.grey),
                      StreamBuilder<List<Comment>>(
                        stream: _firestoreService.getCommentsStream(widget.event.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? widget.event.commentCount;
                          return _buildActionButton(icon: Icons.comment_outlined, label: '$count Comments', onTap: _showComments);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) { return Row(children: [Icon(icon, color: theme.colorScheme.primary, size: 20), const SizedBox(width: 12.0), Expanded(child: Text(text, style: theme.textTheme.bodyLarge))]); }
  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8.0), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 4.0), Text(label, style: TextStyle(color: color))]))); }
}
