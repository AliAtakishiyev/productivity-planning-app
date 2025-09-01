import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  // Daily reminder notification
  Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Daily reminder to complete your tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 9 AM daily
    await _notifications.zonedSchedule(
      1,
      'Don\'t lose your streak! 🔥',
      'Complete all today\'s tasks to keep your streak alive.',
      _nextInstanceOf(9, 0), // 9 AM
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Plan-specific reminder
  Future<void> schedulePlanReminder(String planTitle, int planId) async {
    const androidDetails = AndroidNotificationDetails(
      'plan_reminder',
      'Plan Reminder',
      channelDescription: 'Reminders for specific plans',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 6 PM daily
    await _notifications.zonedSchedule(
      10 + planId, // Unique ID for each plan
      'Your $planTitle plan is waiting! 🔥',
      'Keep your streak alive by completing today\'s tasks.',
      _nextInstanceOf(18, 0), // 6 PM
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Skip day notification
  Future<void> showSkipDayNotification(int skipsUsed, int skipsLeft) async {
    const androidDetails = AndroidNotificationDetails(
      'skip_warning',
      'Skip Warning',
      channelDescription: 'Notifications about skip days',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      100,
      'You skipped today',
      'You used $skipsUsed of your 3 monthly skips. $skipsLeft skips left this month.',
      details,
    );
  }

  // Streak lost notification
  Future<void> showStreakLostNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'streak_lost',
      'Streak Lost',
      channelDescription: 'Notifications when streak is lost',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      101,
      'Streak lost 💔',
      'Start fresh today and build a new streak! 💪',
      details,
    );
  }

  // Streak milestone notification
  Future<void> showStreakMilestoneNotification(int streakDays) async {
    const androidDetails = AndroidNotificationDetails(
      'streak_milestone',
      'Streak Milestone',
      channelDescription: 'Celebrations for streak milestones',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String message = '';
    if (streakDays == 7) {
      message = '🔥 Amazing! You\'ve maintained a 7-day streak!';
    } else if (streakDays == 30) {
      message = '🔥🔥🔥 Incredible! 30 days of consistency!';
    } else if (streakDays == 100) {
      message = '🔥🔥🔥🔥🔥 LEGENDARY! 100 days streak!';
    }

    await _notifications.show(
      102,
      'Streak Milestone! 🎉',
      message,
      details,
    );
  }

  // End of day warning notification
  Future<void> showEndOfDayWarning() async {
    const androidDetails = AndroidNotificationDetails(
      'end_of_day_warning',
      'End of Day Warning',
      channelDescription: 'Warnings at end of day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 10 PM
    await _notifications.zonedSchedule(
      103,
      'Last chance to save your streak! ⏰',
      'Complete your tasks before midnight to keep your streak alive.',
      _nextInstanceOf(22, 0), // 10 PM
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Helper method to get next instance of a specific time
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}
