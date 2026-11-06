import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../price_history.dart';

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('d MMM yyyy').format(d);
}

String _monthLabel(String key) {
  final d = DateTime.tryParse('$key-01');
  return d == null ? key : DateFormat('MMM yyyy').format(d);
}

String _qtyText(Entry e) {
  if (e.quantity == null || e.quantity! <= 0) return '';
  final u = (e.unitLabel ?? '').trim();
  return '${fmtNum(e.quantity)}${u.isEmpty ? '' : ' $u'}';
}

String _unitSuffix(Entry e) {
  final u = (e.unitLabel ?? '').trim();
  return u.isEmpty ? '' : '/$u';
}

/* ============================== PRICE CHANGE CHIP ============================== */

class PriceChangeChip extends StatelessWidget {
  final double pct;
  const PriceChangeChip({super.key, required this.pct});

  @override
  Widget build(BuildContext context) {
    final up = pct > 0;
    final flat = pct.abs() < 0.5;
    final color = flat ? Colors.grey : (up ? expenseColor : incomeColor);
    final icon = flat ? Icons.remove : (up ? Icons.arrow_upward : Icons.arrow_downward);
    final word = flat ? 'same' : (up ? 'costlier' : 'cheaper');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            flat ? word : '${pct.abs().toStringAsFixed(0)}% $word',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/* ============================== "LAST PURCHASE" CARD ============================== */
// Shown while adding an entry: when this was bought last, for how much, how
// much quantity and the price per unit - plus whether it got dearer or cheaper.

class LastPurchaseCard extends StatelessWidget {
  final List<Entry> history; // newest first
  final VoidCallback onOpenHistory;
  final String title;

  const LastPurchaseCard({
    super.key,
    required this.history,
    required this.onOpenHistory,
    this.title = 'Last purchase',
  });

  @override
  Widget build(BuildContext context) {
    final stats = computeStats(history);
    if (stats == null) return const SizedBox.shrink();
    final last = stats.last;
    final prev = stats.previous;

    final parts = <String>[fmtRs(last.amount)];
    final q = _qtyText(last);
    if (q.isNotEmpty) parts.add(q);
    final up = stats.lastUnitPrice;
    if (up != null && q.isNotEmpty) parts.add('${fmtRs(up)}${_unitSuffix(last)}');
    if (last.odometer != null) parts.add('at ${fmtNum(last.odometer)} km');

    final pct = stats.changePct;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldColor.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 16, color: goldColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: goldColor)),
              ),
              TextButton(
                onPressed: onOpenHistory,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 30)),
                child: Text('History (${stats.count})', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Text(
            '${_fmtDate(last.date)}  (${timeAgo(last.date)})',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(parts.join('  •  '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
              if (pct != null) PriceChangeChip(pct: pct),
              const SizedBox(width: 6),
            ],
          ),
          if (prev != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: Text(
                'Before that: ${fmtRs(prev.amount)}'
                '${_qtyText(prev).isEmpty ? '' : '  •  ${_qtyText(prev)}'}'
                '${stats.previousUnitPrice == null || _qtyText(prev).isEmpty ? '' : '  •  ${fmtRs(stats.previousUnitPrice!)}${_unitSuffix(prev)}'}'
                '  on ${_fmtDate(prev.date)}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/* ============================== TREND CHART ============================== */

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;
  _TrendPainter(this.values, this.color, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV - minV < 0.0001) {
      maxV += 1;
      minV -= 1;
    }
    final pad = (maxV - minV) * 0.12;
    minV -= pad;
    maxV += pad;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path();
    final dots = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minV) / (maxV - minV) * size.height;
      dots.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    final dotPaint = Paint()..color = color;
    for (final o in dots) {
      canvas.drawCircle(o, 3.2, dotPaint);
    }
    canvas.drawCircle(dots.last, 5, Paint()..color = color.withOpacity(0.35));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values || old.color != color;
}

class PriceTrendChart extends StatelessWidget {
  final List<double> values; // oldest -> newest
  const PriceTrendChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final shown = values.length > 40 ? values.sublist(values.length - 40) : values;
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(painter: _TrendPainter(shown, goldColor, Colors.grey.withOpacity(0.18))),
    );
  }
}

/* ============================== ANALYTICS CARD ============================== */

class PriceAnalyticsCard extends StatelessWidget {
  final List<Entry> entries; // newest first
  const PriceAnalyticsCard({super.key, required this.entries});

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = computeStats(entries);
    if (stats == null) return const SizedBox.shrink();

    final sample = stats.last;
    final unit = _unitSuffix(sample);
    final trendValues = <double>[];
    for (final e in entries.reversed) {
      final p = unitPrice(e);
      trendValues.add(p ?? e.amount);
    }
    final pct = stats.changePct;
    final hasUnit = stats.hasUnitPrices;

