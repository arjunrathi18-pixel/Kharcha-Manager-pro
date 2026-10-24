import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
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

// Keeps only digits, then assumes a bare 10-digit number is an Indian mobile
// number missing its country code and prefixes it with 91 (wa.me needs the
// full international number with no +, spaces or leading zero).
String sanitizePhoneForWhatsApp(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) digits = '91$digits';
  if (digits.startsWith('0') && digits.length == 11) digits = '91${digits.substring(1)}';
  return digits;
}

// Opens a WhatsApp chat with `phone` pre-filled with `message`. Returns false
// (without throwing) if there's no phone number or the link couldn't launch,
// so callers can show a friendly error instead of crashing.
Future<bool> openWhatsApp(String phone, String message) async {
  final clean = sanitizePhoneForWhatsApp(phone);
  if (clean.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

// The litres actually delivered on `date`: an explicit override wins (0 =
// full leave, any other value = a partial/extra day); otherwise an old-style
// leave note (from before quantity-editing existed) means 0; otherwise it's
// a normal day at the default rate.
double effectiveMilkQty(
  String date,
  Map<String, double> overrides,
  Map<String, String> notes,
  double defaultQty,
) {
  if (overrides.containsKey(date)) return overrides[date]!;
  if (notes.containsKey(date)) return 0.0;
  return defaultQty;
}

const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion when read aloud

String generateMilkLinkCode() {
  final rand = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 6; i++) {
    buffer.write(_codeChars[rand.nextInt(_codeChars.length)]);
  }
  return buffer.toString();
}

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
