import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'helpers.dart';
import 'notification_service.dart';
import 'screens/auth_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/home_shell.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'UI Error:\n\n${details.exceptionAsString()}\n\n${details.stack}',
            style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  };

  runZonedGuarded(() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      runApp(const KharchaApp());
    } catch (e, st) {
      runApp(StartupErrorApp(error: e.toString(), stack: st.toString()));
    }
  }, (error, stack) {
    runApp(StartupErrorApp(error: error.toString(), stack: stack.toString()));
  });
}

class StartupErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const StartupErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Startup Error'), backgroundColor: Colors.red[900]),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'An error occurred while starting the app:\n\n$error\n\n$stack',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}

/* ============================== APP ROOT ============================== */

class KharchaApp extends StatefulWidget {
  const KharchaApp({super.key});

  @override
  State<KharchaApp> createState() => _KharchaAppState();
}

class _KharchaAppState extends State<KharchaApp> {
  bool dark = true;
  String language = 'en';
  List<Entry> entries = [];
  List<Reminder> reminders = [];
  Map<String, double> budgets = {'home': 0, 'personal': 0, 'vehicle': 0};
  Map<String, String> milkLeaves = {};
  Map<String, double> milkQuantityOverrides = {};
  double milkLitresPerDay = 1.0;
  double milkPricePerLitre = 60.0;
  String? milkmanPhone;
  String milkMode = 'customer';
  String? myMilkLinkCode;
  List<RecurringExpense> recurringExpenses = [];
  List<MilkCustomer> milkCustomers = [];
  double? electricityLastReading;
  double electricityRatePerUnit = 8.0;
  String? gasLastCylinderDate;
  double gasCylinderKg = 14.2;
  Map<String, String> waterPresentDays = {};
  double waterRatePerDay = 20.0;
  Map<String, String> rechargePresentDays = {};
  double rechargeRatePerDay = 10.0;
  String? rechargeLastDate;
  List<Map<String, String>> customCategories = [];
  String? pin;
  bool locked = false;
  bool docLoaded = false;
  String? docLoadError;
  bool docLoadTimedOut = false;
  Timer? _docLoadTimeoutTimer;

  StreamSubscription<User?>? authSub;
  StreamSubscription<DocumentSnapshot>? docSub;
  String? currentUid;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    docSub?.cancel();
    docSub = null;
    _docLoadTimeoutTimer?.cancel();
    _docLoadTimeoutTimer = null;

    if (user == null) {
      setState(() {
        currentUid = null;
        docLoaded = false;
        docLoadError = null;
        docLoadTimedOut = false;
        entries = [];
        reminders = [];
        milkLeaves = {};
        milkQuantityOverrides = {};
        milkLitresPerDay = 1.0;
        milkPricePerLitre = 60.0;
        milkmanPhone = null;
        milkMode = 'customer';
        myMilkLinkCode = null;
        recurringExpenses = [];
        milkCustomers = [];
        dark = true;
        pin = null;
        budgets = {'home': 0, 'personal': 0, 'vehicle': 0};
        customCategories = [];
        globalCustomCategories = [];
      });
      return;
    }

