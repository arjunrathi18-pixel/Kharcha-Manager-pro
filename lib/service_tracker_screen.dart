import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../price_history.dart';
import '../service_logic.dart';

String _fmtDate(String? iso) {
  if (iso == null) return '-';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('d MMM yyyy').format(d);
}

String _kmText(double? km) => km == null ? '-' : '${fmtNum(km.roundToDouble())} km';

class ServiceTrackerScreen extends StatefulWidget {
  final List<Entry> entries;
  final Map<String, ServiceSettings> settings;
  final void Function(String vehicleType, ServiceSettings s) onUpdateSettings;
  final void Function(String vehicleType) onRecordService;

  const ServiceTrackerScreen({
    super.key,
    required this.entries,
    required this.settings,
    required this.onUpdateSettings,
    required this.onRecordService,
  });

  @override
  State<ServiceTrackerScreen> createState() => _ServiceTrackerScreenState();
}

class _ServiceTrackerScreenState extends State<ServiceTrackerScreen> {
  late String vt;

  @override
  void initState() {
    super.initState();
    final used = vehicleTypesInUse(widget.entries);
    vt = used.isNotEmpty ? used.first : 'bike';
  }

  ServiceSettings get _settings => widget.settings[vt] ?? ServiceSettings();

  Color _statusColor(String status) {
    switch (status) {
      case 'overdue':
        return expenseColor;
      case 'soon':
        return goldColor;
      case 'ok':
        return incomeColor;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'overdue':
        return 'Overdue';
      case 'soon':
        return 'Due soon';
      case 'ok':
        return 'On track';
      default:
        return 'Not set up';
    }
  }

  /* ---------- dialogs ---------- */

