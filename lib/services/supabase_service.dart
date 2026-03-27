import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'notification_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ─── AUTH ─────────────────────────────────────────────────────────────
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
      });
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ─── PROFILE ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await client.from('profiles').update(updates).eq('id', userId);
  }

  // ─── GROUPS ───────────────────────────────────────────────────────────
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
  }) async {
    final userId = currentUser!.id;
    final inviteCode = _generateInviteCode();

    final group = await client.from('groups').insert({
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'created_by': userId,
    }).select().single();

    // Add creator as admin
    await client.from('group_members').insert({
      'group_id': group['id'],
      'user_id': userId,
      'role': 'admin',
    });

    return group;
  }

  static Future<Map<String, dynamic>?> joinGroup(String inviteCode) async {
    final userId = currentUser!.id;

    final group = await client
        .from('groups')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .maybeSingle();

    if (group == null) return null;

    // Check if already a member
    final existing = await client
        .from('group_members')
        .select()
        .eq('group_id', group['id'])
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) return group; // Already a member

    await client.from('group_members').insert({
      'group_id': group['id'],
      'user_id': userId,
      'role': 'member',
    });

    return group;
  }

  static Future<List<Map<String, dynamic>>> getMyGroups() async {
    final userId = currentUser!.id;

    final memberships = await client
        .from('group_members')
        .select('group_id, groups(*)')
        .eq('user_id', userId);

    return memberships.map<Map<String, dynamic>>((m) {
      return m['groups'] as Map<String, dynamic>;
    }).toList();
  }

  static Future<Map<String, dynamic>?> getGroup(String groupId) async {
    return await client
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers(
      String groupId) async {
    final members = await client
        .from('group_members')
        .select('*, profiles(*)')
        .eq('group_id', groupId)
        .order('joined_at');

    return members;
  }

  static Future<int> getGroupMemberCount(String groupId) async {
    final result = await client
        .from('group_members')
        .select()
        .eq('group_id', groupId);
    return result.length;
  }

  // ─── MEETUPS ──────────────────────────────────────────────────────────
  static Future<String> createMeetup({
    required String groupId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    String? location,
    int? maxAttendees,
    String? category,
    bool isPublic = false,
  }) async {
    final response = await client.from('meetups').insert({
      'group_id': groupId,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt.toIso8601String(),
      'location': location,
      'created_by': currentUser!.id,
      'max_attendees': maxAttendees,
      'category': category,
      'is_public': isPublic,
    }).select('id').single();
    
    return response['id'] as String;
  }

  static Future<void> updateMeetup({
    required String meetupId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    String? location,
    int? maxAttendees,
    String? category,
    bool isPublic = false,
  }) async {
    await client.from('meetups').update({
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt.toIso8601String(),
      'location': location,
      'max_attendees': maxAttendees,
      'category': category,
      'is_public': isPublic,
    }).eq('id', meetupId);
  }

  static Future<List<Map<String, dynamic>>> getCancelledMeetups() async {
    final userId = currentUser!.id;

    final memberships = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    final groupIds =
        memberships.map<String>((m) => m['group_id'] as String).toList();

    if (groupIds.isEmpty) return [];

    final meetups = await client
        .from('meetups')
        .select('*, groups(name), meetup_rsvps(status)')
        .inFilter('group_id', groupIds)
        .eq('status', 'cancelled')
        .order('scheduled_at', ascending: false);

    return meetups;
  }

  static Future<List<Map<String, dynamic>>> getUpcomingMeetups() async {
    final userId = currentUser!.id;

    // Get user's group IDs
    final memberships = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    final groupIds =
        memberships.map<String>((m) => m['group_id'] as String).toList();

    if (groupIds.isEmpty) return [];

    final meetups = await client
        .from('meetups')
        .select('*, groups(name), meetup_rsvps(status)')
        .inFilter('group_id', groupIds)
        .gte('scheduled_at', DateTime.now().subtract(const Duration(days: 1)).toIso8601String())
        .order('scheduled_at');

    return meetups;
  }

  static Future<List<Map<String, dynamic>>> getGroupMeetups(
      String groupId) async {
    return await client
        .from('meetups')
        .select('*, profiles(full_name), meetup_rsvps(status)')
        .eq('group_id', groupId)
        .order('scheduled_at');
  }

  static Future<Map<String, dynamic>?> getMeetup(String meetupId) async {
    return await client
        .from('meetups')
        .select('*, groups(name, id), profiles(full_name)')
        .eq('id', meetupId)
        .maybeSingle();
  }

  static Future<void> cancelMeetup(String meetupId) async {
    await client.from('meetups').update({
      'status': 'cancelled'
    }).eq('id', meetupId);
    
    // Also cancel any local notification scheduled for it
    await NotificationService.cancelReminder(meetupId);
  }

  // ─── RSVPs ────────────────────────────────────────────────────────────
  static Future<void> updateRsvp(String meetupId, String status) async {
    final userId = currentUser!.id;
    // Toggling off RSVP logic if the user selects the same active button
    final existing = await client
        .from('meetup_rsvps')
        .select()
        .eq('meetup_id', meetupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null && existing['status'] == status) {
      await client
          .from('meetup_rsvps')
          .delete()
          .eq('meetup_id', meetupId)
          .eq('user_id', userId);
      return;
    }

    await client.from('meetup_rsvps').upsert({
      'meetup_id': meetupId,
      'user_id': userId,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMeetupRsvps(String meetupId) async {
    return await client
        .from('meetup_rsvps')
        .select('*, profiles(id, full_name, avatar_url)')
        .eq('meetup_id', meetupId);
  }

  // ─── COMMENTS ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMeetupComments(String meetupId) async {
    return await client
        .from('meetup_comments')
        .select('*, profiles(id, full_name, avatar_url)')
        .eq('meetup_id', meetupId)
        .order('created_at', ascending: true);
  }

  static Future<void> addMeetupComment(String meetupId, String content) async {
    await client.from('meetup_comments').insert({
      'meetup_id': meetupId,
      'user_id': currentUser!.id,
      'content': content,
    });
  }

  static Future<void> deleteMeetupComment(String commentId) async {
    await client.from('meetup_comments').delete().eq('id', commentId);
  }

  // ─── MESSAGES ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMessages(
      String groupId) async {
    return await client
        .from('messages')
        .select('*, profiles(full_name, avatar_url)')
        .eq('group_id', groupId)
        .order('created_at')
        .limit(100);
  }

  static Future<void> sendMessage({
    required String groupId,
    required String content,
  }) async {
    await client.from('messages').insert({
      'group_id': groupId,
      'sender_id': currentUser!.id,
      'content': content,
    });
  }

  static RealtimeChannel subscribeToMessages(
      String groupId, void Function(Map<String, dynamic>) onMessage) {
    return client.channel('messages:$groupId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      callback: (payload) {
        onMessage(payload.newRecord);
      },
    ).subscribe();
  }
}
