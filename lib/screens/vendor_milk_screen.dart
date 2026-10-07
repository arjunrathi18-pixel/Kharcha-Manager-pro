import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../helpers.dart';

class VendorMilkScreen extends StatefulWidget {
  final String vendorUid;
  final List<MilkCustomer> customers;
  final void Function(MilkCustomer) onAddCustomer;
  final void Function(MilkCustomer) onUpdateCustomer;
  final void Function(String) onDeleteCustomer;
  final void Function(Entry) onAddEntry;
  final Future<Map<String, String>?> Function(String) onResolveLinkCode;

  const VendorMilkScreen({
    super.key,
    required this.vendorUid,
    required this.customers,
    required this.onAddCustomer,
    required this.onUpdateCustomer,
    required this.onDeleteCustomer,
    required this.onAddEntry,
    required this.onResolveLinkCode,
  });

  @override
  State<VendorMilkScreen> createState() => _VendorMilkScreenState();
}

class _VendorMilkScreenState extends State<VendorMilkScreen> {
  Future<void> openAddCustomerDialog({MilkCustomer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final litresCtrl = TextEditingController(text: existing?.litresPerDay.toString() ?? '1');
    final rateCtrl = TextEditingController(text: existing?.pricePerLitre.toString() ?? '60');
    final linkCodeCtrl = TextEditingController();
    String? linkStatus = existing?.linkedCustomerUid != null ? 'Linked to ${existing!.linkedCustomerName}' : null;
    Map<String, String>? resolvedLink;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'WhatsApp Number'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: litresCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Litres / day'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '₹ / Litre'),
                    ),
                    const SizedBox(height: 14),
                    const Align(alignment: Alignment.centerLeft, child: Text('Live Sync (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    const SizedBox(height: 4),
                    const Text(
                      "If this customer also uses Kharcha Manager, enter the code from their 'My Milk Link' screen so their bill shows up live on their own phone.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Customer Link Code'),
                    ),
                    if (linkStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(linkStatus!, style: const TextStyle(fontSize: 11, color: incomeColor)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    if (linkCodeCtrl.text.trim().isNotEmpty) {
                      final resolved = await widget.onResolveLinkCode(linkCodeCtrl.text.trim());
                      if (resolved == null) {
                        setDialogState(() => linkStatus = 'Code not found — check and try again, or leave blank.');
                        return;
                      }
                      resolvedLink = resolved;
                      setDialogState(() => linkStatus = 'Linked to ${resolved['name']}');
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      final linkedUid = resolvedLink?['uid'] ?? existing?.linkedCustomerUid;
      final linkedName = resolvedLink?['name'] ?? existing?.linkedCustomerName;
      final customer = MilkCustomer(
        id: existing?.id ?? uuid.v4(),
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        litresPerDay: double.tryParse(litresCtrl.text) ?? 1.0,
        pricePerLitre: double.tryParse(rateCtrl.text) ?? 60.0,
        leaves: existing?.leaves,
        quantityOverrides: existing?.quantityOverrides,
        linkedCustomerUid: linkedUid,
        linkedCustomerName: linkedName,
      );
      if (existing == null) {
        widget.onAddCustomer(customer);
      } else {
        widget.onUpdateCustomer(customer);
      }
    }
  }

  Future<void> confirmDelete(MilkCustomer c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Customer?'),
          content: Text('"${c.name}" and their entire leave record will be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
          ],
        );
      },
    );
    if (yes == true) widget.onDeleteCustomer(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDay = now.day;

    return Scaffold(
      appBar: AppBar(title: const Text('Milk Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => openAddCustomerDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Customer'),
              ),
            ),
          ),
          Expanded(
            child: widget.customers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers added yet. Tap "Add Customer" to start billing your milk customers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView(
                    children: widget.customers.map((c) {
                      double litresTillToday = 0;
                      for (int d = 1; d <= todayDay; d++) {
                        final iso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
                        litresTillToday += effectiveMilkQty(iso, c.quantityOverrides, c.leaves, c.litresPerDay);
                      }
                      final amountTillToday = litresTillToday * c.pricePerLitre;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.local_drink, color: goldColor),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${c.litresPerDay} L/day · ₹${c.pricePerLitre}/L · So far this month: ${fmtRs(amountTillToday)}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorCustomerDetailScreen(
                                  vendorUid: widget.vendorUid,
                                  customer: c,
                                  onUpdate: widget.onUpdateCustomer,
                                  onAddEntry: widget.onAddEntry,
                                ),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => openAddCustomerDialog(existing: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => confirmDelete(c),
                              ),
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

class VendorCustomerDetailScreen extends StatefulWidget {
  final String vendorUid;
  final MilkCustomer customer;
  final void Function(MilkCustomer) onUpdate;
  final void Function(Entry) onAddEntry;

  const VendorCustomerDetailScreen({
    super.key,
    required this.vendorUid,
    required this.customer,
    required this.onUpdate,
    required this.onAddEntry,
  });

  @override
  State<VendorCustomerDetailScreen> createState() => _VendorCustomerDetailScreenState();
}

class _VendorCustomerDetailScreenState extends State<VendorCustomerDetailScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  late MilkCustomer customer;

  @override
  void initState() {
    super.initState();
    customer = widget.customer;
  }

  void pushUpdate() {
    widget.onUpdate(customer);
  }

  bool dayHasOverride(String iso) => customer.quantityOverrides.containsKey(iso) || customer.leaves.containsKey(iso);

  Future<void> handleDayTap(String iso, bool isFuture) async {
    if (isFuture) return;

    final currentQty = effectiveMilkQty(iso, customer.quantityOverrides, customer.leaves, customer.litresPerDay);
    final hasOverride = dayHasOverride(iso);
    final qtyCtrl = TextEditingController(text: currentQty == currentQty.roundToDouble() ? currentQty.toStringAsFixed(0) : currentQty.toString());
    final noteCtrl = TextEditingController(text: customer.leaves[iso] ?? '');

    final action = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(iso),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Normal day: ${customer.litresPerDay} L', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Litres delivered this day (0 = leave)'),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. extra 1L, or leave reason'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            if (hasOverride)
              TextButton(onPressed: () => Navigator.pop(context, 'reset'), child: const Text('Reset to Normal')),
            TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
          ],
        );
      },
    );

    if (action == 'reset') {
      setState(() {
        customer.quantityOverrides.remove(iso);
        customer.leaves.remove(iso);
      });
      pushUpdate();
    } else if (action == 'save') {
      final qty = double.tryParse(qtyCtrl.text) ?? customer.litresPerDay;
      final note = noteCtrl.text.trim();
      setState(() {
        customer.quantityOverrides[iso] = qty;
        if (note.isNotEmpty) {
          customer.leaves[iso] = note;
        } else {
          customer.leaves.remove(iso);
        }
      });
      pushUpdate();
    }
  }

