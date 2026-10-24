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
import 'recurring_screen.dart';
import 'vendor_milk_screen.dart';
import 'monthly_report_screen.dart';
import 'milk_link_screen.dart';
import 'receipt_scan_screen.dart';
import 'savings_goals_screen.dart';
import 'planner_screen.dart';
import '../receipt_parser.dart';

class HomeShell extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final List<Entry> entries;
  final List<Reminder> reminders;
  final Map<String, double> budgets;
  final bool dark;
  final String lang;
  final String? pin;
  final Map<String, String> milkLeaves;
  final Map<String, double> milkQuantityOverrides;
  final double milkLitresPerDay;
  final double milkPricePerLitre;
  final String? milkmanPhone;
  final String milkMode;
  final List<RecurringExpense> recurringExpenses;
  final List<MilkCustomer> milkCustomers;
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
  final void Function({bool? dark, String? pin, bool clearPin, Map<String, double>? budgets, String? language, String? milkMode}) onUpdateSettings;
  final void Function(List<Entry>, List<Reminder>) onRestore;
  final VoidCallback onLock;
  final Future<void> Function() onSignOut;
  final void Function(String, double, String) onSetDayQuantity;
  final void Function(String) onResetDay;
  final void Function({double? litresPerDay, double? pricePerLitre, String? milkmanPhone}) onUpdateMilkSettings;
  final void Function(RecurringExpense) onAddRecurring;
  final void Function(RecurringExpense) onUpdateRecurring;
  final void Function(String) onDeleteRecurring;
  final void Function(MilkCustomer) onAddMilkCustomer;
  final void Function(MilkCustomer) onUpdateMilkCustomer;
  final void Function(String) onDeleteMilkCustomer;
  final List<SavingsGoal> savingsGoals;
  final void Function(SavingsGoal) onAddGoal;
  final void Function(SavingsGoal) onUpdateGoal;
  final void Function(String) onDeleteGoal;
  final List<PlanItem> planItems;
  final void Function(PlanItem) onAddPlanItem;
  final void Function(PlanItem) onUpdatePlanItem;
  final void Function(String) onDeletePlanItem;
  final Future<String> Function() onEnsureMilkLinkCode;
  final Future<Map<String, String>?> Function(String) onResolveLinkCode;
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
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.entries,
    required this.reminders,
    required this.budgets,
    required this.dark,
    required this.lang,
    required this.pin,
    required this.milkLeaves,
    required this.milkQuantityOverrides,
    required this.milkLitresPerDay,
    required this.milkPricePerLitre,
    required this.milkmanPhone,
    required this.milkMode,
    required this.recurringExpenses,
    required this.milkCustomers,
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
    required this.onSetDayQuantity,
    required this.onResetDay,
    required this.onUpdateMilkSettings,
    required this.onAddRecurring,
    required this.onUpdateRecurring,
    required this.onDeleteRecurring,
    required this.onAddMilkCustomer,
    required this.onUpdateMilkCustomer,
    required this.onDeleteMilkCustomer,
    required this.savingsGoals,
    required this.onAddGoal,
    required this.onUpdateGoal,
    required this.onDeleteGoal,
    required this.planItems,
    required this.onAddPlanItem,
    required this.onUpdatePlanItem,
    required this.onDeletePlanItem,
    required this.onEnsureMilkLinkCode,
    required this.onResolveLinkCode,
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

  void openEntrySheet(String section, Category cat, String? vehicleType, {String? date, Entry? existing, Entry? prefill, VoidCallback? onSaved}) {
    if (section == 'home' && cat.key == 'milk' && existing == null && prefill == null) {
      if (widget.milkMode == 'vendor') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return VendorMilkScreen(
                vendorUid: widget.userId,
                customers: widget.milkCustomers,
                onAddCustomer: widget.onAddMilkCustomer,
                onUpdateCustomer: widget.onUpdateMilkCustomer,
                onDeleteCustomer: widget.onDeleteMilkCustomer,
                onAddEntry: widget.onAddEntry,
                onResolveLinkCode: widget.onResolveLinkCode,
              );
            },
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return MilkScreen(
              milkLeaves: widget.milkLeaves,
              quantityOverrides: widget.milkQuantityOverrides,
              litresPerDay: widget.milkLitresPerDay,
              pricePerLitre: widget.milkPricePerLitre,
              milkmanPhone: widget.milkmanPhone,
              billName: widget.userName,
              onSetDayQuantity: widget.onSetDayQuantity,
              onResetDay: widget.onResetDay,
              onUpdateSettings: widget.onUpdateMilkSettings,
              onRecordPayment: widget.onAddEntry,
              onAddReminder: widget.onAddReminder,
            );
          },
        ),
      );
      return;
    }

    if (section == 'home' && cat.key == 'electricity' && existing == null && prefill == null) {
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

    if (section == 'home' && cat.key == 'gas' && existing == null && prefill == null) {
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

    if (section == 'home' && cat.key == 'water' && existing == null && prefill == null) {
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

    if (section == 'home' && cat.key == 'recharge' && existing == null && prefill == null) {
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

    if (section == 'home' && (cat.key == 'ration' || cat.key == 'grocery') && existing == null && prefill == null) {
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
          prefill: prefill,
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
            onSaved?.call();
          },
        );
      },
    );
  }

  // Scan a receipt → the scan screen returns the confirmed section/category,
  // and the normal entry sheet opens pre-filled so nothing is saved blindly.
  Future<void> scanReceipt() async {
    final r = await Navigator.push<ReceiptResult>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
    );
    if (r == null || !mounted) return;
    final cat = findCat(r.section, r.vehicleType, r.categoryKey);
    if (cat == null) return;
    final prefill = Entry(
      id: '',
      section: r.section,
      category: r.categoryKey,
      vehicleType: r.vehicleType,
      date: r.dateISO,
      amount: r.amount,
      quantity: r.quantity,
      notes: r.merchant.isEmpty ? 'Scanned receipt' : 'Receipt: ${r.merchant}',
      customLabel: cat.custom ? r.merchant : '',
      createdAt: 0,
    );
    openEntrySheet(r.section, cat, r.vehicleType, date: r.dateISO, prefill: prefill);
  }

  void openPlanner({int tab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlannerScreen(
          items: widget.planItems,
          lang: widget.lang,
          initialTab: tab,
          onAddItem: widget.onAddPlanItem,
          onUpdateItem: widget.onUpdatePlanItem,
          onDeleteItem: widget.onDeletePlanItem,
          onAddReminder: widget.onAddReminder,
          onDeleteReminder: widget.onDeleteReminder,
          onRecordExpense: recordPlanExpense,
        ),
      ),
    );
  }

  void markPlanDone(PlanItem it) {
    it.done = true;
    if (it.reminderId != null) {
      widget.onDeleteReminder(it.reminderId!);
      it.reminderId = null;
    }
    widget.onUpdatePlanItem(it);
  }

  // Turn a planned item into a real expense: pick the category, review the
  // pre-filled entry, and once saved the plan is ticked off.
  void recordPlanExpense(PlanItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CategoryPickerSheet(
          onPick: (s, c, v) {
            Navigator.pop(context);
            final prefill = Entry(
              id: '',
              section: s,
              category: c.key,
              vehicleType: v,
              date: item.date,
              amount: item.amount,
              notes: item.occasionName.isEmpty ? item.title : '${item.occasionName}: ${item.title}',
              customLabel: c.custom ? item.title : '',
              createdAt: 0,
            );
            openEntrySheet(s, c, v, date: item.date, prefill: prefill, onSaved: () => markPlanDone(item));
          },
        );
      },
    );
  }

  void openGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavingsGoalsScreen(
          goals: widget.savingsGoals,
          onAdd: widget.onAddGoal,
          onUpdate: widget.onUpdateGoal,
          onDelete: widget.onDeleteGoal,
          onAddEntry: widget.onAddEntry,
          onDeleteEntry: widget.onDeleteEntry,
        ),
      ),
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
        milkQuantityOverrides: widget.milkQuantityOverrides,
        goals: widget.savingsGoals,
        onOpenGoals: openGoals,
        planItems: widget.planItems,
        onOpenPlanner: openPlanner,
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
        onScanReceipt: scanReceipt,
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
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Planner & Panchang'),
              onTap: () {
                Navigator.pop(context);
                openPlanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Savings Goals'),
              onTap: () {
                Navigator.pop(context);
                openGoals();
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Recurring Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return RecurringExpensesScreen(
                        recurringExpenses: widget.recurringExpenses,
                        onAdd: widget.onAddRecurring,
                        onUpdate: widget.onUpdateRecurring,
                        onDelete: widget.onDeleteRecurring,
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Monthly Report'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return MonthlyReportScreen(entries: widget.entries, budgets: widget.budgets);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('My Milk Link'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyMilkLinkScreen(onEnsureLinkCode: widget.onEnsureMilkLinkCode),
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
                        milkMode: widget.milkMode,
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
