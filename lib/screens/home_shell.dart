import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../helpers.dart';
import '../translations.dart';
import 'utility_screens.dart';
import 'grocery_screens.dart';
import 'entry_sheet.dart';
import 'tabs.dart';
import 'settings_and_more.dart';

class HomeShell extends StatefulWidget {
  final String userEmail;
  final String userName;
  final List<Entry> entries;
  final List<Reminder> reminders;
  final Map<String, double> budgets;
  final bool dark;
  final String lang;
  final String? pin;
  final Map<String, String> milkLeaves;
  final double milkLitresPerDay;
  final double milkPricePerLitre;
  final double? electricityLastReading;
  final double electricityRatePerUnit;
  final String? gasLastCylinderDate;
  final double gasCylinderKg;
  final Map<String, String> waterPresentDays;
  final double waterRatePerDay;
  final Map<String, String> rechargePresentDays;
  final double rechargeRatePerDay;
  final String? rechargeLastDate;
  final void Function(Entry) onAddEntry;
  final void Function(Entry) onUpdateEntry;
  final void Function(String) onDeleteEntry;
  final void Function(Reminder) onAddReminder;
  final void Function(String) onToggleReminder;
  final void Function(String) onDeleteReminder;
  final void Function({bool? dark, String? pin, bool clearPin, Map<String, double>? budgets, String? language}) onUpdateSettings;
  final void Function(List<Entry>, List<Reminder>) onRestore;
  final VoidCallback onLock;
  final Future<void> Function() onSignOut;
  final void Function(String, String) onAddMilkLeave;
  final void Function(String) onRemoveMilkLeave;
  final void Function({double? litresPerDay, double? pricePerLitre}) onUpdateMilkSettings;
  final void Function({double? lastReading, double? ratePerUnit}) onUpdateElectricitySettings;
  final void Function({String? lastCylinderDate, double? cylinderKg}) onUpdateGasSettings;
  final void Function(String, String) onMarkWaterPresent;
  final void Function(String) onUnmarkWaterPresent;
  final void Function(double) onUpdateWaterRate;
  final void Function(String, String) onMarkRechargePresent;
  final void Function(String) onUnmarkRechargePresent;
  final void Function(double) onUpdateRechargeRate;
  final void Function(String) onUpdateRechargeLastDate;
  final String Function(String sectionKey, String label) onEnsureCustomCategory;
  final void Function(String sectionKey, String key) onRemoveCustomCategory;

