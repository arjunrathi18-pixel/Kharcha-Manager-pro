import 'models.dart';

/* ============================== RESULT TYPES ============================== */

// What the scan screen hands back once the user has confirmed everything.
class ReceiptResult {
  final String section;
  final String categoryKey;
  final String? vehicleType;
  final String dateISO;
  final double amount;
  final String merchant;
  final double? quantity;

  const ReceiptResult({
    required this.section,
    required this.categoryKey,
    required this.vehicleType,
    required this.dateISO,
    required this.amount,
    required this.merchant,
    required this.quantity,
  });
}

// What the parser could work out from the OCR text. `confidence`:
//   2 = category matched strongly and clearly beats every alternative
//   1 = best guess — the user should verify it
//   0 = nothing convincing found — category is left empty on purpose
class ParsedReceipt {
  final double? amount;
  final bool amountConfident;
  final DateTime? date;
  final String merchant;
  final double? quantity;
  final String? section;
  final String? categoryKey;
  final String? vehicleType;
  final List<String> matched;
  final int confidence;

  const ParsedReceipt({
    required this.amount,
    required this.amountConfident,
    required this.date,
    required this.merchant,
    required this.quantity,
    required this.section,
    required this.categoryKey,
    required this.vehicleType,
    required this.matched,
    required this.confidence,
  });
}

/* ============================== CATEGORY RULES ============================== */
// Each rule maps a set of keywords to one (section, category). "strong"
// words (shop brands, unmistakable terms) are worth 3 points, "weak" words
// (items typically sold there) 1 point each, capped at 3. A strong word that
// also appears in the merchant name at the top of the receipt gets +2.

class _Rule {
  final String section;
  final String category;
  final List<String> strong;
  final List<String> weak;
  const _Rule(this.section, this.category, this.strong, [this.weak = const <String>[]]);
}

