import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../translations.dart';

class EntrySheet extends StatefulWidget {
  final String section;
  final Category category;
  final String? vehicleType;
  final String date;
  final Entry? existing;
  final String lang;
  final void Function(Entry) onSave;

  const EntrySheet({
    super.key,
    required this.section,
    required this.category,
    this.vehicleType,
    required this.date,
    this.existing,
    required this.lang,
    required this.onSave,
  });

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  late String date;
  final amountCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final rateCtrl = TextEditingController();
  final odoCtrl = TextEditingController();
  final customCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? err;
  bool saving = false;
  String lastEdited = 'qty';

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    date = ex?.date ?? widget.date;
    if (ex != null) {
      if (widget.category.qty) {
        qtyCtrl.text = ex.quantity?.toString() ?? '1';
        rateCtrl.text = ex.rate?.toString() ?? '';
      }
      amountCtrl.text = ex.amount.toString();
      odoCtrl.text = ex.odometer?.toString() ?? '';
      notesCtrl.text = ex.notes;
      customCtrl.text = ex.customLabel;
    } else if (widget.category.qty) {
      amountCtrl.text = '';
    }
  }

  void recompute() {
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    final amt = double.tryParse(amountCtrl.text) ?? 0;

    if (lastEdited == 'amount') {
      if (qty > 0) {
        rateCtrl.text = (amt / qty).toStringAsFixed(2);
      } else if (rate > 0) {
        qtyCtrl.text = (amt / rate).toStringAsFixed(2);
      }
    } else {
      amountCtrl.text = (qty * rate).toStringAsFixed(2);
    }
  }

  double get computedAmount {
    return double.tryParse(amountCtrl.text) ?? 0;
  }

  Future<void> save() async {
    final amt = computedAmount;
    if (amt <= 0) {
      setState(() => err = 'Please enter a valid amount');
      return;
    }
    if (widget.category.custom && customCtrl.text.trim().isEmpty) {
      setState(() => err = 'Please name this category');
      return;
    }
    if (widget.category.trackOdo && double.tryParse(odoCtrl.text) == null) {
      setState(() => err = 'Please enter the odometer reading (km)');
      return;
    }

    setState(() {
      err = null;
      saving = true;
    });

    final e = Entry(
      id: widget.existing?.id ?? uuid.v4(),
      section: widget.section,
      category: widget.category.key,
      vehicleType: widget.vehicleType,
      date: date,
      amount: amt,
      quantity: widget.category.qty ? double.tryParse(qtyCtrl.text) : null,
      rate: widget.category.qty ? double.tryParse(rateCtrl.text) : null,
      unitLabel: widget.category.unitLabel,
      odometer: widget.category.trackOdo ? double.tryParse(odoCtrl.text) : null,
      notes: notesCtrl.text.trim(),
      customLabel: widget.category.custom ? customCtrl.text.trim() : '',
      createdAt: widget.existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    await Future.delayed(const Duration(milliseconds: 150));
    widget.onSave(e);
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.category.icon, color: goldColor, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit: ${widget.category.label}' : widget.category.label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.category.custom) ...[
                TextField(
                  controller: customCtrl,
                  decoration: InputDecoration(labelText: tr('Category name', widget.lang)),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'This name becomes a permanent tile as soon as you save — you won\'t need to type it again.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: date),
                decoration: InputDecoration(labelText: tr('Date', widget.lang), suffixIcon: const Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => date = DateFormat('yyyy-MM-dd').format(picked));
                  }
                },
              ),
              const SizedBox(height: 10),
              if (widget.category.qty) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Quantity (${widget.category.unitLabel})'),
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
                        decoration: InputDecoration(labelText: 'Price / ${widget.category.unitLabel}'),
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
                  decoration: InputDecoration(labelText: tr('Total Amount (editable)', widget.lang), prefixText: '₹ '),
                  onChanged: (_) => setState(() {
                    lastEdited = 'amount';
                    recompute();
                  }),
                ),
              ] else
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('Amount', widget.lang), prefixText: '₹ '),
                  onChanged: (_) => setState(() {}),
                ),
              if (widget.category.trackOdo)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Odometer reading (km) at this fill-up',
                      prefixIcon: Icon(Icons.speed),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(labelText: tr('Note (optional)', widget.lang)),
                maxLines: 2,
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
                  onPressed: saving ? null : save,
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
                  child: Text(
                    saving
                        ? tr(isEditing ? 'Updating...' : 'Saving...', widget.lang)
                        : tr(isEditing ? 'Update Entry' : 'Save Entry', widget.lang),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
