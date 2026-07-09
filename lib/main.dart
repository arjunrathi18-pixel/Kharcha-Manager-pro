import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
            'App start karte waqt ye error aayi:\n\n$error\n\n$stack',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}

const uuid = Uuid();
const appName = 'Kharcha Manager';
const logoAsset = 'file_00000000b9c871fb9437d3793d64cfdb.png';

/* ============================== CATEGORY MODEL ============================== */

class Category {
  final String key;
  final String label;
  final IconData icon;
  final bool qty;
  final String? unitLabel;
  final bool trackOdo;
  final bool custom;

  const Category(
    this.key,
    this.label,
    this.icon, {
    this.qty = false,
    this.unitLabel,
    this.trackOdo = false,
    this.custom = false,
  });
}

const homeCats = [
  Category('milk', 'Milk', Icons.local_drink, qty: true, unitLabel: 'Litre'),
  Category('vegetables', 'Vegetables', Icons.eco),
  Category('fruits', 'Fruits', Icons.apple),
  Category('grocery', 'Grocery', Icons.shopping_cart),
  Category('ration', 'Ration', Icons.inventory_2),
  Category('bakery', 'Bakery', Icons.bakery_dining),
  Category('kitchen', 'Kitchen Items', Icons.kitchen),
  Category('rent', 'Flat Rent', Icons.apartment),
  Category('water', 'Water', Icons.water_drop),
  Category('electricity', 'Electricity', Icons.bolt),
  Category('gas', 'Gas Cylinder', Icons.local_fire_department),
  Category('internet', 'Internet', Icons.wifi),
  Category('dth', 'DTH', Icons.tv),
  Category('recharge', 'Mobile Recharge', Icons.smartphone),
  Category('maintenance', 'House Maintenance', Icons.handyman),
  Category('cleaning', 'Cleaning', Icons.cleaning_services),
  Category('maid', 'Maid Salary', Icons.person),
  Category('medicines', 'Medicines', Icons.medication),
  Category('hospital', 'Hospital', Icons.local_hospital),
  Category('education', 'Education', Icons.school),
  Category('gifts', 'Gifts', Icons.card_giftcard),
  Category('festival', 'Festival', Icons.celebration),
  Category('pets', 'Pets', Icons.pets),
  Category('emi', 'EMI', Icons.payments),
  Category('others', 'Others', Icons.more_horiz, custom: true),
];

const personalCats = [
  Category('clothes', 'Clothes', Icons.checkroom),
  Category('shoes', 'Shoes', Icons.hiking),
  Category('mobile', 'Mobile', Icons.phone_android),
  Category('laptop', 'Laptop', Icons.laptop),
  Category('electronics', 'Electronics', Icons.devices_other),
  Category('gym', 'Gym', Icons.fitness_center),
  Category('salon', 'Salon', Icons.content_cut),
  Category('travel', 'Travel', Icons.flight),
  Category('food', 'Food', Icons.restaurant),
  Category('entertainment', 'Entertainment', Icons.movie),
  Category('shopping', 'Shopping', Icons.shopping_bag),
  Category('medicine', 'Medicine', Icons.medication_outlined),
  Category('insurance', 'Insurance', Icons.shield),
  Category('emi', 'EMI', Icons.payments),
  Category('others', 'Others', Icons.more_horiz, custom: true),
];

const bikeCats = [
  Category('petrol', 'Petrol', Icons.local_gas_station, qty: true, unitLabel: 'Litre', trackOdo: true),
  Category('service', 'Service', Icons.build),
  Category('repair', 'Repair', Icons.construction),
  Category('insurance', 'Insurance', Icons.shield),
  Category('pollution', 'Pollution', Icons.air),
  Category('washing', 'Washing', Icons.local_car_wash),
  Category('accessories', 'Accessories', Icons.settings_input_component),
  Category('challan', 'Challan', Icons.receipt_long),
  Category('emi', 'EMI', Icons.payments),
];

const carCats = [
  Category('petrol', 'Petrol', Icons.local_gas_station, qty: true, unitLabel: 'Litre', trackOdo: true),
  Category('diesel', 'Diesel', Icons.local_gas_station, qty: true, unitLabel: 'Litre', trackOdo: true),
  Category('cng', 'CNG', Icons.propane_tank, qty: true, unitLabel: 'Kg', trackOdo: true),
  Category('service', 'Service', Icons.build),
  Category('tyres', 'Tyres', Icons.circle),
  Category('repair', 'Repair', Icons.construction),
  Category('insurance', 'Insurance', Icons.shield),
  Category('washing', 'Washing', Icons.local_car_wash),
  Category('accessories', 'Accessories', Icons.settings_input_component),
  Category('challan', 'Challan', Icons.receipt_long),
  Category('emi', 'EMI', Icons.payments),
];

const incomeCats = [
  Category('salary', 'Salary', Icons.account_balance_wallet),
  Category('business', 'Business', Icons.storefront),
  Category('freelance', 'Freelance', Icons.laptop_mac),
  Category('rent', 'Rent', Icons.home),
  Category('interest', 'Interest', Icons.trending_up),
  Category('investment', 'Investment Return', Icons.show_chart),
  Category('gift', 'Gift', Icons.card_giftcard),
  Category('others', 'Others', Icons.more_horiz, custom: true),
];

const savingsCats = [
  Category('cash', 'Cash', Icons.account_balance_wallet),
  Category('bank', 'Bank', Icons.account_balance),
  Category('fd', 'FD', Icons.account_balance),
  Category('rd', 'RD', Icons.account_balance),
  Category('sip', 'SIP', Icons.trending_up),
  Category('mutualfund', 'Mutual Fund', Icons.trending_up),
  Category('gold', 'Gold', Icons.inventory),
  Category('silver', 'Silver', Icons.inventory),
  Category('stocks', 'Stocks', Icons.show_chart),
  Category('emergency', 'Emergency Fund', Icons.shield),
];

const sectionLabels = {
  'home': 'Home Expenses',
  'personal': 'Personal Expenses',
  'vehicle': 'Vehicle Expenses',
  'income': 'Income',
  'savings': 'Savings',
};

const fuelKeys = ['petrol', 'diesel', 'cng'];

List<Category> catsFor(String section, String? vehicleType) {
  switch (section) {
    case 'home':
      return homeCats;
    case 'personal':
      return personalCats;
    case 'income':
      return incomeCats;
    case 'savings':
      return savingsCats;
    case 'vehicle':
      return vehicleType == 'car' ? carCats : bikeCats;
    default:
      return [];
  }
}

Category? findCat(String section, String? vehicleType, String key) {
  final list = catsFor(section, vehicleType);
  for (final c in list) {
    if (c.key == key) return c;
  }
  return null;
}

bool isExpenseSection(String s) => s == 'home' || s == 'personal' || s == 'vehicle';

/* ============================== DATA MODELS ============================== */

class Entry {
  String id;
  String section;
  String category;
  String? vehicleType;
  String date;
  double amount;
  double? quantity;
  double? rate;
  String? unitLabel;
  double? odometer;
  String notes;
  String customLabel;
  int createdAt;

