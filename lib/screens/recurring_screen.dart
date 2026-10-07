import 'package:flutter/material.dart';
import '../models.dart';
import '../helpers.dart';

const _recurringSections = ['home', 'personal', 'vehicle'];
const _recurringSectionLabels = {
  'home': 'Home Expenses',
  'personal': 'Personal Expenses',
  'vehicle': 'Vehicle Expenses',
};

class RecurringExpensesScreen extends StatefulWidget {
  final List<RecurringExpense> recurringExpenses;
  final void Function(RecurringExpense) onAdd;
  final void Function(RecurringExpense) onUpdate;
  final void Function(String) onDelete;

  const RecurringExpensesScreen({
    super.key,
    required this.recurringExpenses,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  void openSheet({RecurringExpense? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return RecurringExpenseSheet(
          existing: existing,
          onSave: (r) {
            if (existing != null) {
              widget.onUpdate(r);
            } else {
              widget.onAdd(r);
            }
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> confirmDelete(RecurringExpense r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Recurring Expense?'),
          content: Text('"${r.label()}" will no longer auto-log every month. Past entries already created stay untouched.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
          ],
        );
      },
    );
    if (yes == true) widget.onDelete(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.recurringExpenses];
    sorted.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set up a fixed monthly expense once (Netflix, Gym, EMI, rent...) and it will log itself automatically every month on the chosen day — no need to re-type it.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => openSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Recurring Expense'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No recurring expenses set up yet.'))
                : ListView(
                    children: sorted.map((r) {
                      final cat = findCat(r.section, r.vehicleType, r.category);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: Icon(cat?.icon ?? Icons.repeat, color: r.active ? goldColor : Colors.grey),
                          title: Text(r.label(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text(
                            'Every month on day ${r.dayOfMonth} · ${fmtRs(r.amount)}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onTap: () => openSheet(existing: r),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: r.active,
                                onChanged: (v) {
                                  r.active = v;
                                  widget.onUpdate(r);
                                },
                              ),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => confirmDelete(r)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class RecurringExpenseSheet extends StatefulWidget {
  final RecurringExpense? existing;
  final void Function(RecurringExpense) onSave;

  const RecurringExpenseSheet({super.key, this.existing, required this.onSave});

  @override
  State<RecurringExpenseSheet> createState() => _RecurringExpenseSheetState();
}

class _RecurringExpenseSheetState extends State<RecurringExpenseSheet> {
  String section = 'home';
  String vehicleType = 'bike';
  late String categoryKey;
  final amountCtrl = TextEditingController();
  final customCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  int dayOfMonth = 1;
  bool active = true;
  String? err;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      section = ex.section;
      vehicleType = ex.vehicleType ?? 'bike';
      categoryKey = ex.category;
      amountCtrl.text = ex.amount.toString();
      customCtrl.text = ex.customLabel;
      notesCtrl.text = ex.notes;
      dayOfMonth = ex.dayOfMonth;
      active = ex.active;
    } else {
      categoryKey = catsFor(section, vehicleType).first.key;
    }
  }

  void resetCategoryForSection() {
    final list = catsFor(section, vehicleType);
    if (!list.any((c) => c.key == categoryKey)) {
      categoryKey = list.first.key;
    }
  }

  void save() {
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    final cat = findCat(section, vehicleType, categoryKey);
    if (amt <= 0) {
      setState(() => err = 'Please enter a valid amount');
      return;
    }
    if (cat != null && cat.custom && customCtrl.text.trim().isEmpty) {
      setState(() => err = 'Please name this category');
      return;
    }

    final r = RecurringExpense(
      id: widget.existing?.id ?? uuid.v4(),
      section: section,
      category: categoryKey,
      vehicleType: section == 'vehicle' ? vehicleType : null,
      amount: amt,
      dayOfMonth: dayOfMonth,
      notes: notesCtrl.text.trim(),
      customLabel: (cat != null && cat.custom) ? customCtrl.text.trim() : '',
      active: active,
      lastGeneratedMonth: widget.existing?.lastGeneratedMonth,
    );
    widget.onSave(r);
  }

  @override
  Widget build(BuildContext context) {
    final cats = catsFor(section, vehicleType);
    final selectedCat = findCat(section, vehicleType, categoryKey);
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: goldColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Recurring Expense' : 'New Recurring Expense',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _recurringSections.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_recurringSectionLabels[s]!),
                            selected: section == s,
                            onSelected: (_) => setSheetState(() {
                              section = s;
                              resetCategoryForSection();
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (section == 'vehicle')
                    Row(
                      children: ['bike', 'car'].map((v) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              onPressed: () => setSheetState(() {
                                vehicleType = v;
                                resetCategoryForSection();
                              }),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: vehicleType == v ? goldColor.withOpacity(0.2) : null,
                              ),
                              child: Text(v[0].toUpperCase() + v.substring(1)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: categoryKey,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: cats.map((c) {
                      return DropdownMenuItem(value: c.key, child: Text(c.label));
                    }).toList(),
                    onChanged: (v) => setSheetState(() => categoryKey = v ?? categoryKey),
                  ),
                  if (selectedCat != null && selectedCat.custom) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customCtrl,
                      decoration: const InputDecoration(labelText: 'Category name'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: dayOfMonth,
                    decoration: const InputDecoration(labelText: 'Day of month to log it'),
                    items: List.generate(28, (i) => i + 1).map((d) {
                      return DropdownMenuItem(value: d, child: Text('Day $d'));
                    }).toList(),
                    onChanged: (v) => setSheetState(() => dayOfMonth = v ?? dayOfMonth),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: const Text('Turn off to pause auto-logging without deleting it', style: TextStyle(fontSize: 11)),
                    value: active,
                    onChanged: (v) => setSheetState(() => active = v),
                  ),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err!, style: const TextStyle(color: expenseColor)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: save,
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
                      child: Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