  Future<void> _editSettings() async {
    final s = _settings;
    final kmCtrl = TextEditingController(text: s.intervalKm.toString());
    final monthsCtrl = TextEditingController(text: s.intervalMonths.toString());
    final warnKmCtrl = TextEditingController(text: s.warnKm.toString());
    final warnDaysCtrl = TextEditingController(text: s.warnDays.toString());
    final lastKmCtrl = TextEditingController(text: s.lastServiceKm == null ? '' : s.lastServiceKm!.round().toString());
    String? lastDate = s.lastServiceDate;
    var remind = s.remind;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setS) {
            return AlertDialog(
              title: Text('${vt == 'car' ? 'Car' : 'Bike'} service settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next service after', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Whichever limit comes first. Set any numbers you like.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: kmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kilometres', suffixText: 'km'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: monthsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Months', suffixText: 'months'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Remind me before', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: warnKmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Distance', suffixText: 'km'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: warnDaysCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Time', suffixText: 'days'),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: remind,
                      onChanged: (v) => setS(() => remind = v),
                      title: const Text('Send reminders', style: TextStyle(fontSize: 13)),
                    ),
                    const Divider(),
                    const Text('Last service (starting point)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Only needed if you have not recorded a service in the app yet. A recorded service always takes over.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(lastDate == null ? 'No date set' : _fmtDate(lastDate), style: const TextStyle(fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: DateTime.tryParse(lastDate ?? '') ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setS(() => lastDate = DateFormat('yyyy-MM-dd').format(picked));
                          },
                          child: const Text('Pick date'),
                        ),
                        if (lastDate != null)
                          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setS(() => lastDate = null)),
                      ],
                    ),
                    TextField(
                      controller: lastKmCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Odometer at that service', suffixText: 'km'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    int toInt(TextEditingController c, int fallback) {
      final v = int.tryParse(c.text.trim());
      return (v == null || v < 0) ? fallback : v;
    }

    final updated = ServiceSettings(
      intervalKm: toInt(kmCtrl, s.intervalKm),
      intervalMonths: toInt(monthsCtrl, s.intervalMonths),
      warnKm: toInt(warnKmCtrl, s.warnKm),
      warnDays: toInt(warnDaysCtrl, s.warnDays),
      remind: remind,
      lastServiceKm: double.tryParse(lastKmCtrl.text.trim()),
      lastServiceDate: lastDate,
      currentKmManual: s.currentKmManual,
      currentKmManualDate: s.currentKmManualDate,
    );
    widget.onUpdateSettings(vt, updated);
    if (mounted) setState(() {});
  }

  Future<void> _updateKm(ServiceInfo info) async {
    final ctrl = TextEditingController(text: info.currentKm == null ? '' : info.currentKm!.round().toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Current odometer'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reading now',
              suffixText: 'km',
              helperText: 'Fuel entries update this automatically too',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        );
      },
    );
    if (ok != true) return;
    final v = double.tryParse(ctrl.text.trim());
    if (v == null) return;
    final s = _settings;
    s.currentKmManual = v;
    s.currentKmManualDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    widget.onUpdateSettings(vt, s);
    if (mounted) setState(() {});
  }

  /* ---------- pieces ---------- */

  Widget _progressRow(String label, double value, String right, Color color) {
    final v = value.isNaN ? 0.0 : (value < 0 ? 0.0 : (value > 1 ? 1.0 : value));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: v, minHeight: 9, color: color, backgroundColor: color.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(ServiceInfo info) {
    final s = _settings;
    final color = _statusColor(info.status);
    final name = vt == 'car' ? 'Car' : 'Bike';

    if (!info.hasBaseline) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.build_circle_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('$name service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'No service recorded yet. Record one, or set when your last service was done and at which kilometre, and the app will remind you for the next one.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onRecordService(vt),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record service'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editSettings,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Set last service'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final kmRight = info.kmLeft == null
        ? 'set the odometer'
        : (info.kmLeft! <= 0 ? '${fmtNum((-info.kmLeft!).roundToDouble())} km over' : '${fmtNum(info.kmLeft!.roundToDouble())} km left');
    final timeRight = info.daysLeft == null
        ? '-'
        : (info.daysLeft! <= 0 ? '${-info.daysLeft!} days overdue' : '${info.daysLeft} days left');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text('$name service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusText(info.status), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Next service due', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              [
                if (info.dueKm != null) 'at ${_kmText(info.dueKm)}',
                if (info.dueDate != null) 'by ${DateFormat('d MMM yyyy').format(info.dueDate!)}',
              ].join('  or  '),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Text('whichever comes first', style: TextStyle(fontSize: 11, color: Colors.grey)),
            if (info.dueKm != null) _progressRow('Distance (every ${fmtNum(s.intervalKm.toDouble())} km)', info.kmProgress, kmRight, info.firstBy == 'km' ? color : Colors.blueGrey),
            if (info.dueDate != null) _progressRow('Time (every ${s.intervalMonths} months)', info.timeProgress, timeRight, info.firstBy == 'date' ? color : Colors.blueGrey),
            const Divider(height: 26),
            _fact('Last service', '${_fmtDate(info.baseDate)}${info.baseDate == null ? '' : '  (${timeAgo(info.baseDate!)})'}'),
            _fact('Odometer then', _kmText(info.baseKm)),
            if (info.lastCost != null) _fact('Cost', fmtRs(info.lastCost!)),
            _fact('Odometer now', _kmText(info.currentKm)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onRecordService(vt),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record service'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => _updateKm(info), child: const Text('Update km')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fact(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 108, child: Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _historyCard(List<Entry> services) {
    if (services.isEmpty) return const SizedBox.shrink();
    final newestFirst = [...services];
    newestFirst.sort((a, b) => b.date.compareTo(a.date));
    var total = 0.0;
    for (final e in newestFirst) {
      total += e.amount;
    }
    final avg = total / newestFirst.length;

    final tiles = <Widget>[];
    for (var i = 0; i < newestFirst.length; i++) {
      final e = newestFirst[i];
      final prev = i + 1 < newestFirst.length ? newestFirst[i + 1] : null;
      final gap = <String>[];
      if (prev != null) {
        final d1 = DateTime.tryParse(e.date);
        final d0 = DateTime.tryParse(prev.date);
        if (d1 != null && d0 != null) {
          final days = d1.difference(d0).inDays;
          gap.add(days >= 60 ? '${(days / 30).round()} months after previous' : '$days days after previous');
        }
        if (e.odometer != null && prev.odometer != null) {
          gap.add('${fmtNum((e.odometer! - prev.odometer!).roundToDouble())} km since previous');
        }
      }
      tiles.add(ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.build_outlined, size: 20),
        title: Text(
          '${_fmtDate(e.date)}${e.odometer == null ? '' : '  •  ${fmtNum(e.odometer!.roundToDouble())} km'}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: gap.isEmpty ? null : Text(gap.join('  •  '), style: const TextStyle(fontSize: 11.5)),
        trailing: Text(fmtRs(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Service history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                Text('${newestFirst.length} services', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Total ${fmtRs(total)}  •  average ${fmtRs(avg)} per service', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 18),
            ...tiles,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = computeServiceInfo(widget.entries, vt, _settings);
    final services = widget.entries
        .where((e) => e.section == 'vehicle' && e.vehicleType == vt && e.category == 'service')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Reminders'),
        actions: [IconButton(icon: const Icon(Icons.tune), tooltip: 'Settings', onPressed: _editSettings)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: ['bike', 'car'].map((v) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(v == 'car' ? Icons.directions_car : Icons.two_wheeler, size: 18),
                  label: Text(v == 'car' ? 'Car' : 'Bike'),
                  selected: vt == v,
                  onSelected: (_) => setState(() => vt = v),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _statusCard(info),
          const SizedBox(height: 4),
          _historyCard(services),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
