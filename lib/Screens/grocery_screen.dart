import 'package:flutter/material.dart';
import '../models.dart';
import '../helpers.dart';
import '../grocery_data.dart';
import '../price_history.dart';
import 'history_screen.dart';

class GroceryScreen extends StatefulWidget {
  final void Function(Entry) onSave;
  final List<Entry> history;

  const GroceryScreen({super.key, required this.onSave, this.history = const <Entry>[]});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  bool isVeg = true;
  String categoryKey = vegGroceryCategories[0].key;
  String query = '';

  void openItemSheet(GroceryItem item, String catLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroceryItemSheet(item: item, categoryLabel: catLabel, history: widget.history, onSave: widget.onSave),
    );
  }

  void openQuickAmountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAmountSheet(onSave: widget.onSave),
    );
  }

  Future<void> addCustomItem() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Custom Item'),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Enter item name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
          ],
        );
      },
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      openItemSheet(GroceryItem(nameCtrl.text.trim(), ''), 'Custom Item');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = isVeg ? vegGroceryCategories : nonVegGroceryCategories;
    final currentCat = cats.firstWhere((c) => c.key == categoryKey, orElse: () => cats[0]);
    final items = currentCat.items.where((i) {
      if (query.isEmpty) return true;
      return i.label.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ration / Grocery')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openQuickAmountSheet,
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Add Total Amount Only (without item list)'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Veg'),
                    selected: isVeg,
                    onSelected: (_) => setState(() {
                      isVeg = true;
                      categoryKey = vegGroceryCategories[0].key;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Non-Veg'),
                    selected: !isVeg,
                    onSelected: (_) => setState(() {
                      isVeg = false;
                      categoryKey = nonVegGroceryCategories[0].key;
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: cats.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.label),
                    selected: c.key == categoryKey,
                    onSelected: (_) => setState(() => categoryKey = c.key),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search item',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: addCustomItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Custom Item (not in list)'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: Icon(currentCat.icon, color: goldColor),
                  title: Text(item.label),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => openItemSheet(item, currentCat.label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _groceryUnits = ['Kg', 'Litre', 'Piece', 'Dozen', 'Packet', 'Gram'];

// Oils, milk and juices are bought by the litre, eggs by the dozen, the rest by weight.
String _defaultUnitFor(String label) {
  final l = label.toLowerCase();
  if (l.contains('egg') || l.contains('anda') || l.contains('अंडा')) return 'Dozen';
  for (final k in ['oil', 'tel', 'तेल', 'milk', 'doodh', 'दूध', 'juice', 'vinegar', 'syrup', 'water']) {
    if (l.contains(k)) return 'Litre';
  }
  return 'Kg';
}

class GroceryItemSheet extends StatefulWidget {
  final GroceryItem item;
  final String categoryLabel;
  final List<Entry> history;
  final void Function(Entry) onSave;

  const GroceryItemSheet({
    super.key,
    required this.item,
    required this.categoryLabel,
    this.history = const <Entry>[],
    required this.onSave,
  });

  @override
  State<GroceryItemSheet> createState() => _GroceryItemSheetState();
}

class _GroceryItemSheetState extends State<GroceryItemSheet> {
  final qtyCtrl = TextEditingController(text: '1');
  final rateCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String date = todayISO();
  String lastEdited = 'qty';
  String? err;
  late String unit;
  late List<Entry> past;

  @override
  void initState() {
    super.initState();
    past = historyFor(
      widget.history,
      section: 'home',
      category: 'ration',
      customLabel: widget.item.label,
    );
    // Same unit as last time; otherwise a sensible guess for this item.
    final lastUnit = past.isNotEmpty ? (past.first.unitLabel ?? '') : '';
    unit = _groceryUnits.contains(lastUnit) ? lastUnit : _defaultUnitFor(widget.item.label);
  }

  void recompute() {
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    if (lastEdited == 'amount') {
      if (qty > 0) {
        rateCtrl.text = (amt / qty).toStringAsFixed(2);
      } else if (rate > 0) {
        qtyCtrl.text = (amt / rate).toStringAsFixed(3);
      }
    } else {
      amountCtrl.text = (qty * rate).toStringAsFixed(2);
    }
  }

  void save() {
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    if (amt <= 0) {
      setState(() => err = 'Please enter a valid amount');
      return;
    }
    final entry = Entry(
      id: uuid.v4(),
      section: 'home',
      category: 'ration',
      date: date,
      amount: amt,
      quantity: double.tryParse(qtyCtrl.text),
      rate: double.tryParse(rateCtrl.text),
      unitLabel: unit,
      customLabel: widget.item.label,
      notes: widget.categoryLabel,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.item.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Text(widget.categoryLabel, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              const SizedBox(height: 12),
              if (past.isNotEmpty) ...[
                LastPurchaseCard(
                  history: past,
                  onOpenHistory: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HistoryScreen(title: '${widget.item.label} - history', entries: past)),
                    );
                  },
                ),
                if (unitPrice(past.first) != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.replay, size: 16),
                      label: Text(
                        'Use last rate ${fmtRs(unitPrice(past.first)!)}/${(past.first.unitLabel ?? unit)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => setState(() {
                        rateCtrl.text = unitPrice(past.first)!.toStringAsFixed(2);
                        lastEdited = 'rate';
                        recompute();
                      }),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                children: _groceryUnits.map((u) {
                  return ChoiceChip(
                    label: Text(u, style: const TextStyle(fontSize: 12)),
                    selected: unit == u,
                    onSelected: (_) => setState(() => unit = u),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: date),
                decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Quantity ($unit)'),
                      onChanged: (_) => setState(() {
                        lastEdited = 'qty';
                        recompute();
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '₹ / $unit'),
                      onChanged: (_) => setState(() {
                        lastEdited = 'rate';
                        recompute();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount (editable)', prefixText: '₹ '),
                onChanged: (_) => setState(() {
                  lastEdited = 'amount';
                  recompute();
                }),
              ),
              if (err != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: expenseColor))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAmountSheet extends StatefulWidget {
  final void Function(Entry) onSave;

  const QuickAmountSheet({super.key, required this.onSave});

  @override
  State<QuickAmountSheet> createState() => _QuickAmountSheetState();
}

class _QuickAmountSheetState extends State<QuickAmountSheet> {
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String date = todayISO();
  String? err;

  void save() {
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    if (amt <= 0) {
      setState(() => err = 'Please enter a valid amount');
      return;
    }
    final entry = Entry(
      id: uuid.v4(),
      section: 'home',
      category: 'grocery',
      date: date,
      amount: amt,
      notes: notesCtrl.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Grocery Total Amount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: date),
                decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              if (err != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: expenseColor))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