const List<_Rule> _rules = [
  // ---- Vehicle ----
  _Rule('vehicle', 'petrol', [
    'petrol', 'petroleum', 'fuel', 'indian oil', 'indianoil', 'iocl', 'bpcl', 'bharat petroleum',
    'hpcl', 'hindustan petroleum', 'nayara', 'reliance bp', 'jio bp', 'jio-bp', 'shell', 'speed 97',
    'xtra premium', 'power petrol', 'diesel', 'hsd', 'cng',
  ], ['pump', 'nozzle', 'dispenser', 'octane', 'density', 'vehicle no']),
  _Rule('vehicle', 'service', [
    'service center', 'service centre', 'workshop', 'garage', 'auto care', 'car care', 'bike service',
    'servicing', 'job card', 'engine oil', 'spare parts', 'mechanic', 'authorised service',
    'authorized service',
  ], ['labour', 'labor', 'oil change', 'filter', 'brake', 'clutch']),
  _Rule('vehicle', 'tyres', [
    'tyre', 'tyres', 'tire', 'tires', 'retread', 'wheel alignment', 'balancing',
  ]),
  _Rule('vehicle', 'pollution', [
    'puc', 'pollution under control', 'pollution check', 'emission test',
  ]),
  _Rule('vehicle', 'insurance', [
    'motor insurance', 'vehicle insurance', 'two wheeler insurance', 'car insurance', 'third party',
  ]),
  _Rule('vehicle', 'washing', [
    'car wash', 'bike wash', 'washing', 'detailing', 'polish',
  ]),
  _Rule('vehicle', 'challan', [
    'challan', 'traffic police', 'e-challan', 'traffic fine', 'fine amount',
  ]),
  _Rule('vehicle', 'accessories', [
    'accessories', 'helmet', 'seat cover', 'car mat',
  ], ['horn', 'mirror']),

  // ---- Home ----
  _Rule('home', 'milk', [
    'dairy', 'mother dairy', 'amul', 'doodh', 'milk booth', 'milk parlour', 'milk parlor', 'verka',
    'nandini milk', 'gowardhan',
  ], ['milk', 'curd', 'paneer', 'lassi']),
  _Rule('home', 'vegetables', [
    'vegetable', 'vegetables', 'sabzi', 'sabji', 'subzi', 'veg mart',
  ], ['onion', 'potato', 'tomato', 'brinjal', 'cauliflower', 'spinach', 'palak', 'bhindi', 'gobi']),
  _Rule('home', 'fruits', [
    'fruit', 'fruits', 'fruit shop', 'phal',
  ], ['apple', 'banana', 'mango', 'orange', 'grapes', 'papaya', 'pomegranate', 'watermelon', 'guava']),
  _Rule('home', 'grocery', [
    'supermarket', 'super market', 'dmart', 'd-mart', 'avenue supermarts', 'big bazaar', 'bigbasket',
    'big basket', 'reliance fresh', 'reliance smart', 'more retail', 'spencer', 'star bazaar', 'easyday',
    'easy day', 'blinkit', 'zepto', 'instamart', 'jiomart', 'grofers', 'kirana', 'general store',
    'provision', 'provisions', 'mart', 'bazaar', 'hypermarket', 'grocery', 'groceries',
  ], ['atta', 'rice', 'dal', 'sugar', 'salt', 'masala', 'biscuit', 'soap', 'detergent', 'shampoo']),
  _Rule('home', 'ration', [
    'ration', 'fair price', 'pds', 'wholesale', 'chakki', 'flour mill', 'kariyana',
  ], ['wheat', 'pulses']),
  _Rule('home', 'bakery', [
    'bakery', 'bakers', 'cake', 'cakes', 'pastry', 'confectionery', 'mithai', 'halwai',
  ], ['bread', 'bun', 'cookies']),
  _Rule('home', 'kitchen', [
    'utensil', 'utensils', 'kitchenware', 'crockery', 'cookware', 'stainless steel', 'pressure cooker',
  ], ['mixer', 'grinder', 'gas stove']),
  _Rule('home', 'rent', [
    'rent receipt', 'house rent', 'room rent', 'rent for', 'landlord', 'tenant', 'monthly rent', 'flat rent',
  ], ['rent']),
  _Rule('home', 'water', [
    'water bill', 'jal board', 'jal nigam', 'water supply', 'water tanker', 'jal sansthan',
    'municipal water', 'water charges', 'water can', 'bisleri', 'aquaguard',
  ]),
  _Rule('home', 'electricity', [
    'electricity', 'bijli', 'discom', 'kwh', 'electric bill', 'power corporation', 'vidyut', 'uppcl',
    'bses', 'tata power', 'adani electricity', 'msedcl', 'bescom', 'tneb', 'tangedco', 'cesc',
    'torrent power', 'meter reading', 'units consumed', 'energy charges', 'fixed charges',
  ], ['meter', 'tariff']),
  _Rule('home', 'gas', [
    'lpg', 'indane', 'bharatgas', 'bharat gas', 'hp gas', 'hpgas', 'gas cylinder', 'cylinder',
    'gas agency', 'piped gas',
  ], ['refill', 'subsidy']),
  _Rule('home', 'internet', [
    'broadband', 'fibre', 'fiber', 'jiofiber', 'airtel xstream', 'act fibernet', 'hathway', 'wifi',
    'wi-fi', 'internet bill', 'excitel', 'tikona', 'spectranet',
  ], ['router']),
  _Rule('home', 'dth', [
    'dth', 'tata play', 'tata sky', 'dish tv', 'd2h', 'airtel digital tv', 'sun direct', 'set top box',
  ], ['subscriber id']),
  _Rule('home', 'recharge', [
    'prepaid', 'recharge', 'mobile recharge', 'topup', 'top-up', 'talktime', 'jio', 'airtel',
    'vodafone', 'bsnl', 'idea cellular',
  ], ['validity', 'data pack']),
  _Rule('home', 'maintenance', [
    'plumber', 'plumbing', 'electrician', 'carpenter', 'hardware', 'paint', 'painter', 'sanitary',
    'tiles', 'cement', 'handyman', 'pest control', 'society maintenance', 'maintenance charges',
  ], ['fitting', 'pipe', 'wire']),
  _Rule('home', 'cleaning', [
    'cleaning', 'housekeeping', 'laundry', 'dry clean', 'dry cleaner', 'dhobi', 'urban company',
  ], ['phenyl', 'mop', 'broom']),
  _Rule('home', 'maid', [
    'maid', 'house help', 'domestic help', 'cook salary', 'helper salary',
  ]),
  _Rule('home', 'medicines', [
    'pharmacy', 'pharma', 'medical store', 'medicals', 'medico', 'chemist', 'drug store', 'drugstore',
    'medplus', 'apollo pharmacy', 'netmeds', 'pharmeasy', '1mg', 'wellness forever', 'jan aushadhi',
    'aushadhi', 'dispensary',
  ], ['tablet', 'capsule', 'syrup', 'ointment', 'batch', 'expiry', 'exp date', 'paracetamol', 'vitamin']),
  _Rule('home', 'hospital', [
    'hospital', 'clinic', 'nursing home', 'diagnostic', 'diagnostics', 'pathology', 'pathlab',
    'path lab', 'lab report', 'metropolis', 'thyrocare', 'opd', 'consultation', 'doctor fee',
    'medical centre', 'medical center', 'dental', 'eye care', 'x-ray', 'xray', 'ct scan',
  ], ['patient', 'doctor', 'ward', 'registration fee', 'uhid']),
  _Rule('home', 'education', [
    'school', 'tuition', 'coaching', 'college', 'university', 'academy', 'institute', 'fee receipt',
    'fees', 'admission', 'stationery', 'books', 'book depot', 'bookstore', 'notebook', 'library',
    'exam fee', 'uniform',
  ], ['student', 'course', 'semester']),
  _Rule('home', 'gifts', [
    'gift', 'gifts', 'gift shop', 'bouquet', 'florist', 'flowers', 'archies', 'ferns n petals',
  ], ['greeting', 'wrapping']),
  _Rule('home', 'festival', [
    'puja', 'pooja', 'diwali', 'holi', 'rakhi', 'crackers', 'firecracker', 'fireworks', 'festival',
    'navratri', 'idol', 'diya', 'samagri',
  ]),
  _Rule('home', 'pets', [
    'pet shop', 'pet store', 'veterinary', 'vet clinic', 'pet food', 'heads up for tails', 'pedigree',
    'whiskas', 'dog food', 'cat food',
  ], ['puppy', 'kitten']),
  _Rule('home', 'emi', [
    'emi', 'equated monthly', 'loan account', 'installment', 'instalment', 'bajaj finserv',
    'bajaj finance', 'loan emi', 'home loan', 'car loan',
  ]),

  // ---- Personal ----
  _Rule('personal', 'clothes', [
    'fashion', 'garment', 'garments', 'apparel', 'clothing', 'clothes', 'textile', 'textiles',
    'readymade', 'boutique', 'tailor', 'tailors', 'myntra', 'westside', 'pantaloons', 'max fashion',
    'zudio', 'trends', 'h&m', 'zara', 'levis', 'allen solly', 'peter england', 'van heusen',
    'raymond', 'fabindia', 'biba', 'saree', 'sarees', 'kurta', 'kurti', 'jeans', 'shirt', 'trouser',
    'lehenga', 'suiting',
  ], ['alteration', 'hanger']),
  _Rule('personal', 'shoes', [
    'footwear', 'shoe', 'shoes', 'bata', 'woodland', 'paragon', 'liberty shoes', 'relaxo', 'sparx',
    'campus shoes', 'nike', 'adidas', 'puma', 'skechers', 'crocs', 'sandal', 'sandals', 'slipper',
    'slippers', 'chappal',
  ]),
  _Rule('personal', 'mobile', [
    'mobile store', 'mobile shop', 'mobile phone', 'smartphone', 'imei', 'oneplus', 'xiaomi',
    'realme', 'oppo', 'vivo', 'iphone', 'redmi', 'poco', 'sangeetha mobiles', 'mobile accessories',
  ], ['handset', 'sim card', 'screen guard', 'tempered', 'back cover', 'charger']),
  _Rule('personal', 'laptop', [
    'laptop', 'macbook', 'thinkpad', 'dell', 'lenovo', 'asus', 'acer', 'computer shop', 'computers',
  ], ['ssd', 'keyboard', 'monitor']),
  _Rule('personal', 'electronics', [
    'electronics', 'croma', 'reliance digital', 'vijay sales', 'television', 'refrigerator',
    'washing machine', 'air conditioner', 'microwave', 'headphone', 'earphone', 'bluetooth speaker',
    'led tv', 'appliances',
  ], ['warranty', 'serial no', 'model no']),
  _Rule('personal', 'gym', [
    'gym', 'fitness', 'crossfit', 'yoga', 'zumba', 'cult.fit', 'cultfit', 'membership fee',
    'health club', 'protein', 'whey', 'supplement',
  ], ['trainer', 'workout']),
  _Rule('personal', 'salon', [
    'salon', 'parlour', 'parlor', 'beauty', 'spa', 'barber', 'haircut', 'hair cut', 'grooming',
    'jawed habib', 'green trends', 'facial', 'manicure', 'pedicure', 'massage', 'threading', 'makeup',
  ], ['stylist']),
  _Rule('personal', 'travel', [
    'irctc', 'railway', 'railways', 'train ticket', 'flight', 'air india', 'indigo', 'spicejet',
    'vistara', 'akasa', 'makemytrip', 'goibibo', 'cleartrip', 'redbus', 'abhibus', 'ixigo',
    'ola cabs', 'uber', 'rapido', 'taxi', 'cab', 'toll', 'fastag', 'bus ticket', 'boarding pass',
    'pnr', 'airport', 'oyo', 'lodge', 'resort', 'travels', 'travel agency', 'metro card',
  ], ['trip', 'tour']),
  _Rule('personal', 'food', [
    'restaurant', 'cafe', 'café', 'dhaba', 'zomato', 'swiggy', 'dominos', "domino's", 'pizza',
    'burger', 'mcdonald', "mcdonald's", 'kfc', 'subway', 'biryani', 'biriyani', 'food court',
    'eatery', 'canteen', 'tiffin', 'mess', 'bhojanalay', 'chaat', 'haldiram', 'bikanervala',
    'starbucks', 'cafe coffee day', 'ccd', 'chai', 'juice', 'ice cream', 'baskin', 'dining',
    'tandoor', 'thali', 'dosa', 'idli', 'paratha', 'momos', 'shawarma',
  ], ['kitchen', 'hotel', 'food', 'table no', 'kot', 'dine in', 'dine-in', 'take away', 'takeaway',
      'service charge', 'waiter', 'steward']),
  _Rule('personal', 'entertainment', [
    'cinema', 'pvr', 'inox', 'cinepolis', 'movie', 'multiplex', 'bookmyshow', 'netflix', 'hotstar',
    'prime video', 'spotify', 'gaming', 'game zone', 'amusement', 'water park', 'theme park',
    'imagica', 'wonderla', 'concert', 'event ticket', 'bowling', 'arcade', 'theatre', 'theater',
    'zee5', 'sonyliv',
  ], ['popcorn', 'screen no', 'seat no']),
  _Rule('personal', 'shopping', [
    'amazon', 'flipkart', 'meesho', 'ajio', 'nykaa', 'snapdeal', 'shoppers stop', 'mall',
    'departmental store', 'department store', 'showroom',
  ], ['carry bag', 'exchange within', 'return policy']),
  _Rule('personal', 'insurance', [
    'insurance', 'premium', 'lic', 'policy no', 'policy number', 'hdfc life', 'sbi life',
    'icici prudential', 'star health', 'max life', 'bajaj allianz',
  ], ['policy', 'insured']),
];

