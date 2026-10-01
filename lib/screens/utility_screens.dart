import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xls;
import '../models.dart';
import '../helpers.dart';

/* ============================== MILK SCREEN ============================== */

class MilkScreen extends StatefulWidget {
  final Map<String, String> milkLeaves;
  final double litresPerDay;
  final double pricePerLitre;
  final void Function(String date, String reason) onAddLeave;
  final void Function(String date) onRemoveLeave;
  final void Function({double? litresPerDay, double? pricePerLitre}) onUpdateSettings;
  final void Function(Entry) onRecordPayment;
  final void Function(Reminder) onAddReminder;

  const MilkScreen({
    super.key,
    required this.milkLeaves,
    required this.litresPerDay,
    required this.pricePerLitre,
    required this.onAddLeave,
    required this.onRemoveLeave,
    required this.onUpdateSettings,
    required this.onRecordPayment,
    required this.onAddReminder,
  });

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  late TextEditingController litresCtrl;
  late TextEditingController rateCtrl;
  late Map<String, String> localLeaves;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    litresCtrl = TextEditingController(text: widget.litresPerDay.toString());
    rateCtrl = TextEditingController(text: widget.pricePerLitre.toString());
    localLeaves = Map<String, String>.from(widget.milkLeaves);
  }

  Future<void> handleDayTap(String iso, bool isFuture) async {
    if (isFuture) return;

    if (localLeaves.containsKey(iso)) {
      final reasonCtrl = TextEditingController(text: localLeaves[iso] ?? '');
      final action = await showDialog<String>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Leave: $iso'),
            content: TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
              maxLines: 2,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, 'remove'), child: const Text('Remove Leave')),
              TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Close')),
              TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
            ],
          );
        },
      );
      if (action == 'remove') {
        setState(() => localLeaves.remove(iso));
        widget.onRemoveLeave(iso);
      } else if (action == 'save') {
        setState(() => localLeaves[iso] = reasonCtrl.text.trim());
        widget.onAddLeave(iso, reasonCtrl.text.trim());
      }
      return;
    }

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Mark Leave: $iso'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)', hintText: 'e.g. Went out of town'),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Leave')),
          ],
        );
      },
    );
    if (confirmed == true) {
      setState(() => localLeaves[iso] = reasonCtrl.text.trim());
      widget.onAddLeave(iso, reasonCtrl.text.trim());
    }
  }

  Future<void> exportMonthExcel() async {
    setState(() => exporting = true);
    try {
      final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
      final monthKey = DateFormat('yyyy-MM').format(cursor);
      final monthLabel = DateFormat('MMMM yyyy').format(cursor);

      final book = xls.Excel.createExcel();
      final sheet = book['Milk Tracker'];
      if (book.sheets.keys.contains('Sheet1')) {
        book.delete('Sheet1');
      }

      sheet.appendRow([xls.TextCellValue('Milk Tracker - $monthLabel')]);
      sheet.appendRow([
        xls.TextCellValue('Litres/day: ${widget.litresPerDay}'),
        xls.TextCellValue('Rate: ₹${widget.pricePerLitre.toStringAsFixed(2)}/litre'),
      ]);
      sheet.appendRow([]);
      sheet.appendRow([
        xls.TextCellValue('Date'),
        xls.TextCellValue('Day'),
        xls.TextCellValue('Status'),
        xls.TextCellValue('Reason'),
        xls.TextCellValue('Litre'),
        xls.TextCellValue('Rate (₹)'),
        xls.TextCellValue('Amount (₹)'),
      ]);

      int leaves = 0;
      double totalLitres = 0;
      double totalAmount = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        final dateObj = DateTime(cursor.year, cursor.month, d);
        final iso = DateFormat('yyyy-MM-dd').format(dateObj);
        final dayName = DateFormat('EEE').format(dateObj);
        final isLeave = localLeaves.containsKey(iso);
        final litres = isLeave ? 0.0 : widget.litresPerDay;
        final amount = litres * widget.pricePerLitre;
        if (isLeave) leaves++;
        totalLitres += litres;
        totalAmount += amount;

        sheet.appendRow([
          xls.TextCellValue(DateFormat('dd MMM yyyy').format(dateObj)),
          xls.TextCellValue(dayName),
          xls.TextCellValue(isLeave ? 'Leave' : 'Milk Delivered'),
          xls.TextCellValue(isLeave ? (localLeaves[iso] ?? '') : ''),
          xls.DoubleCellValue(litres),
          xls.DoubleCellValue(widget.pricePerLitre),
          xls.DoubleCellValue(double.parse(amount.toStringAsFixed(2))),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([xls.TextCellValue('Total Days'), xls.IntCellValue(daysInMonth)]);
      sheet.appendRow([xls.TextCellValue('Leaves'), xls.IntCellValue(leaves)]);
      sheet.appendRow([xls.TextCellValue('Milk Delivered Days'), xls.IntCellValue(daysInMonth - leaves)]);
      sheet.appendRow([xls.TextCellValue('Total Litre'), xls.DoubleCellValue(double.parse(totalLitres.toStringAsFixed(2)))]);
      sheet.appendRow([xls.TextCellValue('Total Amount (₹)'), xls.DoubleCellValue(double.parse(totalAmount.toStringAsFixed(2)))]);

      final bytes = book.encode();
      if (bytes == null) {
        throw Exception('Could not generate the Excel file');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/milk_$monthKey.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: 'Milk Tracker - $monthLabel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during Excel export: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget statRow(String label, String value) {
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

  Widget calcCard(String title, String rangeLabel, int totalDays, int leaves, double litres, double amount, {bool isFinal = false}) {
    final delivered = totalDays - leaves;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(rangeLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),
            statRow('Total days', '$totalDays'),
            statRow('Leaves (milk not delivered)', '$leaves'),
            statRow('Milk delivered days', '$delivered'),
            statRow('Total litres', litres.toStringAsFixed(1)),
            statRow('Rate', '₹${widget.pricePerLitre.toStringAsFixed(2)} / litre'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                ],
              ),
            ),
            if (isFinal) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        final entry = Entry(
                          id: uuid.v4(),
                          section: 'home',
                          category: 'milk',
                          date: DateFormat('yyyy-MM-dd').format(lastDay),
                          amount: amount,
                          quantity: litres,
                          rate: widget.pricePerLitre,
                          unitLabel: 'Litre',
                          notes: '$delivered/$totalDays days delivered, $leaves leaves ($rangeLabel)',
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        widget.onRecordPayment(entry);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
                      },
                      child: const Text('Record Payment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        widget.onAddReminder(
                          Reminder(
                            id: uuid.v4(),
                            title: 'Milk Payment - ${DateFormat('MMMM yyyy').format(cursor)}',
                            dueDate: DateFormat('yyyy-MM-dd').format(lastDay),
                            recurring: true,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set')));
                      },
                      child: const Text('Set Reminder'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final monthKey = DateFormat('yyyy-MM').format(cursor);
    final now = DateTime.now();
    final isCurrentMonth = cursor.year == now.year && cursor.month == now.month;

    final leavesThisMonth = localLeaves.keys.where((d) => d.startsWith(monthKey)).length;
    final totalLitres = (daysInMonth - leavesThisMonth) * widget.litresPerDay;
    final finalAmount = totalLitres * widget.pricePerLitre;

    final firstDay = DateTime(cursor.year, cursor.month, 1);
    final lastDay = DateTime(cursor.year, cursor.month, daysInMonth);
    final rangeLabel = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(lastDay)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Milk Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1)),
                      ),
                      Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Tap a date when milk was NOT delivered. Tap again to view or edit the note.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (_, i) {
                      if (i < startWeekday) return const SizedBox();
                      final day = i - startWeekday + 1;
                      final dateObj = DateTime(cursor.year, cursor.month, day);
                      final iso = DateFormat('yyyy-MM-dd').format(dateObj);
                      final isLeave = localLeaves.containsKey(iso);
                      final isFuture = dateObj.isAfter(DateTime(now.year, now.month, now.day));
                      final isToday = iso == todayISO();

                      Color bg;
                      Color? textColor;
                      if (isFuture) {
                        bg = Colors.grey.withOpacity(0.08);
                        textColor = Colors.grey;
                      } else if (isLeave) {
                        bg = expenseColor.withOpacity(0.85);
                        textColor = Colors.white;
                      } else {
                        bg = incomeColor.withOpacity(0.25);
                        textColor = null;
                      }

                      return InkWell(
                        onTap: isFuture ? null : () => handleDayTap(iso, isFuture),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday ? Border.all(color: goldColor, width: 1.5) : null,
                          ),
                          child: Center(
                            child: Text('$day', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      legendDot(incomeColor.withOpacity(0.4), 'Milk Delivered'),
                      legendDot(expenseColor, 'Leave'),
                      legendDot(Colors.grey.withOpacity(0.3), 'Upcoming Date'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Excel Export', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Export the full day-wise milk record for this month (delivered/leave, litres, amount) as an Excel file (.xlsx) and share it.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: exporting ? null : exportMonthExcel,
                      icon: exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.grid_on, size: 18),
                      label: Text(
                        exporting
                            ? 'Preparing Excel...'
                            : 'Export ${DateFormat('MMMM yyyy').format(cursor)} to Excel',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rate Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: litresCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Litres / day'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '₹ / Litre'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onUpdateSettings(
                          litresPerDay: double.tryParse(litresCtrl.text) ?? widget.litresPerDay,
                          pricePerLitre: double.tryParse(rateCtrl.text) ?? widget.pricePerLitre,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate saved')));
                      },
                      child: const Text('Save Rate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentMonth) ...[
            Builder(builder: (_) {
              final todayDay = now.day;
              final leavesTillToday = localLeaves.keys.where((d) {
                if (!d.startsWith(monthKey)) return false;
                final dayNum = int.tryParse(d.split('-').last) ?? 0;
                return dayNum <= todayDay;
              }).length;
              final litresTillToday = (todayDay - leavesTillToday) * widget.litresPerDay;
              final amountTillToday = litresTillToday * widget.pricePerLitre;
              final rangeTillToday = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(now)}';
              return calcCard('Summary So Far', rangeTillToday, todayDay, leavesTillToday, litresTillToday, amountTillToday);
            }),
          ],
          calcCard('Full Month Summary', rangeLabel, daysInMonth, leavesThisMonth, totalLitres, finalAmount, isFinal: true),
        ],
      ),
    );
  }

  Widget legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/* ============================== ELECTRICITY SCREEN ============================== */

class ElectricityScreen extends StatefulWidget {
  final double? lastReading;
  final double ratePerUnit;
  final void Function({double? lastReading, double? ratePerUnit}) onUpdateSettings;
  final void Function(Entry) onRecordPayment;

  const ElectricityScreen({
    super.key,
    required this.lastReading,
    required this.ratePerUnit,
    required this.onUpdateSettings,
    required this.onRecordPayment,
  });

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  late TextEditingController prevCtrl;
  late TextEditingController currCtrl;
  late TextEditingController rateCtrl;
  String billDate = todayISO();
  String? err;

  @override
  void initState() {
    super.initState();
    prevCtrl = TextEditingController(text: widget.lastReading?.toString() ?? '');
    currCtrl = TextEditingController();
    rateCtrl = TextEditingController(text: widget.ratePerUnit.toString());
  }

  double get units {
    final prev = double.tryParse(prevCtrl.text) ?? 0;
    final curr = double.tryParse(currCtrl.text) ?? 0;
    final u = curr - prev;
    return u > 0 ? u : 0;
  }

  double get amount => units * (double.tryParse(rateCtrl.text) ?? 0);

  void save() {
    final curr = double.tryParse(currCtrl.text);
    final prev = double.tryParse(prevCtrl.text);
    final rate = double.tryParse(rateCtrl.text);
    if (curr == null || prev == null || rate == null || curr <= prev) {
      setState(() => err = 'Current reading must be greater than previous reading');
      return;
    }
    final entry = Entry(
      id: uuid.v4(),
      section: 'home',
      category: 'electricity',
      date: billDate,
      amount: amount,
      quantity: units,
      rate: rate,
      unitLabel: 'Unit',
      notes: 'Meter: $prev → $curr ($units units)',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    widget.onRecordPayment(entry);
    widget.onUpdateSettings(lastReading: curr, ratePerUnit: rate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Electricity Bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Meter Reading', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: billDate),
                    decoration: const InputDecoration(labelText: 'Bill Date', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(billDate),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => billDate = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: prevCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Previous Reading'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: currCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Current Reading'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '₹ / Unit'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Units Consumed'), Text('${units.toStringAsFixed(1)} units', style: const TextStyle(fontWeight: FontWeight.bold))],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                      ],
                    ),
                  ),
                  if (err != null)
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(color: expenseColor))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(onPressed: save, child: const Text('Record Bill')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== GAS CYLINDER SCREEN ============================== */

class GasScreen extends StatefulWidget {
  final String? lastCylinderDate;
  final double cylinderKg;
  final void Function({String? lastCylinderDate, double? cylinderKg}) onUpdateSettings;
  final void Function(Entry) onRecordPayment;

  const GasScreen({
    super.key,
    required this.lastCylinderDate,
    required this.cylinderKg,
    required this.onUpdateSettings,
    required this.onRecordPayment,
  });

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> {
  late String prevDate;
  String newDate = todayISO();
  late TextEditingController kgCtrl;
  late TextEditingController amountCtrl;
  String? err;

  @override
  void initState() {
    super.initState();
    prevDate = widget.lastCylinderDate ?? todayISO();
    kgCtrl = TextEditingController(text: widget.cylinderKg.toString());
    amountCtrl = TextEditingController();
  }

  int get days {
    final d = DateTime.parse(newDate).difference(DateTime.parse(prevDate)).inDays;
    return d > 0 ? d : 0;
  }

  double get kgPerDay => days > 0 ? (double.tryParse(kgCtrl.text) ?? 0) / days : 0;
  double get amountPerDay => days > 0 ? (double.tryParse(amountCtrl.text) ?? 0) / days : 0;

  void save() {
    final amt = double.tryParse(amountCtrl.text);
    final kg = double.tryParse(kgCtrl.text);
    if (amt == null || kg == null || days <= 0) {
      setState(() => err = 'The new cylinder date must be after the previous date, and amount/kg must be filled');
      return;
    }
    final entry = Entry(
      id: uuid.v4(),
      section: 'home',
      category: 'gas',
      date: newDate,
      amount: amt,
      quantity: kg,
      unitLabel: 'Kg',
      notes: 'Lasted $days days, ${kgPerDay.toStringAsFixed(3)} kg/day, ₹${amountPerDay.toStringAsFixed(2)}/day',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    widget.onRecordPayment(entry);
    widget.onUpdateSettings(lastCylinderDate: newDate, cylinderKg: kg);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gas Cylinder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cylinder Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: prevDate),
                    decoration: const InputDecoration(labelText: 'When Did the Previous Cylinder Arrive', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(prevDate),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => prevDate = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: newDate),
                    decoration: const InputDecoration(labelText: 'When Did the New Cylinder Arrive', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(newDate),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => newDate = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: kgCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cylinder Weight (Kg)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '₹ '),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('How many days did the cylinder last'), Text('$days days', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Per Day Consumption'), Text('${kgPerDay.toStringAsFixed(3)} kg/day', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Per Day Cost'), Text('₹${amountPerDay.toStringAsFixed(2)}/day', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(fmtRs(double.tryParse(amountCtrl.text) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                      ],
                    ),
                  ),
                  if (err != null)
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(color: expenseColor))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(onPressed: save, child: const Text('Record Cylinder')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== RECHARGE SCREEN ============================== */

class RechargeScreen extends StatefulWidget {
  final String? lastDate;
  final void Function(String date) onUpdateLastDate;
  final void Function(Entry) onRecordPayment;

  const RechargeScreen({
    super.key,
    required this.lastDate,
    required this.onUpdateLastDate,
    required this.onRecordPayment,
  });

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  late String prevDate;
  String newDate = todayISO();
  final validityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String? err;
  List<Map<String, TextEditingController>> plans = [];

  @override
  void initState() {
    super.initState();
    prevDate = widget.lastDate ?? todayISO();
  }

  void addPlan([int? presetValidity]) {
    setState(() {
      plans.add({
        'validity': TextEditingController(text: presetValidity?.toString() ?? ''),
        'price': TextEditingController(),
      });
    });
  }

  void removePlan(int index) {
    setState(() => plans.removeAt(index));
  }

  int get daysSincePrev {
    final d = DateTime.parse(newDate).difference(DateTime.parse(prevDate)).inDays;
    return d > 0 ? d : 0;
  }

  double get perDayCost {
    final v = double.tryParse(validityCtrl.text) ?? 0;
    final p = double.tryParse(priceCtrl.text) ?? 0;
    return v > 0 ? p / v : 0;
  }

  void save() {
    final validity = double.tryParse(validityCtrl.text);
    final price = double.tryParse(priceCtrl.text);
    if (validity == null || validity <= 0 || price == null || price <= 0) {
      setState(() => err = 'Please enter validity and price correctly');
      return;
    }
    final entry = Entry(
      id: uuid.v4(),
      section: 'home',
      category: 'recharge',
      date: newDate,
      amount: price,
      quantity: validity,
      unitLabel: 'Din',
      notes: '$validity-day plan, ₹${perDayCost.toStringAsFixed(2)}/day (previous recharge was $daysSincePrev days ago)',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    widget.onRecordPayment(entry);
    widget.onUpdateLastDate(newDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final computed = plans.map((p) {
      final v = double.tryParse((p['validity'] as TextEditingController).text) ?? 0;
      final pr = double.tryParse((p['price'] as TextEditingController).text) ?? 0;
      final perDay = v > 0 ? pr / v : null;
      return perDay;
    }).toList();

    double? bestPerDay;
    for (final c in computed) {
      if (c != null && (bestPerDay == null || c < bestPerDay)) bestPerDay = c;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Recharge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recharge Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: prevDate),
                    decoration: const InputDecoration(labelText: 'When Was the Previous Recharge Done', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(prevDate),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => prevDate = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: newDate),
                    decoration: const InputDecoration(labelText: 'When Was the New Recharge Done', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(newDate),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => newDate = DateFormat('yyyy-MM-dd').format(picked));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: validityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Validity (Days)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('How many days since previous recharge'), Text('$daysSincePrev days', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Per Day Cost'), Text('₹${perDayCost.toStringAsFixed(2)}/day', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(fmtRs(double.tryParse(priceCtrl.text) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                      ],
                    ),
                  ),
                  if (err != null)
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(color: expenseColor))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(onPressed: save, child: const Text('Record Recharge')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plan Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Compare which plan offers the best value for money', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [28, 56, 84, 180, 365].map((d) {
                      return OutlinedButton(onPressed: () => addPlan(d), child: Text('+ $d days'));
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => addPlan(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Custom Plan'),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(plans.length, (i) {
                    final vCtrl = plans[i]['validity']!;
                    final pCtrl = plans[i]['price']!;
                    final v = double.tryParse(vCtrl.text) ?? 0;
                    final p = double.tryParse(pCtrl.text) ?? 0;
                    final perDay = v > 0 ? p / v : null;
                    final isBest = perDay != null && bestPerDay != null && perDay == bestPerDay;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBest ? goldColor.withOpacity(0.15) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isBest ? goldColor : Theme.of(context).dividerColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: vCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Validity (days)', isDense: true),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: pCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: '₹ Price', isDense: true),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => removePlan(i)),
                            ],
                          ),
                          if (perDay != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(isBest ? '⭐ Best Value' : '', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text('₹${perDay.toStringAsFixed(2)} / day', style: TextStyle(fontWeight: FontWeight.bold, color: isBest ? goldColor : null)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (plans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Add a plan above to compare prices', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== PRESENCE CALENDAR SCREEN (Water / Recharge) ============================== */

class PresenceCalendarScreen extends StatefulWidget {
  final String title;
  final String categoryKey;
  final String instructionText;
  final String presentLabel;
  final String absentLabel;
  final Map<String, String> presentDays;
  final double ratePerDay;
  final void Function(String date, String note) onMarkPresent;
  final void Function(String date) onUnmarkPresent;
  final void Function(double rate) onUpdateRate;
  final void Function(Entry) onRecordPayment;
  final void Function(Reminder) onAddReminder;

  const PresenceCalendarScreen({
    super.key,
    required this.title,
    required this.categoryKey,
    required this.instructionText,
    required this.presentLabel,
    required this.absentLabel,
    required this.presentDays,
    required this.ratePerDay,
    required this.onMarkPresent,
    required this.onUnmarkPresent,
    required this.onUpdateRate,
    required this.onRecordPayment,
    required this.onAddReminder,
  });

  @override
  State<PresenceCalendarScreen> createState() => _PresenceCalendarScreenState();
}

class _PresenceCalendarScreenState extends State<PresenceCalendarScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  late TextEditingController rateCtrl;
  late Map<String, String> localPresent;

  @override
  void initState() {
    super.initState();
    rateCtrl = TextEditingController(text: widget.ratePerDay.toString());
    localPresent = Map<String, String>.from(widget.presentDays);
  }

  Future<void> handleDayTap(String iso, bool isFuture) async {
    if (isFuture) return;

    if (localPresent.containsKey(iso)) {
      final noteCtrl = TextEditingController(text: localPresent[iso] ?? '');
      final action = await showDialog<String>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(iso),
            content: TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note'), maxLines: 2),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, 'remove'), child: const Text('Remove')),
              TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Close')),
              TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
            ],
          );
        },
      );
      if (action == 'remove') {
        setState(() => localPresent.remove(iso));
        widget.onUnmarkPresent(iso);
      } else if (action == 'save') {
        setState(() => localPresent[iso] = noteCtrl.text.trim());
        widget.onMarkPresent(iso, noteCtrl.text.trim());
      }
      return;
    }

    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('${widget.presentLabel}: $iso'),
          content: TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 2),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(widget.presentLabel)),
          ],
        );
      },
    );
    if (confirmed == true) {
      setState(() => localPresent[iso] = noteCtrl.text.trim());
      widget.onMarkPresent(iso, noteCtrl.text.trim());
    }
  }

  Widget statRow(String label, String value) {
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

  Widget calcCard(String title, String rangeLabel, int totalDays, int presentCount, double amount, {bool isFinal = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(rangeLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),
            statRow('Total days', '$totalDays'),
            statRow('${widget.presentLabel} (days)', '$presentCount'),
            statRow('Rate', '₹${widget.ratePerDay.toStringAsFixed(2)} / day'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                ],
              ),
            ),
            if (isFinal) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        final entry = Entry(
                          id: uuid.v4(),
                          section: 'home',
                          category: widget.categoryKey,
                          date: DateFormat('yyyy-MM-dd').format(lastDay),
                          amount: amount,
                          notes: '${widget.presentLabel}: $presentCount/$totalDays days ($rangeLabel)',
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        widget.onRecordPayment(entry);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
                      },
                      child: const Text('Record Payment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        widget.onAddReminder(
                          Reminder(
                            id: uuid.v4(),
                            title: '${widget.title} - ${DateFormat('MMMM yyyy').format(cursor)}',
                            dueDate: DateFormat('yyyy-MM-dd').format(lastDay),
                            recurring: true,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set')));
                      },
                      child: const Text('Set Reminder'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final monthKey = DateFormat('yyyy-MM').format(cursor);
    final now = DateTime.now();
    final isCurrentMonth = cursor.year == now.year && cursor.month == now.month;

    final presentThisMonth = localPresent.keys.where((d) => d.startsWith(monthKey)).length;
    final totalAmount = presentThisMonth * widget.ratePerDay;

    final firstDay = DateTime(cursor.year, cursor.month, 1);
    final lastDay = DateTime(cursor.year, cursor.month, daysInMonth);
    final rangeLabel = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(lastDay)}';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1))),
                      Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(widget.instructionText, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (_, i) {
                      if (i < startWeekday) return const SizedBox();
                      final day = i - startWeekday + 1;
                      final dateObj = DateTime(cursor.year, cursor.month, day);
                      final iso = DateFormat('yyyy-MM-dd').format(dateObj);
                      final isPresent = localPresent.containsKey(iso);
                      final isFuture = dateObj.isAfter(DateTime(now.year, now.month, now.day));
                      final isToday = iso == todayISO();

                      Color bg;
                      Color? textColor;
                      if (isFuture) {
                        bg = Colors.grey.withOpacity(0.08);
                        textColor = Colors.grey;
                      } else if (isPresent) {
                        bg = incomeColor.withOpacity(0.85);
                        textColor = Colors.white;
                      } else {
                        bg = expenseColor.withOpacity(0.2);
                        textColor = null;
                      }

                      return InkWell(
                        onTap: isFuture ? null : () => handleDayTap(iso, isFuture),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday ? Border.all(color: goldColor, width: 1.5) : null,
                          ),
                          child: Center(child: Text('$day', style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: incomeColor.withOpacity(0.85), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 6),
                        Text(widget.presentLabel, style: const TextStyle(fontSize: 11)),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: expenseColor.withOpacity(0.4), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 6),
                        Text(widget.absentLabel, style: const TextStyle(fontSize: 11)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rate Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '₹ / day'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onUpdateRate(double.tryParse(rateCtrl.text) ?? widget.ratePerDay);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate saved')));
                      },
                      child: const Text('Save Rate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentMonth) ...[
            Builder(builder: (_) {
              final todayDay = now.day;
              final presentTillToday = localPresent.keys.where((d) {
                if (!d.startsWith(monthKey)) return false;
                final dayNum = int.tryParse(d.split('-').last) ?? 0;
                return dayNum <= todayDay;
              }).length;
              final amountTillToday = presentTillToday * widget.ratePerDay;
              final rangeTillToday = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(now)}';
              return calcCard('Summary So Far', rangeTillToday, todayDay, presentTillToday, amountTillToday);
            }),
          ],
          calcCard('Full Month Summary', rangeLabel, daysInMonth, presentThisMonth, totalAmount, isFinal: true),
        ],
      ),
    );
  }
}
