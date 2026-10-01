import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'models.dart';
import 'helpers.dart';

// Schedules real, on-device notifications for bill/payment reminders. No
// server or internet is needed at notification-time — Android's own alarm
// system fires these even if the app is closed (as long as the OS hasn't
// been told to aggressively kill the app's background activity).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const int _reminderHour = 9; // Notifications fire at 9:00 AM local time.

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fall back to whatever default the timezone package picked.
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (_) {
      // If notification setup fails on some device, the app must not crash —
      // reminders will simply stay visible only inside the app itself.
    }
  }

  static int _notifId(String reminderId) => reminderId.hashCode & 0x7FFFFFFF;

  static Future<void> scheduleReminder(Reminder r) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    if (r.done) return;

    final due = DateTime.tryParse(r.dueDate);
    if (due == null) return;

    var scheduledDate = tz.TZDateTime(tz.local, due.year, due.month, due.day, _reminderHour);
    final now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) {
      if (!r.recurring) return; // one-time reminder already passed — nothing to schedule
      // Advance month by month until we land on a future date.
      var safety = 0;
      while (scheduledDate.isBefore(now) && safety < 24) {
        final nextMonth = scheduledDate.month == 12 ? 1 : scheduledDate.month + 1;
        final nextYear = scheduledDate.month == 12 ? scheduledDate.year + 1 : scheduledDate.year;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = scheduledDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : scheduledDate.day;
        scheduledDate = tz.TZDateTime(tz.local, nextYear, nextMonth, day, _reminderHour);
        safety++;
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'bill_reminders',
      'Bill Reminders',
      channelDescription: 'Reminders for bills and payments you set inside Kharcha Manager',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        _notifId(r.id),
        appName,
        r.title,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: r.recurring ? DateTimeComponents.dayOfMonthAndTime : null,
      );
    } catch (_) {
      // Exact-alarm permission may be denied on some OEM devices — fail
      // silently rather than crash; the reminder is still visible in-app.
    }
  }

  static Future<void> cancelReminder(String reminderId) async {
    try {
      await _plugin.cancel(_notifId(reminderId));
    } catch (_) {}
  }

  static Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
    for (final r in reminders.where((r) => !r.done)) {
      await scheduleReminder(r);
    }
  }
}
