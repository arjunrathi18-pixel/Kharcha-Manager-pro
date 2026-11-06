import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../helpers.dart';
import '../translations.dart';
import '../price_history.dart';
import 'history_screen.dart';

final DateFormat _monthWords = DateFormat('MMM MMMM yyyy');

String _unitSuffix(Entry e) {
  final u = (e.unitLabel ?? '').trim();
  return u.isEmpty ? '' : '/$u';
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('d MMM yyyy').format(d);
}

// Type anything - "mustard oil", "gas", "service", "petrol", "milk" - and see
// every matching entry from all months and years, with full details, how the
// price moved over time and the month-wise spend.
class UniversalSearchView extends StatefulWidget {
  final List<Entry> entries;
  final String lang;
  final Widget Function(Entry entry, double? changePct) tileBuilder;

  const UniversalSearchView({
    super.key,
    required this.entries,
    required this.lang,
    required this.tileBuilder,
  });

  @override
  State<UniversalSearchView> createState() => _UniversalSearchViewState();
}

class _UniversalSearchViewState extends State<UniversalSearchView> {
  final TextEditingController _ctrl = TextEditingController();
  String query = '';
  String section = 'all';
  String year = 'all';
  int shown = 60;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _matches(Entry e, List<String> tokens) {
    if (tokens.isEmpty) return true;
    final cat = findCat(e.section, e.vehicleType, e.category);
    final d = DateTime.tryParse(e.date);
    final hay = [
      e.label(),
      e.customLabel,
      e.notes,
      e.category,
      cat?.label ?? '',
      secLabelFor(e.section, 'en'),
      e.vehicleType ?? '',
      e.date,
      d == null ? '' : _monthWords.format(d),
      e.amount.toStringAsFixed(0),
      e.unitLabel ?? '',
    ].join(' ').toLowerCase();
    for (final t in tokens) {
      if (!hay.contains(t)) return false;
    }
    return true;
  }

  void _setQuery(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    setState(() {
      query = q;
      shown = 60;
    });
  }

  String _groupTitle(Entry e) {
    final name = e.customLabel.trim();
    final cat = findCat(e.section, e.vehicleType, e.category);
    final base = cat?.label ?? e.category;
    final veh = e.section == 'vehicle' && e.vehicleType != null ? ' (${e.vehicleType})' : '';
    return name.isEmpty ? '$base$veh' : (name == base ? name : '$name - $base$veh');
  }

