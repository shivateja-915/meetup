import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../widgets/meetup_status_badge.dart';
import '../widgets/rsvp_buttons_widget.dart';
import '../widgets/attendees_section_widget.dart';
import '../widgets/meetup_comments_widget.dart';
import 'schedule_meetup_screen.dart';

class MeetupDetailScreen extends StatefulWidget {
  final String meetupId;
  const MeetupDetailScreen({super.key, required this.meetupId});

  @override
  State<MeetupDetailScreen> createState() => _MeetupDetailScreenState();
}

class _MeetupDetailScreenState extends State<MeetupDetailScreen> {
  Map<String, dynamic>? _meetup;
  List<Map<String, dynamic>> _rsvps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetup();
  }

  Future<void> _loadMeetup() async {
    setState(() => _isLoading = true);
    try {
      _meetup = await SupabaseService.getMeetup(widget.meetupId);
      await _loadRsvps();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRsvps() async {
    final rsvps = await SupabaseService.getMeetupRsvps(widget.meetupId);
    if (mounted) setState(() => _rsvps = rsvps);
  }

  Future<void> _deleteMeetup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Meetup'),
        content: const Text('Are you sure you want to cancel this meetup?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.cancelMeetup(widget.meetupId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.warmGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('Meetup Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_meetup != null && _meetup!['created_by'] == SupabaseService.currentUser?.id && _meetup!['status'] != 'cancelled' && DateTime.parse(_meetup!['scheduled_at']).isAfter(DateTime.now()))
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleMeetupScreen(groupId: _meetup!['group_id'], initialMeetup: _meetup)));
                          _loadMeetup();
                        },
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _meetup == null
                        ? const Center(child: Text('Meetup not found'))
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final title = _meetup!['title'] ?? 'Meetup';
    final description = _meetup!['description'] ?? '';
    final location = _meetup!['location'] ?? '';
    final scheduledAt = DateTime.parse(_meetup!['scheduled_at']);
    final groupName = _meetup!['groups']?['name'] ?? '';
    final creatorName = _meetup!['profiles']?['full_name'] ?? 'Unknown';
    final isPast = scheduledAt.isBefore(DateTime.now());
    final isCreator = _meetup!['created_by'] == SupabaseService.currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                MeetupStatusBadge(status: _meetup!['status'] ?? 'upcoming', isPast: isPast),
              ]),
              if (groupName.isNotEmpty) ...[const SizedBox(height: 8), Text(groupName, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500))],
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider, width: 0.5)),
            child: Column(children: [
              _row(Icons.calendar_today_rounded, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(scheduledAt)),
              const Divider(height: 24, color: AppColors.divider),
              _row(Icons.access_time_rounded, 'Time', DateFormat('h:mm a').format(scheduledAt)),
              if (location.isNotEmpty) ...[const Divider(height: 24, color: AppColors.divider), _row(Icons.location_on_outlined, 'Location', location)],
              const Divider(height: 24, color: AppColors.divider),
              _row(Icons.person_outline_rounded, 'Organized by', creatorName),
            ]),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Description', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5)),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider, width: 0.5)),
            child: RsvpButtonsWidget(meetupId: widget.meetupId, onRsvpChanged: _loadRsvps),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider, width: 0.5)),
            child: AttendeesSectionWidget(rsvps: _rsvps),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider, width: 0.5)),
            child: MeetupCommentsWidget(meetupId: widget.meetupId),
          ),
          if (isCreator && !isPast) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: OutlinedButton.icon(
                onPressed: _deleteMeetup,
                icon: Icon(Icons.cancel_outlined, color: AppColors.error),
                label: Text('Cancel Meetup', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ])),
    ]);
  }
}
