import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool notificationsEnabled = true;
  static int notifyBeforeDays = 7;

  static Future<void> scheduleCouponExpiryNotification({
    required int id,
    required String code,
    required DateTime expiryDate,
  }) async {
    if (!notificationsEnabled) return;
    tz.initializeTimeZones();
    final scheduledDate = expiryDate.subtract(Duration(days: notifyBeforeDays));
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      'Kupon wkrótce wygaśnie',
      'Twój kupon $code wygaśnie za $notifyBeforeDays dni!',
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'coupon_channel',
          'Coupon Notifications',
          channelDescription: 'Powiadomienia o wygasających kuponach',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }
}