  Widget _groupCard(List<Entry> list) {
    final stats = computeStats(list)!;
    final last = stats.last;
    final pct = stats.changePct;
    final title = _groupTitle(last);
    final priceText = stats.lastUnitPrice != null && last.quantity != null
        ? '${fmtRs(stats.lastUnitPrice!)}${_unitSuffix(last)}'
        : fmtRs(last.amount);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistoryScreen(title: title, entries: list)),
          );
        },
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(
          '${stats.count} purchases  •  last ${_fmtDate(last.date)} (${timeAgo(last.date)})  •  total ${fmtRs(stats.totalSpent)}',
          style: const TextStyle(fontSize: 11.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(priceText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: goldColor)),
            if (pct != null) PriceChangeChip(pct: pct),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // years present in the data
    final years = <String>{};
    for (final e in widget.entries) {
      if (e.date.length >= 4) years.add(e.date.substring(0, 4));
    }
    final yearList = years.toList()..sort((a, b) => b.compareTo(a));

    final filtered = widget.entries.where((e) {
      if (section != 'all' && e.section != section) return false;
      if (year != 'all' && !e.date.startsWith(year)) return false;
      return _matches(e, tokens);
    }).toList();
    filtered.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    });

    // group "the same item" together
    final groups = <String, List<Entry>>{};
    for (final e in filtered) {
      groups.putIfAbsent(itemKeyOf(e), () => <Entry>[]).add(e);
    }
    final groupLists = groups.values.toList();
    groupLists.sort((a, b) => b.length.compareTo(a.length));

    // price change of each entry against the previous purchase of the same item
    final changeById = <String, double?>{};
    for (final list in groupLists) {
      final ch = priceChanges(list);
      for (var i = 0; i < list.length; i++) {
        changeById[list[i].id] = ch[i];
      }
    }

    final sectionKeys = ['all', 'home', 'personal', 'vehicle', 'income', 'savings'];
    var total = 0.0;
    for (final e in filtered) {
      total += e.amount;
    }

    final children = <Widget>[
      TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: 'Search anything - mustard oil, gas, service, petrol...',
          border: const OutlineInputBorder(),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close), onPressed: () => _setQuery('')),
        ),
        onChanged: (v) => setState(() {
          query = v;
          shown = 60;
        }),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
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
      if (yearList.length > 1)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['all', ...yearList].map((y) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(y == 'all' ? 'All years' : y),
                  selected: year == y,
                  onSelected: (_) => setState(() => year = y),
                ),
              );
            }).toList(),
          ),
        ),
      const SizedBox(height: 8),
    ];

    if (tokens.isEmpty && section == 'all' && year == 'all') {
      // Nothing typed yet: offer the things bought most often.
      final all = <String, List<Entry>>{};
      for (final e in widget.entries) {
        all.putIfAbsent(itemKeyOf(e), () => <Entry>[]).add(e);
      }
      final top = all.values.toList()..sort((a, b) => b.length.compareTo(a.length));
      children.add(const Padding(
        padding: EdgeInsets.only(top: 6, bottom: 8),
        child: Text('Find the last price, every purchase and how much it got dearer or cheaper.',
            style: TextStyle(color: Colors.grey, fontSize: 12.5)),
      ));
      if (top.isNotEmpty) {
        children.add(const Text('Bought often', style: TextStyle(fontWeight: FontWeight.bold)));
        children.add(const SizedBox(height: 6));
        children.add(Wrap(
          spacing: 8,
          runSpacing: 6,
          children: top.take(14).map((l) {
            final e = l.first;
            final name = e.customLabel.trim().isNotEmpty ? e.customLabel.trim() : (findCat(e.section, e.vehicleType, e.category)?.label ?? e.category);
            return ActionChip(
              label: Text('$name (${l.length})', style: const TextStyle(fontSize: 12)),
              onPressed: () => _setQuery(name),
            );
          }).toList(),
        ));
      }
      return ListView(padding: const EdgeInsets.all(12), children: children);
    }

    // summary
    if (filtered.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No matching entries.', style: TextStyle(color: Colors.grey))),
      ));
      return ListView(padding: const EdgeInsets.all(12), children: children);
    }

    final oldest = filtered.last.date;
    final newest = filtered.first.date;
    children.add(Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${filtered.length} entries', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    oldest == newest ? _fmtDate(newest) : '${_fmtDate(oldest)} to ${_fmtDate(newest)}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: goldColor)),
          ],
        ),
      ),
    ));

    if (groupLists.length == 1) {
      // exactly one item: full price analytics and month-wise spend
      children.add(PriceAnalyticsCard(entries: groupLists.first));
      children.add(MonthTotalsCard(entries: groupLists.first));
    } else {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 4, left: 4),
        child: Text('Matching items - tap one for its full price history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ));
      for (final g in groupLists.take(12)) {
        children.add(_groupCard(g));
      }
      children.add(MonthTotalsCard(entries: filtered));
    }

    children.add(const Padding(
      padding: EdgeInsets.only(top: 14, bottom: 4, left: 4),
      child: Text('All matching entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ));
    for (final e in filtered.take(shown)) {
      children.add(widget.tileBuilder(e, changeById[e.id]));
    }
    if (filtered.length > shown) {
      children.add(Center(
        child: TextButton(
          onPressed: () => setState(() => shown += 60),
          child: Text('Show more (${filtered.length - shown} left)'),
        ),
      ));
    }
    children.add(const SizedBox(height: 20));

    return ListView(padding: const EdgeInsets.all(12), children: children);
  }
}