    // Compare the latest price with the average of earlier ones.
    String? vsAvg;
    Color vsAvgColor = Colors.grey;
    if (hasUnit && stats.avgUnitPrice != null && stats.count > 1) {
      final lastP = stats.lastUnitPrice!;
      final diff = (lastP - stats.avgUnitPrice!) / stats.avgUnitPrice! * 100;
      if (diff.abs() >= 1) {
        vsAvg = diff > 0
            ? 'Latest price is ${diff.toStringAsFixed(0)}% above your average'
            : 'Latest price is ${diff.abs().toStringAsFixed(0)}% below your average';
        vsAvgColor = diff > 0 ? expenseColor : incomeColor;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, size: 18, color: goldColor),
                const SizedBox(width: 6),
                const Expanded(child: Text('Price analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                if (pct != null) PriceChangeChip(pct: pct),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat('Purchases', '${stats.count}'),
                _stat('Total spent', fmtRs(stats.totalSpent)),
                _stat('Avg per purchase', fmtRs(stats.avgAmount)),
              ],
            ),
            if (hasUnit) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat('Latest price', '${fmtRs(stats.lastUnitPrice!)}$unit', color: goldColor),
                  _stat('Lowest', '${fmtRs(stats.minUnitPrice!)}$unit', color: incomeColor),
                  _stat('Highest', '${fmtRs(stats.maxUnitPrice!)}$unit', color: expenseColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat('Average price', '${fmtRs(stats.avgUnitPrice!)}$unit'),
                  _stat('Cheapest on', stats.cheapest == null ? '-' : _fmtDate(stats.cheapest!.date)),
                  _stat('Costliest on', stats.costliest == null ? '-' : _fmtDate(stats.costliest!.date)),
                ],
              ),
            ],
            if (vsAvg != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(vsAvg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vsAvgColor)),
              ),
            if (trendValues.length >= 2) ...[
              const SizedBox(height: 12),
              Text(hasUnit ? 'Price per unit over time' : 'Amount over time', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 6),
              PriceTrendChart(values: trendValues),
            ],
          ],
        ),
      ),
    );
  }
}

/* ============================== MONTH-WISE TOTALS ============================== */

class MonthTotalsCard extends StatelessWidget {
  final List<Entry> entries;
  final int maxMonths;
  const MonthTotalsCard({super.key, required this.entries, this.maxMonths = 12});

  @override
  Widget build(BuildContext context) {
    final all = monthTotals(entries);
    if (all.isEmpty) return const SizedBox.shrink();
    final shown = all.length > maxMonths ? all.sublist(all.length - maxMonths) : all;
    var maxV = 0.0;
    for (final m in shown) {
      if (m.total > maxV) maxV = m.total;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Month-wise spend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            ...shown.reversed.map((m) {
              final ratio = maxV <= 0 ? 0.0 : m.total / maxV;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(_monthLabel(m.monthKey), style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          color: goldColor,
                          backgroundColor: goldColor.withOpacity(0.12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 86,
                      child: Text(
                        '${fmtRs(m.total)} (${m.count})',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/* ============================== ENTRY TILE WITH PRICE DELTA ============================== */

class HistoryEntryTile extends StatelessWidget {
  final Entry entry;
  final double? changePct; // vs the previous purchase of the same item
  final VoidCallback? onTap;
  final bool showLabel;

  const HistoryEntryTile({super.key, required this.entry, this.changePct, this.onTap, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final details = <String>[];
    final q = _qtyText(e);
    if (q.isNotEmpty) details.add(q);
    final up = unitPrice(e);
    if (up != null && q.isNotEmpty) details.add('${fmtRs(up)}${_unitSuffix(e)}');
    if (e.odometer != null) details.add('${fmtNum(e.odometer)} km');
    if (e.notes.trim().isNotEmpty) details.add(e.notes.trim());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: onTap,
        dense: true,
        title: Text(
          showLabel ? e.label() : _fmtDate(e.date),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        subtitle: Text(
          [if (showLabel) _fmtDate(e.date), ...details].join('  •  '),
          style: const TextStyle(fontSize: 11.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmtRs(e.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (changePct != null) PriceChangeChip(pct: changePct!),
          ],
        ),
      ),
    );
  }
}

// % change of each purchase against the one before it (entries newest first).
List<double?> priceChanges(List<Entry> newestFirst) {
  final out = <double?>[];
  for (var i = 0; i < newestFirst.length; i++) {
    if (i + 1 >= newestFirst.length) {
      out.add(null);
      continue;
    }
    final a = newestFirst[i];
    final b = newestFirst[i + 1];
    final ua = unitPrice(a);
    final ub = unitPrice(b);
    double? pct;
    if (ua != null && ub != null && ub > 0) {
      pct = (ua - ub) / ub * 100;
    } else if (ua == null && ub == null && b.amount > 0) {
      pct = (a.amount - b.amount) / b.amount * 100;
    }
    out.add(pct);
  }
  return out;
}

/* ============================== FULL HISTORY SCREEN ============================== */

class HistoryScreen extends StatelessWidget {
  final String title;
  final List<Entry> entries; // newest first
  final void Function(Entry)? onEdit;

  const HistoryScreen({super.key, required this.title, required this.entries, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final changes = priceChanges(entries);
    final widgets = <Widget>[];

    String? currentYear;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final year = e.date.length >= 4 ? e.date.substring(0, 4) : '';
      if (year != currentYear) {
        currentYear = year;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4, left: 4),
          child: Text(year, style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 13)),
        ));
      }
      widgets.add(HistoryEntryTile(
        entry: e,
        changePct: changes[i],
        onTap: onEdit == null ? null : () => onEdit!(e),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: entries.isEmpty
          ? const Center(child: Text('No past entries yet.', style: TextStyle(color: Colors.grey)))
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                PriceAnalyticsCard(entries: entries),
                const SizedBox(height: 8),
                MonthTotalsCard(entries: entries),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 8),
                  child: Text('All purchases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                ...widgets,
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
