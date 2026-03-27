import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../widgets/meetup_card.dart';
import 'meetup_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _upcomingMeetups = [];
  List<Map<String, dynamic>> _cancelledMeetups = [];
  int _selectedIndex = 0; // 0 for Upcoming, 1 for Cancelled
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseService.getProfile(userId);
        _userName = profile?['full_name'] ?? 'there';
      }
      final upcoming = await SupabaseService.getUpcomingMeetups();
      final cancelled = await SupabaseService.getCancelledMeetups();
      
      final now = DateTime.now();
      _upcomingMeetups = upcoming.where((m) {
        if (m['status'] == 'cancelled') return false;
        final d = DateTime.parse(m['scheduled_at']).toLocal();
        if (d.year == now.year && d.month == now.month && d.day == now.day) return true;
        return d.isAfter(now);
      }).toList();
      _cancelledMeetups = cancelled;
    } catch (e) {
      // Handle error silently
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.warmGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey, $_userName! 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section header (Segmented Control)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 0 ? AppColors.dark : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Upcoming (${_upcomingMeetups.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedIndex == 0 ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 1 ? AppColors.dark : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cancelled (${_cancelledMeetups.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedIndex == 1 ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Meetup list
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadData,
                child: _isLoading
                    ? _buildLoadingSkeleton()
                    : (_selectedIndex == 0 ? _upcomingMeetups : _cancelledMeetups).isEmpty
                        ? _buildEmptyState(_selectedIndex)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: (_selectedIndex == 0 ? _upcomingMeetups : _cancelledMeetups).length,
                            itemBuilder: (context, index) {
                              final currentList = _selectedIndex == 0 ? _upcomingMeetups : _cancelledMeetups;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: MeetupCard(
                                  meetup: currentList[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MeetupDetailScreen(
                                          meetupId: currentList[index]['id'],
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(int selectedIndex) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selectedIndex == 0 ? Icons.event_available_rounded : Icons.event_busy_rounded,
                  size: 60,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                selectedIndex == 0 ? 'No upcoming meetups' : 'No cancelled meetups',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedIndex == 0 ? 'Join a group and schedule\nyour first meetup!' : 'Looks like everything\nis going as planned!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
