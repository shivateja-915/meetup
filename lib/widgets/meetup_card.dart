import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'meetup_status_badge.dart';

class MeetupCard extends StatelessWidget {
  final Map<String, dynamic> meetup;
  final VoidCallback onTap;

  const MeetupCard({super.key, required this.meetup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = meetup['title'] ?? 'Meetup';
    final location = meetup['location'] ?? '';
    final groupName = meetup['groups']?['name'] ?? '';
    final scheduledAt = meetup['scheduled_at'] != null ? DateTime.parse(meetup['scheduled_at']).toLocal() : DateTime.now();
    
    // Check if it's past but ignore the hour/minute for strict day math, or just use precise time.
    final isPast = scheduledAt.isBefore(DateTime.now());
    
    final rsvps = meetup['meetup_rsvps'] as List<dynamic>? ?? [];
    final goingCount = rsvps.where((r) => r['status'] == 'going').length;
    final maybeCount = rsvps.where((r) => r['status'] == 'maybe').length;

    String rsvpText = '';
    if (goingCount > 0 || maybeCount > 0) {
      if (goingCount > 0 && maybeCount > 0) {
        rsvpText = '$goingCount Going · $maybeCount Maybe';
      } else if (goingCount > 0) {
        rsvpText = '$goingCount going';
      } else {
        rsvpText = '$maybeCount maybe';
      }
    }

    // Determine status logic per PRD
    String displayStatus = meetup['status'] ?? 'upcoming';
    if (displayStatus != 'cancelled') {
        final now = DateTime.now();
        if (scheduledAt.year == now.year && scheduledAt.month == now.month && scheduledAt.day == now.day) {
            displayStatus = 'today';
        } else if (isPast) {
            displayStatus = 'completed';
        } else {
            displayStatus = 'upcoming';
        }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: (displayStatus == 'completed' || displayStatus == 'cancelled') ? AppColors.darkGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('dd').format(scheduledAt), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1)),
                  Text(DateFormat('MMM').format(scheduledAt).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      MeetupStatusBadge(status: displayStatus, isPast: displayStatus == 'completed'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (groupName.isNotEmpty)
                    Text(groupName, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(DateFormat('h:mm a').format(scheduledAt), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      if (location.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(location, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                  if (rsvpText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(rsvpText, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
