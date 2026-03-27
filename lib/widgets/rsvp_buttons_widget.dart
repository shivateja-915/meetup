import 'package:flutter/material.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class RsvpButtonsWidget extends StatefulWidget {
  final String meetupId;
  final VoidCallback onRsvpChanged;

  const RsvpButtonsWidget({super.key, required this.meetupId, required this.onRsvpChanged});

  @override
  State<RsvpButtonsWidget> createState() => _RsvpButtonsWidgetState();
}

class _RsvpButtonsWidgetState extends State<RsvpButtonsWidget> {
  List<Map<String, dynamic>> _rsvps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRsvps();
  }

  Future<void> _loadRsvps() async {
    final rsvps = await SupabaseService.getMeetupRsvps(widget.meetupId);
    if (mounted) {
      setState(() {
        _rsvps = rsvps;
        _isLoading = false;
      });
      widget.onRsvpChanged();
    }
  }

  Future<void> _updateRsvp(String status) async {
    setState(() => _isLoading = true);
    await SupabaseService.updateRsvp(widget.meetupId, status);
    
    if (status == 'going') {
      final m = await SupabaseService.getMeetup(widget.meetupId);
      if (m != null) {
        await NotificationService.scheduleMeetupReminder(
           id: widget.meetupId,
           title: m['title'],
           location: m['location'] ?? '',
           scheduledAt: DateTime.parse(m['scheduled_at']).toLocal(),
        );
      }
    } else {
       await NotificationService.cancelReminder(widget.meetupId);
    }
    
    await _loadRsvps();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final currentUserRsvp = _rsvps.where((r) => r['user_id'] == SupabaseService.currentUser?.id).firstOrNull;
    final currentStatus = currentUserRsvp?['status'];

    final goingCount = _rsvps.where((r) => r['status'] == 'going').length;
    final maybeCount = _rsvps.where((r) => r['status'] == 'maybe').length;
    final notGoingCount = _rsvps.where((r) => r['status'] == 'not_going').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Are you going?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRsvpButton('Going', 'going', '✅', currentStatus == 'going'),
            _buildRsvpButton('Maybe', 'maybe', '🤔', currentStatus == 'maybe'),
            _buildRsvpButton('Can\'t Go', 'not_going', '❌', currentStatus == 'not_going'),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '$goingCount Going  ·  $maybeCount Maybe  ·  $notGoingCount Can\'t Go',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpButton(String label, String value, String icon, bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () => _updateRsvp(value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.divider,
                width: isActive ? 0 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
