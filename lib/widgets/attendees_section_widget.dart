import 'package:flutter/material.dart';
import '../main.dart';

class AttendeesSectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> rsvps;

  const AttendeesSectionWidget({super.key, required this.rsvps});

  @override
  State<AttendeesSectionWidget> createState() => _AttendeesSectionWidgetState();
}

class _AttendeesSectionWidgetState extends State<AttendeesSectionWidget> {
  bool _goingExpanded = true;
  bool _maybeExpanded = false;
  bool _cantGoExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.rsvps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Be the first to respond!', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ),
      );
    }

    final going = widget.rsvps.where((r) => r['status'] == 'going').toList();
    final maybe = widget.rsvps.where((r) => r['status'] == 'maybe').toList();
    final cantGo = widget.rsvps.where((r) => r['status'] == 'not_going').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (going.isNotEmpty) _buildSection('✅ Going', going, _goingExpanded, (val) => setState(() => _goingExpanded = val)),
        if (maybe.isNotEmpty) _buildSection('🤔 Maybe', maybe, _maybeExpanded, (val) => setState(() => _maybeExpanded = val)),
        if (cantGo.isNotEmpty) _buildSection('❌ Can\'t Go', cantGo, _cantGoExpanded, (val) => setState(() => _cantGoExpanded = val), isGrey: true),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> users, bool isExpanded, ValueChanged<bool> onToggle, {bool isGrey = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onToggle(!isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Text('$title (${users.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: isGrey ? AppColors.textSecondary : null)),
                const Spacer(),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (isExpanded)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final profile = users[index]['profiles'];
                final String name = profile['full_name'] ?? 'Unknown';
                final String? avatar = profile['avatar_url'];

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.divider,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)) : null,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          name.split(' ').first,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: isGrey ? AppColors.textSecondary : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
