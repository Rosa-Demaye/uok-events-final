import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/comment_model.dart';
import 'package:uok_events/models/memo_model.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';

class _CommentNode {
  final Comment comment;
  final int level;
  _CommentNode(this.comment, this.level);
}

class MemoDetailsPage extends StatefulWidget {
  final Memo memo;
  const MemoDetailsPage({super.key, required this.memo});

  @override
  State<MemoDetailsPage> createState() => _MemoDetailsPageState();
}

class _MemoDetailsPageState extends State<MemoDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();

  Comment? _replyingTo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _commentController.text.isEmpty) return;

    try {
      final userModel = await _firestoreService.getCurrentUserModel(userId);
      final userName = userModel.fullName;
      final parentId = _replyingTo?.id;

      await _firestoreService.addMemoComment(widget.memo.id, _commentController.text, userId, userName, parentCommentId: parentId);
      
      _commentController.clear();
      if (mounted) {
        setState(() => _replyingTo = null);
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
    _firestoreService.toggleMemoCommentLike(widget.memo.id, commentId, userId, isCurrentlyLiked);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.memo.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _firestoreService.getMemoCommentsStream(widget.memo.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading comments: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final flattenedComments = _flattenComments(snapshot.data!);

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: flattenedComments.length + 1, // +1 for the memo content header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMemoHeader(theme);
                    }
                    final node = flattenedComments[index - 1];
                    return Padding(
                      padding: EdgeInsets.only(left: 20.0 * node.level, top: 4, bottom: 4),
                      child: _buildCommentItem(node.comment),
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildMemoHeader(ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.memo.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('by ${widget.memo.authorName} on ${DateFormat.yMMMd().format(widget.memo.timestamp)}', style: theme.textTheme.bodySmall),
            const Divider(height: 32),
            Text(widget.memo.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            const Divider(height: 32),
            Text('Comments', style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        _buildMemoHeader(theme),
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No comments yet. Be the first to reply!')),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final currentUserId = _authService.currentUser?.uid;
    final isOwner = currentUserId == comment.userId;
    final isLikedByMe = currentUserId != null && comment.likes.contains(currentUserId);

    return ListTile(
      leading: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(comment.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircleAvatar(radius: 20);
          final user = snapshot.data!;
          return CircleAvatar(
            radius: 20,
            backgroundImage: user.profilePictureUrl.isNotEmpty ? NetworkImage(user.profilePictureUrl) : null,
            child: user.profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
          );
        },
      ),
      title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.text),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Text(_formatRelativeTime(comment.timestamp.toDate()), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12.0),
              InkWell(
                onTap: () => setState(() => _replyingTo = comment),
                child: Text('Reply', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600]))
              ),
              const SizedBox(width: 12.0),
              InkWell(
                onTap: () => _handleCommentLike(comment.id, isLikedByMe),
                child: Row(
                  children: [
                    Icon(isLikedByMe ? Icons.favorite : Icons.favorite_border, color: isLikedByMe ? Colors.redAccent : Colors.grey, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(comment.likes.length.toString(), style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
      trailing: isOwner 
        ? PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _firestoreService.deleteMemoComment(widget.memo.id, comment.id);
              }
            },
            itemBuilder: (context) => [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
            icon: const Icon(Icons.more_vert, size: 20),
          )
        : null,
      onTap: () => setState(() => _replyingTo = comment),
    );
  }

  Widget _buildCommentInputField() {
    return Material(
      elevation: 8.0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Replying to ${_replyingTo!.userName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    InkWell(
                      onTap: () => setState(() => _replyingTo = null),
                      child: const Icon(Icons.close, size: 18, color: Colors.black54),
                    )
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Write a comment...', border: OutlineInputBorder()),
                    autofocus: _replyingTo != null,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.send), onPressed: _postComment, style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
