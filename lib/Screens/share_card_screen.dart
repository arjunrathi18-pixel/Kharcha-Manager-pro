import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../helpers.dart';
import '../muhurat.dart';
import '../panchang.dart';

const Color _cardBg = Color(0xFF06100E);
const Color _muted = Color(0xFF9FB3AC);

/* ============================== GENERIC "SHARE AS IMAGE" SCREEN ============================== */

class ShareCardScreen extends StatefulWidget {
  final String title;
  final Widget card;
  final String caption;
  final String fileName;

  const ShareCardScreen({
    super.key,
    required this.title,
    required this.card,
    required this.caption,
    required this.fileName,
  });

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool sharing = false;

  Future<void> _share() async {
    setState(() => sharing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('Could not create the image');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: widget.caption);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(color: _cardBg, padding: const EdgeInsets.all(14), child: widget.card),
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
                      onPressed: sharing ? null : _share,
                      icon: sharing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.share),
                      label: Text(sharing ? 'Preparing...' : 'Share Image'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick WhatsApp in the share sheet, then choose the chat.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
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

/* ============================== SHARED CARD PIECES ============================== */

Widget _cardShell({required Widget header, required List<Widget> body}) {
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
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
        ),
      ],
    ),
  );
}

Widget _cardHeader({required IconData icon, required String kicker, required String title, required String subtitle}) {
  return Container(
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
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kicker, style: const TextStyle(color: goldColor, fontSize: 11.5, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35)),
      ],
    ),
  );
}

Widget _row(String k, String v, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 108, child: Text(k, style: const TextStyle(fontSize: 12.5, color: _muted))),
        Expanded(child: Text(v, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white))),
      ],
    ),
  );
}

Widget _footer(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Center(child: Text(text, style: const TextStyle(fontSize: 10, color: _muted, letterSpacing: 0.4))),
  );
}

/* ============================== PANCHANG DAY CARD ============================== */

class PanchangDayCard extends StatelessWidget {
  final DateTime date;
  final City city;
  final bool purnimanta;
  final String lang;

  const PanchangDayCard({super.key, required this.date, required this.city, required this.purnimanta, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = Panchang.day(date);
    final m = muhuratFor(date, city);
    final hi = lang == 'hi';

    final subtitle = p == null
        ? city.name
        : '${Panchang.hinduDateLine(p, purnimanta, lang)}  •  ${hi ? 'विक्रम संवत' : 'Vikram Samvat'} ${Panchang.vikramSamvat(p)}';

    final body = <Widget>[];
    if (p != null) {
      final next = p.tithi % 30 + 1;
      body.add(_row(hi ? 'तिथि' : 'Tithi', '${Panchang.tithiLabel(p.tithi, lang)}\n${hi ? 'तक' : 'until'} ${Panchang.formatMinutes(p.tithiEnd, lang)}, ${hi ? 'फिर' : 'then'} ${Panchang.tithiLabel(next, lang)}'));
      body.add(_row(hi ? 'नक्षत्र' : 'Nakshatra', '${Panchang.nakshatraName(p.nakshatra, lang)}\n${hi ? 'तक' : 'until'} ${Panchang.formatMinutes(p.nakEnd, lang)}'));
    }
    if (m != null) {
      body.add(const SizedBox(height: 4));
      body.add(Container(height: 1, color: Colors.white12));
      body.add(const SizedBox(height: 4));
      body.add(_row(hi ? 'सूर्योदय' : 'Sunrise', clockText(m.sunrise)));
      body.add(_row(hi ? 'सूर्यास्त' : 'Sunset', clockText(m.sunset)));
      body.add(_row(hi ? 'राहु काल' : 'Rahu Kaal', rangeText(m.rahu), valueColor: const Color(0xFFFF8A80)));
      body.add(_row(hi ? 'यमगंड' : 'Yamaganda', rangeText(m.yamaganda), valueColor: const Color(0xFFFF8A80)));
      body.add(_row(hi ? 'गुलिक काल' : 'Gulika Kaal', rangeText(m.gulika), valueColor: const Color(0xFFFF8A80)));
      body.add(_row(
        hi ? 'अभिजित मुहूर्त' : 'Abhijit Muhurat',
        m.abhijit == null ? (hi ? 'बुधवार को नहीं' : 'Not on Wednesdays') : rangeText(m.abhijit!),
        valueColor: m.abhijit == null ? _muted : const Color(0xFF7CE0A8),
      ));
      body.add(_row(hi ? 'ब्रह्म मुहूर्त' : 'Brahma Muhurat', rangeText(m.brahma), valueColor: const Color(0xFF7CE0A8)));
    }
    if (p != null && p.events.isNotEmpty) {
      body.add(const SizedBox(height: 6));
      body.add(Container(height: 1, color: Colors.white12));
      body.add(const SizedBox(height: 8));
      body.add(Wrap(
        spacing: 6,
        runSpacing: 6,
        children: p.events.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: goldColor.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
            child: Text(Panchang.eventName(c, p, lang), style: const TextStyle(fontSize: 11.5, color: goldColor, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ));
    }
    body.add(_footer('Made with Kharcha Manager  •  ${city.name}'));

    return _cardShell(
      header: _cardHeader(
        icon: Icons.calendar_month,
        kicker: hi ? 'पंचांग' : 'PANCHANG',
        title: DateFormat('EEEE, d MMMM yyyy').format(date),
        subtitle: subtitle,
      ),
      body: body,
    );
  }
}

/* ============================== PLAN CARD ============================== */

class PlanCard extends StatelessWidget {
  final String occasion;
  final DateTime date;
  final String hinduLine;
  final List<PlanItem> items;

  const PlanCard({super.key, required this.occasion, required this.date, required this.hinduLine, required this.items});

  @override
  Widget build(BuildContext context) {
    var total = 0.0;
    for (final i in items) {
      if (!i.done) total += i.amount;
    }

    final body = <Widget>[];
    if (items.isEmpty) {
      body.add(const Text('Nothing planned yet.', style: TextStyle(color: _muted, fontSize: 12.5)));
    }
    for (final i in items) {
      body.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(i.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 17, color: i.done ? const Color(0xFF7CE0A8) : _muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                i.title,
                style: TextStyle(
                  fontSize: 13,
                  color: i.done ? _muted : Colors.white,
                  decoration: i.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (i.amount > 0) Text(fmtRs(i.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ));
    }
    if (total > 0) {
      body.add(const SizedBox(height: 10));
      body.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [goldColor.withOpacity(0.28), goldColor.withOpacity(0.12)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: goldColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PLANNED TOTAL', style: TextStyle(color: goldColor, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            Text(fmtRs(total), style: const TextStyle(color: goldColor, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ));
    }
    body.add(_footer('Made with Kharcha Manager'));

    return _cardShell(
      header: _cardHeader(
        icon: Icons.event_note,
        kicker: 'EXPENSE PLAN',
        title: occasion,
        subtitle: '${DateFormat('EEEE, d MMMM yyyy').format(date)}${hinduLine.isEmpty ? '' : '\n$hinduLine'}',
      ),
      body: body,
    );
  }
}