  Entry({
    required this.id,
    required this.section,
    required this.category,
    this.vehicleType,
    required this.date,
    required this.amount,
    this.quantity,
    this.rate,
    this.unitLabel,
    this.odometer,
    this.notes = '',
    this.customLabel = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section': section,
      'category': category,
      'vehicleType': vehicleType,
      'date': date,
      'amount': amount,
      'quantity': quantity,
      'rate': rate,
      'unitLabel': unitLabel,
      'odometer': odometer,
      'notes': notes,
      'customLabel': customLabel,
      'createdAt': createdAt,
    };
  }

  factory Entry.fromJson(Map<String, dynamic> j) {
    return Entry(
      id: j['id'],
      section: j['section'],
      category: j['category'],
      vehicleType: j['vehicleType'],
      date: j['date'],
      amount: (j['amount'] as num).toDouble(),
      quantity: j['quantity'] == null ? null : (j['quantity'] as num).toDouble(),
      rate: j['rate'] == null ? null : (j['rate'] as num).toDouble(),
      unitLabel: j['unitLabel'],
      odometer: j['odometer'] == null ? null : (j['odometer'] as num).toDouble(),
      notes: j['notes'] ?? '',
      customLabel: j['customLabel'] ?? '',
      createdAt: j['createdAt'] ?? 0,
    );
  }

  String label() {
    final cat = findCat(section, vehicleType, category);
    final base = cat?.label ?? category;
    return customLabel.isNotEmpty ? '$base: $customLabel' : base;
  }
}

class Reminder {
  String id;
  String title;
  String dueDate;
  bool recurring;
  bool done;

  Reminder({
    required this.id,
    required this.title,
    required this.dueDate,
    this.recurring = false,
    this.done = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate,
      'recurring': recurring,
      'done': done,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> j) {
    return Reminder(
      id: j['id'],
      title: j['title'],
      dueDate: j['dueDate'],
      recurring: j['recurring'] ?? false,
      done: j['done'] ?? false,
    );
  }
}

/* ============================== HELPERS ============================== */

String todayISO() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String monthKeyOf(String iso) => iso.length >= 7 ? iso.substring(0, 7) : '';
String fmtRs(num n) => '\u20B9' + NumberFormat('#,##,##0.##', 'en_IN').format(n);
String fmtNum(double? n) => n == null ? '\u2014' : NumberFormat('#,##,##0.##', 'en_IN').format(n);

const goldColor = Color(0xFFE3BE6C);
const goldDeep = Color(0xFFC9962F);
const bgDark = Color(0xFF0A1815);
const cardDark = Color(0xFF132923);
const heroDark2 = Color(0xFF1B4438);
const expenseColor = Color(0xFFE2876A);
const incomeColor = Color(0xFF7FC9A0);
const savingsColor = Color(0xFF7FB8D9);

List<Map<String, dynamic>> computeFuelLog(List<Entry> entries, String vehicleType) {
  final fuel = entries.where((e) {
    return e.section == 'vehicle' &&
        e.vehicleType == vehicleType &&
        fuelKeys.contains(e.category) &&
        e.odometer != null;
  }).toList();

  fuel.sort((a, b) => a.odometer!.compareTo(b.odometer!));

  final result = <Map<String, dynamic>>[];
  for (int i = 0; i < fuel.length; i++) {
    final e = fuel[i];
    if (i == 0) {
      result.add({'entry': e, 'distance': null, 'costPerKm': null, 'kmpl': null});
      continue;
    }
    final prev = fuel[i - 1];
    final distance = e.odometer! - prev.odometer!;
    final costPerKm = distance > 0 ? e.amount / distance : null;
    final kmpl = (distance > 0 && e.quantity != null && e.quantity! > 0) ? distance / e.quantity! : null;
    result.add({'entry': e, 'distance': distance, 'costPerKm': costPerKm, 'kmpl': kmpl});
  }
  return result;
}

/* ============================== APP ROOT ============================== */

class KharchaApp extends StatefulWidget {
  const KharchaApp({super.key});

  @override
  State<KharchaApp> createState() => _KharchaAppState();
}

class _KharchaAppState extends State<KharchaApp> {
  bool dark = true;
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
  String? pin;
  bool locked = false;
  bool docLoaded = false;

  StreamSubscription<User?>? authSub;
  StreamSubscription<DocumentSnapshot>? docSub;
  String? currentUid;

  @override
  void initState() {
    super.initState();
    authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    docSub?.cancel();
    docSub = null;

    if (user == null) {
      setState(() {
        currentUid = null;
        docLoaded = false;
        entries = [];
        reminders = [];
        milkLeaves = {};
        milkLitresPerDay = 1.0;
        milkPricePerLitre = 60.0;
        dark = true;
        pin = null;
        budgets = {'home': 0, 'personal': 0, 'vehicle': 0};
      });
      return;
    }

    currentUid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    docSub = docRef.snapshots().listen((snap) async {
      if (!snap.exists) {
        await docRef.set({
          'entries': [],
          'reminders': [],
          'milkLeaves': [],
          'milkSettings': {'litresPerDay': 1.0, 'pricePerLitre': 60.0},
          'settings': {'dark': true, 'pin': null, 'budgets': {'home': 0, 'personal': 0, 'vehicle': 0}},
        });
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      final entriesRaw = (data['entries'] as List? ?? []);
      final remindersRaw = (data['reminders'] as List? ?? []);
      final milkLeavesRaw = (data['milkLeaves'] as List? ?? []);
      final milkSettingsRaw = (data['milkSettings'] as Map<String, dynamic>? ?? {});
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

      setState(() {
        entries = entriesRaw.map((e) => Entry.fromJson(Map<String, dynamic>.from(e))).toList();
        reminders = remindersRaw.map((r) => Reminder.fromJson(Map<String, dynamic>.from(r))).toList();
        milkLeaves = parsedLeaves;
        milkLitresPerDay = (milkSettingsRaw['litresPerDay'] as num?)?.toDouble() ?? 1.0;
        milkPricePerLitre = (milkSettingsRaw['pricePerLitre'] as num?)?.toDouble() ?? 60.0;
        dark = settingsRaw['dark'] ?? true;
        pin = settingsRaw['pin'];
        if (settingsRaw['budgets'] != null) {
          final rawBudgets = settingsRaw['budgets'] as Map;
          budgets = rawBudgets.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
        }
        docLoaded = true;
      });
    });
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
    await _docRef?.update({'settings': {'dark': dark, 'pin': pin, 'budgets': budgets}});
  }

  Future<void> _pushMilk() async {
    await _docRef?.update({
      'milkLeaves': milkLeaves.entries.map((e) => {'date': e.key, 'reason': e.value}).toList(),
      'milkSettings': {'litresPerDay': milkLitresPerDay, 'pricePerLitre': milkPricePerLitre},
    });
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
  }

  void toggleReminder(String id) {
    setState(() {
      final r = reminders.firstWhere((r) => r.id == id);
      r.done = !r.done;
    });
    _pushReminders();
  }

  void deleteReminder(String id) {
    setState(() => reminders.removeWhere((r) => r.id == id));
    _pushReminders();
  }

  void updateSettings({bool? dark, String? pin, bool clearPin = false, Map<String, double>? budgets}) {
    setState(() {
      if (dark != null) this.dark = dark;
      if (clearPin) this.pin = null;
      if (pin != null) this.pin = pin;
      if (budgets != null) this.budgets = budgets;
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
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    authSub?.cancel();
    docSub?.cancel();
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
            pin: pin,
            milkLeaves: milkLeaves,
            milkLitresPerDay: milkLitresPerDay,
            milkPricePerLitre: milkPricePerLitre,
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
          );
        },
      ),
    );
  }
}

