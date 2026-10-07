import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../translations.dart';

/* ============================== REMINDERS SCREEN ============================== */

class RemindersScreen extends StatefulWidget {
  final List<Reminder> reminders;
  final void Function(Reminder) onAdd;
  final void Function(String) onToggle;
  final void Function(String) onDelete;

  const RemindersScreen({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final titleCtrl = TextEditingController();
  String dueDate = todayISO();
  bool recurring = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.reminders];
    sorted.sort((a, b) => (a.done ? 1 : 0).compareTo(b.done ? 1 : 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'You will get a phone notification on the due date at 9:00 AM.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title (e.g. Rent, Milk payment)'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(text: dueDate),
                          decoration: const InputDecoration(labelText: 'Due date'),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(dueDate),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => dueDate = DateFormat('yyyy-MM-dd').format(picked));
                            }
                          },
                        ),
                      ),
                      Checkbox(
                        value: recurring,
                        onChanged: (v) => setState(() => recurring = v ?? false),
                      ),
                      const Text('Monthly'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        widget.onAdd(
                          Reminder(id: uuid.v4(), title: titleCtrl.text.trim(), dueDate: dueDate, recurring: recurring),
                        );
                        titleCtrl.clear();
                      },
                      child: const Text('Add Reminder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No reminders yet.'))
                : ListView(
                    children: sorted.map((r) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(value: r.done, onChanged: (_) => widget.onToggle(r.id)),
                          title: Text(r.title, style: TextStyle(decoration: r.done ? TextDecoration.lineThrough : null)),
                          subtitle: Text('${r.dueDate}${r.recurring ? ' · Monthly' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => widget.onDelete(r.id),
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

/* ============================== EXPORT SCREEN ============================== */

class ExportScreen extends StatefulWidget {
  final List<Entry> entries;
  final List<Reminder> reminders;
  final void Function(List<Entry>, List<Reminder>) onRestore;

  const ExportScreen({
    super.key,
    required this.entries,
    required this.reminders,
    required this.onRestore,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String msg = '';

  Future<void> exportCSV() async {
    final header = ['Date', 'Section', 'Category', 'Vehicle', 'Quantity', 'Unit', 'Odometer', 'Amount', 'Notes'];
    final rows = widget.entries.map((e) {
      return [
        e.date,
        sectionLabels[e.section],
        e.label(),
        e.vehicleType ?? '',
        e.quantity ?? '',
        e.unitLabel ?? '',
        e.odometer ?? '',
        e.amount,
        e.notes.replaceAll('"', '""'),
      ];
    });

    final allRows = [header, ...rows];
    final csv = allRows.map((r) => r.map((v) => '"$v"').join(',')).join('\n');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_${todayISO()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
    setState(() => msg = 'CSV shared.');
  }

  Future<void> exportBackup() async {
    final data = jsonEncode({
      'entries': widget.entries.map((e) => e.toJson()).toList(),
      'reminders': widget.reminders.map((r) => r.toJson()).toList(),
    });

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup_${todayISO()}.json');
    await file.writeAsString(data);
    await Share.shareXFiles([XFile(file.path)]);
    setState(() => msg = 'Backup shared.');
  }

  Future<void> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    try {
      final file = File(result.files.single.path!);
      final data = jsonDecode(await file.readAsString());
      final entries = (data['entries'] as List).map((e) => Entry.fromJson(e)).toList();
      final remindersRaw = data['reminders'] as List? ?? [];
      final reminders = remindersRaw.map((r) => Reminder.fromJson(r)).toList();
      widget.onRestore(entries, reminders);
      setState(() => msg = 'Backup restored successfully.');
    } catch (e) {
      setState(() => msg = 'Invalid backup file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export / Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.table_chart), title: const Text('Share as CSV'), onTap: exportCSV)),
          Card(child: ListTile(leading: const Icon(Icons.backup), title: const Text('Share Full Backup (.json)'), onTap: exportBackup)),
          Card(child: ListTile(leading: const Icon(Icons.restore), title: const Text('Restore from Backup'), onTap: restoreBackup)),
          if (msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: goldColor)),
            ),
          const SizedBox(height: 20),
          Text(
            '${widget.entries.length} entries recorded.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* ============================== SETTINGS SCREEN ============================== */

class SettingsScreen extends StatefulWidget {
  final bool dark;
  final String lang;
  final Map<String, double> budgets;
  final String? pin;
  final String milkMode;
  final void Function({bool? dark, String? pin, bool clearPin, Map<String, double>? budgets, String? language, String? milkMode}) onUpdate;

  const SettingsScreen({
    super.key,
    required this.dark,
    required this.lang,
    required this.budgets,
    required this.pin,
    required this.milkMode,
    required this.onUpdate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, TextEditingController> budgetCtrls;
  final pinCtrl = TextEditingController();
  String msg = '';

  @override
  void initState() {
    super.initState();
    budgetCtrls = {};
    for (final k in ['home', 'personal', 'vehicle']) {
      budgetCtrls[k] = TextEditingController(text: (widget.budgets[k] ?? 0).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(tr('Dark theme', widget.lang)),
            value: widget.dark,
            onChanged: (v) => widget.onUpdate(dark: v),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.language, color: goldColor),
                      SizedBox(width: 10),
                      Text('App Language', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('English'),
                          selected: widget.lang == 'en',
                          onSelected: (_) => widget.onUpdate(language: 'en'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('हिंदी'),
                          selected: widget.lang == 'hi',
                          onSelected: (_) => widget.onUpdate(language: 'hi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Currently, only Navigation, Section and Category names change with the language setting. The rest of the screens are English for now.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_drink, color: goldColor),
                      SizedBox(width: 10),
                      Text('Milk Tracking Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Customer'),
                          selected: widget.milkMode == 'customer',
                          onSelected: (_) => widget.onUpdate(milkMode: 'customer'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Milk Vendor'),
                          selected: widget.milkMode == 'vendor',
                          onSelected: (_) => widget.onUpdate(milkMode: 'vendor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Customer: track your own milk and share the bill with your milkman. Vendor: manage multiple customers, bill them, and record payments.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Monthly Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
          ...['home', 'personal', 'vehicle'].map((k) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: budgetCtrls[k],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: secLabelFor(k, widget.lang)),
              ),
            );
          }),
          ElevatedButton(
            onPressed: () {
              final newBudgets = <String, double>{};
              for (final k in budgetCtrls.keys) {
                newBudgets[k] = double.tryParse(budgetCtrls[k]!.text) ?? 0;
              }
              widget.onUpdate(budgets: newBudgets);
              setState(() => msg = tr('Budgets saved.', widget.lang));
            },
            child: Text(tr('Save Budgets', widget.lang)),
          ),
          const Divider(height: 32),
          Text(tr('PIN Lock', widget.lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.pin != null)
            ElevatedButton(
              onPressed: () {
                widget.onUpdate(clearPin: true);
                setState(() => msg = tr('PIN disabled.', widget.lang));
              },
              style: ElevatedButton.styleFrom(backgroundColor: expenseColor),
              child: Text(tr('Disable PIN', widget.lang)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pinCtrl,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr('4-digit PIN', widget.lang), counterText: ''),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!RegExp(r'^\d{4}$').hasMatch(pinCtrl.text)) {
                      setState(() => msg = tr('PIN must be 4 digits.', widget.lang));
                      return;
                    }
                    widget.onUpdate(pin: pinCtrl.text);
                    setState(() => msg = tr('PIN enabled.', widget.lang));
                  },
                  child: Text(tr('Set', widget.lang)),
                ),
              ],
            ),
          if (msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: goldColor)),
            ),
        ],
      ),
    );
  }
}

/* ============================== ABOUT & FEEDBACK ============================== */

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                logoAsset,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF0CE85), goldDeep]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text(appName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          const Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12.5))),
          const SizedBox(height: 20),
          const Text(
            "$appName is built to help you track your daily expenses, milk accounts, and vehicle petrol/km costing all in one place. Your data is securely synced to the cloud, so you can log in from any device and see your full records.",
            style: TextStyle(height: 1.5, fontSize: 13.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Developed by', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("HOUSE OF D'VISHA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldColor)),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "© ${DateTime.now().year} HOUSE OF D'VISHA. All rights reserved.",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final msgCtrl = TextEditingController();
  String category = 'Suggestion';
  bool sending = false;
  bool sent = false;

  Future<void> submit() async {
    if (msgCtrl.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'message': msgCtrl.text.trim(),
        'category': category,
        'userEmail': user?.email ?? 'unknown',
        'userName': user?.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        sent = true;
        msgCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending feedback, please try again.')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback / Suggestion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Send your suggestion or issue directly to the developer.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['Suggestion', 'Bug Report', 'Feature Request', 'Other'].map((c) {
              return ChoiceChip(
                label: Text(c),
                selected: category == c,
                onSelected: (_) => setState(() => category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: msgCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Write your message',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: sending ? null : submit,
              child: Text(sending ? 'Sending...' : 'Send Feedback'),
            ),
          ),
          if (sent)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'Thank you! Your feedback has been received.',
                style: TextStyle(color: incomeColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
