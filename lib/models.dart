import 'package:flutter/material.dart';

/* ============================== CATEGORY MODEL ============================== */

class Category {
  final String key;
  final String label;
  final IconData icon;
  final bool qty;
  final String? unitLabel;
  final bool trackOdo;
  final bool custom;
  final bool generated;

  const Category(
    this.key,
    this.label,
    this.icon, {
    this.qty = false,
    this.unitLabel,
    this.trackOdo = false,
    this.custom = false,
    this.generated = false,
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
  Category('others', 'Others', Icons.more_horiz, custom: true),
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
  Category('others', 'Others', Icons.more_horiz, custom: true),
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
  Category('others', 'Others', Icons.more_horiz, custom: true),
];

// User-created (permanent) categories — when a name is typed into "Others"
// for the first time, it's saved here and shown as a normal tile from then
// on. Loaded from Firestore at runtime (see KharchaApp._onAuthChanged).
List<Map<String, String>> globalCustomCategories = [];

String customSectionKey(String section, String? vehicleType) {
  if (section == 'vehicle') return 'vehicle_${vehicleType ?? 'bike'}';
  return section;
}

List<Category> customCatsFor(String sectionKey) {
  return globalCustomCategories
      .where((c) => c['sectionKey'] == sectionKey)
      .map((c) => Category(c['key']!, c['label']!, Icons.label, generated: true))
      .toList();
}

const fuelKeys = ['petrol', 'diesel', 'cng'];

List<Category> catsFor(String section, String? vehicleType) {
  List<Category> base;
  switch (section) {
    case 'home':
      base = homeCats;
      break;
    case 'personal':
      base = personalCats;
      break;
    case 'income':
      base = incomeCats;
      break;
    case 'savings':
      base = savingsCats;
      break;
    case 'vehicle':
      base = vehicleType == 'car' ? carCats : bikeCats;
      break;
    default:
      base = [];
  }
  final custom = customCatsFor(customSectionKey(section, vehicleType));
  if (custom.isEmpty) return base;
  final othersIndex = base.indexWhere((c) => c.key == 'others');
  if (othersIndex == -1) return [...base, ...custom];
  return [...base.sublist(0, othersIndex), ...custom, ...base.sublist(othersIndex)];
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