/* ============================== AUTH SCREEN ============================== */

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  bool isSignup = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => error = 'Email aur password dono bharo');
      return;
    }
    if (isSignup && (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || dobCtrl.text.trim().isEmpty)) {
      setState(() => error = 'Naam, phone number aur date of birth bhi bharo');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (isSignup) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        await cred.user?.updateDisplayName(nameCtrl.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'profile': {
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'dob': dobCtrl.text.trim(),
            'email': email,
          },
        }, SetOptions(merge: true));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Kuch galat ho gaya';
      if (e.code == 'user-not-found') msg = 'Ye email registered nahi hai. Sign up karo.';
      if (e.code == 'wrong-password') msg = 'Galat password.';
      if (e.code == 'email-already-in-use') msg = 'Ye email pehle se registered hai. Login karo.';
      if (e.code == 'weak-password') msg = 'Password kam se kam 6 characters ka rakho.';
      if (e.code == 'invalid-email') msg = 'Email sahi format mein daalo.';
      setState(() => error = msg);
    } catch (e) {
      setState(() => error = 'Kuch galat ho gaya. Dobara try karo.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -1.0),
            radius: 1.6,
            colors: [heroDark2, bgDark],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF0CE85), goldDeep]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: goldColor.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  isSignup ? 'Naya Account Banao' : 'Login karo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isSignup
                      ? '$appName mein register karo apna data hamesha ke liye sync rakhne ke liye.'
                      : 'Login karke apna data kisi bhi device par sync kar sakte ho.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
                const SizedBox(height: 28),
                if (isSignup) ...[
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Poora Naam'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Date of Birth').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => dobCtrl.text = DateFormat('dd MMM yyyy').format(picked));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Phone Number'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: fieldDecoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: fieldDecoration('Password'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!, style: const TextStyle(color: expenseColor, fontSize: 13)),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loading ? 'Please wait...' : (isSignup ? 'Sign Up' : 'Login')),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => setState(() => isSignup = !isSignup),
                  child: Text(
                    isSignup ? 'Already an account hai? Login karo' : 'Naya user ho? Sign up karo',
                    style: const TextStyle(color: goldColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== LOCK SCREEN ============================== */

class LockScreen extends StatefulWidget {
  final String pin;
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.pin, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final ctrl = TextEditingController();
  bool err = false;

  void submit() {
    if (ctrl.text == widget.pin) {
      widget.onUnlock();
    } else {
      setState(() => err = true);
      ctrl.clear();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => err = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.lock, color: Colors.black87, size: 26),
            ),
            const SizedBox(height: 18),
            const Text('Enter PIN', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 26),
            SizedBox(
              width: 160,
              child: TextField(
                controller: ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: err ? expenseColor : Colors.white24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: goldColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => submit(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
              child: const Text('Unlock'),
            ),
            if (err)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Incorrect PIN', style: TextStyle(color: expenseColor)),
              ),
          ],
        ),
      ),
    );
  }
}

/* ============================== HOME SHELL ============================== */

class HomeShell extends StatefulWidget {
  final String userEmail;
  final String userName;
  final List<Entry> entries;
  final List<Reminder> reminders;
  final Map<String, double> budgets;
  final bool dark;
  final String? pin;
  final Map<String, String> milkLeaves;
  final double milkLitresPerDay;
  final double milkPricePerLitre;
  final void Function(Entry) onAddEntry;
  final void Function(Entry) onUpdateEntry;
  final void Function(String) onDeleteEntry;
  final void Function(Reminder) onAddReminder;
  final void Function(String) onToggleReminder;
  final void Function(String) onDeleteReminder;
  final void Function({bool? dark, String? pin, bool clearPin, Map<String, double>? budgets}) onUpdateSettings;
  final void Function(List<Entry>, List<Reminder>) onRestore;
  final VoidCallback onLock;
  final Future<void> Function() onSignOut;
  final void Function(String, String) onAddMilkLeave;
  final void Function(String) onRemoveMilkLeave;
  final void Function({double? litresPerDay, double? pricePerLitre}) onUpdateMilkSettings;

