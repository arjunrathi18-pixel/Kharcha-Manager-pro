import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../panchang.dart';
import '../notify_plan.dart';

const Map<String, String> _kindLabels = {
  'birthday': 'Birthday',
  'anniversary': 'Anniversary',
  'shraddh': 'Shraddh / Punya tithi',
  'other': 'Other',
};

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'birthday':
      return Icons.cake_outlined;
    case 'anniversary':
      return Icons.favorite_border;
    case 'shraddh':
      return Icons.local_fire_department_outlined;
    default:
      return Icons.event;
  }
}

const Map<int, String> _remindOptions = {
  0: 'On the day only',
  1: '1 day before + on the day',
  2: '2 days before + on the day',
  3: '3 days before + on the day',
  7: '1 week before + on the day',
};

// "Kartika Shukla Dwitiya" (purnimanta month names, as used in North India).
String _hinduLabel(int monthIdx, int tithi, String lang) {
  final shownMonth = tithi > 15 ? (monthIdx + 1) % 12 : monthIdx;
  final mName = Panchang.monthName(shownMonth, false, lang);
  return '$mName ${Panchang.tithiLabel(tithi, lang)}';
}

class TithiEventsScreen extends StatefulWidget {
  final List<TithiEvent> events;
  final String lang;
  final void Function(TithiEvent) onAdd;
  final void Function(TithiEvent) onUpdate;
  final void Function(String) onDelete;