  // Sums the actual litres delivered from day 1 through `uptoDay` of the
  // given month, honouring any per-day overrides (leave or partial).
  Map<String, num> monthTotals(int year, int month, int uptoDay) {
    double litres = 0;
    int adjustedDays = 0;
    for (int d = 1; d <= uptoDay; d++) {
      final iso = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      litres += effectiveMilkQty(iso, customer.quantityOverrides, customer.leaves, customer.litresPerDay);
      if (dayHasOverride(iso)) adjustedDays++;
    }
    return {'litres': litres, 'adjustedDays': adjustedDays};
  }

  Future<void> editRateSettings() async {
    final litresCtrl = TextEditingController(text: customer.litresPerDay.toString());
    final rateCtrl = TextEditingController(text: customer.pricePerLitre.toString());
    final phoneCtrl = TextEditingController(text: customer.phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit Rate / Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: litresCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Litres / day')),
              const SizedBox(height: 10),
              TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '₹ / Litre')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Number')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved == true) {
      setState(() {
        customer.litresPerDay = double.tryParse(litresCtrl.text) ?? customer.litresPerDay;
        customer.pricePerLitre = double.tryParse(rateCtrl.text) ?? customer.pricePerLitre;
        customer.phone = phoneCtrl.text.trim();
      });
      pushUpdate();
    }
  }

  Future<void> shareOnWhatsApp(String rangeLabel, int totalDays, int adjustedDays, double litres, double amount) async {
    final normalDays = totalDays - adjustedDays;
    final message =
        '🥛 Milk Bill - ${DateFormat('MMMM yyyy').format(cursor)}\n'
        'Dear ${customer.name},\n\n'
        'Normal days: $normalDays/$totalDays\n'
        'Rate: ₹${customer.pricePerLitre.toStringAsFixed(2)} / Litre\n'
        'Total Litres: ${litres.toStringAsFixed(1)} L\n'
        'Total Amount: ${fmtRs(amount)}\n\n'
        'Please make the payment at your convenience. Thank you!';

    final ok = await openWhatsApp(customer.phone, message);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp — check the saved phone number.')),
      );
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

  Widget calcCard(String title, String rangeLabel, int totalDays, int adjustedDays, double litres, double amount, {bool isFinal = false}) {
    final normalDays = totalDays - adjustedDays;
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
            statRow('Normal days', '$normalDays'),
            statRow('Adjusted days (leave/partial)', '$adjustedDays'),
            statRow('Total litres', litres.toStringAsFixed(1)),
            statRow('Rate', '₹${customer.pricePerLitre.toStringAsFixed(2)} / litre'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bill Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                ],
              ),
            ),
            if (isFinal) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => shareOnWhatsApp(rangeLabel, totalDays, leaves, litres, amount),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Share on WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        final entry = Entry(
                          id: uuid.v4(),
                          section: 'income',
                          category: 'milksales',
                          date: DateFormat('yyyy-MM-dd').format(lastDay),
                          amount: amount,
                          quantity: litres,
                          rate: customer.pricePerLitre,
                          unitLabel: 'Litre',
                          customLabel: customer.name,
                          notes: '$normalDays/$totalDays normal days, $adjustedDays adjusted ($rangeLabel)',
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        widget.onAddEntry(entry);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment recorded as income')),
                        );
                      },
                      child: const Text('Record Payment'),
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

  String get _linkId => '${widget.vendorUid}_${customer.linkedCustomerUid}';

  Widget buildFlagsBanner() {
    if (customer.linkedCustomerUid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('milk_shared')
          .doc(_linkId)
          .collection('flags')
          .where('resolved', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        return Card(
          color: expenseColor.withOpacity(0.12),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: expenseColor, size: 18),
                    SizedBox(width: 8),
                    Text('Customer flagged an issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                ...docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${data['date'] ?? ''}: ${data['note'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('milk_shared')
                                .doc(_linkId)
                                .collection('flags')
                                .doc(d.id)
                                .update({'resolved': true});
                          },
                          child: const Text('Resolve', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final now = DateTime.now();
    final isCurrentMonth = cursor.year == now.year && cursor.month == now.month;

    final fullMonthTotals = monthTotals(cursor.year, cursor.month, daysInMonth);
    final totalLitres = fullMonthTotals['litres']!.toDouble();
    final adjustedDaysThisMonth = fullMonthTotals['adjustedDays']!.toInt();
    final finalAmount = totalLitres * customer.pricePerLitre;

    final firstDay = DateTime(cursor.year, cursor.month, 1);
    final lastDay = DateTime(cursor.year, cursor.month, daysInMonth);
    final rangeLabel = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(lastDay)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: editRateSettings)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildFlagsBanner(),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Tap any date to mark a leave or edit how much milk this customer got that day.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
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
                      final dayQty = effectiveMilkQty(iso, customer.quantityOverrides, customer.leaves, customer.litresPerDay);
                      final isLeave = dayHasOverride(iso) && dayQty <= 0;
                      final isPartial = dayHasOverride(iso) && dayQty > 0;
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
                      } else if (isPartial) {
                        bg = goldColor.withOpacity(0.6);
                        textColor = Colors.black87;
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
                          child: Center(child: Text('$day', style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentMonth) ...[
            Builder(builder: (_) {
              final todayDay = now.day;
              final soFarTotals = monthTotals(now.year, now.month, todayDay);
              final litresTillToday = soFarTotals['litres']!.toDouble();
              final adjustedDaysTillToday = soFarTotals['adjustedDays']!.toInt();
              final amountTillToday = litresTillToday * customer.pricePerLitre;
              final rangeTillToday = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(now)}';
              return calcCard('Summary So Far', rangeTillToday, todayDay, adjustedDaysTillToday, litresTillToday, amountTillToday);
            }),
          ],
          calcCard('Full Month Bill', rangeLabel, daysInMonth, adjustedDaysThisMonth, totalLitres, finalAmount, isFinal: true),
        ],
      ),
    );
  }
}
