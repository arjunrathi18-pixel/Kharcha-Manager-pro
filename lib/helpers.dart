import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

const uuid = Uuid();
const appName = 'Kharcha Manager';
const logoAsset = 'file_00000000b9c871fb9437d3793d64cfdb.png';

String todayISO() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String monthKeyOf(String iso) => iso.length >= 7 ? iso.substring(0, 7) : '';
String fmtRs(num n) => '₹' + NumberFormat('#,##,##0.##', 'en_IN').format(n);
String fmtNum(double? n) => n == null ? '—' : NumberFormat('#,##,##0.##', 'en_IN').format(n);

const goldColor = Color(0xFFE3BE6C);
const goldDeep = Color(0xFFC9962F);
const bgDark = Color(0xFF0A1815);
const cardDark = Color(0xFF132923);
const heroDark2 = Color(0xFF1B4438);
const expenseColor = Color(0xFFE2876A);
const incomeColor = Color(0xFF7FC9A0);
const savingsColor = Color(0xFF7FB8D9);

List<Map<String, dynamic>> computeFuelLog(List<Entry> entries, String vehicleType) {
  final fuel = entries.where((e) {
    return e.section == 'vehicle' &&
        e.vehicleType == vehicleType &&
        fuelKeys.contains(e.category) &&
        e.odometer != null;
  }).toList();

  fuel.sort((a, b) => a.odometer!.compareTo(b.odometer!));

  final result = <Map<String, dynamic>>[];
  for (int i = 0; i < fuel.length; i++) {
    final e = fuel[i];
    if (i == 0) {
      result.add({'entry': e, 'distance': null, 'costPerKm': null, 'kmpl': null});
      continue;
    }
    final prev = fuel[i - 1];
    final distance = e.odometer! - prev.odometer!;
    final costPerKm = distance > 0 ? e.amount / distance : null;
    final kmpl = (distance > 0 && e.quantity != null && e.quantity! > 0) ? distance / e.quantity! : null;
    result.add({'entry': e, 'distance': distance, 'costPerKm': costPerKm, 'kmpl': kmpl});
  }
  return result;
}