/* ============================== TEXT HELPERS ============================== */

final Map<String, RegExp> _kwCache = {};

// Short keywords must match as whole words ("hp", "lic", "mall"), longer ones
// can simply be contained in the text.
bool _has(String text, String kw) {
  if (kw.length <= 4) {
    final re = _kwCache.putIfAbsent(
      kw,
      () => RegExp('(^|[^a-z0-9])' + RegExp.escape(kw) + r'($|[^a-z0-9])'),
    );
    return re.hasMatch(text);
  }
  return text.contains(kw);
}

final RegExp _isoDateRe = RegExp(r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b');
final RegExp _dmyRe = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b');
final RegExp _monRe = RegExp(
  r'\b(\d{1,2})[\s\-]*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s,\-\.]*(\d{2,4})\b',
);

const Map<String, int> _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

DateTime? _buildDate(int y, int m, int d) {
  final now = DateTime.now();
  var year = y;
  if (year < 100) year += 2000;
  if (year < 2015 || year > now.year + 1) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(year, m, d);
  if (dt.month != m || dt.day != d) return null;
  if (dt.isAfter(now.add(const Duration(days: 1)))) return null;
  return dt;
}

DateTime? _dateFromRow(String row) {
  final low = row.toLowerCase();
  for (final m in _isoDateRe.allMatches(low)) {
    final dt = _buildDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    if (dt != null) return dt;
  }
  for (final m in _dmyRe.allMatches(low)) {
    var d = int.parse(m.group(1)!);
    var mo = int.parse(m.group(2)!);
    final y = int.parse(m.group(3)!);
    if (mo > 12 && d <= 12) {
      final t = d;
      d = mo;
      mo = t;
    }
    final dt = _buildDate(y, mo, d);
    if (dt != null) return dt;
  }
  for (final m in _monRe.allMatches(low)) {
    final mo = _months[m.group(2)!];
    if (mo == null) continue;
    final dt = _buildDate(int.parse(m.group(3)!), mo, int.parse(m.group(1)!));
    if (dt != null) return dt;
  }
  return null;
}

// Removes things that look like numbers but aren't amounts: dates, times,
// GSTINs and long ids/phone numbers.
String _stripNoise(String s) {
  var t = s.toLowerCase();
  t = t.replaceAll(_isoDateRe, ' ');
  t = t.replaceAll(_dmyRe, ' ');
  t = t.replaceAll(_monRe, ' ');
  t = t.replaceAll(RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:am|pm)?'), ' ');
  t = t.replaceAll(RegExp(r'\b\d{2}[a-z]{5}\d{4}[a-z]\d[a-z\d][a-z\d]\b'), ' ');
  t = t.replaceAll(RegExp(r'\d{9,}'), ' ');
  return t;
}

final RegExp _numTokenRe = RegExp(r'\d[\d,]*(?:\.\d+)?');

List<double> _amountsIn(String s, {bool allowSixDigitInts = false}) {
  final cleaned = _stripNoise(s);
  final out = <double>[];
  for (final m in _numTokenRe.allMatches(cleaned)) {
    final raw = m.group(0)!.replaceAll(',', '');
    final v = double.tryParse(raw);
    if (v == null) continue;
    if (v < 1 || v > 5000000) continue;
    // 6-digit integers are almost always PIN codes / invoice numbers.
    if (!allowSixDigitInts && !raw.contains('.') && raw.length == 6) continue;
    out.add(v);
  }
  return out;
}

double _maxOf(List<double> v) {
  var m = v.first;
  for (final x in v) {
    if (x > m) m = x;
  }
  return m;
}

const List<String> _tier3 = [
  'grand total', 'net payable', 'amount payable', 'total payable', 'net amount', 'total amount',
  'bill amount', 'invoice total', 'amount due', 'balance due', 'total due', 'to pay', 'net total',
];
const List<String> _tier3Exclude = ['sub total', 'subtotal', 'sub-total', 'in words'];
const List<String> _tier2Words = ['total', 'sale amount', 'sale value', 'amount'];
const List<String> _lowerExclude = [
  'sub total', 'subtotal', 'sub-total', 'total qty', 'total quantity', 'total item', 'total saving',
  'total discount', 'total tax', 'total gst', 'total cgst', 'total sgst', 'total igst', 'total mrp',
  'savings', 'you saved', 'in words', 'tendered', 'tender', 'change', 'cash', 'paid', 'received',
  'given', 'round off', 'roundoff', 'discount', 'cgst', 'sgst', 'igst',
];

bool _anyContains(String text, List<String> list) {
  for (final k in list) {
    if (text.contains(k)) return true;
  }
  return false;
}

class _AmountPick {
  final double? amount;
  final bool confident;
  const _AmountPick(this.amount, this.confident);
}

_AmountPick _pickAmount(List<String> rows) {
  final tierVals = <int, List<double>>{3: <double>[], 2: <double>[]};

  for (int i = 0; i < rows.length; i++) {
    final low = rows[i].toLowerCase();
    int tier = 0;
    if (_anyContains(low, _tier3) && !_anyContains(low, _tier3Exclude)) {
      tier = 3;
    } else if (!_anyContains(low, _lowerExclude)) {
      for (final w in _tier2Words) {
        if (low.contains(w)) {
          tier = 2;
          break;
        }
      }
    }
    if (tier == 0) continue;

    var vals = _amountsIn(rows[i]);
    if (vals.isEmpty && i + 1 < rows.length) {
      vals = _amountsIn(rows[i + 1]);
    }
    if (vals.isNotEmpty) tierVals[tier]!.addAll(vals);
  }

  if (tierVals[3]!.isNotEmpty) return _AmountPick(_maxOf(tierVals[3]!), true);
  if (tierVals[2]!.isNotEmpty) return _AmountPick(_maxOf(tierVals[2]!), true);

  // Fallback: the biggest decimal-looking number that isn't on a payment /
  // tax line, else the biggest plain number. Flagged as not confident.
  final decimals = <double>[];
  final plain = <double>[];
  for (final r in rows) {
    final low = r.toLowerCase();
    if (_anyContains(low, ['cash', 'tender', 'change', 'paid', 'received', 'cgst', 'sgst', 'igst', 'gst'])) {
      continue;
    }
    final hasDecimal = RegExp(r'\d\.\d{2}\b').hasMatch(_stripNoise(r));
    for (final v in _amountsIn(r)) {
      if (hasDecimal && v != v.roundToDouble()) {
        decimals.add(v);
      } else if (hasDecimal) {
        decimals.add(v);
      } else {
        plain.add(v);
      }
    }
  }
  if (decimals.isNotEmpty) return _AmountPick(_maxOf(decimals), false);
  if (plain.isNotEmpty) return _AmountPick(_maxOf(plain), false);
  return const _AmountPick(null, false);
}

String _pickMerchant(List<String> rows) {
  final skip = RegExp(
    r'^(tax invoice|invoice|bill|cash memo|cash bill|receipt|gstin|gst no|gst|retail invoice|original|duplicate|customer copy|welcome|thank|phone|ph|tel|mob)',
  );
  for (final r in rows.take(6)) {
    final t = r.trim();
    final letters = RegExp(r'[A-Za-z]').allMatches(t).length;
    if (letters < 3) continue;
    if (skip.hasMatch(t.toLowerCase())) continue;
    return t.length > 40 ? t.substring(0, 40) : t;
  }
  return '';
}

double? _fuelQuantity(String text) {
  final low = text.toLowerCase();
  final m1 = RegExp(r'(?:qty|quantity|volume|vol|litres?|ltrs?)\s*[:\-]?\s*(\d{1,3}\.\d{1,3})').firstMatch(low);
  if (m1 != null) return double.tryParse(m1.group(1)!);
  final m2 = RegExp(r'(\d{1,3}\.\d{1,3})\s*(?:l|ltr|ltrs|litre|litres)\b').firstMatch(low);
  if (m2 != null) return double.tryParse(m2.group(1)!);
  return null;
}

/* ============================== MAIN ENTRY POINT ============================== */

ParsedReceipt parseReceipt(List<String> rows) {
  final text = rows.join('\n');
  final low = text.toLowerCase();

  // ---- amount / date / merchant ----
  final pick = _pickAmount(rows);
  DateTime? date;
  for (final r in rows) {
    date = _dateFromRow(r);
    if (date != null) break;
  }
  final merchant = _pickMerchant(rows);
  final merchantLow = merchant.toLowerCase();

  // ---- category: the user's own custom categories win if their name shows up ----
  for (final c in globalCustomCategories) {
    final label = (c['label'] ?? '').toLowerCase().trim();
    final sectionKey = c['sectionKey'] ?? '';
    if (label.length < 3 || sectionKey.isEmpty) continue;
    if (!_has(low, label)) continue;
    final isVehicle = sectionKey.startsWith('vehicle_');
    final section = isVehicle ? 'vehicle' : sectionKey;
    if (section != 'home' && section != 'personal' && section != 'vehicle') continue;
    return ParsedReceipt(
      amount: pick.amount,
      amountConfident: pick.confident,
      date: date,
      merchant: merchant,
      quantity: null,
      section: section,
      categoryKey: c['key'],
      vehicleType: isVehicle ? sectionKey.substring('vehicle_'.length) : null,
      matched: [label],
      confidence: 2,
    );
  }

  // ---- category: score every built-in rule ----
  _Rule? best;
  var bestScore = 0;
  var secondScore = 0;
  var bestMatched = <String>[];

  for (final rule in _rules) {
    var score = 0;
    final matched = <String>[];
    for (final kw in rule.strong) {
      if (_has(low, kw)) {
        score += 3;
        if (merchantLow.isNotEmpty && _has(merchantLow, kw)) score += 2;
        matched.add(kw);
      }
    }
    var weakScore = 0;
    for (final kw in rule.weak) {
      if (_has(low, kw)) {
        weakScore += 1;
        matched.add(kw);
      }
    }
    score += weakScore > 3 ? 3 : weakScore;

    if (score > bestScore) {
      secondScore = bestScore;
      best = rule;
      bestScore = score;
      bestMatched = matched;
    } else if (score > secondScore) {
      secondScore = score;
    }
  }

  var confidence = 0;
  if (best != null) {
    if (bestScore >= 3 && bestScore - secondScore >= 2) {
      confidence = 2;
    } else if (bestScore >= 2) {
      confidence = 1;
    }
  }

  // Not convinced? Leave the category empty rather than guess.
  if (best == null || confidence == 0) {
    return ParsedReceipt(
      amount: pick.amount,
      amountConfident: pick.confident,
      date: date,
      merchant: merchant,
      quantity: null,
      section: null,
      categoryKey: null,
      vehicleType: null,
      matched: bestMatched,
      confidence: 0,
    );
  }

  var category = best.category;
  String? vehicleType;
  double? quantity;

  if (best.section == 'vehicle') {
    if (category == 'petrol') {
      if (_has(low, 'diesel') || _has(low, 'hsd')) {
        category = 'diesel';
      } else if (_has(low, 'cng')) {
        category = 'cng';
      }
    }
    if (category == 'petrol' || category == 'diesel' || category == 'cng') {
      quantity = _fuelQuantity(text);
    }

    if (category == 'diesel' || category == 'cng' || category == 'tyres') {
      vehicleType = 'car';
    } else if (_has(low, 'bike') || _has(low, 'scooter') || _has(low, 'motorcycle') || _has(low, 'two wheeler')) {
      vehicleType = 'bike';
    } else if (_has(low, 'car') || _has(low, 'sedan') || _has(low, 'suv') || _has(low, 'four wheeler')) {
      vehicleType = 'car';
    } else if (quantity != null) {
      vehicleType = quantity <= 12 ? 'bike' : 'car';
    } else {
      vehicleType = 'bike';
    }
  }

  return ParsedReceipt(
    amount: pick.amount,
    amountConfident: pick.confident,
    date: date,
    merchant: merchant,
    quantity: quantity,
    section: best.section,
    categoryKey: category,
    vehicleType: vehicleType,
    matched: bestMatched,
    confidence: confidence,
  );
}