  const TithiEventsScreen({
    super.key,
    required this.events,
    required this.lang,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TithiEventsScreen> createState() => _TithiEventsScreenState();
}

class _TithiEventsScreenState extends State<TithiEventsScreen> {
  String get lang => widget.lang;

  Future<void> _openEditor({TithiEvent? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var kind = existing?.kind ?? 'birthday';
    var remind = existing?.remindDaysBefore ?? 1;
    if (!_remindOptions.containsKey(remind)) remind = 1;

    // mode: 'date' = work the tithi out from a Gregorian date, 'manual' = pick it
    var mode = existing == null ? 'date' : 'manual';
    DateTime? srcDate = existing != null && existing.sourceDate.isNotEmpty ? DateTime.tryParse(existing.sourceDate) : null;
    int? birthMinutes;
    var purnimanta = true;
    var mMonth = 0;
    var mKrishna = false;
    var mTithiN = 1;
    if (existing != null) {
      final t = existing.tithi;
      mKrishna = t > 15;
      mTithiN = t > 15 ? t - 15 : t;
      mMonth = mKrishna ? (existing.monthIdx + 1) % 12 : existing.monthIdx;
    }
    String? err;

    HinduDate? derived() {
      if (srcDate == null) return null;
      return Panchang.hinduDateOf(srcDate!, minutes: birthMinutes);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setS) {
            final d = derived();
            return AlertDialog(
              title: Text(existing == null ? 'New tithi date' : 'Edit tithi date'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Papa, Dadaji, Our wedding'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _kindLabels.entries.map((e) {
                        return ChoiceChip(
                          label: Text(e.value, style: const TextStyle(fontSize: 12)),
                          selected: kind == e.key,
                          onSelected: (_) => setS(() => kind = e.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('From a date', style: TextStyle(fontSize: 12))),
                            selected: mode == 'date',
                            onSelected: (_) => setS(() => mode = 'date'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pick the tithi', style: TextStyle(fontSize: 12))),
                            selected: mode == 'manual',
                            onSelected: (_) => setS(() => mode = 'manual'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (mode == 'date') ...[
                      Text(
                        kind == 'shraddh' ? 'Date of passing' : (kind == 'anniversary' ? 'Date of the event' : 'Date of birth'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              srcDate == null ? 'No date chosen' : DateFormat('d MMM yyyy').format(srcDate!),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: srcDate ?? DateTime(1990, 1, 1),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setS(() => srcDate = picked);
                            },
                            child: const Text('Pick date'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              birthMinutes == null
                                  ? 'Time not set (tithi at sunrise is used)'
                                  : 'Time: ${Panchang.formatMinutes(birthMinutes!, 'en')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: dialogContext,
                                initialTime: const TimeOfDay(hour: 6, minute: 0),
                              );
                              if (t != null) setS(() => birthMinutes = t.hour * 60 + t.minute);
                            },
                            child: Text(birthMinutes == null ? 'Add time' : 'Change'),
                          ),
                          if (birthMinutes != null)
                            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setS(() => birthMinutes = null)),
                        ],
                      ),
                      if (srcDate != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: goldColor.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            d == null ? 'Could not work out the tithi for this date.' : 'Hindu date: ${_hinduLabel(d.monthIdx, d.tithi, lang)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: goldColor),
                          ),
                        ),
                    ] else ...[
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Purnimanta', style: TextStyle(fontSize: 12)),
                            selected: purnimanta,
                            onSelected: (_) => setS(() => purnimanta = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Amanta', style: TextStyle(fontSize: 12)),
                            selected: !purnimanta,
                            onSelected: (_) => setS(() => purnimanta = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: mMonth,
                        decoration: const InputDecoration(labelText: 'Hindu month'),
                        items: List.generate(12, (i) => DropdownMenuItem<int>(value: i, child: Text(Panchang.monthName(i, false, lang)))),
                        onChanged: (v) => setS(() => mMonth = v ?? 0),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Shukla (waxing)', style: TextStyle(fontSize: 12)),
                            selected: !mKrishna,
                            onSelected: (_) => setS(() => mKrishna = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Krishna (waning)', style: TextStyle(fontSize: 12)),
                            selected: mKrishna,
                            onSelected: (_) => setS(() => mKrishna = true),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<int>(
                        value: mTithiN,
                        decoration: const InputDecoration(labelText: 'Tithi'),
                        items: List.generate(15, (i) {
                          final n = i + 1;
                          final abs = mKrishna ? (n == 15 ? 30 : 15 + n) : n;
                          return DropdownMenuItem<int>(value: n, child: Text(Panchang.tithiName(abs, lang)));
                        }),
                        onChanged: (v) => setS(() => mTithiN = v ?? 1),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: remind,
                      decoration: const InputDecoration(labelText: 'Reminder'),
                      items: _remindOptions.entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setS(() => remind = v ?? 1),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(err!, style: const TextStyle(color: expenseColor, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      setS(() => err = 'Please enter a name');
                      return;
                    }
                    if (mode == 'date' && derived() == null) {
                      setS(() => err = 'Pick a date between 1940 and today');
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    int monthIdx;
    int tithi;
    var source = '';
    if (mode == 'date') {
      final d = Panchang.hinduDateOf(srcDate!, minutes: birthMinutes)!;
      monthIdx = d.monthIdx;
      tithi = d.tithi;
      source = DateFormat('yyyy-MM-dd').format(srcDate!);
    } else {
      tithi = mKrishna ? (mTithiN == 15 ? 30 : 15 + mTithiN) : mTithiN;
      // Purnimanta names the dark half after the NEXT amanta month.
      monthIdx = (purnimanta && mKrishna) ? (mMonth + 11) % 12 : mMonth;
    }

    if (existing != null) {
      existing.name = nameCtrl.text.trim();
      existing.kind = kind;
      existing.monthIdx = monthIdx;
      existing.tithi = tithi;
      existing.note = noteCtrl.text.trim();
      existing.remindDaysBefore = remind;
      existing.sourceDate = source;
      widget.onUpdate(existing);
    } else {
      widget.onAdd(TithiEvent(
        id: uuid.v4(),
        name: nameCtrl.text.trim(),
        kind: kind,
        monthIdx: monthIdx,
        tithi: tithi,
        note: noteCtrl.text.trim(),
        remindDaysBefore: remind,
        sourceDate: source,
      ));
    }
    if (mounted) setState(() {});
  }

  Future<void> _delete(TithiEvent e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete this date?'),
          content: Text('"${e.name}" and its yearly reminders will be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (yes == true) {
      widget.onDelete(e.id);
      if (mounted) setState(() {});
    }
  }

  Widget _card(TithiEvent e) {
    final today = DateTime.now();
    final dates = Panchang.nextOccurrences(e.monthIdx, e.tithi, today, count: 3);
    final t0 = DateTime(today.year, today.month, today.day);

    String inText(DateTime d) {
      final diff = d.difference(t0).inDays;
      if (diff == 0) return 'today';
      if (diff == 1) return 'tomorrow';
      return 'in $diff days';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditor(existing: e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_kindIcon(e.kind), color: goldColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        Text(
                          '${tithiKindLabel(e.kind)}  •  ${_hinduLabel(e.monthIdx, e.tithi, lang)}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _delete(e)),
                ],
              ),
              const SizedBox(height: 8),
              if (dates.isEmpty)
                const Text('No upcoming date found in the calendar range.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < dates.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: i == 0 ? goldColor.withOpacity(0.2) : Colors.grey.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          i == 0
                              ? '${DateFormat('EEE, d MMM yyyy').format(dates[i])}  (${inText(dates[i])})'
                              : DateFormat('d MMM yyyy').format(dates[i]),
                          style: TextStyle(fontSize: 12, fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal),
                        ),
                      ),
                  ],
                ),
              if (e.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(e.note, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.events];
    final today = DateTime.now();
    DateTime? nextOf(TithiEvent e) {
      final d = Panchang.nextOccurrences(e.monthIdx, e.tithi, today, count: 1);
      return d.isEmpty ? null : d.first;
    }

    sorted.sort((a, b) {
      final da = nextOf(a);
      final db = nextOf(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Hindu birthdays & shraddh')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: goldColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Birthdays, anniversaries and shraddh dates that follow the Hindu tithi come on a different English date every year. Add one from the English date (or pick the tithi) and you get a reminder every year automatically.',
                      style: TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No dates added yet.', style: TextStyle(color: Colors.grey))),
            )
          else
            ...sorted.map(_card),
        ],
      ),
    );
  }
}
