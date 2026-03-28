import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../widgets/meetup_card.dart';
import '../widgets/chat_bubble.dart';
import 'schedule_meetup_screen.dart';
import 'meetup_detail_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  final List<Map<String, dynamic>> _meetups = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _showCancelled = false;
  
  final List<Map<String, dynamic>> _todayMeetups = [];
  final List<Map<String, dynamic>> _upcomingMeetups = [];
  final List<Map<String, dynamic>> _completedMeetups = [];
  final List<Map<String, dynamic>> _cancelledMeetups = [];

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioPlayer = AudioPlayer();
  RealtimeChannel? _messageChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _group = await SupabaseService.getGroup(widget.groupId);
      _members = await SupabaseService.getGroupMembers(widget.groupId);
      final rawMeetups = await SupabaseService.getGroupMeetups(widget.groupId);
      _messages = await SupabaseService.getMessages(widget.groupId);

      final now = DateTime.now();
      _todayMeetups.clear();
      _upcomingMeetups.clear();
      _completedMeetups.clear();
      _cancelledMeetups.clear();

      for (var m in rawMeetups) {
        if (m['status'] == 'cancelled') {
          _cancelledMeetups.add(m);
          continue;
        }
        final d = DateTime.parse(m['scheduled_at']).toLocal();
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          _todayMeetups.add(m);
        } else if (d.isBefore(now)) {
          _completedMeetups.add(m);
        } else {
          _upcomingMeetups.add(m);
        }
      }

      _upcomingMeetups.sort((a, b) => DateTime.parse(a['scheduled_at']).compareTo(DateTime.parse(b['scheduled_at'])));
      _completedMeetups.sort((a, b) => DateTime.parse(b['scheduled_at']).compareTo(DateTime.parse(a['scheduled_at'])));
      _cancelledMeetups.sort((a, b) => DateTime.parse(b['scheduled_at']).compareTo(DateTime.parse(a['scheduled_at'])));
    } catch (e) {
      // Handle error
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _subscribeToMessages() {
    final currentUserId = SupabaseService.currentUser?.id;
    _messageChannel = SupabaseService.subscribeToMessages(
      widget.groupId,
      (newMessage) async {
        // Play notification sound only for messages from others
        if (newMessage['sender_id'] != currentUserId) {
          try {
            await _audioPlayer.play(AssetSource('sounds/receive.mp3'));
          } catch (e) {
            debugPrint('Error playing receive sound: $e');
          }
        }

        // Fetch the full message with profile info
        final messages = await SupabaseService.getMessages(widget.groupId);
        if (mounted) {
          setState(() => _messages = messages);
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // In reverse: true list, 0 is the bottom (newest)
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Play pop sound
    try {
      await _audioPlayer.play(AssetSource('sounds/send.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    try {
      await SupabaseService.sendMessage(
        groupId: widget.groupId,
        content: text,
      );
      // Immediately scroll to bottom (newest)
      _scrollToBottom();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = _group?['invite_code'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.warmGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.groupName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_members.length} members',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    // Invite code chip
                    if (inviteCode.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Invite code copied to clipboard!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                inviteCode,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Members'),
                    Tab(text: 'Meetups'),
                    Tab(text: 'Chat'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMembersTab(),
                    _buildMeetupsTab(),
                    _buildChatTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final profile = member['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name'] ?? 'Unknown';
        final role = member['role'] ?? 'member';
        final joinedAt = member['joined_at'] != null
            ? timeago.format(DateTime.parse(member['joined_at']))
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (role == 'admin') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Joined $joinedAt',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetupsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Stack(
      children: [
        _meetups.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_rounded,
                        size: 60,
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No meetups scheduled',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to schedule one',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ..._todayMeetups.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MeetupCard(meetup: m, onTap: () => _goToMeetup(m['id'])))),
                  ..._upcomingMeetups.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MeetupCard(meetup: m, onTap: () => _goToMeetup(m['id'])))),
                  ..._completedMeetups.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Opacity(opacity: 0.6, child: MeetupCard(meetup: m, onTap: () => _goToMeetup(m['id']))))),
                  if (_cancelledMeetups.isNotEmpty) ...[
                    TextButton(
                      onPressed: () => setState(() => _showCancelled = !_showCancelled),
                      child: Text(_showCancelled ? 'Hide Cancelled Meetups' : 'Show Cancelled Meetups (${_cancelledMeetups.length})', style: const TextStyle(color: AppColors.textTertiary)),
                    ),
                    if (_showCancelled)
                      ..._cancelledMeetups.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Opacity(opacity: 0.4, child: MeetupCard(meetup: m, onTap: () => _goToMeetup(m['id']))))),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScheduleMeetupScreen(groupId: widget.groupId),
                ),
              ).then((_) => _loadData());
            },
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  void _goToMeetup(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MeetupDetailScreen(meetupId: id)),
    ).then((_) => _loadData());
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String text;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      text = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
          ),
          Expanded(child: Container(height: 0.5, color: AppColors.divider)),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final currentUserId = SupabaseService.currentUser?.id;

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 60,
                          color: AppColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start the conversation!',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest at bottom
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    // In reverse: true, earlier index is later message (bottom)
                    // Index 0 is newest (bottom)
                    final msg = _messages[_messages.length - 1 - index];
                    final isMe = msg['sender_id'] == currentUserId;
                    
                    final msgDate = DateTime.parse(msg['created_at']).toLocal();
                    bool showDate = false;
                    
                    // Show date if it's the oldest message (last index) or day changed from next older message
                    if (index == _messages.length - 1) {
                      showDate = true;
                    } else {
                      final olderMsg = _messages[_messages.length - 1 - (index + 1)];
                      final olderDate = DateTime.parse(olderMsg['created_at']).toLocal();
                      if (msgDate.year != olderDate.year || msgDate.month != olderDate.month || msgDate.day != olderDate.day) {
                         showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msgDate),
                        ChatBubble(
                          message: msg,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border:
                Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
