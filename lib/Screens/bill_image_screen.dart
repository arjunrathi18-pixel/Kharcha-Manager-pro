import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../helpers.dart';

// Everything the bill card needs to draw itself.
class MilkBillData {
  final String partyLabel;
  final String partyName;
  final DateTime month;
  final double litresPerDay;
  final double pricePerLitre;
  final Map<String, double> overrides;
  final Map<String, String> notes;

  const MilkBillData({
    required this.partyLabel,
    required this.partyName,
    required this.month,
    required this.litresPerDay,
    required this.pricePerLitre,
    required this.overrides,
    required this.notes,
  });
}

const Color _billBg = Color(0xFF06100E);
const Color _billMuted = Color(0xFF9FB3AC);

String _qtyLabel(double q) => q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(1);

class BillImageScreen extends StatefulWidget {
  final MilkBillData data;
  final String caption;

  const BillImageScreen({super.key, required this.data, required this.caption});

  @override
  State<BillImageScreen> createState() => _BillImageScreenState();
}

class _BillImageScreenState extends State<BillImageScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool sharing = false;

  Future<void> _shareImage() async {
    setState(() => sharing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not create the image');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final monthKey = DateFormat('yyyy_MM').format(widget.data.month);
      final file = File('${dir.path}/milk_bill_$monthKey.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: widget.caption,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share the bill: $e')));
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Image')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: _billBg,
                    padding: const EdgeInsets.all(14),
                    child: _BillCard(data: widget.data),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: sharing ? null : _shareImage,
                      icon: sharing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.share),
                      label: Text(sharing ? 'Preparing...' : 'Share Image'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick WhatsApp in the share sheet, then choose the chat to send it to.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
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

class _BillCard extends StatelessWidget {
  final MilkBillData data;

  const _BillCard({required this.data});

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: _billMuted)),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _billMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = data.month;
    final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
    final startWeekday = DateTime(m.year, m.month, 1).weekday % 7;

    double litres = 0;
    int adjustedDays = 0;
    final adjustments = <String>[];
    final cells = <Widget>[];

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final iso = '${m.year}-${m.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final qty = effectiveMilkQty(iso, data.overrides, data.notes, data.litresPerDay);
      final hasOverride = data.overrides.containsKey(iso) || data.notes.containsKey(iso);
      litres += qty;

      Color bg;
      Color fg;
      String? sub;
      if (hasOverride && qty <= 0) {
        bg = expenseColor.withOpacity(0.9);
        fg = Colors.white;
        sub = '0';
      } else if (hasOverride) {
        bg = goldColor.withOpacity(0.9);
        fg = Colors.black87;
        sub = _qtyLabel(qty);
      } else {
        bg = incomeColor.withOpacity(0.22);
        fg = Colors.white;
        sub = null;
      }

      if (hasOverride) {
        adjustedDays++;
        final note = data.notes[iso] ?? '';
        final dayText = DateFormat('d MMM').format(DateTime(m.year, m.month, d));
        final what = qty <= 0 ? 'No milk' : '${_qtyLabel(qty)} L';
        adjustments.add(note.isEmpty ? '$dayText  -  $what' : '$dayText  -  $what  ($note)');
      }

      cells.add(
        Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$d', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
                if (sub != null) Text(sub, style: TextStyle(fontSize: 8, color: fg)),
              ],
            ),
          ),
        ),
      );
    }

    final amount = litres * data.pricePerLitre;
    final normalDays = daysInMonth - adjustedDays;
    final shownAdjustments = adjustments.take(8).toList();
    final extra = adjustments.length - shownAdjustments.length;
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [heroDark2, bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF0CE85), goldDeep]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_drink, color: Colors.black87, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MILK BILL',
                            style: TextStyle(color: goldColor, fontSize: 11.5, letterSpacing: 1.6, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMMM yyyy').format(m),
                            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${data.partyLabel}: ${data.partyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: weekdays
                      .map((w) => Expanded(
                            child: Center(
                              child: Text(w, style: const TextStyle(fontSize: 10, color: _billMuted, fontWeight: FontWeight.bold)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: cells,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _legend(incomeColor.withOpacity(0.5), 'Normal'),
                    _legend(goldColor, 'Different qty'),
                    _legend(expenseColor, 'No milk'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white12),
                const SizedBox(height: 8),
                _line('Rate', '₹${data.pricePerLitre.toStringAsFixed(2)} / litre'),
                _line('Normal day', '${_qtyLabel(data.litresPerDay)} L'),
                _line('Normal days', '$normalDays'),
                _line('Adjusted days', '$adjustedDays'),
                _line('Total milk', '${litres.toStringAsFixed(1)} L'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [goldColor.withOpacity(0.28), goldColor.withOpacity(0.12)]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: goldColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(color: goldColor, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fmtRs(amount),
                        style: const TextStyle(color: goldColor, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (shownAdjustments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Adjustments', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...shownAdjustments.map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(a, style: const TextStyle(fontSize: 11, color: _billMuted)),
                    ),
                  ),
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('+ $extra more', style: const TextStyle(fontSize: 11, color: _billMuted)),
                    ),
                ],
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Made with Kharcha Manager',
                    style: TextStyle(fontSize: 10, color: _billMuted, letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
