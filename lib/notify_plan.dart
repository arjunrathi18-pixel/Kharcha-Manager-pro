import 'package:intl/intl.dart';
import 'models.dart';
import 'notification_service.dart';
import 'panchang.dart';
import 'service_logic.dart';

String _ymd(DateTime d) => DateFormat('yyyyMMdd').format(d);
DateTime _at(DateTime d, int hour) => DateTime(d.year, d.month, d.day, hour);
DateTime _minusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);

String tithiKindLabel(String kind) {
  switch (kind) {
    case 'birthday':
      return 'Birthday';
    case 'anniversary':
      return 'Anniversary';
    case 'shraddh':
      return 'Shraddh / Punya tithi';
    default:
      return 'Tithi date';
  }
}

// Everything that should ping the user without them creating a Reminder by
// hand. Rebuilt whenever data changes, so it always reflects the latest state.
List<ScheduledNote> buildScheduledNotes({
  required PlannerPrefs prefs,
  required List<TithiEvent> events,
  required Map<String, ServiceSettings> service,
  required List<Entry> entries,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final out = <ScheduledNote>[];

  // ---- 1. "Diwali in 15 days - plan your expenses" ----
  if (prefs.nudgesOn) {
    for (final code in prefs.nudgeCodes) {
      for (final date in Panchang.occurrencesOf(code)) {
        if (date.isBefore(today) || date.difference(today).inDays > 400) continue;
        final fireAt = _at(_minusDays(date, prefs.nudgeLeadDays), 9);
        if (!fireAt.isAfter(n)) continue;
        final name = Panchang.eventName(code, Panchang.day(date), 'en');
        out.add(ScheduledNote(
          'nudge-$code-${_ymd(date)}',
          fireAt,
          '$name in ${prefs.nudgeLeadDays} days',
          '${DateFormat('EEE, d MMM').format(date)} - open Planner to plan your expenses.',
        ));
      }
    }
  }

  // ---- 2. Hindu birthdays, anniversaries, shraddh ----
  for (final e in events) {
    final dates = Panchang.nextOccurrences(e.monthIdx, e.tithi, today, count: 3);
    final kind = tithiKindLabel(e.kind);
    for (final date in dates) {
      final dateText = DateFormat('EEE, d MMM yyyy').format(date);
      if (e.remindDaysBefore > 0) {
        final fireAt = _at(_minusDays(date, e.remindDaysBefore), 9);
        if (fireAt.isAfter(n)) {
          out.add(ScheduledNote(
            'tithi-${e.id}-${_ymd(date)}-a',
            fireAt,
            '$kind: ${e.name}',
            e.remindDaysBefore == 1 ? 'Tomorrow ($dateText)' : 'In ${e.remindDaysBefore} days ($dateText)',
          ));
        }
      }
      final onDay = _at(date, 8);
      if (onDay.isAfter(n)) {
        out.add(ScheduledNote(
          'tithi-${e.id}-${_ymd(date)}-b',
          onDay,
          'Today: ${e.name}',
          '$kind by tithi - $dateText',
        ));
      }
    }
  }

  // ---- 3. Vehicle service ----
  for (final vt in service.keys) {
    final s = service[vt]!;
    if (!s.remind) continue;
    final info = computeServiceInfo(entries, vt, s, today: today);
    if (!info.hasBaseline) continue;
    final label = info.vehicleLabel;

    final due = info.dueDate;
    if (due != null) {
      final warnAt = _at(_minusDays(due, s.warnDays), 9);
      if (warnAt.isAfter(n)) {
        out.add(ScheduledNote(
          'service-$vt-warn',
          warnAt,
          '$label service due in ${s.warnDays} days',
          'Due by ${DateFormat('d MMM yyyy').format(due)} (${s.intervalMonths} months since the last service).',
        ));
      }
      final dueAt = _at(due, 9);
      if (dueAt.isAfter(n)) {
        out.add(ScheduledNote('service-$vt-due', dueAt, '$label service is due today', 'Time for the periodic service.'));
      }
    }

    // Close to (or past) the limit: a daily nudge at 9 AM until the service is recorded.
    if (info.status == 'soon' || info.status == 'overdue') {
      var nag = _at(today, 9);
      if (!nag.isAfter(n)) nag = nag.add(const Duration(days: 1));
      final parts = <String>[];
      final kmLeft = info.kmLeft;
      if (kmLeft != null) {
        parts.add(kmLeft <= 0 ? '${(-kmLeft).round()} km over the limit' : '${kmLeft.round()} km left');
      }
      final daysLeft = info.daysLeft;
      if (daysLeft != null) {
        parts.add(daysLeft <= 0 ? '${-daysLeft} days overdue' : '$daysLeft days left');
      }
      out.add(ScheduledNote(
        'service-$vt-nag',
        nag,
        '$label service ${info.status == 'overdue' ? 'overdue' : 'due soon'}',
        parts.join(' | '),
      ));
    }
  }

  return out;
}
