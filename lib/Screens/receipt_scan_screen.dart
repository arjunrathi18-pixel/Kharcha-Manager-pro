import 'dart:io';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../receipt_parser.dart';

const _scanSections = ['home', 'personal', 'vehicle'];
const _scanSectionLabels = {
  'home': 'Home Expenses',
  'personal': 'Personal Expenses',
  'vehicle': 'Vehicle Expenses',
};

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? image;
  bool scanning = false;
  String? error;
  ParsedReceipt? parsed;
  String rawText = '';

  final amountCtrl = TextEditingController();
  final merchantCtrl = TextEditingController();
  String dateISO = todayISO();
  String section = 'home';
  String vehicleType = 'bike';
  String? categoryKey;

  @override
  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 92, maxWidth: 2400);
      if (x == null) return;
      setState(() {
        image = File(x.path);
        scanning = true;
        error = null;
        parsed = null;
      });
      await _scan(x.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          scanning = false;
          error = 'Could not open the image: $e';
        });
      }
    }
  }

  // OCR returns text pieces in blocks; receipts are read row by row, so
  // pieces that sit on the same horizontal line (item name + price, "Total"
  // + amount) are joined back into one row.
  List<String> _rowsFrom(RecognizedText result) {
    final lines = <TextLine>[];
    for (final b in result.blocks) {
      lines.addAll(b.lines);
    }
    if (lines.isEmpty) return [];
    lines.sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    final rows = <List<TextLine>>[];
    for (final l in lines) {
      if (rows.isNotEmpty) {
        final last = rows.last;
        var sum = 0.0;
        for (final e in last) {
          sum += e.boundingBox.center.dy;
        }
        final refCenter = sum / last.length;
        final tol = max(l.boundingBox.height, last.first.boundingBox.height) * 0.6;
        if ((l.boundingBox.center.dy - refCenter).abs() <= tol) {
          last.add(l);
          continue;
        }
      }
      rows.add([l]);
    }

    return rows.map((r) {
      r.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return r.map((e) => e.text).join('  ');
    }).toList();
  }

  Future<void> _scan(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      final rows = _rowsFrom(result);
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() {
          scanning = false;
          error = 'No text found in this photo. Try again with better light and the receipt held flat.';
        });
        return;
      }
      final p = parseReceipt(rows);
      setState(() {
        rawText = rows.join('\n');
        _apply(p);
        scanning = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          scanning = false;
          error = 'Could not read the receipt: $e';
        });
      }
    } finally {
      await recognizer.close();
    }
  }

  void _apply(ParsedReceipt p) {
    parsed = p;
    final a = p.amount;
    amountCtrl.text = a == null ? '' : (a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(2));
    merchantCtrl.text = p.merchant;
    dateISO = p.date != null ? DateFormat('yyyy-MM-dd').format(p.date!) : todayISO();
    section = p.section ?? 'home';
    vehicleType = p.vehicleType ?? 'bike';
    categoryKey = p.categoryKey;
    _fixCategory();
  }

  List<Category> get _cats => catsFor(section, section == 'vehicle' ? vehicleType : null);

  void _fixCategory() {
    if (categoryKey != null && !_cats.any((c) => c.key == categoryKey)) {
      categoryKey = null;
    }
  }

  void _confirm() {
    final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (categoryKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a category')));
      return;
    }
    Navigator.pop(
      context,
      ReceiptResult(
        section: section,
        categoryKey: categoryKey!,
        vehicleType: section == 'vehicle' ? vehicleType : null,
        dateISO: dateISO,
        amount: amt,
        merchant: merchantCtrl.text.trim(),
        quantity: parsed?.categoryKey == categoryKey ? parsed?.quantity : null,
      ),
    );
  }

  Widget _banner() {
    final p = parsed!;
    Color color;
    IconData icon;
    String text;
    if (p.confidence == 2) {
      color = incomeColor;
      icon = Icons.check_circle_outline;
      text = 'Category detected from the receipt'
          '${p.matched.isEmpty ? '' : ' (matched: ${p.matched.take(4).join(', ')})'}';
    } else if (p.confidence == 1) {
      color = goldColor;
      icon = Icons.help_outline;
      text = 'Best guess — please verify the category'
          '${p.matched.isEmpty ? '' : ' (matched: ${p.matched.take(4).join(', ')})'}';
    } else {
      color = expenseColor;
      icon = Icons.info_outline;
      text = 'Could not tell the category from this receipt, so none is pre-selected. Please choose it below.';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _review() {
    final p = parsed!;
    final cats = _cats;
    final dropdownValue = cats.any((c) => c.key == categoryKey) ? categoryKey : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _banner(),
        const SizedBox(height: 16),
        TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Total amount', prefixText: '₹ '),
        ),
        if (!p.amountConfident)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'The total was not clearly found — please check this amount.',
              style: TextStyle(fontSize: 11, color: expenseColor),
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          readOnly: true,
          controller: TextEditingController(text: dateISO),
          decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(dateISO) ?? DateTime.now(),
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => dateISO = DateFormat('yyyy-MM-dd').format(picked));
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: merchantCtrl,
          decoration: const InputDecoration(labelText: 'Shop / merchant'),
        ),
        const SizedBox(height: 16),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _scanSections.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_scanSectionLabels[s]!),
                  selected: section == s,
                  onSelected: (_) => setState(() {
                    section = s;
                    _fixCategory();
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        if (section == 'vehicle') ...[
          const SizedBox(height: 10),
          Row(
            children: ['bike', 'car'].map((v) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      vehicleType = v;
                      _fixCategory();
                    }),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: vehicleType == v ? goldColor.withOpacity(0.2) : null,
                    ),
                    child: Text(v[0].toUpperCase() + v.substring(1)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: dropdownValue,
          hint: const Text('Select category'),
          decoration: const InputDecoration(labelText: 'Category'),
          items: cats.map((c) => DropdownMenuItem(value: c.key, child: Text(c.label))).toList(),
          onChanged: (v) => setState(() => categoryKey = v),
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Show scanned text', style: TextStyle(fontSize: 13)),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(rawText, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to review entry'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: scanning ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanning ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('From Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Reads the receipt on your phone (no internet needed), picks the matching category and fills in the amount and date. You always get to review before anything is saved.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          if (scanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error!, style: const TextStyle(color: expenseColor, fontSize: 13)),
            ),
          if (image != null && !scanning)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image!, height: 170, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          if (parsed != null && !scanning) _review(),
        ],
      ),
    );
  }
}
