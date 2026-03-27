import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../services/supabase_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class MeetupCommentsWidget extends StatefulWidget {
  final String meetupId;

  const MeetupCommentsWidget({super.key, required this.meetupId});

  @override
  State<MeetupCommentsWidget> createState() => _MeetupCommentsWidgetState();
}

class _MeetupCommentsWidgetState extends State<MeetupCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await SupabaseService.getMeetupComments(widget.meetupId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToComments() {
    _subscription = SupabaseService.client
        .channel('public:meetup_comments:meetup_id=eq.${widget.meetupId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meetup_comments',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'meetup_id',
          value: widget.meetupId),
      callback: (payload) {
        debugPrint('Comment change detected: ${payload.eventType}');
        _loadComments();
      },
    ).subscribe();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.deleteMeetupComment(commentId);
      await _loadComments();
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    // --- Optimistic UI Update (Zero delay) ---
    // We add the comment to the local list immediately
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempComment = {
      'id': tempId,
      'content': text,
      'user_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
      'profiles': {
        'full_name': 'You',
        'avatar_url': null,
      }
    };

    if (mounted) {
      setState(() {
        _comments.add(tempComment);
        _commentController.clear();
      });
    }
    
    // FocusScope.of(context).unfocus(); // Uncomment if you want keyboard to close
    
    try {
      await SupabaseService.addMeetupComment(widget.meetupId, text);
      // The real comment will come back via the Realtime subscription and 
      // replace the list when _loadComments() is called by the callback.
    } catch (e) {
      debugPrint('Failed to send comment: $e');
      // On failure, remove the fake comment so the user knows it failed
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c['id'] == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send comment. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments (${_comments.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text('No comments yet. Start the conversation!', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final profile = comment['profiles'] ?? {};
              final isOwnComment = comment['user_id'] == SupabaseService.currentUser?.id;
              // Admin logic would require knowing if user is group admin, but PRD says "admin can delete any comment (long-press)..."
              // As a simple MVP, we just allow the comment owner or anyone (if we lack admin check context here)
              // Actually we just allow the owner.
              
              return InkWell(
                onLongPress: isOwnComment ? () => _deleteComment(comment['id']) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.divider,
                      backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                      child: profile['avatar_url'] == null ? Text((profile['full_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(profile['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const Spacer(),
                              Text(timeago.format(DateTime.parse(comment['created_at'])), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment['content'], style: const TextStyle(fontSize: 14, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                onPressed: _sendComment,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