  const HomeShell({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.entries,
    required this.reminders,
    required this.budgets,
    required this.dark,
    required this.lang,
    required this.pin,
    required this.milkLeaves,
    required this.milkLitresPerDay,
    required this.milkPricePerLitre,
    required this.electricityLastReading,
    required this.electricityRatePerUnit,
    required this.gasLastCylinderDate,
    required this.gasCylinderKg,
    required this.waterPresentDays,
    required this.waterRatePerDay,
    required this.rechargePresentDays,
    required this.rechargeRatePerDay,
    required this.rechargeLastDate,
    required this.onAddEntry,
    required this.onUpdateEntry,
    required this.onDeleteEntry,
    required this.onAddReminder,
    required this.onToggleReminder,
    required this.onDeleteReminder,
    required this.onUpdateSettings,
    required this.onRestore,
    required this.onLock,
    required this.onSignOut,
    required this.onAddMilkLeave,
    required this.onRemoveMilkLeave,
    required this.onUpdateMilkSettings,
    required this.onUpdateElectricitySettings,
    required this.onUpdateGasSettings,
    required this.onMarkWaterPresent,
    required this.onUnmarkWaterPresent,
    required this.onUpdateWaterRate,
    required this.onMarkRechargePresent,
    required this.onUnmarkRechargePresent,
    required this.onUpdateRechargeRate,
    required this.onUpdateRechargeLastDate,
    required this.onEnsureCustomCategory,
    required this.onRemoveCustomCategory,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tabIndex = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void openEntrySheet(String section, Category cat, String? vehicleType, {String? date, Entry? existing}) {
    if (section == 'home' && cat.key == 'milk' && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return MilkScreen(
              milkLeaves: widget.milkLeaves,
              litresPerDay: widget.milkLitresPerDay,
              pricePerLitre: widget.milkPricePerLitre,
              onAddLeave: widget.onAddMilkLeave,
              onRemoveLeave: widget.onRemoveMilkLeave,
              onUpdateSettings: widget.onUpdateMilkSettings,
              onRecordPayment: widget.onAddEntry,
              onAddReminder: widget.onAddReminder,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && cat.key == 'electricity' && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return ElectricityScreen(
              lastReading: widget.electricityLastReading,
              ratePerUnit: widget.electricityRatePerUnit,
              onUpdateSettings: widget.onUpdateElectricitySettings,
              onRecordPayment: widget.onAddEntry,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && cat.key == 'gas' && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return GasScreen(
              lastCylinderDate: widget.gasLastCylinderDate,
              cylinderKg: widget.gasCylinderKg,
              onUpdateSettings: widget.onUpdateGasSettings,
              onRecordPayment: widget.onAddEntry,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && cat.key == 'water' && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return PresenceCalendarScreen(
              title: 'Water Tracker',
              categoryKey: 'water',
              instructionText: 'Tap the date when water arrived',
              presentLabel: 'Water Arrived',
              absentLabel: 'Water Did Not Arrive',
              presentDays: widget.waterPresentDays,
              ratePerDay: widget.waterRatePerDay,
              onMarkPresent: widget.onMarkWaterPresent,
              onUnmarkPresent: widget.onUnmarkWaterPresent,
              onUpdateRate: widget.onUpdateWaterRate,
              onRecordPayment: widget.onAddEntry,
              onAddReminder: widget.onAddReminder,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && cat.key == 'recharge' && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return RechargeScreen(
              lastDate: widget.rechargeLastDate,
              onUpdateLastDate: widget.onUpdateRechargeLastDate,
              onRecordPayment: widget.onAddEntry,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && (cat.key == 'ration' || cat.key == 'grocery') && existing == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroceryScreen(onSave: widget.onAddEntry),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return EntrySheet(
          section: section,
          category: cat,
          vehicleType: vehicleType,
          date: date ?? todayISO(),
          existing: existing,
          lang: widget.lang,
          onSave: (e) {
            Entry finalEntry = e;
            // "Others" tile: typed name becomes a brand-new permanent tile from now on.
            if (cat.custom && e.customLabel.trim().isNotEmpty) {
              final sectionKey = customSectionKey(section, vehicleType);
              final newKey = widget.onEnsureCustomCategory(sectionKey, e.customLabel.trim());
              finalEntry = Entry(
                id: e.id,
                section: e.section,
                category: newKey,
                vehicleType: e.vehicleType,
                date: e.date,
                amount: e.amount,
                quantity: e.quantity,
                rate: e.rate,
                unitLabel: e.unitLabel,
                odometer: e.odometer,
                notes: e.notes,
                customLabel: '',
                createdAt: e.createdAt,
              );
            }
            if (existing != null) {
              widget.onUpdateEntry(finalEntry);
            } else {
              widget.onAddEntry(finalEntry);
            }
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void openEditEntry(Entry e) {
    final cat = findCat(e.section, e.vehicleType, e.category) ?? Category(e.category, e.label(), Icons.receipt_long, custom: true);
    openEntrySheet(e.section, cat, e.vehicleType, date: e.date, existing: e);
  }

  void showCategoryPickerForDate(String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CategoryPickerSheet(
          onPick: (s, c, v) {
            Navigator.pop(context);
            openEntrySheet(s, c, v, date: date);
          },
        );
      },
    );
  }

  Future<void> confirmSignOut() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will be signed out from this device. Your data will come back once you log in again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
          ],
        );
      },
    );
    if (yes == true) {
      await widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(
        entries: widget.entries,
        budgets: widget.budgets,
        reminders: widget.reminders,
        milkLeaves: widget.milkLeaves,
        milkLitresPerDay: widget.milkLitresPerDay,
        milkPricePerLitre: widget.milkPricePerLitre,
        onEditEntry: openEditEntry,
        lang: widget.lang,
      ),
      AddTab(
        onPick: openEntrySheet,
        entries: widget.entries,
        onEditEntry: openEditEntry,
        lang: widget.lang,
        onRemoveCustomCategory: widget.onRemoveCustomCategory,
      ),
      CalendarTab(
        entries: widget.entries,
        onDelete: widget.onDeleteEntry,
        onAdd: showCategoryPickerForDate,
        onEdit: openEditEntry,
        lang: widget.lang,
      ),
      AnalyticsTab(entries: widget.entries, budgets: widget.budgets),
      SearchTab(entries: widget.entries, onDelete: widget.onDeleteEntry, onEdit: openEditEntry, lang: widget.lang),
    ];

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(appName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            if (widget.userName.isNotEmpty)
              Text('Hi, ${widget.userName}', style: const TextStyle(fontSize: 11.5, color: goldColor)),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [heroDark2, bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        actions: [
          if (widget.pin != null) IconButton(icon: const Icon(Icons.lock), onPressed: widget.onLock),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [heroDark2, bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 40, color: goldColor),
                  const SizedBox(height: 8),
                  if (widget.userName.isNotEmpty)
                    Text(widget.userName, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(widget.userEmail, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Reminders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return RemindersScreen(
                        reminders: widget.reminders,
                        onAdd: widget.onAddReminder,
                        onToggle: widget.onToggleReminder,
                        onDelete: widget.onDeleteReminder,
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export / Backup'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return ExportScreen(
                        entries: widget.entries,
                        reminders: widget.reminders,
                        onRestore: widget.onRestore,
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return SettingsScreen(
                        dark: widget.dark,
                        lang: widget.lang,
                        budgets: widget.budgets,
                        pin: widget.pin,
                        onUpdate: widget.onUpdateSettings,
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share App'),
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'I use $appName to track my daily expenses, milk accounts, and vehicle petrol/km costing. You should try it too!',
                  subject: appName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedback / Suggestion'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: expenseColor),
              title: const Text('Sign Out', style: TextStyle(color: expenseColor)),
              onTap: () {
                Navigator.pop(context);
                confirmSignOut();
              },
            ),
          ],
        ),
      ),
      body: tabs[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard), label: navLabelFor('Dashboard', widget.lang)),
          NavigationDestination(icon: const Icon(Icons.add_circle), label: navLabelFor('Add', widget.lang)),
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: navLabelFor('Calendar', widget.lang)),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: navLabelFor('Analytics', widget.lang)),
          NavigationDestination(icon: const Icon(Icons.search), label: navLabelFor('Search', widget.lang)),
        ],
      ),
    );
  }
}
