import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';

String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('d MMM yyyy').format(d);
}

// "Save ₹X / month to reach it by <date>" — null when there's no target date
// or the goal is already complete.
String? _neededText(SavingsGoal g) {
  if (g.completed || g.targetDate == null) return null;
  final target = DateTime.tryParse(g.targetDate!);
  if (target == null) return null;
  final now = DateTime.now();
  if (!target.isAfter(now)) return 'Target date has passed';
  final days = target.difference(now).inDays;
  final months = max(1, (days / 30).ceil());
  final remaining = g.targetAmount - g.saved;
  return 'Save ${fmtRs(remaining / months)} / month to reach it by ${_fmtDate(g.targetDate)}';
}

/* ============================== DIALOGS ============================== */

Future<void> _openGoalDialog(
  BuildContext context, {
  SavingsGoal? existing,
  required void Function(SavingsGoal) onSave,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final targetCtrl = TextEditingController(text: existing == null ? '' : _plain(existing.targetAmount));
  String? targetDate = existing?.targetDate;
  String? err;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setS) {
          return AlertDialog(
            title: Text(existing == null ? 'New Savings Goal' : 'Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Goal name', hintText: 'e.g. New phone, Goa trip'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          targetDate == null ? 'Target date (optional)' : 'By ${_fmtDate(targetDate)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          var initial = DateTime.tryParse(targetDate ?? '') ?? now.add(const Duration(days: 90));
                          if (initial.isBefore(now)) initial = now;
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: initial,
                            firstDate: now,
                            lastDate: DateTime(now.year + 20),
                          );
                          if (picked != null) {
                            setS(() => targetDate = DateFormat('yyyy-MM-dd').format(picked));
                          }
                        },
                        child: const Text('Pick date'),
                      ),
                      if (targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setS(() => targetDate = null),
                        ),
                    ],
                  ),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(err!, style: const TextStyle(color: expenseColor, fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final target = double.tryParse(targetCtrl.text.replaceAll(',', '').trim()) ?? 0;
                  if (nameCtrl.text.trim().isEmpty) {
                    setS(() => err = 'Please enter a goal name');
                    return;
                  }
                  if (target <= 0) {
                    setS(() => err = 'Please enter a target amount');
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

  if (ok == true) {
    final target = double.tryParse(targetCtrl.text.replaceAll(',', '').trim()) ?? 0;
    if (existing != null) {
      existing.name = nameCtrl.text.trim();
      existing.targetAmount = target;
      existing.targetDate = targetDate;
      onSave(existing);
    } else {
      onSave(SavingsGoal(
        id: uuid.v4(),
        name: nameCtrl.text.trim(),
        targetAmount: target,
        targetDate: targetDate,
        createdDate: todayISO(),
      ));
    }
  }
}

Future<void> _openAddMoneyDialog(
  BuildContext context,
  SavingsGoal goal, {
  required void Function(GoalContribution c, bool recordEntry) onSave,
}) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String date = todayISO();
  bool record = true;
  String? err;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setS) {
          return AlertDialog(
            title: Text('Add to ${goal.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: date),
                    decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setS(() => date = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: record,
                    onChanged: (v) => setS(() => record = v ?? true),
                    title: const Text('Also record as a Savings entry', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Counts towards Total Savings and lowers your remaining balance',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(err!, style: const TextStyle(color: expenseColor, fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
                  if (amt <= 0) {
                    setS(() => err = 'Please enter a valid amount');
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );

  if (ok == true) {
    final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    onSave(
      GoalContribution(id: uuid.v4(), date: date, amount: amt, note: noteCtrl.text.trim()),
      record,
    );
  }
}

/* ============================== GOAL LIST ============================== */

class SavingsGoalsScreen extends StatefulWidget {
  final List<SavingsGoal> goals;
  final void Function(SavingsGoal) onAdd;
  final void Function(SavingsGoal) onUpdate;
  final void Function(String) onDelete;
  final void Function(Entry) onAddEntry;
  final void Function(String) onDeleteEntry;

  const SavingsGoalsScreen({
    super.key,
    required this.goals,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddEntry,
    required this.onDeleteEntry,
  });

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  Widget _card(SavingsGoal g) {
    final needed = _neededText(g);
    final pct = (g.progress * 100).toStringAsFixed(0);
    final barColor = g.completed ? incomeColor : goldColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(
                goal: g,
                onUpdate: widget.onUpdate,
                onDelete: widget.onDelete,
                onAddEntry: widget.onAddEntry,
                onDeleteEntry: widget.onDeleteEntry,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(g.completed ? Icons.emoji_events : Icons.flag, color: barColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: barColor)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: g.progress,
                  minHeight: 10,
                  color: barColor,
                  backgroundColor: goldColor.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${fmtRs(g.saved)} saved', style: const TextStyle(fontSize: 12)),
                  Text('of ${fmtRs(g.targetAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (needed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(needed, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ),
              if (g.completed)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Goal reached! 🎉', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: incomeColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGoalDialog(context, onSave: widget.onAdd),
                icon: const Icon(Icons.add),
                label: const Text('New Goal'),
              ),
            ),
          ),
          Expanded(
            child: widget.goals.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No goals yet. Set one — a new phone, a trip, an emergency fund — and watch your progress grow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView(children: widget.goals.map(_card).toList()),
          ),
        ],
      ),
    );
  }
}

/* ============================== GOAL DETAIL ============================== */

class GoalDetailScreen extends StatefulWidget {
  final SavingsGoal goal;
  final void Function(SavingsGoal) onUpdate;
  final void Function(String) onDelete;
  final void Function(Entry) onAddEntry;
  final void Function(String) onDeleteEntry;

  const GoalDetailScreen({
    super.key,
    required this.goal,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddEntry,
    required this.onDeleteEntry,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late SavingsGoal goal;

  @override
  void initState() {
    super.initState();
    goal = widget.goal;
  }

  void _addMoney() {
    _openAddMoneyDialog(context, goal, onSave: (c, record) {
      if (record) {
        final entry = Entry(
          id: uuid.v4(),
          section: 'savings',
          category: 'goal',
          date: c.date,
          amount: c.amount,
          customLabel: goal.name,
          notes: c.note.isEmpty ? 'Goal deposit' : c.note,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        c.entryId = entry.id;
        widget.onAddEntry(entry);
      }
      setState(() => goal.contributions.add(c));
      widget.onUpdate(goal);
    });
  }

  Future<void> _deleteContribution(GoalContribution c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove this deposit?'),
          content: Text(
            c.entryId != null
                ? '${fmtRs(c.amount)} will be removed from this goal and from your Savings entries.'
                : '${fmtRs(c.amount)} will be removed from this goal.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
          ],
        );
      },
    );
    if (yes == true) {
      if (c.entryId != null) widget.onDeleteEntry(c.entryId!);
      setState(() => goal.contributions.removeWhere((x) => x.id == c.id));
      widget.onUpdate(goal);
    }
  }

  Future<void> _deleteGoal() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete this goal?'),
          content: const Text(
            'The goal and its deposit history will be removed. Savings entries already recorded on your dashboard stay as they are.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (yes == true) {
      widget.onDelete(goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...goal.contributions];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    final remaining = max(0.0, goal.targetAmount - goal.saved);
    final needed = _neededText(goal);
    final pct = (goal.progress * 100).toStringAsFixed(0);
    final ringColor = goal.completed ? incomeColor : goldColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openGoalDialog(context, existing: goal, onSave: (g) {
              setState(() {});
              widget.onUpdate(g);
            }),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteGoal),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: goal.progress,
                            strokeWidth: 12,
                            color: ringColor,
                            backgroundColor: goldColor.withOpacity(0.15),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct%', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: ringColor)),
                            const Text('saved', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (goal.completed)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: incomeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Goal reached! 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: incomeColor),
                      ),
                    ),
                  _row('Saved', fmtRs(goal.saved)),
                  _row('Target', fmtRs(goal.targetAmount)),
                  _row('Remaining', fmtRs(remaining)),
                  if (goal.targetDate != null) _row('Target date', _fmtDate(goal.targetDate)),
                  if (needed != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(needed, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _addMoney,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Money'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Deposits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No deposits yet.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...sorted.map((c) {
              final subtitle = c.note.isEmpty ? _fmtDate(c.date) : '${_fmtDate(c.date)} · ${c.note}';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.savings_outlined, color: savingsColor),
                  title: Text(fmtRs(c.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _deleteContribution(c),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
