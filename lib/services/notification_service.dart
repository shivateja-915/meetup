import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Not fully supported on desktop web without additional config

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInitialize = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );

    await _notificationsPlugin!.initialize(settings: initializationSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = _notificationsPlugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleMeetupReminder({
    required String id,
    required String title,
    required String location,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb || _notificationsPlugin == null) return;
    
    final reminderTime = scheduledAt.subtract(const Duration(hours: 1));
    
    // Don't schedule if it's already past the reminder time
    if (reminderTime.isBefore(DateTime.now())) return;

    final int notificationId = id.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'meetup_reminders',
      'Meetup Reminders',
      channelDescription: 'Reminders for upcoming meetups',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final timeString = DateFormat('h:mm a').format(scheduledAt);
    final locationText = location.isNotEmpty ? 'at $location ' : '';
    
    await _notificationsPlugin!.zonedSchedule(
      id: notificationId,
      title: 'Meetup in 1 hour!',
      body: '$title ${locationText}starts at $timeString. Don\'t be late!',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id,
    );
  }

  static Future<void> cancelReminder(String id) async {
    if (kIsWeb || _notificationsPlugin == null) return;
    final int notificationId = id.hashCode;
    await _notificationsPlugin!.cancel(id: notificationId);
  }
}
