import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uok_events/models/memo_model.dart';
import 'package:uok_events/models/user_model.dart';
import 'package:uok_events/screens/memo_details_page.dart';
import 'package:uok_events/services/auth_service.dart';
import 'package:uok_events/services/firestore_service.dart';

class MemoCard extends StatefulWidget {
  final Memo memo;

  const MemoCard({super.key, required this.memo});

  @override
  State<MemoCard> createState() => _MemoCardState();
}

class _MemoCardState extends State<MemoCard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.memo.likes.length;
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _isLiked = widget.memo.likes.contains(userId);
    }
  }

  void _handleLike() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final originalIsLiked = _isLiked;
    final originalLikeCount = _likeCount;

    setState(() {
      _isLiked = !originalIsLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });

    try {
      await _firestoreService.toggleMemoLike(widget.memo.id, userId, originalIsLiked);
    } catch (e) {
      setState(() {
        _isLiked = originalIsLiked;
        _likeCount = originalLikeCount;
      });
      // Optional: Show an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MemoDetailsPage(memo: widget.memo))),
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.memo.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              StreamBuilder<UserModel>(
                stream: _firestoreService.getUserStream(widget.memo.authorId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('by...', style: TextStyle(fontStyle: FontStyle.italic));
                  }
                  final author = snapshot.data!;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: author.profilePictureUrl.isNotEmpty ? NetworkImage(author.profilePictureUrl) : null,
                        child: author.profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 12) : null,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'by ${author.fullName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 24.0),
              Text(
                widget.memo.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                maxLines: 5, // Limit lines in the feed
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(widget.memo.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.grey),
                        onPressed: _handleLike,
                        tooltip: 'Like',
                      ),
                      Text('$_likeCount'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MemoDetailsPage(memo: widget.memo))),
                        tooltip: 'Comment',
                      ),
                      Text('${widget.memo.commentCount}'),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
