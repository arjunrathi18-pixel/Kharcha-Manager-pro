import 'models.dart';

/* ============================== PURCHASE HISTORY LOGIC ============================== */
// Pure functions (no UI) that answer questions like "when did I last buy
// mustard oil, how much did it cost and what was the price per litre?".

// Entries that represent "the same thing" as the one being added: same
// section + category (+ vehicle type) and, when a name is involved (grocery
// items, custom categories), the same name.
List<Entry> historyFor(
  List<Entry> all, {
  required String section,
  required String category,
  String? vehicleType,
  String customLabel = '',
  String? excludeId,
}) {
  final wanted = customLabel.trim().toLowerCase();
  final out = all.where((e) {
    if (e.id == excludeId) return false;
    if (e.section != section || e.category != category) return false;
    if (section == 'vehicle' && vehicleType != null && e.vehicleType != vehicleType) return false;
    if (wanted.isNotEmpty && e.customLabel.trim().toLowerCase() != wanted) return false;
    return true;
  }).toList();
  out.sort((a, b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  });
  return out;
}

// Price per unit of an entry: the stored rate, or amount / quantity when the
// rate was not typed in.
double? unitPrice(Entry e) {
  if (e.rate != null && e.rate! > 0) return e.rate;
  if (e.quantity != null && e.quantity! > 0) return e.amount / e.quantity!;
  return null;
}

class PriceStats {
  final int count;
  final Entry last;
  final Entry? previous;
  final double? lastUnitPrice;
  final double? previousUnitPrice;
  final double? minUnitPrice;
  final double? maxUnitPrice;
  final double? avgUnitPrice;
  final double totalSpent;
  final double avgAmount;
  final Entry? cheapest;
  final Entry? costliest;

  const PriceStats({
    required this.count,
    required this.last,
    required this.previous,
    required this.lastUnitPrice,
    required this.previousUnitPrice,
    required this.minUnitPrice,
    required this.maxUnitPrice,
    required this.avgUnitPrice,
    required this.totalSpent,
    required this.avgAmount,
    required this.cheapest,
    required this.costliest,
  });

  // % change of the latest price against the one before it (unit price when
  // available, otherwise total amount).
  double? get changePct {
    final a = lastUnitPrice ?? last.amount;
    final b = previousUnitPrice ?? previous?.amount;
    if (previous == null || b == null || b <= 0) return null;
    // Only compare like with like: both unit prices, or both plain amounts.
    if ((lastUnitPrice == null) != (previousUnitPrice == null)) {
      return (last.amount - previous!.amount) / previous!.amount * 100;
    }
    return (a - b) / b * 100;
  }

  bool get hasUnitPrices => lastUnitPrice != null;
}

// [entries] must be newest first (as returned by historyFor).
PriceStats? computeStats(List<Entry> entries) {
  if (entries.isEmpty) return null;
  final last = entries.first;
  final previous = entries.length > 1 ? entries[1] : null;

  final unitPrices = <double>[];
  Entry? cheapest;
  Entry? costliest;
  double? minP;
  double? maxP;
  var total = 0.0;
  for (final e in entries) {
    total += e.amount;
    final p = unitPrice(e);
    if (p == null) continue;
    unitPrices.add(p);
    if (minP == null || p < minP) {
      minP = p;
      cheapest = e;
    }
    if (maxP == null || p > maxP) {
      maxP = p;
      costliest = e;
    }
  }
  double? avgP;
  if (unitPrices.isNotEmpty) {
    avgP = unitPrices.reduce((a, b) => a + b) / unitPrices.length;
  }

  return PriceStats(
    count: entries.length,
    last: last,
    previous: previous,
    lastUnitPrice: unitPrice(last),
    previousUnitPrice: previous == null ? null : unitPrice(previous),
    minUnitPrice: minP,
    maxUnitPrice: maxP,
    avgUnitPrice: avgP,
    totalSpent: total,
    avgAmount: total / entries.length,
    cheapest: cheapest,
    costliest: costliest,
  );
}

// "3 days ago", "2 months ago", "1 year ago"
String timeAgo(String isoDate, {DateTime? now}) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return '';
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff <= 0) return 'today';
  if (diff == 1) return 'yesterday';
  if (diff < 31) return '$diff days ago';
  final months = diff ~/ 30;
  if (months < 12) return months == 1 ? '1 month ago' : '$months months ago';
  final years = diff ~/ 365;
  final restMonths = (diff - years * 365) ~/ 30;
  final y = years == 1 ? '1 year' : '$years years';
  return restMonths > 0 ? '$y $restMonths mo ago' : '$y ago';
}

// A stable key that groups entries of "the same item" for search analytics.
String itemKeyOf(Entry e) {
  final name = e.customLabel.trim().toLowerCase();
  final veh = e.section == 'vehicle' ? '|${e.vehicleType ?? ''}' : '';
  return '${e.section}|${e.category}$veh|$name';
}

class MonthTotal {
  final String monthKey; // yyyy-MM
  final double total;
  final int count;
  const MonthTotal(this.monthKey, this.total, this.count);
}

List<MonthTotal> monthTotals(List<Entry> entries) {
  final map = <String, List<double>>{};
  for (final e in entries) {
    if (e.date.length < 7) continue;
    final k = e.date.substring(0, 7);
    map.putIfAbsent(k, () => <double>[0, 0]);
    map[k]![0] += e.amount;
    map[k]![1] += 1;
  }
  final keys = map.keys.toList()..sort();
  return keys.map((k) => MonthTotal(k, map[k]![0], map[k]![1].toInt())).toList();
}