  const HomeShell({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.entries,
    required this.reminders,
    required this.budgets,
    required this.dark,
    required this.pin,
    required this.milkLeaves,
    required this.milkLitresPerDay,
    required this.milkPricePerLitre,
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
          onSave: (e) {
            if (existing != null) {
              widget.onUpdateEntry(e);
            } else {
              widget.onAddEntry(e);
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
          content: const Text('Aap is device se sign out ho jaoge. Dubara login karke data phir se aa jayega.'),
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
      ),
      AddTab(onPick: openEntrySheet, entries: widget.entries, onEditEntry: openEditEntry),
      CalendarTab(
        entries: widget.entries,
        onDelete: widget.onDeleteEntry,
        onAdd: showCategoryPickerForDate,
        onEdit: openEditEntry,
      ),
      AnalyticsTab(entries: widget.entries),
      SearchTab(entries: widget.entries, onDelete: widget.onDeleteEntry, onEdit: openEditEntry),
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
                  'Main $appName use kar raha/rahi hoon apna roz ka kharcha, milk hisaab aur gaadi ki costing track karne ke liye. Aap bhi try karo!',
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

/* ============================== MILK SCREEN ============================== */

class MilkScreen extends StatefulWidget {
  final Map<String, String> milkLeaves;
  final double litresPerDay;
  final double pricePerLitre;
  final void Function(String date, String reason) onAddLeave;
  final void Function(String date) onRemoveLeave;
  final void Function({double? litresPerDay, double? pricePerLitre}) onUpdateSettings;
  final void Function(Entry) onRecordPayment;
  final void Function(Reminder) onAddReminder;

  const MilkScreen({
    super.key,
    required this.milkLeaves,
    required this.litresPerDay,
    required this.pricePerLitre,
    required this.onAddLeave,
    required this.onRemoveLeave,
    required this.onUpdateSettings,
    required this.onRecordPayment,
    required this.onAddReminder,
  });

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  late TextEditingController litresCtrl;
  late TextEditingController rateCtrl;
  late Map<String, String> localLeaves;

  @override
  void initState() {
    super.initState();
    litresCtrl = TextEditingController(text: widget.litresPerDay.toString());
    rateCtrl = TextEditingController(text: widget.pricePerLitre.toString());
    localLeaves = Map<String, String>.from(widget.milkLeaves);
  }

  Future<void> handleDayTap(String iso, bool isFuture) async {
    if (isFuture) return;

    if (localLeaves.containsKey(iso)) {
      final reasonCtrl = TextEditingController(text: localLeaves[iso] ?? '');
      final action = await showDialog<String>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Leave: $iso'),
            content: TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
              maxLines: 2,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, 'remove'), child: const Text('Leave Hatao')),
              TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Band Karo')),
              TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
            ],
          );
        },
      );
      if (action == 'remove') {
        setState(() => localLeaves.remove(iso));
        widget.onRemoveLeave(iso);
      } else if (action == 'save') {
        setState(() => localLeaves[iso] = reasonCtrl.text.trim());
        widget.onAddLeave(iso, reasonCtrl.text.trim());
      }
      return;
    }

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Leave mark karo: $iso'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)', hintText: 'e.g. Ghoomne gaye the'),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Leave')),
          ],
        );
      },
    );
    if (confirmed == true) {
      setState(() => localLeaves[iso] = reasonCtrl.text.trim());
      widget.onAddLeave(iso, reasonCtrl.text.trim());
    }
  }

  Widget statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget calcCard(String title, String rangeLabel, int totalDays, int leaves, double litres, double amount, {bool isFinal = false}) {
    final delivered = totalDays - leaves;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(rangeLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),
            statRow('Total din', '$totalDays'),
            statRow('Leaves (milk nahi aaya)', '$leaves'),
            statRow('Milk delivered din', '$delivered'),
            statRow('Total litre', litres.toStringAsFixed(1)),
            statRow('Rate', '\u20b9${widget.pricePerLitre.toStringAsFixed(2)} / litre'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmtRs(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 18)),
                ],
              ),
            ),
            if (isFinal) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        final entry = Entry(
                          id: uuid.v4(),
                          section: 'home',
                          category: 'milk',
                          date: DateFormat('yyyy-MM-dd').format(lastDay),
                          amount: amount,
                          quantity: litres,
                          rate: widget.pricePerLitre,
                          unitLabel: 'Litre',
                          notes: '$delivered/$totalDays din delivered, $leaves leaves ($rangeLabel)',
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        widget.onRecordPayment(entry);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment record ho gaya')));
                      },
                      child: const Text('Payment Record Karo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final lastDay = DateTime(cursor.year, cursor.month + 1, 0);
                        widget.onAddReminder(
                          Reminder(
                            id: uuid.v4(),
                            title: 'Milk Payment - ${DateFormat('MMMM yyyy').format(cursor)}',
                            dueDate: DateFormat('yyyy-MM-dd').format(lastDay),
                            recurring: true,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder lag gaya')));
                      },
                      child: const Text('Reminder Lagao'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final monthKey = DateFormat('yyyy-MM').format(cursor);
    final now = DateTime.now();
    final isCurrentMonth = cursor.year == now.year && cursor.month == now.month;

    final leavesThisMonth = localLeaves.keys.where((d) => d.startsWith(monthKey)).length;
    final totalLitres = (daysInMonth - leavesThisMonth) * widget.litresPerDay;
    final finalAmount = totalLitres * widget.pricePerLitre;

    final firstDay = DateTime(cursor.year, cursor.month, 1);
    final lastDay = DateTime(cursor.year, cursor.month, daysInMonth);
    final rangeLabel = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(lastDay)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Milk Tracker')),
      body: ListView(
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
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1)),
                      ),
                      Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Jis din milk NAHI aaya, us date par tap karo. Dobara tap karke note dekh/edit kar sakte ho.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
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
                      final isLeave = localLeaves.containsKey(iso);
                      final isFuture = dateObj.isAfter(DateTime(now.year, now.month, now.day));
                      final isToday = iso == todayISO();

                      Color bg;
                      Color? textColor;
                      if (isFuture) {
                        bg = Colors.grey.withOpacity(0.08);
                        textColor = Colors.grey;
                      } else if (isLeave) {
                        bg = expenseColor.withOpacity(0.85);
                        textColor = Colors.white;
                      } else {
                        bg = incomeColor.withOpacity(0.25);
                        textColor = null;
                      }

                      return InkWell(
                        onTap: isFuture ? null : () => handleDayTap(iso, isFuture),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday ? Border.all(color: goldColor, width: 1.5) : null,
                          ),
                          child: Center(
                            child: Text('$day', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      legendDot(incomeColor.withOpacity(0.4), 'Milk aaya'),
                      legendDot(expenseColor, 'Leave'),
                      legendDot(Colors.grey.withOpacity(0.3), 'Aane wali date'),
                    ],
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
                  const Text('Rate Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: litresCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Litre / din'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '\u20b9 / Litre'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onUpdateSettings(
                          litresPerDay: double.tryParse(litresCtrl.text) ?? widget.litresPerDay,
                          pricePerLitre: double.tryParse(rateCtrl.text) ?? widget.pricePerLitre,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate save ho gaya')));
                      },
                      child: const Text('Rate Save Karo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentMonth) ...[
            Builder(builder: (_) {
              final todayDay = now.day;
              final leavesTillToday = localLeaves.keys.where((d) {
                if (!d.startsWith(monthKey)) return false;
                final dayNum = int.tryParse(d.split('-').last) ?? 0;
                return dayNum <= todayDay;
              }).length;
              final litresTillToday = (todayDay - leavesTillToday) * widget.litresPerDay;
              final amountTillToday = litresTillToday * widget.pricePerLitre;
              final rangeTillToday = '${DateFormat('d MMM').format(firstDay)} - ${DateFormat('d MMM yyyy').format(now)}';
              return calcCard('Abhi Tak Ka Hisaab', rangeTillToday, todayDay, leavesTillToday, litresTillToday, amountTillToday);
            }),
          ],
          calcCard('Poore Mahine Ka Hisaab', rangeLabel, daysInMonth, leavesThisMonth, totalLitres, finalAmount, isFinal: true),
        ],
      ),
    );
  }

  Widget legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/* ============================== CATEGORY ENTRIES SCREEN ============================== */

class CategoryEntriesScreen extends StatelessWidget {
  final String title;
  final List<Entry> entries;
  final void Function(Entry)? onEdit;

