import 'models.dart';

/* ============================== VEHICLE SERVICE LOGIC ============================== */
// Works out when the next service is due: after [intervalKm] kilometres OR
// [intervalMonths] months since the last service, whichever comes FIRST.
// The kilometres come from the odometer readings typed in with fuel fills
// (and service entries); a manual reading can be added too.

DateTime addMonths(DateTime d, int n) {
  final total = d.month - 1 + n;
  final y = d.year + total ~/ 12;
  final m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > last ? last : d.day);
}

class ServiceInfo {
  final String vehicleType;
  final bool hasBaseline;
  final String? baseDate; // yyyy-MM-dd of the last service
  final double? baseKm; // odometer at the last service
  final double? lastCost;
  final double? currentKm;
  final double? dueKm;
  final DateTime? dueDate;
  final double? kmLeft;
  final int? daysLeft;
  final String status; // nodata | ok | soon | overdue
  final String? firstBy; // km | date  (which limit arrives first)
  final double kmProgress;
  final double timeProgress;

  const ServiceInfo({
    required this.vehicleType,
    required this.hasBaseline,
    required this.baseDate,
    required this.baseKm,
    required this.lastCost,
    required this.currentKm,
    required this.dueKm,
    required this.dueDate,
    required this.kmLeft,
    required this.daysLeft,
    required this.status,
    required this.firstBy,
    required this.kmProgress,
    required this.timeProgress,
  });

  String get vehicleLabel => vehicleType == 'car' ? 'Car' : 'Bike';
}

ServiceInfo computeServiceInfo(List<Entry> entries, String vt, ServiceSettings s, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final t0 = DateTime(now.year, now.month, now.day);

  final veh = entries.where((e) => e.section == 'vehicle' && e.vehicleType == vt).toList();
  final services = veh.where((e) => e.category == 'service').toList();
  services.sort((a, b) => b.date.compareTo(a.date));

  // current kilometres = highest odometer reading seen
  double? currentKm;
  for (final e in veh) {
    final o = e.odometer;
    if (o != null && (currentKm == null || o > currentKm)) currentKm = o;
  }
  final manualKm = s.currentKmManual;
  if (manualKm != null && (currentKm == null || manualKm > currentKm)) currentKm = manualKm;

  // starting point = latest service entry, or the manual "last service" values
  String? baseDate;
  double? baseKm;
  double? lastCost;
  final lastE = services.isEmpty ? null : services.first;
  final manualDate = s.lastServiceDate;
  if (manualDate != null && manualDate.isNotEmpty && (lastE == null || manualDate.compareTo(lastE.date) > 0)) {
    baseDate = manualDate;
    baseKm = s.lastServiceKm;
  } else if (lastE != null) {
    baseDate = lastE.date;
    baseKm = lastE.odometer;
    lastCost = lastE.amount;
    if (baseKm == null) {
      // No odometer typed with the service: use the closest earlier reading (e.g. from fuel).
      String? bestDate;
      double? bestKm;
      for (final e in veh) {
        final o = e.odometer;
        if (o == null || e.date.compareTo(lastE.date) > 0) continue;
        if (bestDate == null ||
            e.date.compareTo(bestDate) > 0 ||
            (e.date == bestDate && bestKm != null && o > bestKm)) {
          bestDate = e.date;
          bestKm = o;
        }
      }
      baseKm = bestKm;
    }
  }

  final hasBaseline = baseDate != null && baseDate.isNotEmpty;
  if (!hasBaseline) {
    return ServiceInfo(
      vehicleType: vt,
      hasBaseline: false,
      baseDate: null,
      baseKm: null,
      lastCost: null,
      currentKm: currentKm,
      dueKm: null,
      dueDate: null,
      kmLeft: null,
      daysLeft: null,
      status: 'nodata',
      firstBy: null,
      kmProgress: 0,
      timeProgress: 0,
    );
  }

  final base = DateTime.tryParse(baseDate);
  DateTime? dueDate;
  int? daysLeft;
  double timeProgress = 0;
  if (base != null && s.intervalMonths > 0) {
    dueDate = addMonths(base, s.intervalMonths);
    daysLeft = dueDate.difference(t0).inDays;
    final total = dueDate.difference(base).inDays;
    if (total > 0) timeProgress = t0.difference(base).inDays / total;
  }

  double? dueKm;
  double? kmLeft;
  double kmProgress = 0;
  if (baseKm != null && s.intervalKm > 0) {
    dueKm = baseKm + s.intervalKm;
    if (currentKm != null) {
      kmLeft = dueKm - currentKm;
      kmProgress = (currentKm - baseKm) / s.intervalKm;
    }
  }

  final overdue = (kmLeft != null && kmLeft <= 0) || (daysLeft != null && daysLeft <= 0);
  final soon = (kmLeft != null && kmLeft <= s.warnKm) || (daysLeft != null && daysLeft <= s.warnDays);
  final status = overdue ? 'overdue' : (soon ? 'soon' : 'ok');

  String? firstBy;
  if (kmLeft != null && daysLeft != null) {
    firstBy = kmProgress >= timeProgress ? 'km' : 'date';
  } else if (kmLeft != null) {
    firstBy = 'km';
  } else if (daysLeft != null) {
    firstBy = 'date';
  }

  return ServiceInfo(
    vehicleType: vt,
    hasBaseline: true,
    baseDate: baseDate,
    baseKm: baseKm,
    lastCost: lastCost,
    currentKm: currentKm,
    dueKm: dueKm,
    dueDate: dueDate,
    kmLeft: kmLeft,
    daysLeft: daysLeft,
    status: status,
    firstBy: firstBy,
    kmProgress: kmProgress,
    timeProgress: timeProgress,
  );
}

// Which vehicle types the user actually has data for.
List<String> vehicleTypesInUse(List<Entry> entries) {
  final out = <String>[];
  for (final vt in ['bike', 'car']) {
    if (entries.any((e) => e.section == 'vehicle' && e.vehicleType == vt)) out.add(vt);
  }
  return out;
}