    currentUid = user.uid;
    currentUserName = user.displayName;
    docLoadError = null;
    docLoadTimedOut = false;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Safety net: if nothing has come back within 12 seconds (slow/no
    // network, misconfigured Firestore rules, etc.), stop showing a bare
    // spinner forever — show an actionable Retry/Sign Out screen instead.
    _docLoadTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && !docLoaded) {
        setState(() => docLoadTimedOut = true);
      }
    });

    docSub = docRef.snapshots().listen((snap) async {
      if (!snap.exists) {
        // A snapshot straight from the (empty, post-reinstall/update) local
        // cache can report "doesn't exist" even when the real document is
        // sitting on the server — the client just hasn't heard back yet.
        // Only create a fresh document once Firestore has actually confirmed
        // with the server that there is nothing there; otherwise wait
        // quietly for the next (server-backed) snapshot.
        if (snap.metadata.isFromCache) return;
        try {
          await docRef.set({
            'entries': [],
            'reminders': [],
            'milkLeaves': [],
            'milkQuantityOverrides': [],
            'myMilkLinkCode': null,
            'milkSettings': {'litresPerDay': 1.0, 'pricePerLitre': 60.0, 'milkmanPhone': null},
            'electricitySettings': {'lastReading': null, 'ratePerUnit': 8.0},
            'gasSettings': {'lastCylinderDate': null, 'cylinderKg': 14.2},
            'waterData': {'presentDays': [], 'ratePerDay': 20.0},
            'rechargeData': {'presentDays': [], 'ratePerDay': 10.0},
            'rechargeLastDate': null,
            'customCategories': [],
            'recurringExpenses': [],
            'milkCustomers': [],
            'settings': {'dark': true, 'pin': null, 'budgets': {'home': 0, 'personal': 0, 'vehicle': 0}, 'milkMode': 'customer'},
          });
        } catch (e) {
          if (mounted) setState(() => docLoadError = e.toString());
        }
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      final entriesRaw = (data['entries'] as List? ?? []);
      final remindersRaw = (data['reminders'] as List? ?? []);
      final milkLeavesRaw = (data['milkLeaves'] as List? ?? []);
      final milkOverridesRaw = (data['milkQuantityOverrides'] as List? ?? []);
      final milkSettingsRaw = (data['milkSettings'] as Map<String, dynamic>? ?? {});
      final electricityRaw = (data['electricitySettings'] as Map<String, dynamic>? ?? {});
      final gasRaw = (data['gasSettings'] as Map<String, dynamic>? ?? {});
      final waterRaw = (data['waterData'] as Map<String, dynamic>? ?? {});
      final rechargeRaw = (data['rechargeData'] as Map<String, dynamic>? ?? {});
      final customCatsRaw = (data['customCategories'] as List? ?? []);
      final recurringRaw = (data['recurringExpenses'] as List? ?? []);
      final milkCustomersRaw = (data['milkCustomers'] as List? ?? []);
      final settingsRaw = (data['settings'] as Map<String, dynamic>? ?? {});

      final parsedLeaves = <String, String>{};
      for (final item in milkLeavesRaw) {
        if (item is Map) {
          final d = item['date']?.toString();
          if (d != null) parsedLeaves[d] = item['reason']?.toString() ?? '';
        } else if (item is String) {
          parsedLeaves[item] = '';
        }
      }

      final parsedMilkOverrides = <String, double>{};
      for (final item in milkOverridesRaw) {
        if (item is Map) {
          final d = item['date']?.toString();
          final q = item['quantity'];
          if (d != null && q != null) parsedMilkOverrides[d] = (q as num).toDouble();
        }
      }

      Map<String, String> parsePresentDays(dynamic raw) {
        final result = <String, String>{};
        if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final d = item['date']?.toString();
              if (d != null) result[d] = item['note']?.toString() ?? '';
            }
          }
        }
        return result;
      }

      final parsedCustomCats = customCatsRaw
          .whereType<Map>()
          .map((c) => c.map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();

      final parsedReminders = remindersRaw.map((r) => Reminder.fromJson(Map<String, dynamic>.from(r))).toList();
      final parsedRecurring = recurringRaw.map((r) => RecurringExpense.fromJson(Map<String, dynamic>.from(r))).toList();
      final parsedMilkCustomers = milkCustomersRaw.map((c) => MilkCustomer.fromJson(Map<String, dynamic>.from(c))).toList();

      setState(() {
        entries = entriesRaw.map((e) => Entry.fromJson(Map<String, dynamic>.from(e))).toList();
        reminders = parsedReminders;
        milkLeaves = parsedLeaves;
        milkQuantityOverrides = parsedMilkOverrides;
        myMilkLinkCode = data['myMilkLinkCode']?.toString();
        milkLitresPerDay = (milkSettingsRaw['litresPerDay'] as num?)?.toDouble() ?? 1.0;
        milkPricePerLitre = (milkSettingsRaw['pricePerLitre'] as num?)?.toDouble() ?? 60.0;
        milkmanPhone = milkSettingsRaw['milkmanPhone']?.toString();
        recurringExpenses = parsedRecurring;
        milkCustomers = parsedMilkCustomers;
        electricityLastReading = (electricityRaw['lastReading'] as num?)?.toDouble();
        electricityRatePerUnit = (electricityRaw['ratePerUnit'] as num?)?.toDouble() ?? 8.0;
        gasLastCylinderDate = gasRaw['lastCylinderDate']?.toString();
        gasCylinderKg = (gasRaw['cylinderKg'] as num?)?.toDouble() ?? 14.2;
        waterPresentDays = parsePresentDays(waterRaw['presentDays']);
        waterRatePerDay = (waterRaw['ratePerDay'] as num?)?.toDouble() ?? 20.0;
        rechargePresentDays = parsePresentDays(rechargeRaw['presentDays']);
        rechargeRatePerDay = (rechargeRaw['ratePerDay'] as num?)?.toDouble() ?? 10.0;
        rechargeLastDate = data['rechargeLastDate']?.toString();
        customCategories = parsedCustomCats;
        globalCustomCategories = parsedCustomCats;
        dark = settingsRaw['dark'] ?? true;
        language = settingsRaw['language'] ?? 'en';
        milkMode = settingsRaw['milkMode'] ?? 'customer';
        pin = settingsRaw['pin'];
        if (settingsRaw['budgets'] != null) {
          final rawBudgets = settingsRaw['budgets'] as Map;
          budgets = rawBudgets.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
        }
        docLoaded = true;
        docLoadError = null;
        docLoadTimedOut = false;
      });
      _docLoadTimeoutTimer?.cancel();
      NotificationService.rescheduleAll(parsedReminders);
      _processRecurringExpenses(parsedRecurring);
    }, onError: (Object e) {
      if (mounted) setState(() => docLoadError = e.toString());
    });
  }

  void _retryDocLoad() {
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  DocumentReference<Map<String, dynamic>>? get _docRef {
    if (currentUid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(currentUid);
  }

  Future<void> _pushEntries() async {
    await _docRef?.update({'entries': entries.map((e) => e.toJson()).toList()});
  }

  Future<void> _pushReminders() async {
    await _docRef?.update({'reminders': reminders.map((r) => r.toJson()).toList()});
  }

  Future<void> _pushSettings() async {
    await _docRef?.update({
      'settings': {'dark': dark, 'pin': pin, 'budgets': budgets, 'language': language, 'milkMode': milkMode}
    });
  }

  Future<void> _pushMilk() async {
    await _docRef?.update({
      'milkLeaves': milkLeaves.entries.map((e) => {'date': e.key, 'reason': e.value}).toList(),
      'milkQuantityOverrides': milkQuantityOverrides.entries.map((e) => {'date': e.key, 'quantity': e.value}).toList(),
      'milkSettings': {'litresPerDay': milkLitresPerDay, 'pricePerLitre': milkPricePerLitre, 'milkmanPhone': milkmanPhone},
    });
  }

  Future<void> _pushRecurring() async {
    await _docRef?.update({'recurringExpenses': recurringExpenses.map((r) => r.toJson()).toList()});
  }

  Future<void> _pushMilkCustomers() async {
    await _docRef?.update({'milkCustomers': milkCustomers.map((c) => c.toJson()).toList()});
  }

  Future<void> _pushElectricity() async {
    await _docRef?.update({
      'electricitySettings': {'lastReading': electricityLastReading, 'ratePerUnit': electricityRatePerUnit},
    });
  }

  Future<void> _pushGas() async {
    await _docRef?.update({
      'gasSettings': {'lastCylinderDate': gasLastCylinderDate, 'cylinderKg': gasCylinderKg},
    });
  }

  Future<void> _pushWater() async {
    await _docRef?.update({
      'waterData': {
        'presentDays': waterPresentDays.entries.map((e) => {'date': e.key, 'note': e.value}).toList(),
        'ratePerDay': waterRatePerDay,
      },
    });
  }

  Future<void> _pushRecharge() async {
    await _docRef?.update({
      'rechargeData': {
        'presentDays': rechargePresentDays.entries.map((e) => {'date': e.key, 'note': e.value}).toList(),
        'ratePerDay': rechargeRatePerDay,
      },
    });
  }

  Future<void> _pushCustomCategories() async {
    await _docRef?.update({'customCategories': customCategories});
  }

  void updateElectricitySettings({double? lastReading, double? ratePerUnit}) {
    setState(() {
      if (lastReading != null) electricityLastReading = lastReading;
      if (ratePerUnit != null) electricityRatePerUnit = ratePerUnit;
    });
    _pushElectricity();
  }

  void updateGasSettings({String? lastCylinderDate, double? cylinderKg}) {
    setState(() {
      if (lastCylinderDate != null) gasLastCylinderDate = lastCylinderDate;
      if (cylinderKg != null) gasCylinderKg = cylinderKg;
    });
    _pushGas();
  }

  void markWaterPresent(String date, String note) {
    setState(() => waterPresentDays[date] = note);
    _pushWater();
  }

  void unmarkWaterPresent(String date) {
    setState(() => waterPresentDays.remove(date));
    _pushWater();
  }

  void updateWaterRate(double rate) {
    setState(() => waterRatePerDay = rate);
    _pushWater();
  }

  void markRechargePresent(String date, String note) {
    setState(() => rechargePresentDays[date] = note);
    _pushRecharge();
  }

  void unmarkRechargePresent(String date) {
    setState(() => rechargePresentDays.remove(date));
    _pushRecharge();
  }

  void updateRechargeRate(double rate) {
    setState(() => rechargeRatePerDay = rate);
    _pushRecharge();
  }

  void updateRechargeLastDate(String date) {
    setState(() => rechargeLastDate = date);
    _docRef?.update({'rechargeLastDate': date});
  }

  // Returns the key to use for this category name inside this section.
  // If the name already exists (case-insensitive), reuses its key. Otherwise
  // creates a brand-new permanent tile and syncs it to Firestore.
  String ensureCustomCategory(String sectionKey, String label) {
    final normalized = label.trim();
    for (final c in customCategories) {
      if (c['sectionKey'] == sectionKey && (c['label'] ?? '').toLowerCase() == normalized.toLowerCase()) {
        return c['key']!;
      }
    }
    final key = 'c${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      customCategories = [
        ...customCategories,
        {'sectionKey': sectionKey, 'key': key, 'label': normalized},
      ];
      globalCustomCategories = customCategories;
    });
    _pushCustomCategories();
    return key;
  }

  void removeCustomCategory(String sectionKey, String key) {
    setState(() {
      customCategories = customCategories
          .where((c) => !(c['sectionKey'] == sectionKey && c['key'] == key))
          .toList();
      globalCustomCategories = customCategories;
    });
    _pushCustomCategories();
  }

  void addEntry(Entry e) {
    setState(() => entries.add(e));
    _pushEntries();
  }

  void updateEntry(Entry updated) {
    setState(() {
      final idx = entries.indexWhere((e) => e.id == updated.id);
      if (idx != -1) entries[idx] = updated;
    });
    _pushEntries();
  }

  void deleteEntry(String id) {
    setState(() => entries.removeWhere((e) => e.id == id));
    _pushEntries();
  }

  void addReminder(Reminder r) {
    setState(() => reminders.add(r));
    _pushReminders();
    NotificationService.scheduleReminder(r);
  }

  void toggleReminder(String id) {
    late Reminder toggled;
    setState(() {
      final r = reminders.firstWhere((r) => r.id == id);
      r.done = !r.done;
      toggled = r;
    });
    _pushReminders();
    if (toggled.done) {
      NotificationService.cancelReminder(id);
    } else {
      NotificationService.scheduleReminder(toggled);
    }
  }

  void deleteReminder(String id) {
    NotificationService.cancelReminder(id);
    setState(() => reminders.removeWhere((r) => r.id == id));
    _pushReminders();
  }

  void updateSettings({bool? dark, String? pin, bool clearPin = false, Map<String, double>? budgets, String? language, String? milkMode}) {
    setState(() {
      if (dark != null) this.dark = dark;
      if (clearPin) this.pin = null;
      if (pin != null) this.pin = pin;
      if (budgets != null) this.budgets = budgets;
      if (language != null) this.language = language;
      if (milkMode != null) this.milkMode = milkMode;
    });
    _pushSettings();
  }

  void setMilkDayQuantity(String date, double quantity, String note) {
    setState(() {
      milkQuantityOverrides[date] = quantity;
      if (note.isNotEmpty) {
        milkLeaves[date] = note;
      } else {
        milkLeaves.remove(date);
      }
    });
    _pushMilk();
  }

  void resetMilkDay(String date) {
    setState(() {
      milkQuantityOverrides.remove(date);
      milkLeaves.remove(date);
    });
    _pushMilk();
  }

  void updateMilkSettings({double? litresPerDay, double? pricePerLitre, String? milkmanPhone}) {
    setState(() {
      if (litresPerDay != null) milkLitresPerDay = litresPerDay;
      if (pricePerLitre != null) milkPricePerLitre = pricePerLitre;
      if (milkmanPhone != null) this.milkmanPhone = milkmanPhone;
    });
    _pushMilk();
  }

  void addRecurring(RecurringExpense r) {
    setState(() => recurringExpenses.add(r));
    _pushRecurring();
  }

  void updateRecurring(RecurringExpense r) {
    setState(() {
      final idx = recurringExpenses.indexWhere((x) => x.id == r.id);
      if (idx != -1) recurringExpenses[idx] = r;
    });
    _pushRecurring();
  }

  void deleteRecurring(String id) {
    setState(() => recurringExpenses.removeWhere((r) => r.id == id));
    _pushRecurring();
  }

  // Checks every active recurring expense and auto-logs it as a normal
  // Entry once per month, on or after its chosen day — so fixed bills like
  // Netflix/Gym/EMI don't need to be re-typed every month.
  void _processRecurringExpenses(List<RecurringExpense> list) {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final newEntries = <Entry>[];
    final updated = <RecurringExpense>[];
    var changed = false;

    for (final r in list) {
      if (r.active && r.lastGeneratedMonth != currentMonth && now.day >= r.dayOfMonth) {
        final dateStr = '$currentMonth-${r.dayOfMonth.toString().padLeft(2, '0')}';
        newEntries.add(Entry(
          id: uuid.v4(),
          section: r.section,
          category: r.category,
          vehicleType: r.vehicleType,
          date: dateStr,
          amount: r.amount,
          notes: r.notes.isEmpty ? 'Auto-logged recurring expense' : r.notes,
          customLabel: r.customLabel,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        updated.add(RecurringExpense(
          id: r.id,
          section: r.section,
          category: r.category,
          vehicleType: r.vehicleType,
          amount: r.amount,
          dayOfMonth: r.dayOfMonth,
          notes: r.notes,
          customLabel: r.customLabel,
          active: r.active,
          lastGeneratedMonth: currentMonth,
        ));
        changed = true;
      } else {
        updated.add(r);
      }
    }

    if (changed) {
      setState(() {
        entries = [...entries, ...newEntries];
        recurringExpenses = updated;
      });
      _pushEntries();
      _pushRecurring();
    }
  }

  void addMilkCustomer(MilkCustomer c) {
    setState(() => milkCustomers.add(c));
    _pushMilkCustomers();
    _syncLinkedCustomer(c);
  }

  void updateMilkCustomer(MilkCustomer c) {
    setState(() {
      final idx = milkCustomers.indexWhere((x) => x.id == c.id);
      if (idx != -1) milkCustomers[idx] = c;
    });
    _pushMilkCustomers();
    _syncLinkedCustomer(c);
  }

  void deleteMilkCustomer(String id) {
    setState(() => milkCustomers.removeWhere((c) => c.id == id));
    _pushMilkCustomers();
  }

  // Mirrors a linked customer's bill into a shared document both the vendor
  // and that customer's own account can read, so it shows up live on the
  // customer's phone if they also use this app. Editing still only happens
  // from the vendor's side — the customer's copy is read-only.
  Future<void> _syncLinkedCustomer(MilkCustomer c) async {
    if (c.linkedCustomerUid == null || currentUid == null) return;
    final linkId = '${currentUid}_${c.linkedCustomerUid}';
    try {
      await FirebaseFirestore.instance.collection('milk_shared').doc(linkId).set({
        'vendorUid': currentUid,
        'vendorName': FirebaseAuth.instance.currentUser?.displayName ?? currentUserName ?? '',
        'customerUid': c.linkedCustomerUid,
        'customerName': c.name,
        'litresPerDay': c.litresPerDay,
        'pricePerLitre': c.pricePerLitre,
        'leaves': c.leaves.entries.map((e) => {'date': e.key, 'reason': e.value}).toList(),
        'quantityOverrides': c.quantityOverrides.entries.map((e) => {'date': e.key, 'quantity': e.value}).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // If the Firestore rules for milk_shared haven't been published yet,
      // fail quietly — the vendor's own records are unaffected either way.
    }
  }

  // Lazily creates (once) and returns this account's short code that a
  // vendor can enter to link this customer for live bill sync.
  Future<String> ensureMilkLinkCode() async {
    if (myMilkLinkCode != null) return myMilkLinkCode!;
    final code = generateMilkLinkCode();
    try {
      await FirebaseFirestore.instance.collection('milk_link_codes').doc(code).set({
        'customerUid': currentUid,
        'customerName': FirebaseAuth.instance.currentUser?.displayName ?? currentUserName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _docRef?.update({'myMilkLinkCode': code});
      setState(() => myMilkLinkCode = code);
    } catch (_) {}
    return code;
  }

  // Looks up a code a vendor typed in and returns the matching customer's
  // uid/name, or null if the code doesn't exist.
  Future<Map<String, String>?> resolveLinkCode(String code) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('milk_link_codes').doc(code.trim().toUpperCase()).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return {
        'uid': data['customerUid']?.toString() ?? '',
        'name': data['customerName']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  void restoreBackup(List<Entry> e, List<Reminder> r) {
    setState(() {
      entries = e;
      reminders = r;
    });
    _pushEntries();
    _pushReminders();
    NotificationService.rescheduleAll(r);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    authSub?.cancel();
    docSub?.cancel();
    _docLoadTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = dark
        ? ColorScheme.fromSeed(
            seedColor: goldColor,
            brightness: Brightness.dark,
            surface: bgDark,
            surfaceTint: Colors.transparent,
          )
        : ColorScheme.fromSeed(seedColor: goldColor, brightness: Brightness.light);

    final theme = dark
        ? ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            scaffoldBackgroundColor: bgDark,
            cardColor: cardDark,
            appBarTheme: const AppBarTheme(
              backgroundColor: bgDark,
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            drawerTheme: const DrawerThemeData(backgroundColor: cardDark),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: cardDark,
              indicatorColor: goldColor.withOpacity(0.22),
              elevation: 0,
            ),
            dialogTheme: const DialogTheme(backgroundColor: cardDark),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        : ThemeData(colorScheme: scheme, useMaterial3: true);

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          if (user == null) {
            return const AuthScreen();
          }
          if (!docLoaded) {
            if (docLoadError != null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load your data.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          docLoadError!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _retryDocLoad, child: const Text('Retry')),
                        const SizedBox(height: 4),
                        TextButton(onPressed: signOut, child: const Text('Sign Out')),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (docLoadTimedOut) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'This is taking longer than usual.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check your internet connection and try again.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _retryDocLoad, child: const Text('Retry')),
                        const SizedBox(height: 4),
                        TextButton(onPressed: signOut, child: const Text('Sign Out')),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (locked && pin != null) {
            return LockScreen(pin: pin!, onUnlock: () => setState(() => locked = false));
          }
          return HomeShell(
            userId: user.uid,
            userEmail: user.email ?? '',
            userName: user.displayName ?? '',
            entries: entries,
            reminders: reminders,
            budgets: budgets,
            dark: dark,
            lang: language,
            pin: pin,
            milkLeaves: milkLeaves,
            milkQuantityOverrides: milkQuantityOverrides,
            milkLitresPerDay: milkLitresPerDay,
            milkPricePerLitre: milkPricePerLitre,
            milkmanPhone: milkmanPhone,
            milkMode: milkMode,
            recurringExpenses: recurringExpenses,
            milkCustomers: milkCustomers,
            electricityLastReading: electricityLastReading,
            electricityRatePerUnit: electricityRatePerUnit,
            gasLastCylinderDate: gasLastCylinderDate,
            gasCylinderKg: gasCylinderKg,
            waterPresentDays: waterPresentDays,
            waterRatePerDay: waterRatePerDay,
            rechargePresentDays: rechargePresentDays,
            rechargeRatePerDay: rechargeRatePerDay,
            rechargeLastDate: rechargeLastDate,
            onAddEntry: addEntry,
            onUpdateEntry: updateEntry,
            onDeleteEntry: deleteEntry,
            onAddReminder: addReminder,
            onToggleReminder: toggleReminder,
            onDeleteReminder: deleteReminder,
            onUpdateSettings: updateSettings,
            onRestore: restoreBackup,
            onLock: () => setState(() => locked = true),
            onSignOut: signOut,
            onSetDayQuantity: setMilkDayQuantity,
            onResetDay: resetMilkDay,
            onUpdateMilkSettings: updateMilkSettings,
            onAddRecurring: addRecurring,
            onUpdateRecurring: updateRecurring,
            onDeleteRecurring: deleteRecurring,
            onAddMilkCustomer: addMilkCustomer,
            onUpdateMilkCustomer: updateMilkCustomer,
            onDeleteMilkCustomer: deleteMilkCustomer,
            onEnsureMilkLinkCode: ensureMilkLinkCode,
            onResolveLinkCode: resolveLinkCode,
            onUpdateElectricitySettings: updateElectricitySettings,
            onUpdateGasSettings: updateGasSettings,
            onMarkWaterPresent: markWaterPresent,
            onUnmarkWaterPresent: unmarkWaterPresent,
            onUpdateWaterRate: updateWaterRate,
            onMarkRechargePresent: markRechargePresent,
            onUnmarkRechargePresent: unmarkRechargePresent,
            onUpdateRechargeRate: updateRechargeRate,
            onUpdateRechargeLastDate: updateRechargeLastDate,
            onEnsureCustomCategory: ensureCustomCategory,
            onRemoveCustomCategory: removeCustomCategory,
          );
        },
      ),
    );
  }
}
