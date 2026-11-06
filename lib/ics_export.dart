import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// One all-day event in the exported calendar.
class IcsEvent {
  final String uid;
  final DateTime date;
  final String title;
  final String description;
  final int? alarmDaysBefore; // pops up a reminder this many days before (9 AM)

  const IcsEvent({
    required this.uid,
    required this.date,
    required this.title,
    this.description = '',
    this.alarmDaysBefore,
  });
}

String _escape(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n');
}

String _ymd(DateTime d) => DateFormat('yyyyMMdd').format(d);

// Builds the text of an iCalendar (.ics) file. Google Calendar, Apple
// Calendar and Outlook can all import it.
String buildIcs(List<IcsEvent> events, {String calendarName = 'Kharcha Manager'}) {
  final stamp = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Kharcha Manager//Panchang Planner//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-WR-CALNAME:${_escape(calendarName)}',
  ];
  for (final e in events) {
    final next = DateTime(e.date.year, e.date.month, e.date.day + 1);
    lines.add('BEGIN:VEVENT');
    lines.add('UID:${e.uid}@kharcha-manager');
    lines.add('DTSTAMP:$stamp');
    lines.add('DTSTART;VALUE=DATE:${_ymd(e.date)}');
    lines.add('DTEND;VALUE=DATE:${_ymd(next)}');
    lines.add('SUMMARY:${_escape(e.title)}');
    if (e.description.isNotEmpty) lines.add('DESCRIPTION:${_escape(e.description)}');
    final a = e.alarmDaysBefore;
    if (a != null) {
      // All-day events start at midnight, so 9 AM of the reminder day is
      // (a * 24 - 9) hours before the start (or 9 hours after it on the day itself).
      lines.add('BEGIN:VALARM');
      lines.add('ACTION:DISPLAY');
      lines.add('DESCRIPTION:${_escape(e.title)}');
      lines.add(a <= 0 ? 'TRIGGER:PT9H' : 'TRIGGER:-PT${a * 24 - 9}H');
      lines.add('END:VALARM');
    }
    lines.add('END:VEVENT');
  }
  lines.add('END:VCALENDAR');
  return '${lines.join('\r\n')}\r\n';
}

// Writes the file and opens the share sheet; choosing Google Calendar (or
// opening the file from WhatsApp / Files) imports every event.
Future<void> shareIcs({required String fileName, required String content, String text = ''}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName.ics');
  await file.writeAsString(content);
  await Share.shareXFiles([XFile(file.path, mimeType: 'text/calendar')], text: text);
}
