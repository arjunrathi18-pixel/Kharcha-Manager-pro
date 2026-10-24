import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers.dart';

class MyMilkLinkScreen extends StatefulWidget {
  final Future<String> Function() onEnsureLinkCode;

  const MyMilkLinkScreen({super.key, required this.onEnsureLinkCode});

  @override
  State<MyMilkLinkScreen> createState() => _MyMilkLinkScreenState();
}

class _MyMilkLinkScreenState extends State<MyMilkLinkScreen> {
  String? code;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await widget.onEnsureLinkCode();
    if (mounted) {
      setState(() {
        code = c;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Milk Link')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Link Code', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Share this code with your milkman so their bill for you shows up live right here — no need to wait for a WhatsApp message.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        code ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 4, color: goldColor),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Linked Vendors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Live bills from any vendor who has entered the code above for you.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          if (myUid == null)
            const Text('Sign in to see linked vendors.')
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('milk_shared').where('customerUid', isEqualTo: myUid).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No vendor has linked you yet.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final vendorName = (data['vendorName']?.toString().isNotEmpty ?? false) ? data['vendorName'].toString() : 'Milk Vendor';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_drink, color: goldColor),
                        title: Text(vendorName),
                        subtitle: Text('${data['litresPerDay'] ?? 0} L/day · ₹${data['pricePerLitre'] ?? 0}/L'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LinkedVendorDetailScreen(linkId: d.id, vendorName: vendorName)),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class LinkedVendorDetailScreen extends StatefulWidget {
  final String linkId;
  final String vendorName;

  const LinkedVendorDetailScreen({super.key, required this.linkId, required this.vendorName});

  @override
  State<LinkedVendorDetailScreen> createState() => _LinkedVendorDetailScreenState();
}

class _LinkedVendorDetailScreenState extends State<LinkedVendorDetailScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> flagIssue(String? date) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(date != null ? 'Flag Issue: $date' : 'Flag an Issue'),
          content: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              labelText: 'What looks wrong?',
              hintText: 'e.g. I did not get milk but it is not marked as leave',
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send to Vendor')),
          ],
        );
      },
    );
    if (confirmed == true && noteCtrl.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('milk_shared').doc(widget.linkId).collection('flags').add({
          'date': date ?? todayISO(),
          'note': noteCtrl.text.trim(),
          'resolved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to your vendor')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Milk from ${widget.vendorName}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('milk_shared').doc(widget.linkId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          final litresPerDay = (data['litresPerDay'] as num?)?.toDouble() ?? 0;
          final pricePerLitre = (data['pricePerLitre'] as num?)?.toDouble() ?? 0;

          final leavesRaw = (data['leaves'] as List? ?? []);
          final notes = <String, String>{};
          for (final item in leavesRaw) {
            if (item is Map) {
              final d = item['date']?.toString();
              if (d != null) notes[d] = item['reason']?.toString() ?? '';
            }
          }
          final overridesRaw = (data['quantityOverrides'] as List? ?? []);
          final overrides = <String, double>{};
          for (final item in overridesRaw) {
            if (item is Map) {
              final d = item['date']?.toString();
              final q = item['quantity'];
              if (d != null && q != null) overrides[d] = (q as num).toDouble();
            }
          }

          final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
          final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
          final now = DateTime.now();

          double litres = 0;
          for (int d = 1; d <= daysInMonth; d++) {
            final iso = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
            litres += effectiveMilkQty(iso, overrides, notes, litresPerDay);
          }
          final amount = litres * pricePerLitre;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Read-only — your vendor enters this. Tap a date if something looks wrong.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                        itemCount: startWeekday + daysInMonth,
                        itemBuilder: (_, i) {
                          if (i < startWeekday) return const SizedBox();
                          final day = i - startWeekday + 1;
                          final dateObj = DateTime(cursor.year, cursor.month, day);
                          final iso = DateFormat('yyyy-MM-dd').format(dateObj);
                          final qty = effectiveMilkQty(iso, overrides, notes, litresPerDay);
                          final hasOverride = overrides.containsKey(iso) || notes.containsKey(iso);
                          final isLeave = hasOverride && qty <= 0;
                          final isPartial = hasOverride && qty > 0;
                          final isFuture = dateObj.isAfter(DateTime(now.year, now.month, now.day));

                          Color bg;
                          Color? textColor;
                          if (isFuture) {
                            bg = Colors.grey.withOpacity(0.08);
                            textColor = Colors.grey;
                          } else if (isLeave) {
                            bg = expenseColor.withOpacity(0.85);
                            textColor = Colors.white;
                          } else if (isPartial) {
                            bg = goldColor.withOpacity(0.6);
                            textColor = Colors.black87;
                          } else {
                            bg = incomeColor.withOpacity(0.25);
                            textColor = null;
                          }

                          return InkWell(
                            onTap: isFuture ? null : () => flagIssue(iso),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('$day', style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${DateFormat('MMMM yyyy').format(cursor)} Bill', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Litres'), Text(litres.toStringAsFixed(1))]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rate'), Text('₹${pricePerLitre.toStringAsFixed(2)} / L')]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bill Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => flagIssue(null),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Flag an Issue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
