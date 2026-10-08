import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../helpers.dart';
import '../translations.dart';

/* ============================== CATEGORY ENTRIES SCREEN ============================== */

class CategoryEntriesScreen extends StatelessWidget {
  final String title;
  final List<Entry> entries;
  final void Function(Entry)? onEdit;

  const CategoryEntriesScreen({super.key, required this.title, required this.entries, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    final total = sorted.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${sorted.length} entries', style: const TextStyle(color: Colors.grey)),
                Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No entries yet.'))
                : ListView(
                    children: sorted.map((e) {
                      return EntryTile(entry: e, onDelete: () {}, onEdit: onEdit == null ? null : () => onEdit!(e));
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

/* ============================== ENTRY TILE (shared) ============================== */

class EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const EntryTile({super.key, required this.entry, required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cat = findCat(entry.section, entry.vehicleType, entry.category);
    final color = isExpenseSection(entry.section)
        ? expenseColor
        : (entry.section == 'income' ? incomeColor : savingsColor);

    String sub = entry.date;
    sub += ' · ${sectionLabels[entry.section]!}';
    if (entry.vehicleType != null) sub += ' · ${entry.vehicleType}';
    if (entry.quantity != null) {
      final unit = entry.unitLabel == 'Litre' ? 'L' : (entry.unitLabel ?? '');
      sub += ' · ${entry.quantity}$unit';
    }
    if (entry.odometer != null) sub += ' · ${fmtNum(entry.odometer)} km';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        child: ListTile(
          leading: Icon(cat?.icon ?? Icons.more_horiz, color: color),
          title: Text(entry.label(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 11.5)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fmtRs(entry.amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== DASHBOARD TAB ============================== */

class DashboardTab extends StatelessWidget {
  final List<Entry> entries;
  final Map<String, double> budgets;
  final List<Reminder> reminders;
  final Map<String, String> milkLeaves;
  final Map<String, double> milkQuantityOverrides;
  final double milkLitresPerDay;
  final double milkPricePerLitre;
  final void Function(Entry) onEditEntry;
  final String lang;

  const DashboardTab({
    super.key,
    required this.entries,
    required this.budgets,
    required this.reminders,
    required this.milkLeaves,
    required this.milkQuantityOverrides,
    required this.milkLitresPerDay,
    required this.milkPricePerLitre,
    required this.onEditEntry,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final today = todayISO();

    double sum(bool Function(Entry) f) {
      return entries.where(f).fold(0.0, (s, e) => s + e.amount);
    }

    final milkRecordedThisMonth = entries.any((e) => e.category == 'milk' && monthKeyOf(e.date) == thisMonth);
    final todayDay = now.day;
    double litresSoFarThisMonth = 0;
    for (int d = 1; d <= todayDay; d++) {
      final iso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      litresSoFarThisMonth += effectiveMilkQty(iso, milkQuantityOverrides, milkLeaves, milkLitresPerDay);
    }
    final litresToday = effectiveMilkQty(today, milkQuantityOverrides, milkLeaves, milkLitresPerDay);
    final milkAccruedToday = milkRecordedThisMonth ? 0.0 : litresToday * milkPricePerLitre;
    final milkAccruedMonth = milkRecordedThisMonth ? 0.0 : litresSoFarThisMonth * milkPricePerLitre;

    final todayExpense = sum((e) => isExpenseSection(e.section) && e.date == today) + milkAccruedToday;
    final monthExpense = sum((e) => isExpenseSection(e.section) && monthKeyOf(e.date) == thisMonth) + milkAccruedMonth;
    final monthIncome = sum((e) => e.section == 'income' && monthKeyOf(e.date) == thisMonth);
    final totalIncome = sum((e) => e.section == 'income');
    final totalExpense = sum((e) => isExpenseSection(e.section)) + milkAccruedMonth;
    final totalSavings = sum((e) => e.section == 'savings');
    final remaining = totalIncome - totalExpense - totalSavings;

    final bySection = {
      'home': sum((e) => e.section == 'home' && monthKeyOf(e.date) == thisMonth) + milkAccruedMonth,
      'personal': sum((e) => e.section == 'personal' && monthKeyOf(e.date) == thisMonth),
      'vehicle': sum((e) => e.section == 'vehicle' && monthKeyOf(e.date) == thisMonth),
    };

    void openSection(String k) {
      final filtered = entries.where((e) => e.section == k).toList();
      if (k == 'home' && !milkRecordedThisMonth) {
        for (int d = 1; d <= todayDay; d++) {
          final iso = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, d));
          final qty = effectiveMilkQty(iso, milkQuantityOverrides, milkLeaves, milkLitresPerDay);
          if (qty > 0) {
            filtered.add(Entry(
              id: 'milk-auto-$iso',
              section: 'home',
              category: 'milk',
              date: iso,
              amount: qty * milkPricePerLitre,
              quantity: qty,
              rate: milkPricePerLitre,
              unitLabel: 'Litre',
              notes: 'Auto (daily milk, not yet recorded)',
              createdAt: 0,
            ));
          }
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryEntriesScreen(title: secLabelFor(k, lang), entries: filtered, onEdit: onEditEntry),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [heroDark2, bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: goldColor.withOpacity(0.18)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('REMAINING BALANCE', lang),
                    style: const TextStyle(color: goldColor, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.bold),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(logoAsset, width: 28, height: 28, errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fmtRs(remaining),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              Container(margin: const EdgeInsets.symmetric(vertical: 16), height: 1, color: Colors.white.withOpacity(0.12)),
              Row(
                children: [
                  Text('${tr('Savings', lang)} ', style: const TextStyle(color: Colors.white70)),
                  Text(fmtRs(totalSavings), style: const TextStyle(color: savingsColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('${tr('Income(M)', lang)} ', style: const TextStyle(color: Colors.white70)),
                  Text(fmtRs(monthIncome), style: const TextStyle(color: incomeColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            statCard(tr('Today', lang), todayExpense, expenseColor),
            statCard(tr('This Month (1 - Aaj)', lang), monthExpense, expenseColor),
            statCard(tr('Income (Month)', lang), monthIncome, incomeColor),
            statCard(tr('Total Savings', lang), totalSavings, savingsColor),
          ],
        ),
        const SizedBox(height: 20),
        Text(tr('This Month by Section', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(tr('(tap to view entries)', lang), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        ...['home', 'personal', 'vehicle'].map((k) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => openSection(k),
              child: ListTile(
                leading: Icon(
                  k == 'home' ? Icons.home : (k == 'personal' ? Icons.person : Icons.directions_car),
                  color: goldColor,
                ),
                title: Text(secLabelFor(k, lang)),
                subtitle: (budgets[k] ?? 0) > 0
                    ? LinearProgressIndicator(
                        value: (bySection[k]! / budgets[k]!).clamp(0, 1),
                        color: bySection[k]! > budgets[k]! ? expenseColor : goldColor,
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fmtRs(bySection[k]!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: expenseColor),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget statCard(String label, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(fmtRs(value), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/* ============================== CALENDAR TAB ============================== */

class CalendarTab extends StatefulWidget {
  final List<Entry> entries;
  final void Function(String) onDelete;
  final void Function(String) onAdd;
  final void Function(Entry) onEdit;
  final String lang;

  const CalendarTab({super.key, required this.entries, required this.onDelete, required this.onAdd, required this.onEdit, required this.lang});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  String selectedDate = todayISO();

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;

    final dayEntries = widget.entries.where((e) => e.date == selectedDate).toList();
    dayEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final iso = DateFormat('yyyy-MM-dd').format(DateTime(cursor.year, cursor.month, day));
              final selected = iso == selectedDate;
              final hasEntries = widget.entries.any((e) => e.date == iso);
              return InkWell(
                onTap: () => setState(() => selectedDate = iso),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? goldColor : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      if (hasEntries)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : expenseColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => widget.onAdd(selectedDate),
                icon: const Icon(Icons.add, size: 16),
                label: Text(tr('Add', widget.lang)),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayEntries.isEmpty
              ? Center(child: Text(tr('No entries for this date.', widget.lang)))
              : ListView(
                  children: dayEntries.map((e) {
                    return EntryTile(entry: e, onDelete: () => widget.onDelete(e.id), onEdit: () => widget.onEdit(e));
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

/* ============================== ANALYTICS TAB ============================== */

class AnalyticsTab extends StatelessWidget {
  final List<Entry> entries;
  final Map<String, double> budgets;

  const AnalyticsTab({super.key, required this.entries, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);

    final catMap = <String, double>{};
    for (final e in entries) {
      if (isExpenseSection(e.section) && monthKeyOf(e.date) == thisMonth) {
        catMap[e.label()] = (catMap[e.label()] ?? 0) + e.amount;
      }
    }
    final catData = catMap.entries.toList();
    catData.sort((a, b) => b.value.compareTo(a.value));
    final top = catData.take(6).toList();

    final fuelLogBike = computeFuelLog(entries, 'bike');
    final fuelLogCar = computeFuelLog(entries, 'car');

    final vehicleMonthsSet = <String>{};
    for (final e in entries) {
      if (e.section == 'vehicle') vehicleMonthsSet.add(monthKeyOf(e.date));
    }
    final vehicleMonths = vehicleMonthsSet.toList()..sort();

    final allComputed = [...fuelLogBike, ...fuelLogCar];
    final monthlyVehicle = vehicleMonths.map((m) {
      double distance = 0;
      for (final f in allComputed) {
        final entry = f['entry'] as Entry;
        if (f['distance'] != null && monthKeyOf(entry.date) == m) {
          distance += f['distance'] as double;
        }
      }
      double fuelCost = 0;
      double totalCost = 0;
      for (final e in entries) {
        if (e.section == 'vehicle' && monthKeyOf(e.date) == m) {
          totalCost += e.amount;
          if (fuelKeys.contains(e.category)) fuelCost += e.amount;
        }
      }
      return {
        'month': m,
        'distance': distance,
        'fuelCost': fuelCost,
        'totalCost': totalCost,
        'fuelPerKm': distance > 0 ? fuelCost / distance : null,
        'overallPerKm': distance > 0 ? totalCost / distance : null,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInsightsCard(),
        const SizedBox(height: 16),
        _buildMonthComparisonCard(),
        const SizedBox(height: 16),
        if (_hasAnyBudget()) ...[
          _buildBudgetStatusCard(),
          const SizedBox(height: 16),
        ],
        _buildTrendChartCard(),
        const SizedBox(height: 16),
        _buildYearlyOverviewCard(),
        const SizedBox(height: 20),
        if (fuelLogBike.isNotEmpty || fuelLogCar.isNotEmpty) ...[
          const Text('Fuel Fill-up Log (₹/km & km/l)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (fuelLogBike.isNotEmpty) fuelTable('Bike', fuelLogBike),
          if (fuelLogCar.isNotEmpty) fuelTable('Car', fuelLogCar),
          const SizedBox(height: 20),
        ],
        if (monthlyVehicle.isNotEmpty) ...[
          const Text('Month-end Vehicle Costing (All Expenses)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...monthlyVehicle.map((m) => monthlyVehicleCard(m)),
          const SizedBox(height: 20),
        ],
        const Text('Category-wise (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (top.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Text('No expenses this month yet.'))
        else
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: List.generate(top.length, (i) {
                  final colors = [expenseColor, savingsColor, incomeColor, goldColor, Colors.purple, Colors.teal];
                  return PieChartSectionData(
                    value: top[i].value,
                    color: colors[i % colors.length],
                    title: top[i].key,
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    final insights = _generateInsights();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, color: goldColor, size: 18),
                SizedBox(width: 8),
                Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            ...insights.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = DateFormat('yyyy-MM').format(lastMonthDate);
    final insights = <String>[];

    final catMap = <String, double>{};
    for (final e in entries) {
      if (isExpenseSection(e.section) && monthKeyOf(e.date) == thisMonth) {
        catMap[e.label()] = (catMap[e.label()] ?? 0) + e.amount;
      }
    }
    if (catMap.isNotEmpty) {
      final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final t = sorted.first;
      insights.add("This month's biggest expense is ${t.key} at ${fmtRs(t.value)}.");
    }

    for (final sec in ['home', 'personal', 'vehicle']) {
      final curr = entries.where((e) => e.section == sec && monthKeyOf(e.date) == thisMonth).fold(0.0, (s, e) => s + e.amount);
      final prev = entries.where((e) => e.section == sec && monthKeyOf(e.date) == lastMonth).fold(0.0, (s, e) => s + e.amount);
      if (prev > 0 && curr > 0) {
        final pctChange = ((curr - prev) / prev) * 100;
        if (pctChange.abs() >= 10) {
          final dir = pctChange > 0 ? 'higher' : 'lower';
          insights.add('${sectionLabels[sec]} is ${pctChange.abs().toStringAsFixed(0)}% $dir than last month.');
        }
      }
    }

    budgets.forEach((sec, limit) {
      if (limit <= 0) return;
      final spent = entries.where((e) => e.section == sec && monthKeyOf(e.date) == thisMonth).fold(0.0, (s, e) => s + e.amount);
      final pct = (spent / limit) * 100;
      if (pct >= 100) {
        insights.add('You have crossed your ${sectionLabels[sec]} budget for this month.');
      } else if (pct >= 80) {
        insights.add('You have used ${pct.toStringAsFixed(0)}% of your ${sectionLabels[sec]} budget this month.');
      }
    });

    final vehicleFuel = [...computeFuelLog(entries, 'bike'), ...computeFuelLog(entries, 'car')]
        .where((f) => f['kmpl'] != null)
        .toList();
    if (vehicleFuel.length >= 2) {
      final latest = vehicleFuel.last['kmpl'] as double;
      final prevAvg = vehicleFuel
              .sublist(0, vehicleFuel.length - 1)
              .map((f) => f['kmpl'] as double)
              .fold(0.0, (a, b) => a + b) /
          (vehicleFuel.length - 1);
      if (prevAvg > 0) {
        final diffPct = ((latest - prevAvg) / prevAvg) * 100;
        if (diffPct.abs() >= 8) {
          final dir = diffPct > 0 ? 'better' : 'worse';
          insights.add('Latest fuel mileage is $dir than your average by ${diffPct.abs().toStringAsFixed(0)}%.');
        }
      }
    }

    if (insights.isEmpty) {
      insights.add('Not enough data yet to generate insights — keep adding entries!');
    }
    return insights;
  }

  Widget _buildMonthComparisonCard() {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = DateFormat('yyyy-MM').format(lastMonthDate);
    final sections = ['home', 'personal', 'vehicle'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month vs Last Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MMMM').format(now)} vs ${DateFormat('MMMM').format(lastMonthDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Divider(height: 22),
            ...sections.map((sec) {
              final curr = entries.where((e) => e.section == sec && monthKeyOf(e.date) == thisMonth).fold(0.0, (s, e) => s + e.amount);
              final prev = entries.where((e) => e.section == sec && monthKeyOf(e.date) == lastMonth).fold(0.0, (s, e) => s + e.amount);
              final pct = prev > 0 ? ((curr - prev) / prev) * 100 : null;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sectionLabels[sec]!, style: const TextStyle(fontSize: 13)),
                    Row(
                      children: [
                        Text(fmtRs(curr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 6),
                        if (pct != null)
                          Row(
                            children: [
                              Icon(
                                pct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 13,
                                color: pct >= 0 ? expenseColor : incomeColor,
                              ),
                              Text(
                                '${pct.abs().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: pct >= 0 ? expenseColor : incomeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
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

  bool _hasAnyBudget() => budgets.values.any((v) => v > 0);

  Widget _buildBudgetStatusCard() {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final sections = ['home', 'personal', 'vehicle'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Budget Status (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...sections.where((sec) => (budgets[sec] ?? 0) > 0).map((sec) {
              final limit = budgets[sec]!;
              final spent = entries.where((e) => e.section == sec && monthKeyOf(e.date) == thisMonth).fold(0.0, (s, e) => s + e.amount);
              final ratio = (spent / limit).clamp(0.0, 1.0);
              Color barColor;
              String? warning;
              if (spent >= limit) {
                barColor = expenseColor;
                warning = 'Budget crossed';
              } else if (spent >= limit * 0.8) {
                barColor = goldColor;
                warning = '${((spent / limit) * 100).toStringAsFixed(0)}% used';
              } else {
                barColor = incomeColor;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sectionLabels[sec]!, style: const TextStyle(fontSize: 13)),
                        Text('${fmtRs(spent)} / ${fmtRs(limit)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        color: barColor,
                        minHeight: 8,
                        backgroundColor: barColor.withOpacity(0.15),
                      ),
                    ),
                    if (warning != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(warning, style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.bold)),
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

  Widget _buildTrendChartCard() {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final expenseSpots = <FlSpot>[];
    final incomeSpots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < months.length; i++) {
      final mk = DateFormat('yyyy-MM').format(months[i]);
      final exp = entries.where((e) => isExpenseSection(e.section) && monthKeyOf(e.date) == mk).fold(0.0, (s, e) => s + e.amount);
      final inc = entries.where((e) => e.section == 'income' && monthKeyOf(e.date) == mk).fold(0.0, (s, e) => s + e.amount);
      expenseSpots.add(FlSpot(i.toDouble(), exp));
      incomeSpots.add(FlSpot(i.toDouble(), inc));
      if (exp > maxY) maxY = exp;
      if (inc > maxY) maxY = inc;
    }
    if (maxY <= 0) maxY = 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('6-Month Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(expenseColor, 'Expense'),
                const SizedBox(width: 16),
                _legendDot(incomeColor, 'Income'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY * 1.2,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(DateFormat('MMM').format(months[idx]), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: expenseColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: incomeColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildYearlyOverviewCard() {
    final year = DateTime.now().year.toString();
    final totalIncome = entries.where((e) => e.section == 'income' && e.date.startsWith(year)).fold(0.0, (s, e) => s + e.amount);
    final totalExpense = entries.where((e) => isExpenseSection(e.section) && e.date.startsWith(year)).fold(0.0, (s, e) => s + e.amount);
    final totalSavings = entries.where((e) => e.section == 'savings' && e.date.startsWith(year)).fold(0.0, (s, e) => s + e.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$year Overview', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 22),
            _yearRow('Total Income', totalIncome, incomeColor),
            _yearRow('Total Expense', totalExpense, expenseColor),
            _yearRow('Total Savings', totalSavings, savingsColor),
          ],
        ),
      ),
    );
  }

  Widget _yearRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(fmtRs(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget monthlyVehicleCard(Map<String, dynamic> m) {
    final month = m['month'] as String;
    final distance = m['distance'] as double;
    final fuelCost = m['fuelCost'] as double;
    final totalCost = m['totalCost'] as double;
    final overallPerKm = m['overallPerKm'] as double?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Distance: ${distance.toStringAsFixed(0)} km'),
            Text('Fuel cost: ${fmtRs(fuelCost)}'),
            Text('Total vehicle cost: ${fmtRs(totalCost)}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall ₹/km (fuel + all expenses)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    overallPerKm != null ? '₹${overallPerKm.toStringAsFixed(2)}' : '—',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fuelTable(String label, List<Map<String, dynamic>> log) {
    final rows = <TableRow>[
      const TableRow(
        children: [
          Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('Odo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('Km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('₹/km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: goldColor)),
          Text('km/l', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: savingsColor)),
        ],
      ),
    ];

    for (final f in log) {
      final e = f['entry'] as Entry;
      final d = f['distance'] as double?;
      final cpk = f['costPerKm'] as double?;
      final kmpl = f['kmpl'] as double?;
      rows.add(
        TableRow(
          children: [
            Text(e.date, style: const TextStyle(fontSize: 11)),
            Text(fmtNum(e.odometer), style: const TextStyle(fontSize: 11)),
            Text(d != null ? d.toStringAsFixed(0) : '—', style: const TextStyle(fontSize: 11)),
            Text(cpk != null ? '₹${cpk.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 11, color: goldColor)),
            Text(kmpl != null ? kmpl.toStringAsFixed(2) : '—', style: const TextStyle(fontSize: 11, color: savingsColor)),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.2),
              },
              children: rows,
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== SEARCH TAB ============================== */

class SearchTab extends StatefulWidget {
  final List<Entry> entries;
  final void Function(String) onDelete;
  final void Function(Entry) onEdit;
  final String lang;

  const SearchTab({super.key, required this.entries, required this.onDelete, required this.onEdit, required this.lang});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String query = '';
  String section = 'all';

  @override
  Widget build(BuildContext context) {
    final results = widget.entries.where((e) {
      if (section != 'all' && e.section != section) return false;
      if (query.isNotEmpty) {
        final hay = '${e.label()} ${e.notes}'.toLowerCase();
        if (!hay.contains(query.toLowerCase())) return false;
      }
      return true;
    }).toList();
    results.sort((a, b) => b.date.compareTo(a.date));

    final total = results.fold(0.0, (s, e) => s + e.amount);
    final sectionKeys = ['all', 'home', 'personal', 'vehicle', 'income', 'savings'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: tr('Search notes or category', widget.lang),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: sectionKeys.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s == 'all' ? tr('All', widget.lang) : secLabelFor(s, widget.lang)),
                  selected: section == s,
                  onSelected: (_) => setState(() => section = s),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${results.length} ${tr('results', widget.lang)}'),
              Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(child: Text(tr('No matching entries.', widget.lang)))
              : ListView(
                  children: results.map((e) {
                    return EntryTile(entry: e, onDelete: () => widget.onDelete(e.id), onEdit: () => widget.onEdit(e));
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

/* ============================== ADD TAB ============================== */

class AddTab extends StatefulWidget {
  final void Function(String, Category, String?, {String? date}) onPick;
  final List<Entry> entries;
  final void Function(Entry) onEditEntry;
  final String lang;
  final void Function(String sectionKey, String key) onRemoveCustomCategory;

  const AddTab({
    super.key,
    required this.onPick,
    required this.entries,
    required this.onEditEntry,
    required this.lang,
    required this.onRemoveCustomCategory,
  });

  @override
  State<AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<AddTab> {
  String section = 'home';
  String vehicleType = 'bike';

  Future<void> _confirmDeleteCustomCategory(Category c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Category?'),
          content: Text('"${c.label}" tile will be removed permanently. Existing entries stay safe — only the tile is removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
          ],
        );
      },
    );
    if (confirm == true) {
      widget.onRemoveCustomCategory(customSectionKey(section, vehicleType), c.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: sectionLabels.keys.map((s) {
                final selected = s == section;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(secLabelFor(s, widget.lang)),
                    selected: selected,
                    onSelected: (_) => setState(() => section = s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (section == 'vehicle')
            Row(
              children: ['bike', 'car'].map((v) {
                final selected = v == vehicleType;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => vehicleType = v),
                      icon: Icon(v == 'bike' ? Icons.motorcycle : Icons.directions_car),
                      label: Text(v[0].toUpperCase() + v.substring(1)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected ? goldColor.withOpacity(0.2) : null,
                        side: BorderSide(color: selected ? goldColor : Colors.grey.shade400),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          if (catsFor(section, vehicleType).any((c) => c.generated))
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Long-press a custom tile to remove it.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: catsFor(section, vehicleType).map((c) {
              final catEntries = widget.entries.where((e) {
                if (e.section != section || e.category != c.key) return false;
                if (section == 'vehicle' && e.vehicleType != vehicleType) return false;
                return true;
              }).toList();

              return Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onPick(section, c, section == 'vehicle' ? vehicleType : null),
                      onLongPress: c.generated ? () => _confirmDeleteCustomCategory(c) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(c.icon, color: goldColor, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              catLabelFor(c, widget.lang),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (catEntries.isNotEmpty)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryEntriesScreen(title: catLabelFor(c, widget.lang), entries: catEntries, onEdit: widget.onEditEntry),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: goldColor, shape: BoxShape.circle),
                          child: Text(
                            '${catEntries.length}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ============================== CATEGORY PICKER SHEET (for calendar "Add") ============================== */

class CategoryPickerSheet extends StatelessWidget {
  final void Function(String, Category, String?) onPick;

  const CategoryPickerSheet({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: AddTabPicker(onPick: onPick),
          ),
        );
      },
    );
  }
}

class AddTabPicker extends StatefulWidget {
  final void Function(String, Category, String?) onPick;

  const AddTabPicker({super.key, required this.onPick});

  @override
  State<AddTabPicker> createState() => _AddTabPickerState();
}

class _AddTabPickerState extends State<AddTabPicker> {
  String section = 'home';
  String vehicleType = 'bike';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: sectionLabels.keys.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(sectionLabels[s]!),
                  selected: s == section,
                  onSelected: (_) => setState(() => section = s),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (section == 'vehicle')
          Row(
            children: ['bike', 'car'].map((v) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => setState(() => vehicleType = v),
                    child: Text(v),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: catsFor(section, vehicleType).map((c) {
            return InkWell(
              onTap: () => widget.onPick(section, c, section == 'vehicle' ? vehicleType : null),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, color: goldColor),
                    const SizedBox(height: 6),
                    Text(
                      c.label,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