  const CategoryEntriesScreen({super.key, required this.title, required this.entries, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    final total = sorted.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${sorted.length} entries', style: const TextStyle(color: Colors.grey)),
                Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('Koi entry nahi hai.'))
                : ListView(
                    children: sorted.map((e) {
                      return EntryTile(entry: e, onDelete: () {}, onEdit: onEdit == null ? null : () => onEdit!(e));
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

/* ============================== ADD TAB ============================== */

class AddTab extends StatefulWidget {
  final void Function(String, Category, String?, {String? date}) onPick;
  final List<Entry> entries;
  final void Function(Entry) onEditEntry;

  const AddTab({super.key, required this.onPick, required this.entries, required this.onEditEntry});

  @override
  State<AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<AddTab> {
  String section = 'home';
  String vehicleType = 'bike';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: sectionLabels.keys.map((s) {
                final selected = s == section;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(sectionLabels[s]!),
                    selected: selected,
                    onSelected: (_) => setState(() => section = s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (section == 'vehicle')
            Row(
              children: ['bike', 'car'].map((v) {
                final selected = v == vehicleType;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => vehicleType = v),
                      icon: Icon(v == 'bike' ? Icons.motorcycle : Icons.directions_car),
                      label: Text(v[0].toUpperCase() + v.substring(1)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected ? goldColor.withOpacity(0.2) : null,
                        side: BorderSide(color: selected ? goldColor : Colors.grey.shade400),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: catsFor(section, vehicleType).map((c) {
              final catEntries = widget.entries.where((e) {
                if (e.section != section || e.category != c.key) return false;
                if (section == 'vehicle' && e.vehicleType != vehicleType) return false;
                return true;
              }).toList();

              return Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onPick(section, c, section == 'vehicle' ? vehicleType : null),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: goldColor.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(c.icon, color: goldColor, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (catEntries.isNotEmpty)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryEntriesScreen(title: c.label, entries: catEntries, onEdit: widget.onEditEntry),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: goldColor, shape: BoxShape.circle),
                          child: Text(
                            '${catEntries.length}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CategoryPickerSheet extends StatelessWidget {
  final void Function(String, Category, String?) onPick;

  const CategoryPickerSheet({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: AddTabPicker(onPick: onPick),
          ),
        );
      },
    );
  }
}

class AddTabPicker extends StatefulWidget {
  final void Function(String, Category, String?) onPick;

  const AddTabPicker({super.key, required this.onPick});

  @override
  State<AddTabPicker> createState() => _AddTabPickerState();
}

class _AddTabPickerState extends State<AddTabPicker> {
  String section = 'home';
  String vehicleType = 'bike';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: sectionLabels.keys.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(sectionLabels[s]!),
                  selected: s == section,
                  onSelected: (_) => setState(() => section = s),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (section == 'vehicle')
          Row(
            children: ['bike', 'car'].map((v) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => setState(() => vehicleType = v),
                    child: Text(v),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: catsFor(section, vehicleType).map((c) {
            return InkWell(
              onTap: () => widget.onPick(section, c, section == 'vehicle' ? vehicleType : null),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, color: goldColor),
                    const SizedBox(height: 6),
                    Text(
                      c.label,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/* ============================== ENTRY SHEET ============================== */

class EntrySheet extends StatefulWidget {
  final String section;
  final Category category;
  final String? vehicleType;
  final String date;
  final Entry? existing;
  final void Function(Entry) onSave;

  const EntrySheet({
    super.key,
    required this.section,
    required this.category,
    this.vehicleType,
    required this.date,
    this.existing,
    required this.onSave,
  });

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  late String date;
  final amountCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final rateCtrl = TextEditingController();
  final odoCtrl = TextEditingController();
  final customCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? err;
  bool saving = false;
  String lastEdited = 'qty';

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    date = ex?.date ?? widget.date;
    if (ex != null) {
      if (widget.category.qty) {
        qtyCtrl.text = ex.quantity?.toString() ?? '1';
        rateCtrl.text = ex.rate?.toString() ?? '';
      }
      amountCtrl.text = ex.amount.toString();
      odoCtrl.text = ex.odometer?.toString() ?? '';
      notesCtrl.text = ex.notes;
      customCtrl.text = ex.customLabel;
    } else if (widget.category.qty) {
      amountCtrl.text = '';
    }
  }

  void recompute() {
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    final amt = double.tryParse(amountCtrl.text) ?? 0;

    if (lastEdited == 'amount') {
      if (qty > 0) {
        rateCtrl.text = (amt / qty).toStringAsFixed(2);
      } else if (rate > 0) {
        qtyCtrl.text = (amt / rate).toStringAsFixed(2);
      }
    } else {
      amountCtrl.text = (qty * rate).toStringAsFixed(2);
    }
  }

  double get computedAmount {
    if (!widget.category.qty) {
      return double.tryParse(amountCtrl.text) ?? 0;
    }
    return double.tryParse(amountCtrl.text) ?? 0;
  }

  Future<void> save() async {
    final amt = computedAmount;
    if (amt <= 0) {
      setState(() => err = 'Please enter a valid amount');
      return;
    }
    if (widget.category.custom && customCtrl.text.trim().isEmpty) {
      setState(() => err = 'Please name this category');
      return;
    }
    if (widget.category.trackOdo && double.tryParse(odoCtrl.text) == null) {
      setState(() => err = 'Please enter the odometer reading (km)');
      return;
    }

    setState(() {
      err = null;
      saving = true;
    });

    final e = Entry(
      id: widget.existing?.id ?? uuid.v4(),
      section: widget.section,
      category: widget.category.key,
      vehicleType: widget.vehicleType,
      date: date,
      amount: amt,
      quantity: widget.category.qty ? double.tryParse(qtyCtrl.text) : null,
      rate: widget.category.qty ? double.tryParse(rateCtrl.text) : null,
      unitLabel: widget.category.unitLabel,
      odometer: widget.category.trackOdo ? double.tryParse(odoCtrl.text) : null,
      notes: notesCtrl.text.trim(),
      customLabel: widget.category.custom ? customCtrl.text.trim() : '',
      createdAt: widget.existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    await Future.delayed(const Duration(milliseconds: 150));
    widget.onSave(e);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.category.icon, color: goldColor, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit: ${widget.category.label}' : widget.category.label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.category.custom)
                TextField(
                  controller: customCtrl,
                  decoration: const InputDecoration(labelText: 'Category name'),
                ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: date),
                decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => date = DateFormat('yyyy-MM-dd').format(picked));
                  }
                },
              ),
              const SizedBox(height: 10),
              if (widget.category.qty) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Quantity (${widget.category.unitLabel})'),
                        onChanged: (_) => setState(() {
                          lastEdited = 'qty';
                          recompute();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Price / ${widget.category.unitLabel}'),
                        onChanged: (_) => setState(() {
                          lastEdited = 'rate';
                          recompute();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Amount (editable)', prefixText: '\u20B9 '),
                  onChanged: (_) => setState(() {
                    lastEdited = 'amount';
                    recompute();
                  }),
                ),
              ] else
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '\u20B9 '),
                  onChanged: (_) => setState(() {}),
                ),
              if (widget.category.trackOdo)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Odometer reading (km) at this fill-up',
                      prefixIcon: Icon(Icons.speed),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(err!, style: const TextStyle(color: expenseColor)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving ? null : save,
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
                  child: Text(saving ? (isEditing ? 'Updating...' : 'Saving...') : (isEditing ? 'Update Entry' : 'Save Entry')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== DASHBOARD TAB ============================== */

class DashboardTab extends StatelessWidget {
  final List<Entry> entries;
  final Map<String, double> budgets;
  final List<Reminder> reminders;
  final Map<String, String> milkLeaves;
  final double milkLitresPerDay;
  final double milkPricePerLitre;
  final void Function(Entry) onEditEntry;

  const DashboardTab({
    super.key,
    required this.entries,
    required this.budgets,
    required this.reminders,
    required this.milkLeaves,
    required this.milkLitresPerDay,
    required this.milkPricePerLitre,
    required this.onEditEntry,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final today = todayISO();

    double sum(bool Function(Entry) f) {
      return entries.where(f).fold(0.0, (s, e) => s + e.amount);
    }

    final milkRecordedThisMonth = entries.any((e) => e.category == 'milk' && monthKeyOf(e.date) == thisMonth);
    final todayDay = now.day;
    final leavesTillToday = milkLeaves.keys.where((d) {
      if (!d.startsWith(thisMonth)) return false;
      final dayNum = int.tryParse(d.split('-').last) ?? 0;
      return dayNum <= todayDay;
    }).length;
    final milkAccruedToday = milkRecordedThisMonth
        ? 0.0
        : (!milkLeaves.containsKey(today) ? milkLitresPerDay * milkPricePerLitre : 0.0);
    final milkAccruedMonth = milkRecordedThisMonth ? 0.0 : (todayDay - leavesTillToday) * milkLitresPerDay * milkPricePerLitre;

    final todayExpense = sum((e) => isExpenseSection(e.section) && e.date == today) + milkAccruedToday;
    final monthExpense = sum((e) => isExpenseSection(e.section) && monthKeyOf(e.date) == thisMonth) + milkAccruedMonth;
    final monthIncome = sum((e) => e.section == 'income' && monthKeyOf(e.date) == thisMonth);
    final totalIncome = sum((e) => e.section == 'income');
    final totalExpense = sum((e) => isExpenseSection(e.section)) + milkAccruedMonth;
    final totalSavings = sum((e) => e.section == 'savings');
    final remaining = totalIncome - totalExpense - totalSavings;

    final bySection = {
      'home': sum((e) => e.section == 'home' && monthKeyOf(e.date) == thisMonth) + milkAccruedMonth,
      'personal': sum((e) => e.section == 'personal' && monthKeyOf(e.date) == thisMonth),
      'vehicle': sum((e) => e.section == 'vehicle' && monthKeyOf(e.date) == thisMonth),
    };

    void openSection(String k) {
      final filtered = entries.where((e) => e.section == k).toList();
      if (k == 'home' && !milkRecordedThisMonth) {
        for (int d = 1; d <= todayDay; d++) {
          final iso = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, d));
          if (!milkLeaves.containsKey(iso)) {
            filtered.add(Entry(
              id: 'milk-auto-$iso',
              section: 'home',
              category: 'milk',
              date: iso,
              amount: milkLitresPerDay * milkPricePerLitre,
              quantity: milkLitresPerDay,
              rate: milkPricePerLitre,
              unitLabel: 'Litre',
              notes: 'Auto (daily milk, abhi tak record nahi hua)',
              createdAt: 0,
            ));
          }
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryEntriesScreen(title: sectionLabels[k]!, entries: filtered, onEdit: onEditEntry),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [heroDark2, bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: goldColor.withOpacity(0.18)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REMAINING BALANCE',
                    style: TextStyle(color: goldColor, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.bold),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(logoAsset, width: 28, height: 28, errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fmtRs(remaining),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              Container(margin: const EdgeInsets.symmetric(vertical: 16), height: 1, color: Colors.white.withOpacity(0.12)),
              Row(
                children: [
                  const Text('Savings ', style: TextStyle(color: Colors.white70)),
                  Text(fmtRs(totalSavings), style: const TextStyle(color: savingsColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  const Text('Income(M) ', style: TextStyle(color: Colors.white70)),
                  Text(fmtRs(monthIncome), style: const TextStyle(color: incomeColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            statCard('Today', todayExpense, expenseColor),
            statCard('This Month (1 - Aaj)', monthExpense, expenseColor),
            statCard('Income (Month)', monthIncome, incomeColor),
            statCard('Total Savings', totalSavings, savingsColor),
          ],
        ),
        const SizedBox(height: 20),
        const Text('This Month by Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('(tap karke entries dekho)', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        ...['home', 'personal', 'vehicle'].map((k) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => openSection(k),
              child: ListTile(
                leading: Icon(
                  k == 'home' ? Icons.home : (k == 'personal' ? Icons.person : Icons.directions_car),
                  color: goldColor,
                ),
                title: Text(sectionLabels[k]!),
                subtitle: (budgets[k] ?? 0) > 0
                    ? LinearProgressIndicator(
                        value: (bySection[k]! / budgets[k]!).clamp(0, 1),
                        color: bySection[k]! > budgets[k]! ? expenseColor : goldColor,
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fmtRs(bySection[k]!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: expenseColor),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget statCard(String label, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(fmtRs(value), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/* ============================== CALENDAR TAB ============================== */

class CalendarTab extends StatefulWidget {
  final List<Entry> entries;
  final void Function(String) onDelete;
  final void Function(String) onAdd;
  final void Function(Entry) onEdit;

  const CalendarTab({super.key, required this.entries, required this.onDelete, required this.onAdd, required this.onEdit});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month);
  String selectedDate = todayISO();

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7;

    final dayEntries = widget.entries.where((e) => e.date == selectedDate).toList();
    dayEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month - 1)),
              ),
              Text(DateFormat('MMMM yyyy').format(cursor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => cursor = DateTime(cursor.year, cursor.month + 1)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final iso = DateFormat('yyyy-MM-dd').format(DateTime(cursor.year, cursor.month, day));
              final selected = iso == selectedDate;
              final hasEntries = widget.entries.any((e) => e.date == iso);
              return InkWell(
                onTap: () => setState(() => selectedDate = iso),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? goldColor : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      if (hasEntries)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : expenseColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => widget.onAdd(selectedDate),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayEntries.isEmpty
              ? const Center(child: Text('No entries for this date.'))
              : ListView(
                  children: dayEntries.map((e) {
                    return EntryTile(entry: e, onDelete: () => widget.onDelete(e.id), onEdit: () => widget.onEdit(e));
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const EntryTile({super.key, required this.entry, required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cat = findCat(entry.section, entry.vehicleType, entry.category);
    final color = isExpenseSection(entry.section)
        ? expenseColor
        : (entry.section == 'income' ? incomeColor : savingsColor);

    String sub = entry.date;
    sub += ' \u00b7 ${sectionLabels[entry.section]!}';
    if (entry.vehicleType != null) sub += ' \u00b7 ${entry.vehicleType}';
    if (entry.quantity != null) {
      final unit = entry.unitLabel == 'Litre' ? 'L' : (entry.unitLabel ?? '');
      sub += ' \u00b7 ${entry.quantity}$unit';
    }
    if (entry.odometer != null) sub += ' \u00b7 ${fmtNum(entry.odometer)} km';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        child: ListTile(
          leading: Icon(cat?.icon ?? Icons.more_horiz, color: color),
          title: Text(entry.label(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 11.5)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fmtRs(entry.amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== ANALYTICS TAB ============================== */

class AnalyticsTab extends StatelessWidget {
  final List<Entry> entries;

  const AnalyticsTab({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);

    final catMap = <String, double>{};
    for (final e in entries) {
      if (isExpenseSection(e.section) && monthKeyOf(e.date) == thisMonth) {
        catMap[e.label()] = (catMap[e.label()] ?? 0) + e.amount;
      }
    }
    final catData = catMap.entries.toList();
    catData.sort((a, b) => b.value.compareTo(a.value));
    final top = catData.take(6).toList();

    final fuelLogBike = computeFuelLog(entries, 'bike');
    final fuelLogCar = computeFuelLog(entries, 'car');

    final vehicleMonthsSet = <String>{};
    for (final e in entries) {
      if (e.section == 'vehicle') vehicleMonthsSet.add(monthKeyOf(e.date));
    }
    final vehicleMonths = vehicleMonthsSet.toList()..sort();

    final allComputed = [...fuelLogBike, ...fuelLogCar];
    final monthlyVehicle = vehicleMonths.map((m) {
      double distance = 0;
      for (final f in allComputed) {
        final entry = f['entry'] as Entry;
        if (f['distance'] != null && monthKeyOf(entry.date) == m) {
          distance += f['distance'] as double;
        }
      }
      double fuelCost = 0;
      double totalCost = 0;
      for (final e in entries) {
        if (e.section == 'vehicle' && monthKeyOf(e.date) == m) {
          totalCost += e.amount;
          if (fuelKeys.contains(e.category)) fuelCost += e.amount;
        }
      }
      return {
        'month': m,
        'distance': distance,
        'fuelCost': fuelCost,
        'totalCost': totalCost,
        'fuelPerKm': distance > 0 ? fuelCost / distance : null,
        'overallPerKm': distance > 0 ? totalCost / distance : null,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fuelLogBike.isNotEmpty || fuelLogCar.isNotEmpty) ...[
          const Text('Fuel Fill-up Log (\u20b9/km & km/l)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (fuelLogBike.isNotEmpty) fuelTable('Bike', fuelLogBike),
          if (fuelLogCar.isNotEmpty) fuelTable('Car', fuelLogCar),
          const SizedBox(height: 20),
        ],
        if (monthlyVehicle.isNotEmpty) ...[
          const Text('Month-end Vehicle Costing (All Expenses)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...monthlyVehicle.map((m) => monthlyVehicleCard(m)),
          const SizedBox(height: 20),
        ],
        const Text('Category-wise (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (top.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Text('No expenses this month yet.'))
        else
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: List.generate(top.length, (i) {
                  final colors = [expenseColor, savingsColor, incomeColor, goldColor, Colors.purple, Colors.teal];
                  return PieChartSectionData(
                    value: top[i].value,
                    color: colors[i % colors.length],
                    title: top[i].key,
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget monthlyVehicleCard(Map<String, dynamic> m) {
    final month = m['month'] as String;
    final distance = m['distance'] as double;
    final fuelCost = m['fuelCost'] as double;
    final totalCost = m['totalCost'] as double;
    final overallPerKm = m['overallPerKm'] as double?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Distance: ${distance.toStringAsFixed(0)} km'),
            Text('Fuel cost: ${fmtRs(fuelCost)}'),
            Text('Total vehicle cost: ${fmtRs(totalCost)}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall \u20b9/km (fuel + all expenses)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    overallPerKm != null ? '\u20b9${overallPerKm.toStringAsFixed(2)}' : '\u2014',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fuelTable(String label, List<Map<String, dynamic>> log) {
    final rows = <TableRow>[
      const TableRow(
        children: [
          Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('Odo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('Km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('\u20b9/km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: goldColor)),
          Text('km/l', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: savingsColor)),
        ],
      ),
    ];

    for (final f in log) {
      final e = f['entry'] as Entry;
      final d = f['distance'] as double?;
      final cpk = f['costPerKm'] as double?;
      final kmpl = f['kmpl'] as double?;
      rows.add(
        TableRow(
          children: [
            Text(e.date, style: const TextStyle(fontSize: 11)),
            Text(fmtNum(e.odometer), style: const TextStyle(fontSize: 11)),
            Text(d != null ? d.toStringAsFixed(0) : '\u2014', style: const TextStyle(fontSize: 11)),
            Text(cpk != null ? '\u20b9${cpk.toStringAsFixed(2)}' : '\u2014', style: const TextStyle(fontSize: 11, color: goldColor)),
            Text(kmpl != null ? kmpl.toStringAsFixed(2) : '\u2014', style: const TextStyle(fontSize: 11, color: savingsColor)),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.2),
              },
              children: rows,
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== SEARCH TAB ============================== */

class SearchTab extends StatefulWidget {
  final List<Entry> entries;
  final void Function(String) onDelete;
  final void Function(Entry) onEdit;

  const SearchTab({super.key, required this.entries, required this.onDelete, required this.onEdit});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String query = '';
  String section = 'all';

  @override
  Widget build(BuildContext context) {
    final results = widget.entries.where((e) {
      if (section != 'all' && e.section != section) return false;
      if (query.isNotEmpty) {
        final hay = '${e.label()} ${e.notes}'.toLowerCase();
        if (!hay.contains(query.toLowerCase())) return false;
      }
      return true;
    }).toList();
    results.sort((a, b) => b.date.compareTo(a.date));

    final total = results.fold(0.0, (s, e) => s + e.amount);
    final sectionKeys = ['all', 'home', 'personal', 'vehicle', 'income', 'savings'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search notes or category',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: sectionKeys.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s == 'all' ? 'All' : sectionLabels[s]!),
                  selected: section == s,
                  onSelected: (_) => setState(() => section = s),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${results.length} results'),
              Text(fmtRs(total), style: const TextStyle(fontWeight: FontWeight.bold, color: goldColor)),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('No matching entries.'))
              : ListView(
                  children: results.map((e) {
                    return EntryTile(entry: e, onDelete: () => widget.onDelete(e.id), onEdit: () => widget.onEdit(e));
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

/* ============================== REMINDERS SCREEN ============================== */

class RemindersScreen extends StatefulWidget {
  final List<Reminder> reminders;
  final void Function(Reminder) onAdd;
  final void Function(String) onToggle;
  final void Function(String) onDelete;

  const RemindersScreen({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final titleCtrl = TextEditingController();
  String dueDate = todayISO();
  bool recurring = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.reminders];
    sorted.sort((a, b) => (a.done ? 1 : 0).compareTo(b.done ? 1 : 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title (e.g. Rent, Milk payment)'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(text: dueDate),
                          decoration: const InputDecoration(labelText: 'Due date'),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(dueDate),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => dueDate = DateFormat('yyyy-MM-dd').format(picked));
                            }
                          },
                        ),
                      ),
                      Checkbox(
                        value: recurring,
                        onChanged: (v) => setState(() => recurring = v ?? false),
                      ),
                      const Text('Monthly'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        widget.onAdd(
                          Reminder(id: uuid.v4(), title: titleCtrl.text.trim(), dueDate: dueDate, recurring: recurring),
                        );
                        titleCtrl.clear();
                      },
                      child: const Text('Add Reminder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No reminders yet.'))
                : ListView(
                    children: sorted.map((r) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(value: r.done, onChanged: (_) => widget.onToggle(r.id)),
                          title: Text(r.title, style: TextStyle(decoration: r.done ? TextDecoration.lineThrough : null)),
                          subtitle: Text('${r.dueDate}${r.recurring ? ' \u00b7 Monthly' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => widget.onDelete(r.id),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

/* ============================== EXPORT SCREEN ============================== */

class ExportScreen extends StatefulWidget {
  final List<Entry> entries;
  final List<Reminder> reminders;
  final void Function(List<Entry>, List<Reminder>) onRestore;

  const ExportScreen({
    super.key,
    required this.entries,
    required this.reminders,
    required this.onRestore,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String msg = '';

  Future<void> exportCSV() async {
    final header = ['Date', 'Section', 'Category', 'Vehicle', 'Quantity', 'Unit', 'Odometer', 'Amount', 'Notes'];
    final rows = widget.entries.map((e) {
      return [
        e.date,
        sectionLabels[e.section],
        e.label(),
        e.vehicleType ?? '',
        e.quantity ?? '',
        e.unitLabel ?? '',
        e.odometer ?? '',
        e.amount,
        e.notes.replaceAll('"', '""'),
      ];
    });

    final allRows = [header, ...rows];
    final csv = allRows.map((r) => r.map((v) => '"$v"').join(',')).join('\n');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_${todayISO()}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
    setState(() => msg = 'CSV shared.');
  }

  Future<void> exportBackup() async {
    final data = jsonEncode({
      'entries': widget.entries.map((e) => e.toJson()).toList(),
      'reminders': widget.reminders.map((r) => r.toJson()).toList(),
    });

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup_${todayISO()}.json');
    await file.writeAsString(data);
    await Share.shareXFiles([XFile(file.path)]);
    setState(() => msg = 'Backup shared.');
  }

  Future<void> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    try {
      final file = File(result.files.single.path!);
      final data = jsonDecode(await file.readAsString());
      final entries = (data['entries'] as List).map((e) => Entry.fromJson(e)).toList();
      final remindersRaw = data['reminders'] as List? ?? [];
      final reminders = remindersRaw.map((r) => Reminder.fromJson(r)).toList();
      widget.onRestore(entries, reminders);
      setState(() => msg = 'Backup restored successfully.');
    } catch (e) {
      setState(() => msg = 'Invalid backup file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export / Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.table_chart), title: const Text('Share as CSV'), onTap: exportCSV)),
          Card(child: ListTile(leading: const Icon(Icons.backup), title: const Text('Share Full Backup (.json)'), onTap: exportBackup)),
          Card(child: ListTile(leading: const Icon(Icons.restore), title: const Text('Restore from Backup'), onTap: restoreBackup)),
          if (msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: goldColor)),
            ),
          const SizedBox(height: 20),
          Text(
            '${widget.entries.length} entries recorded.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* ============================== SETTINGS SCREEN ============================== */

class SettingsScreen extends StatefulWidget {
  final bool dark;
  final Map<String, double> budgets;
  final String? pin;
  final void Function({bool? dark, String? pin, bool clearPin, Map<String, double>? budgets}) onUpdate;

  const SettingsScreen({
    super.key,
    required this.dark,
    required this.budgets,
    required this.pin,
    required this.onUpdate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, TextEditingController> budgetCtrls;
  final pinCtrl = TextEditingController();
  String msg = '';

  @override
  void initState() {
    super.initState();
    budgetCtrls = {};
    for (final k in ['home', 'personal', 'vehicle']) {
      budgetCtrls[k] = TextEditingController(text: (widget.budgets[k] ?? 0).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark theme'),
            value: widget.dark,
            onChanged: (v) => widget.onUpdate(dark: v),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.language, color: goldColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('App Language\n(jaldi aa raha hai — Hindi/English/regional)', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Monthly Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
          ...['home', 'personal', 'vehicle'].map((k) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: budgetCtrls[k],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: sectionLabels[k]),
              ),
            );
          }),
          ElevatedButton(
            onPressed: () {
              final newBudgets = <String, double>{};
              for (final k in budgetCtrls.keys) {
                newBudgets[k] = double.tryParse(budgetCtrls[k]!.text) ?? 0;
              }
              widget.onUpdate(budgets: newBudgets);
              setState(() => msg = 'Budgets saved.');
            },
            child: const Text('Save Budgets'),
          ),
          const Divider(height: 32),
          const Text('PIN Lock', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.pin != null)
            ElevatedButton(
              onPressed: () {
                widget.onUpdate(clearPin: true);
                setState(() => msg = 'PIN disabled.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: expenseColor),
              child: const Text('Disable PIN'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pinCtrl,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '4-digit PIN', counterText: ''),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!RegExp(r'^\d{4}$').hasMatch(pinCtrl.text)) {
                      setState(() => msg = 'PIN must be 4 digits.');
                      return;
                    }
                    widget.onUpdate(pin: pinCtrl.text);
                    setState(() => msg = 'PIN enabled.');
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          if (msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: goldColor)),
            ),
        ],
      ),
    );
  }
}

/* ============================== ABOUT & FEEDBACK ============================== */

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                logoAsset,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF0CE85), goldDeep]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text(appName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          const Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12.5))),
          const SizedBox(height: 20),
          const Text(
            'Kharcha Manager aapke roz ke kharche, milk ka hisaab, aur vehicle ki petrol/km costing ek hi jagah track karne ke liye banaya gaya hai. Aapka data surakshit taur par cloud mein sync hota hai, taaki aap kisi bhi device se login karke apna poora hisaab dekh sakein.',
            style: TextStyle(height: 1.5, fontSize: 13.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Developed by', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("HOUSE OF D'VISHA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldColor)),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "\u00a9 ${DateTime.now().year} HOUSE OF D'VISHA. All rights reserved.",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final msgCtrl = TextEditingController();
  String category = 'Suggestion';
  bool sending = false;
  bool sent = false;

  Future<void> submit() async {
    if (msgCtrl.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'message': msgCtrl.text.trim(),
        'category': category,
        'userEmail': user?.email ?? 'unknown',
        'userName': user?.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        sent = true;
        msgCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bhejne mein error aayi, dobara try karo.')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback / Suggestion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Apna suggestion ya problem seedha developer tak bhejo.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['Suggestion', 'Bug Report', 'Feature Request', 'Other'].map((c) {
              return ChoiceChip(
                label: Text(c),
                selected: category == c,
                onSelected: (_) => setState(() => category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: msgCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Apna message likho',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: sending ? null : submit,
              child: Text(sending ? 'Bhej rahe hain...' : 'Feedback Bhejo'),
            ),
          ),
          if (sent)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'Dhanyawad! Aapka feedback mil gaya.',
                style: TextStyle(color: incomeColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
