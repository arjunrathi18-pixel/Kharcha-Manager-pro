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
  double milkLitresPerDay = 1.0;
  double milkPricePerLitre = 60.0;
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
        milkLitresPerDay = 1.0;
        milkPricePerLitre = 60.0;
        dark = true;
        pin = null;
        budgets = {'home': 0, 'personal': 0, 'vehicle': 0};
        customCategories = [];
        globalCustomCategories = [];
      });
      return;
    }

    currentUid = user.uid;
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
            'milkSettings': {'litresPerDay': 1.0, 'pricePerLitre': 60.0},
            'electricitySettings': {'lastReading': null, 'ratePerUnit': 8.0},
            'gasSettings': {'lastCylinderDate': null, 'cylinderKg': 14.2},
            'waterData': {'presentDays': [], 'ratePerDay': 20.0},
            'rechargeData': {'presentDays': [], 'ratePerDay': 10.0},
            'rechargeLastDate': null,
            'customCategories': [],
            'settings': {'dark': true, 'pin': null, 'budgets': {'home': 0, 'personal': 0, 'vehicle': 0}},
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
      final milkSettingsRaw = (data['milkSettings'] as Map<String, dynamic>? ?? {});
      final electricityRaw = (data['electricitySettings'] as Map<String, dynamic>? ?? {});
      final gasRaw = (data['gasSettings'] as Map<String, dynamic>? ?? {});
      final waterRaw = (data['waterData'] as Map<String, dynamic>? ?? {});
      final rechargeRaw = (data['rechargeData'] as Map<String, dynamic>? ?? {});
      final customCatsRaw = (data['customCategories'] as List? ?? []);
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

      setState(() {
        entries = entriesRaw.map((e) => Entry.fromJson(Map<String, dynamic>.from(e))).toList();
        reminders = parsedReminders;
        milkLeaves = parsedLeaves;
        milkLitresPerDay = (milkSettingsRaw['litresPerDay'] as num?)?.toDouble() ?? 1.0;
        milkPricePerLitre = (milkSettingsRaw['pricePerLitre'] as num?)?.toDouble() ?? 60.0;
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
    await _docRef?.update({'settings': {'dark': dark, 'pin': pin, 'budgets': budgets, 'language': language}});
  }

  Future<void> _pushMilk() async {
    await _docRef?.update({
      'milkLeaves': milkLeaves.entries.map((e) => {'date': e.key, 'reason': e.value}).toList(),
      'milkSettings': {'litresPerDay': milkLitresPerDay, 'pricePerLitre': milkPricePerLitre},
    });
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

  void updateSettings({bool? dark, String? pin, bool clearPin = false, Map<String, double>? budgets, String? language}) {
    setState(() {
      if (dark != null) this.dark = dark;
      if (clearPin) this.pin = null;
      if (pin != null) this.pin = pin;
      if (budgets != null) this.budgets = budgets;
      if (language != null) this.language = language;
    });
    _pushSettings();
  }

  void addMilkLeave(String date, String reason) {
    setState(() => milkLeaves[date] = reason);
    _pushMilk();
  }

  void removeMilkLeave(String date) {
    setState(() => milkLeaves.remove(date));
    _pushMilk();
  }

  void updateMilkSettings({double? litresPerDay, double? pricePerLitre}) {
    setState(() {
      if (litresPerDay != null) milkLitresPerDay = litresPerDay;
      if (pricePerLitre != null) milkPricePerLitre = pricePerLitre;
    });
    _pushMilk();
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
            userEmail: user.email ?? '',
            userName: user.displayName ?? '',
            entries: entries,
            reminders: reminders,
            budgets: budgets,
            dark: dark,
            lang: language,
            pin: pin,
            milkLeaves: milkLeaves,
            milkLitresPerDay: milkLitresPerDay,
            milkPricePerLitre: milkPricePerLitre,
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
            onAddMilkLeave: addMilkLeave,
            onRemoveMilkLeave: removeMilkLeave,
            onUpdateMilkSettings: updateMilkSettings,
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
