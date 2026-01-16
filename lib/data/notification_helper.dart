import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> scheduleCouponExpiryNotification({
    required int id,
    required String code,
    required DateTime expiryDate,
  }) async {
    tz.initializeTimeZones();
    final scheduledDate = expiryDate.subtract(const Duration(days: 7));
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      'Kupon wkrótce wygaśnie',
      'Twój kupon $code wygaśnie za 7 dni!',
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