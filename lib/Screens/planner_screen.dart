import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../panchang.dart';

String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

const Map<int, String> _remindChoices = {
  -1: 'No reminder',
  0: 'On the day (9:00 AM)',
  1: '1 day before',
  2: '2 days before',
  3: '3 days before',
  7: '1 week before',
  14: '2 weeks before',
};

class PlannerScreen extends StatefulWidget {
  final List<PlanItem> items;
  final String lang;
  final int initialTab;
  final void Function(PlanItem) onAddItem;
  final void Function(PlanItem) onUpdateItem;
  final void Function(String) onDeleteItem;
  final void Function(Reminder) onAddReminder;
  final void Function(String) onDeleteReminder;
  final void Function(PlanItem) onRecordExpense;

  const PlannerScreen({
    super.key,
    required this.items,
    required this.lang,
    required this.initialTab,
    required this.onAddItem,
    required this.onUpdateItem,
    required this.onDeleteItem,
    required this.onAddReminder,
    required this.onDeleteReminder,
    required this.onRecordExpense,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late DateTime cursor;
  late DateTime selected;
  bool purnimanta = true;
  String festFilter = 'major';
  String noteFilter = 'upcoming';

  String get lang => widget.lang;
  String t(String en, String hi) => lang == 'hi' ? hi : en;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    var now = DateTime.now();
    if (!Panchang.inRange(now)) now = Panchang.firstDate;
    selected = DateTime(now.year, now.month, now.day);
    cursor = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /* ============================== SAVE / REMINDER LOGIC ============================== */

  String _reminderTitle(PlanItem it) {
    final occ = it.occasionName.isEmpty ? '' : '${it.occasionName}: ';
    final amt = it.amount > 0 ? ' (${fmtRs(it.amount)})' : '';
    return 'Planner - $occ${it.title}$amt';
  }

  // Saves a plan item and keeps its Reminder in sync: any old reminder is
  // removed and, if the item is still pending and has a reminder choice, a new
  // one is created (it shows up in Reminders and fires a notification at 9 AM).
  void _persist(PlanItem item, {required bool isNew}) {
    if (item.reminderId != null) {
      widget.onDeleteReminder(item.reminderId!);
      item.reminderId = null;
    }
    final d = DateTime.tryParse(item.date);
    final n = item.remindDaysBefore;
    if (n != null && !item.done && d != null) {
      final due = DateTime(d.year, d.month, d.day).subtract(Duration(days: n));
      final r = Reminder(id: uuid.v4(), title: _reminderTitle(item), dueDate: _iso(due));
      item.reminderId = r.id;
      widget.onAddReminder(r);
      final now = DateTime.now();
      if (due.isBefore(DateTime(now.year, now.month, now.day))) {
        _snack('That reminder date has already passed, so no notification will fire.');
      }
    }
    if (isNew) {
      widget.onAddItem(item);
    } else {
      widget.onUpdateItem(item);
    }
    if (mounted) setState(() {});
  }

  void _toggleDone(PlanItem it) {
    it.done = !it.done;
    if (it.done) {
      if (it.reminderId != null) {
        widget.onDeleteReminder(it.reminderId!);
        it.reminderId = null;
      }
      widget.onUpdateItem(it);
      setState(() {});
    } else {
      // Un-done: bring the reminder back if one was chosen.
      _persist(it, isNew: false);
    }
  }

  Future<void> _deleteItem(PlanItem it) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete this plan?'),
          content: Text('"${it.title}" and its reminder will be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (yes == true) {
      if (it.reminderId != null) widget.onDeleteReminder(it.reminderId!);
      widget.onDeleteItem(it.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editItem({
    PlanItem? existing,
    DateTime? date,
    String occasionCode = '',
    String occasionName = '',
    String title = '',
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? title);
    final amountCtrl = TextEditingController(
      text: existing == null || existing.amount <= 0 ? '' : _plain(existing.amount),
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final occCtrl = TextEditingController(text: existing?.occasionName ?? occasionName);
    final originalOccasion = existing?.occasionName ?? occasionName;
    var dateV = existing != null ? (DateTime.tryParse(existing.date) ?? DateTime.now()) : (date ?? DateTime.now());
    var remind = existing != null ? (existing.remindDaysBefore ?? -1) : 1;
    String? err;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setS) {
            return AlertDialog(
              title: Text(existing == null ? 'New Plan' : 'Edit Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'What to buy / pay', hintText: 'e.g. Sweets, New clothes'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Estimated amount (optional)', prefixText: '₹ '),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('EEE, d MMM yyyy').format(dateV)),
                      decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: dateV,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) setS(() => dateV = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: occCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Occasion (optional)', hintText: 'e.g. Diwali'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: remind,
                      decoration: const InputDecoration(labelText: 'Reminder'),
                      items: _remindChoices.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setS(() => remind = v ?? -1),
                    ),
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
                    if (titleCtrl.text.trim().isEmpty) {
                      setS(() => err = 'Please enter what you need to buy or pay');
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

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final occName = occCtrl.text.trim();
    final keepCode = occName == originalOccasion ? (existing?.occasionCode ?? occasionCode) : '';

    if (existing != null) {
      existing.title = titleCtrl.text.trim();
      existing.amount = amount;
      existing.date = _iso(dateV);
      existing.occasionName = occName;
      existing.occasionCode = keepCode;
      existing.note = noteCtrl.text.trim();
      existing.remindDaysBefore = remind < 0 ? null : remind;
      _persist(existing, isNew: false);
    } else {
      _persist(
        PlanItem(
          id: uuid.v4(),
          title: titleCtrl.text.trim(),
          amount: amount,
          date: _iso(dateV),
          occasionCode: keepCode,
          occasionName: occName,
          note: noteCtrl.text.trim(),
          remindDaysBefore: remind < 0 ? null : remind,
        ),
        isNew: true,
      );
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('About this calendar'),
          content: const SingleChildScrollView(
            child: Text(
              'Tithi, nakshatra and Hindu months are calculated astronomically (Lahiri ayanamsa) for the Ujjain meridian, using the tithi at sunrise, and cover 2024 to 2035.\n\n'
              'Festival dates follow standard Smarta panchang rules. Some festivals (for example Janmashtami and Ekadashi) can be observed a day later by Vaishnava traditions; the app shows the Vaishnava Janmashtami separately when it differs.\n\n'
              'Islamic dates are approximate and depend on moon sighting.\n\n'
              'For exact muhurat or regional customs, please confirm with your local panchang or pandit.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        );
      },
    );
  }

  /* ============================== SHARED WIDGETS ============================== */

  Color _catColor(String code) {
    switch (Panchang.categoryOf(code)) {
      case 'holiday':
        return expenseColor;
      case 'vrat':
        return savingsColor;
      case 'eclipse':
        return Colors.purpleAccent;
      default:
        return goldColor;
    }
  }

  Widget _itemTile(PlanItem it) {
    final d = DateTime.tryParse(it.date) ?? DateTime.now();
    final parts = <String>[DateFormat('d MMM yyyy').format(d)];
    if (it.occasionName.isNotEmpty) parts.add(it.occasionName);
    if (it.remindDaysBefore != null && !it.done) {
      parts.add(it.remindDaysBefore == 0 ? 'Reminder on the day' : 'Reminder ${it.remindDaysBefore}d before');
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        leading: Checkbox(value: it.done, onChanged: (_) => _toggleDone(it)),
        title: Text(
          it.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: it.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(parts.join(' · '), style: const TextStyle(fontSize: 11.5)),
        onTap: () => _editItem(existing: it),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (it.amount > 0) Text(fmtRs(it.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editItem(existing: it);
                if (v == 'record') widget.onRecordExpense(it);
                if (v == 'delete') _deleteItem(it);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'record', child: Text('Record as expense')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  /* ============================== CALENDAR TAB ============================== */

  String _monthHeader() {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final a = Panchang.day(DateTime(cursor.year, cursor.month, 1));
    final b = Panchang.day(DateTime(cursor.year, cursor.month, daysInMonth));
    if (a == null || b == null) return '';
    String m(PanchangDay p) => purnimanta
        ? Panchang.monthName(p.pMonthIdx, p.pAdhika, lang)
        : Panchang.monthName(p.monthIdx, p.adhika, lang);
    final m1 = m(a);
    final m2 = m(b);
    final names = m1 == m2 ? m1 : '$m1 – $m2';
    return '$names  •  ${t('Vikram Samvat', 'विक्रम संवत')} ${Panchang.vikramSamvat(b)}';
  }

  Widget _cell(int day) {
    final date = DateTime(cursor.year, cursor.month, day);
    final p = Panchang.day(date);
    final sel = _same(date, selected);
    final isToday = _same(date, DateTime.now());
    var major = false;
    var vrat = false;
    if (p != null) {
      for (final c in p.events) {
        if (Panchang.isMajor(c)) {
          major = true;
        } else {
          vrat = true;
        }
      }
    }
    final iso = _iso(date);
    final planned = widget.items.any((i) => i.date == iso && !i.done);

    Color? bg;
    if (sel) {
      bg = goldColor;
    } else if (p != null && p.tithi == 15) {
      bg = goldColor.withOpacity(0.2);
    } else if (p != null && p.tithi == 30) {
      bg = Colors.grey.withOpacity(0.25);
    }
    final fg = sel ? Colors.black87 : null;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => selected = date),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: goldColor, width: 1.4) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: fg)),
            if (p != null)
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Panchang.tithiShort(p.tithi, lang),
                    style: TextStyle(fontSize: 8.5, color: sel ? Colors.black87 : Colors.grey),
                  ),
                ),
              ),
            SizedBox(
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (major) _dot(expenseColor),
                  if (vrat) _dot(savingsColor),
                  if (planned) _dot(incomeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(c),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(k, style: const TextStyle(color: Colors.grey, fontSize: 12.5))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _dayDetail(DateTime date) {
    final p = Panchang.day(date);
    if (p == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Panchang data is available for 2024 to 2035.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final iso = _iso(date);
    final dayItems = widget.items.where((i) => i.date == iso).toList();
    final nextTithi = p.tithi % 30 + 1;
    final until = t('until', 'तक');
    final then = t('then', 'फिर');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, d MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '${Panchang.hinduDateLine(p, purnimanta, lang)}  •  ${t('Vikram Samvat', 'विक्रम संवत')} ${Panchang.vikramSamvat(p)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 22),
            _kv(
              t('Tithi', 'तिथि'),
              '${Panchang.tithiLabel(p.tithi, lang)}\n$until ${Panchang.formatMinutes(p.tithiEnd, lang)}, $then ${Panchang.tithiLabel(nextTithi, lang)}',
            ),
            _kv(
              t('Nakshatra', 'नक्षत्र'),
              '${Panchang.nakshatraName(p.nakshatra, lang)}\n$until ${Panchang.formatMinutes(p.nakEnd, lang)}',
            ),
            _kv(
              t('Month', 'माह'),
              purnimanta
                  ? Panchang.monthName(p.pMonthIdx, p.pAdhika, lang)
                  : Panchang.monthName(p.monthIdx, p.adhika, lang),
            ),
            if (p.events.isNotEmpty) ...[
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: p.events.map((c) {
                  final col = _catColor(c);
                  return ActionChip(
                    avatar: Icon(Icons.circle, size: 10, color: col),
                    label: Text(Panchang.eventName(c, p, lang), style: const TextStyle(fontSize: 12)),
                    onPressed: () => _openOccasion(date, c),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(child: Text('Planner notes', style: TextStyle(fontWeight: FontWeight.bold))),
                TextButton.icon(
                  onPressed: () => _editItem(date: date),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add plan'),
                ),
              ],
            ),
            if (dayItems.isEmpty)
              const Text('Nothing planned for this day.', style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              ...dayItems.map(_itemTile),
          ],
        ),
      ),
    );
  }

  Widget _calendarTab() {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final canPrev = Panchang.inRange(DateTime(cursor.year, cursor.month, 0));
    final canNext = Panchang.inRange(DateTime(cursor.year, cursor.month + 1, 1));
    final weekdays = lang == 'hi' ? weekdayShortHi : weekdayShortEn;

    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_cell(d));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canPrev ? () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1)) : null,
            ),
            Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canNext ? () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1)) : null,
            ),
          ],
        ),
        Center(
          child: Text(_monthHeader(), style: const TextStyle(fontSize: 12.5, color: goldColor, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Purnimanta'),
              selected: purnimanta,
              onSelected: (_) => setState(() => purnimanta = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Amanta'),
              selected: !purnimanta,
              onSelected: (_) => setState(() => purnimanta = false),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: weekdays
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          children: cells,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            _legendItem(expenseColor, 'Festival / holiday'),
            _legendItem(savingsColor, 'Vrat'),
            _legendItem(incomeColor, 'Planned'),
          ],
        ),
        const SizedBox(height: 12),
        _dayDetail(selected),
        const SizedBox(height: 20),
      ],
    );
  }

  /* ============================== FESTIVALS TAB ============================== */

  Widget _occTile(PanchangOccurrence o) {
    final p = Panchang.day(o.date);
    final name = Panchang.eventName(o.code, p, lang);
    final today = DateTime.now();
    final diff = DateTime(o.date.year, o.date.month, o.date.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    final whenText = diff == 0 ? t('Today', 'आज') : (diff == 1 ? t('Tomorrow', 'कल') : t('in $diff days', '$diff दिन बाद'));
    final iso = _iso(o.date);
    final plans = widget.items.where((i) => i.date == iso && i.occasionCode == o.code && !i.done).toList();
    var total = 0.0;
    for (final i in plans) {
      total += i.amount;
    }
    final col = _catColor(o.code);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOccasion(o.date, o.code),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: col.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text('${o.date.day}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: col)),
                    Text(DateFormat('MMM').format(o.date), style: TextStyle(fontSize: 10.5, color: col)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('EEE').format(o.date)} • ${p == null ? '' : Panchang.hinduDateLine(p, purnimanta, lang)} • $whenText',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (plans.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(total > 0 ? fmtRs(total) : '${plans.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: incomeColor)),
                    Text('${plans.length} planned', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                  ],
                )
              else
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _festivalsTab() {
    final today = DateTime.now();
    List<PanchangOccurrence> list;
    if (festFilter == 'vrat') {
      list = Panchang.upcoming(today, days: 120, majorOnly: false).where((o) => !Panchang.isMajor(o.code)).toList();
    } else {
      list = Panchang.upcoming(today, days: 400).where((o) {
        final c = Panchang.categoryOf(o.code);
        if (festFilter == 'festival') return c == 'festival';
        if (festFilter == 'holiday') return c == 'holiday';
        return true;
      }).toList();
    }

    final filters = <String, String>{'major': 'All', 'festival': 'Festivals', 'holiday': 'Holidays', 'vrat': 'Vrats'};

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            children: filters.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: festFilter == e.key,
                  onSelected: (_) => setState(() => festFilter = e.key),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No upcoming dates found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _occTile(list[i]),
                ),
        ),
      ],
    );
  }

  /* ============================== OCCASION PAGE ============================== */

  void _openOccasion(DateTime date, String code) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _occasionPage(date, code)),
    );
  }

  Widget _occasionPage(DateTime date, String code) {
    final p = Panchang.day(date);
    final name = Panchang.eventName(code, p, lang);
    final f = Panchang.info(code);
    final iso = _iso(date);
    final its = widget.items.where((i) => i.date == iso && i.occasionCode == code).toList();
    var total = 0.0;
    for (final i in its) {
      if (!i.done) total += i.amount;
    }
    final today = DateTime.now();
    final diff = DateTime(date.year, date.month, date.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    final whenText = diff < 0
        ? t('Past', 'बीत चुका')
        : (diff == 0 ? t('Today', 'आज') : t('In $diff days', '$diff दिन बाद'));
    final taken = its.map((i) => i.title.toLowerCase()).toSet();
    final suggestions = Panchang.expensesFor(code).where((s) => !taken.contains(s.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE, d MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (p != null) ...[
                    const SizedBox(height: 4),
                    Text(Panchang.hinduDateLine(p, purnimanta, lang), style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                  ],
                  if (f != null && f.desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(f.desc, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                  const SizedBox(height: 10),
                  Text(whenText, style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Typical expenses - tap to add', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: suggestions.map((s) {
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _editItem(date: date, occasionCode: code, occasionName: name, title: s),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Text('Your plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              if (total > 0) Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
            ],
          ),
          const SizedBox(height: 6),
          if (its.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Nothing planned yet. Tap a suggestion above or add your own.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
            )
          else
            ...its.map(_itemTile),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _editItem(date: date, occasionCode: code, occasionName: name),
              icon: const Icon(Icons.add),
              label: const Text('Add custom item'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /* ============================== NOTEPAD TAB ============================== */

  Widget _notepadTab() {
    var list = [...widget.items];
    if (noteFilter == 'upcoming') list = list.where((i) => !i.done).toList();
    if (noteFilter == 'done') list = list.where((i) => i.done).toList();
    list.sort((a, b) => a.date.compareTo(b.date));

    var pendingTotal = 0.0;
    var pendingCount = 0;
    for (final i in widget.items) {
      if (!i.done) {
        pendingTotal += i.amount;
        pendingCount++;
      }
    }

    // Group: one block per (occasion, date); notes without an occasion go together.
    final groups = <String, List<PlanItem>>{};
    final order = <String>[];
    for (final i in list) {
      final key = i.occasionName.isEmpty ? 'General notes' : '${i.occasionName} · ${DateFormat('d MMM yyyy').format(DateTime.tryParse(i.date) ?? DateTime.now())}';
      if (!groups.containsKey(key)) {
        groups[key] = <PlanItem>[];
        order.add(key);
      }
      groups[key]!.add(i);
    }

    final filters = <String, String>{'upcoming': 'Upcoming', 'done': 'Done', 'all': 'All'};

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: goldColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pendingCount == 0 ? 'No pending plans' : '$pendingCount pending - ${fmtRs(pendingTotal)} planned',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...filters.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: noteFilter == e.key,
                  onSelected: (_) => setState(() => noteFilter = e.key),
                ),
              );
            }),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _editItem(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add note'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (order.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Your notepad is empty.\nOpen a festival to see typical expenses, or tap "Add note".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...order.map((key) {
            final items = groups[key]!;
            var sub = 0.0;
            for (final i in items) {
              if (!i.done) sub += i.amount;
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: goldColor))),
                        if (sub > 0) Text(fmtRs(sub), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...items.map(_itemTile),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  /* ============================== BUILD ============================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner & Panchang'),
        actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfo)],
        bottom: TabBar(
          controller: _tabs,
          labelColor: goldColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: goldColor,
          tabs: const [Tab(text: 'Calendar'), Tab(text: 'Festivals'), Tab(text: 'Notepad')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_calendarTab(), _festivalsTab(), _notepadTab()],
      ),
    );
  }
}
