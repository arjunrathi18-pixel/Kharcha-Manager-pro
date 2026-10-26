import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models.dart';
import '../helpers.dart';

// The default PDF fonts don't reliably render the ₹ glyph, so the report
// uses "Rs." instead — only inside the generated PDF, not in the app's UI.
String _fmtRsPdf(num n) => 'Rs. ' + NumberFormat('#,##,##0.##', 'en_IN').format(n);

class MonthlyReportScreen extends StatefulWidget {
  final List<Entry> entries;
  final Map<String, double> budgets;

  const MonthlyReportScreen({super.key, required this.entries, required this.budgets});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  bool generating = false;

  pw.TableRow _row(String label, String value, {bool isHeader = false}) {
    final style = isHeader
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
        : const pw.TextStyle(fontSize: 11);
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value, style: style)),
      ],
    );
  }

  Future<void> generateAndShare() async {
    setState(() => generating = true);
    try {
      final monthKey = DateFormat('yyyy-MM').format(cursor);
      final monthLabel = DateFormat('MMMM yyyy').format(cursor);
      final monthEntries = widget.entries.where((e) => monthKeyOf(e.date) == monthKey).toList();

      double sum(bool Function(Entry) f) => monthEntries.where(f).fold(0.0, (s, e) => s + e.amount);

      final totalIncome = sum((e) => e.section == 'income');
      final totalExpense = sum((e) => isExpenseSection(e.section));
      final totalSavings = sum((e) => e.section == 'savings');
      final net = totalIncome - totalExpense - totalSavings;

      final sectionTotals = {
        'home': sum((e) => e.section == 'home'),
        'personal': sum((e) => e.section == 'personal'),
        'vehicle': sum((e) => e.section == 'vehicle'),
      };

      final catMap = <String, double>{};
      for (final e in monthEntries) {
        if (isExpenseSection(e.section)) {
          catMap[e.label()] = (catMap[e.label()] ?? 0) + e.amount;
        }
      }
      final catList = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(appName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Monthly Report - $monthLabel', style: const pw.TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
                children: [
                  _row('Total Income', _fmtRsPdf(totalIncome)),
                  _row('Total Expense', _fmtRsPdf(totalExpense)),
                  _row('Total Savings', _fmtRsPdf(totalSavings)),
                  _row('Net (Income - Expense - Savings)', _fmtRsPdf(net)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Section-wise Expenses', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
                children: [
                  _row('Home Expenses', _fmtRsPdf(sectionTotals['home']!)),
                  _row('Personal Expenses', _fmtRsPdf(sectionTotals['personal']!)),
                  _row('Vehicle Expenses', _fmtRsPdf(sectionTotals['vehicle']!)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Category-wise Expenses', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (catList.isEmpty)
                pw.Text('No expenses recorded this month.', style: const pw.TextStyle(fontSize: 11))
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
                  children: [
                    _row('Category', 'Amount', isHeader: true),
                    ...catList.map((c) => _row(c.key, _fmtRsPdf(c.value))),
                  ],
                ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.Text(
                "Generated by $appName - HOUSE OF D'VISHA",
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kharcha_report_$monthKey.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: '$appName Report - $monthLabel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1))),
                      Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Generates a formatted PDF with income/expense/savings totals, section-wise and category-wise breakdowns for the selected month — ready to share.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: generating ? null : generateAndShare,
                      icon: generating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(generating ? 'Generating...' : 'Generate & Share PDF'),
                    ),
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
