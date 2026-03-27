import 'package:flutter/material.dart';
import '../main.dart';

class MeetupStatusBadge extends StatelessWidget {
  final String status;
  final bool isPast;

  const MeetupStatusBadge({super.key, required this.status, required this.isPast});

  @override
  Widget build(BuildContext context) {
    String label = 'Upcoming';
    Color color = AppColors.primary; // Green
    
    if (status == 'cancelled') {
      label = 'Cancelled';
      color = AppColors.error; // Red
    } else if (status == 'completed' || isPast) {
      label = 'Completed';
      color = AppColors.textTertiary; // Grey
    } else if (status == 'today') {
      label = 'Today';
      color = const Color(0xFFE8845A); // Orange
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
