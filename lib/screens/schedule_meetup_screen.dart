import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class ScheduleMeetupScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic>? initialMeetup;

  const ScheduleMeetupScreen({super.key, required this.groupId, this.initialMeetup});

  @override
  State<ScheduleMeetupScreen> createState() => _ScheduleMeetupScreenState();
}

class _ScheduleMeetupScreenState extends State<ScheduleMeetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  
  String? _selectedCategory;
  bool _isPublic = false;
  bool _isLoading = false;

  final List<String> _categories = [
    '🏏 Sports', '🎬 Movie', '🍽️ Food & Dining', '🎮 Gaming', 
    '📚 Study', '🎵 Music', '🏕️ Outdoor', '🎉 Party', '💼 Work', '🔧 Other'
  ];

  bool get isEditMode => widget.initialMeetup != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final initial = widget.initialMeetup!;
      _titleController.text = initial['title'] ?? '';
      _descriptionController.text = initial['description'] ?? '';
      _locationController.text = initial['location'] ?? '';
      if (initial['max_attendees'] != null) {
        _maxAttendeesController.text = initial['max_attendees'].toString();
      }
      _selectedCategory = initial['category'];
      _isPublic = initial['is_public'] ?? false;
      
      final dt = DateTime.parse(initial['scheduled_at']).toLocal();
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _showConfirmationSheet() {
    if (!_formKey.currentState!.validate()) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheduledAt = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedTime.hour, _selectedTime.minute,
        );

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Confirm Meetup Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                _confirmRow('Title', _titleController.text),
                _confirmRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(scheduledAt)),
                _confirmRow('Time', DateFormat('h:mm a').format(scheduledAt)),
                _confirmRow('Location', _locationController.text.isEmpty ? 'No location set' : _locationController.text),
                _confirmRow('Category', _selectedCategory ?? 'None'),
                _confirmRow('Max Attendees', _maxAttendeesController.text.isEmpty ? 'Unlimited' : _maxAttendeesController.text),
                _confirmRow('Visibility', _isPublic ? 'Public' : 'Group Members Only'),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: AppColors.divider),
                        ),
                        child: Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveMeetup(scheduledAt);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(isEditMode ? 'Save Changes' : 'Confirm & Schedule'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Future<void> _saveMeetup(DateTime scheduledAt) async {
    setState(() => _isLoading = true);
    try {
      final maxAttendees = int.tryParse(_maxAttendeesController.text.trim());
      
      if (isEditMode) {
        await SupabaseService.updateMeetup(
          meetupId: widget.initialMeetup!['id'],
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          scheduledAt: scheduledAt,
          location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
          maxAttendees: maxAttendees,
          category: _selectedCategory,
          isPublic: _isPublic,
        );
        
        await NotificationService.scheduleMeetupReminder(
          id: widget.initialMeetup!['id'],
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          scheduledAt: scheduledAt,
        );
      } else {
        final newId = await SupabaseService.createMeetup(
          groupId: widget.groupId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          scheduledAt: scheduledAt,
          location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
          maxAttendees: maxAttendees,
          category: _selectedCategory,
          isPublic: _isPublic,
        );
        
        await NotificationService.scheduleMeetupReminder(
          id: newId,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          scheduledAt: scheduledAt,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Meetup updated successfully' : 'Meetup scheduled!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider, width: 0.5)),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(isEditMode ? 'Edit Meetup' : 'Schedule Meetup', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Meetup Title', prefixIcon: Icon(Icons.event_rounded, color: AppColors.textTertiary)),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 48), child: Icon(Icons.notes_rounded, color: AppColors.textTertiary))),
                        ),
                        const SizedBox(height: 16),

                        // Date and Time
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppColors.textTertiary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: AppColors.textTertiary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(hintText: 'Location (optional)', prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _maxAttendeesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: 'Max Attendees (e.g., 10)', prefixIcon: Icon(Icons.people_outline_rounded, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(height: 24),

                        Text('Category', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(category, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : null;
                                    });
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text('Who can see this meetup?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isPublic = false),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Group Members Only', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            const Text('Only people in this group can see it', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: !_isPublic ? Border.all(color: AppColors.primary, width: 6) : Border.all(color: AppColors.textTertiary, width: 2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Public', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textTertiary)),
                                          const SizedBox(height: 2),
                                          const Text('Anyone with the link can view (Coming Soon)', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 20, height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.divider, width: 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _showConfirmationSheet,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isEditMode ? 'Review Changes' : 'Schedule Meetup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
