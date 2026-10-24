import 'panchang_data.dart';

/* ============================== TYPES ============================== */

class PanchangDay {
  final DateTime date;
  final int tithi; // 1..30 at sunrise (1-15 Shukla, 16-30 Krishna)
  final int nakshatra; // 1..27 at sunrise
  final int monthIdx; // amanta month, 0 = Chaitra ... 11 = Phalguna
  final bool adhika;
  final int pMonthIdx; // purnimanta month
  final bool pAdhika;
  final int tithiEnd; // minutes after midnight IST (>= 1440 means next day)
  final int nakEnd;
  final List<String> events;

  const PanchangDay({
    required this.date,
    required this.tithi,
    required this.nakshatra,
    required this.monthIdx,
    required this.adhika,
    required this.pMonthIdx,
    required this.pAdhika,
    required this.tithiEnd,
    required this.nakEnd,
    required this.events,
  });

  bool get shukla => tithi <= 15;
}

class PanchangOccurrence {
  final DateTime date;
  final String code;
  const PanchangOccurrence(this.date, this.code);
}

class FestivalInfo {
  final String en;
  final String hi;
  final String category; // festival | holiday | vrat | eclipse
  final String desc;
  final List<String> expenses;
  const FestivalInfo(this.en, this.hi, this.category, this.desc, [this.expenses = const <String>[]]);
}

/* ============================== NAMES ============================== */

const List<String> _tithiEn = [
  'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami', 'Shashthi', 'Saptami',
  'Ashtami', 'Navami', 'Dashami', 'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi',
];
const List<String> _tithiHi = [
  'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पंचमी', 'षष्ठी', 'सप्तमी',
  'अष्टमी', 'नवमी', 'दशमी', 'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी',
];
const List<String> _tithiShortEn = [
  'Prat', 'Dwit', 'Trit', 'Chtu', 'Panc', 'Shas', 'Sapt',
  'Asht', 'Nava', 'Dasa', 'Ekad', 'Dwad', 'Tray', 'Chtd',
];

const List<String> _monthEn = [
  'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha', 'Shravana', 'Bhadrapada',
  'Ashwin', 'Kartika', 'Margashirsha', 'Pausha', 'Magha', 'Phalguna',
];
const List<String> _monthHi = [
  'चैत्र', 'वैशाख', 'ज्येष्ठ', 'आषाढ़', 'श्रावण', 'भाद्रपद',
  'आश्विन', 'कार्तिक', 'मार्गशीर्ष', 'पौष', 'माघ', 'फाल्गुन',
];

const List<String> _nakEn = [
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu', 'Pushya',
  'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati',
  'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana',
  'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
];
const List<String> _nakHi = [
  'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा', 'आर्द्रा', 'पुनर्वसु', 'पुष्य',
  'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त', 'चित्रा', 'स्वाति',
  'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूल', 'पूर्वाषाढ़ा', 'उत्तराषाढ़ा', 'श्रवण',
  'धनिष्ठा', 'शतभिषा', 'पूर्वाभाद्रपद', 'उत्तराभाद्रपद', 'रेवती',
];

// Ekadashi names, indexed by PURNIMANTA month (Chaitra .. Phalguna).
const List<String> _ekaKrishnaEn = [
  'Papmochani', 'Varuthini', 'Apara', 'Yogini', 'Kamika', 'Aja',
  'Indira', 'Rama', 'Utpanna', 'Saphala', 'Shattila', 'Vijaya',
];
const List<String> _ekaKrishnaHi = [
  'पापमोचिनी', 'वरूथिनी', 'अपरा', 'योगिनी', 'कामिका', 'अजा',
  'इंदिरा', 'रमा', 'उत्पन्ना', 'सफला', 'षटतिला', 'विजया',
];
const List<String> _ekaShuklaEn = [
  'Kamada', 'Mohini', 'Nirjala', 'Devshayani', 'Putrada (Shravana)', 'Parivartini',
  'Papankusha', 'Devutthana', 'Mokshada', 'Putrada (Pausha)', 'Jaya', 'Amalaki',
];
const List<String> _ekaShuklaHi = [
  'कामदा', 'मोहिनी', 'निर्जला', 'देवशयनी', 'पुत्रदा (श्रावण)', 'परिवर्तिनी',
  'पापांकुशा', 'देवउठनी', 'मोक्षदा', 'पुत्रदा (पौष)', 'जया', 'आमलकी',
];

const List<String> weekdayShortEn = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const List<String> weekdayShortHi = ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'];

/* ============================== FESTIVAL CATALOG ============================== */

const Map<String, FestivalInfo> _catalog = {
  // ---- Major Hindu festivals ----
  'gudi_padwa': FestivalInfo('Gudi Padwa / Ugadi', 'गुड़ी पड़वा / उगादी', 'festival',
      'Hindu New Year (Chaitra Shukla Pratipada) and the first day of Chaitra Navratri.',
      ['Puja samagri', 'Sweets', 'Decoration (gudi, torans)', 'New purchases']),
  'gangaur': FestivalInfo('Gangaur', 'गणगौर', 'festival',
      'Festival of Gauri (Parvati), celebrated specially in Rajasthan.',
      ['Mehendi', 'Shringar items & clothes', 'Sweets (ghewar)', 'Puja thali']),
  'ram_navami': FestivalInfo('Ram Navami', 'राम नवमी', 'festival',
      'Birth of Lord Rama (Chaitra Shukla Navami).',
      ['Puja samagri', 'Prasad', 'Decoration', 'Donations']),
  'mahavir_jayanti': FestivalInfo('Mahavir Jayanti', 'महावीर जयंती', 'holiday',
      'Birth anniversary of Lord Mahavir (Chaitra Shukla Trayodashi).',
      ['Donations', 'Puja items']),
  'hanuman_jayanti': FestivalInfo('Hanuman Jayanti', 'हनुमान जयंती', 'festival',
      'Birth of Lord Hanuman (Chaitra Purnima).',
      ['Sindoor, chola & puja items', 'Prasad (boondi / laddoo)', 'Bhandara / donation']),
  'akshaya_tritiya': FestivalInfo('Akshaya Tritiya', 'अक्षय तृतीया', 'festival',
      'An auspicious day for new beginnings and buying gold (Vaishakha Shukla Tritiya).',
      ['Gold / silver purchase', 'Puja samagri', 'Donations', 'Sweets']),
  'buddha_purnima': FestivalInfo('Buddha Purnima', 'बुद्ध पूर्णिमा', 'holiday',
      'Birth anniversary of Gautama Buddha (Vaishakha Purnima).',
      ['Donations', 'Flowers & offerings']),
  'vat_savitri': FestivalInfo('Vat Savitri Vrat', 'वट सावित्री व्रत', 'festival',
      'Married women fast for the long life of their husbands (Jyeshtha Amavasya).',
      ['Puja samagri', 'Fruits (mango)', 'Shringar items']),
  'ganga_dussehra': FestivalInfo('Ganga Dussehra', 'गंगा दशहरा', 'festival',
      'Descent of the Ganga to earth (Jyeshtha Shukla Dashami).',
      ['Ganga snan travel', 'Donations']),
  'rath_yatra': FestivalInfo('Jagannath Rath Yatra', 'जगन्नाथ रथ यात्रा', 'festival',
      'Chariot festival of Lord Jagannath (Ashadha Shukla Dwitiya).',
      ['Donations', 'Prasad', 'Travel']),
  'guru_purnima': FestivalInfo('Guru Purnima', 'गुरु पूर्णिमा', 'festival',
      'Day to honour teachers and gurus (Ashadha Purnima).',
      ['Guru dakshina', 'Puja items', 'Sweets']),
  'hariyali_teej': FestivalInfo('Hariyali Teej', 'हरियाली तीज', 'festival',
      'Monsoon festival of Shiva-Parvati (Shravana Shukla Tritiya).',
      ['Mehendi', 'Green clothes & bangles', 'Swing & decoration', 'Sweets (ghewar)']),
  'nag_panchami': FestivalInfo('Nag Panchami', 'नाग पंचमी', 'festival',
      'Worship of serpent deities (Shravana Shukla Panchami).',
      ['Milk & puja items', 'Donation']),
  'raksha_bandhan': FestivalInfo('Raksha Bandhan', 'रक्षाबंधन', 'festival',
      'Sisters tie rakhi on brothers (Shravana Purnima).',
      ['Rakhis', 'Sweets', 'Gifts', 'Travel to meet siblings']),
  'kajari_teej': FestivalInfo('Kajari Teej', 'कजरी तीज', 'festival',
      'Monsoon festival observed by married women (Krishna Tritiya).',
      ['Puja items', 'Sweets']),
  'janmashtami': FestivalInfo('Janmashtami (Smarta)', 'जन्माष्टमी (स्मार्त)', 'festival',
      'Birth of Lord Krishna, observed when Ashtami prevails at midnight (Smarta).',
      ['Puja samagri', 'Jhanki decoration', 'Sweets / panjiri', 'Fasting food']),
  'janmashtami_vaishnava': FestivalInfo('Janmashtami (Vaishnava / ISKCON)', 'जन्माष्टमी (वैष्णव)', 'festival',
      'Janmashtami as observed by Vaishnava traditions, when it differs from the Smarta date.',
      ['Puja samagri', 'Sweets', 'Fasting food']),
  'dahi_handi': FestivalInfo('Dahi Handi', 'दही हांडी', 'festival',
      'The day after Janmashtami, celebrated with human pyramids to break the handi.',
      ['Handi & decoration', 'Contribution to the mandal', 'Sweets']),
  'hartalika_teej': FestivalInfo('Hartalika Teej', 'हरतालिका तीज', 'festival',
      'Fast for Shiva-Parvati (Bhadrapada Shukla Tritiya).',
      ['Puja samagri', 'Shringar items', 'Sweets']),
  'ganesh_chaturthi': FestivalInfo('Ganesh Chaturthi', 'गणेश चतुर्थी', 'festival',
      'Birth of Lord Ganesha (Bhadrapada Shukla Chaturthi).',
      ['Ganesh idol', 'Decoration', 'Modak & sweets', 'Flowers & puja items', 'Visarjan expenses']),
  'radha_ashtami': FestivalInfo('Radha Ashtami', 'राधा अष्टमी', 'festival',
      'Birth of Radha (Bhadrapada Shukla Ashtami).',
      ['Puja items', 'Sweets']),
  'anant_chaturdashi': FestivalInfo('Anant Chaturdashi', 'अनंत चतुर्दशी', 'festival',
      'Worship of Lord Vishnu; Ganesh Visarjan day (Bhadrapada Shukla Chaturdashi).',
      ['Visarjan expenses', 'Puja items']),
  'pitru_paksha': FestivalInfo('Pitru Paksha begins', 'पितृ पक्ष प्रारंभ', 'festival',
      'Fortnight for honouring ancestors (Shraddha).',
      ['Shraddha items & pind daan', 'Brahmin bhojan / dakshina', 'Donations']),
  'sarva_pitru_amavasya': FestivalInfo('Sarva Pitru Amavasya', 'सर्व पितृ अमावस्या', 'festival',
      'Last day of Pitru Paksha (Mahalaya), Shraddha for all ancestors.',
      ['Shraddha items', 'Brahmin bhojan / dakshina', 'Donations']),
  'vishwakarma_puja': FestivalInfo('Vishwakarma Puja', 'विश्वकर्मा पूजा', 'festival',
      'Worship of Lord Vishwakarma, observed on Kanya Sankranti.',
      ['Puja items', 'Tools / machinery cleaning', 'Prasad']),
  'navratri_start': FestivalInfo('Sharad Navratri begins', 'शारदीय नवरात्रि प्रारंभ', 'festival',
      'Nine nights of Goddess Durga begin (Ashwin Shukla Pratipada).',
      ['Puja samagri', 'Fasting food (vrat)', 'Garba outfits', 'Kanya pujan gifts']),
  'durga_ashtami': FestivalInfo('Durga Ashtami', 'दुर्गा अष्टमी', 'festival',
      'Maha Ashtami of Navratri; Kanya pujan is done on this day or Navami.',
      ['Kanya pujan (gifts, prasad)', 'Havan samagri']),
  'maha_navami': FestivalInfo('Maha Navami', 'महा नवमी', 'festival',
      'Ninth day of Navratri; Kanya pujan and havan.',
      ['Kanya pujan (gifts, prasad)', 'Havan samagri']),
  'dussehra': FestivalInfo('Dussehra (Vijayadashami)', 'दशहरा (विजयादशमी)', 'festival',
      'Victory of good over evil (Ashwin Shukla Dashami).',
      ['Sweets', 'Fair / effigy expenses', 'New purchases', 'Gifts']),
  'sharad_purnima': FestivalInfo('Sharad Purnima', 'शरद पूर्णिमा', 'festival',
      'Harvest full moon; kheer is kept under the moonlight (Ashwin Purnima).',
      ['Kheer ingredients', 'Puja items']),
  'karwa_chauth': FestivalInfo('Karwa Chauth', 'करवा चौथ', 'festival',
      'Married women fast from sunrise to moonrise for their husbands.',
      ['Sargi items', 'Mehendi', 'Jewellery / clothes', 'Puja thali', 'Gift for spouse']),
  'ahoi_ashtami': FestivalInfo('Ahoi Ashtami', 'अहोई अष्टमी', 'festival',
      'Mothers fast for the well-being of their children.',
      ['Puja samagri', 'Silver locket / pendant', 'Sweets']),
  'dhanteras': FestivalInfo('Dhanteras', 'धनतेरस', 'festival',
      'First day of Diwali; buying gold, silver or utensils is considered auspicious.',
      ['Gold / silver / utensils', 'Puja samagri', 'Sweets']),
  'naraka_chaturdashi': FestivalInfo('Naraka Chaturdashi (Choti Diwali)', 'नरक चतुर्दशी (छोटी दिवाली)', 'festival',
      'The day before Diwali; early-morning oil bath and lighting of diyas.',
      ['Diyas & oil', 'Sweets']),
  'diwali': FestivalInfo('Diwali (Lakshmi Puja)', 'दीपावली (लक्ष्मी पूजन)', 'festival',
      'Festival of lights; Lakshmi-Ganesh puja on Kartika Amavasya.',
      ['Sweets & dry fruits', 'Diyas, lights & decoration', 'Crackers', 'New clothes', 'Gifts for family',
        'Puja samagri & flowers', 'Home cleaning / painting', 'Rangoli colours']),
  'govardhan_puja': FestivalInfo('Govardhan Puja / Annakut', 'गोवर्धन पूजा / अन्नकूट', 'festival',
      'Worship of Govardhan hill; a large offering of food (Annakut).',
      ['Annakut bhog ingredients', 'Sweets']),
  'bhai_dooj': FestivalInfo('Bhai Dooj', 'भाई दूज', 'festival',
      'Sisters apply tilak on brothers (Kartika Shukla Dwitiya).',
      ['Gift for sister / brother', 'Sweets', 'Travel']),
  'chhath_puja': FestivalInfo('Chhath Puja (Sandhya Arghya)', 'छठ पूजा (संध्या अर्घ्य)', 'festival',
      'Worship of the Sun God; evening offering on Kartika Shukla Shashthi.',
      ['Soop, daura & bamboo items', 'Fruits & thekua ingredients', 'Sugarcane', 'Travel']),
  'dev_uthani': FestivalInfo('Dev Uthani Ekadashi', 'देवउठनी एकादशी', 'festival',
      'Lord Vishnu wakes from his sleep; weddings season begins (Kartika Shukla Ekadashi).',
      ['Tulsi vivah items', 'Sugarcane & fruits', 'Puja samagri']),
  'dev_deepawali': FestivalInfo('Dev Deepawali', 'देव दीपावली', 'festival',
      'Festival of lights of the gods, famous at Varanasi (Kartika Purnima).',
      ['Diyas & oil', 'Ghat / aarti expenses', 'Donations']),
  'guru_nanak_jayanti': FestivalInfo('Guru Nanak Jayanti', 'गुरु नानक जयंती', 'holiday',
      'Birth anniversary of Guru Nanak Dev (Kartika Purnima).',
      ['Langar contribution', 'Gurudwara offerings', 'Sweets']),
  'geeta_jayanti': FestivalInfo('Geeta Jayanti', 'गीता जयंती', 'festival',
      'Day the Bhagavad Gita was revealed (Margashirsha Shukla Ekadashi).',
      ['Donation', 'Gita books']),
  'dattatreya_jayanti': FestivalInfo('Dattatreya Jayanti', 'दत्तात्रेय जयंती', 'festival',
      'Birth of Lord Dattatreya (Margashirsha Purnima).',
      ['Puja items', 'Donation']),
  'lohri': FestivalInfo('Lohri', 'लोहड़ी', 'festival',
      'Winter bonfire festival, celebrated mainly in Punjab and Haryana.',
      ['Rewri, peanuts & popcorn', 'Bonfire wood', 'Sweets', 'Gifts']),
  'makar_sankranti': FestivalInfo('Makar Sankranti', 'मकर संक्रांति', 'festival',
      'The Sun enters Capricorn. Kites, til-gud and charity mark the day.',
      ['Til-gud sweets', 'Kites & manjha', 'Donations (khichdi, blankets)', 'Ganga snan travel']),
  'vasant_panchami': FestivalInfo('Vasant Panchami', 'वसंत पंचमी', 'festival',
      'Worship of Goddess Saraswati; the start of spring (Magha Shukla Panchami).',
      ['Yellow clothes / items', 'Saraswati puja items', 'Books & stationery', 'Sweets']),
  'mahashivaratri': FestivalInfo('Maha Shivaratri', 'महाशिवरात्रि', 'festival',
      'The great night of Lord Shiva; fasting and night-long worship.',
      ['Bel patra, milk & puja items', 'Fasting food', 'Temple offerings', 'Jagran expenses']),
  'holika_dahan': FestivalInfo('Holika Dahan', 'होलिका दहन', 'festival',
      'Bonfire on Phalguna Purnima, after Bhadra ends.',
      ['Puja samagri', 'Wood / cow-dung cakes']),
  'holi': FestivalInfo('Holi (Dhulandi)', 'होली (धुलेंडी)', 'festival',
      'Festival of colours, the day after Holika Dahan.',
      ['Colours & gulal', 'Sweets & gujiya', 'Pichkari & water balloons', 'New clothes', 'Thandai ingredients']),
  'baisakhi': FestivalInfo('Baisakhi / Mesha Sankranti', 'बैसाखी / मेष संक्रांति', 'festival',
      'Solar new year and harvest festival; the Sun enters Aries.',
      ['Gurudwara offerings', 'Sweets', 'New clothes']),

  // ---- Public holidays ----
  'republic_day': FestivalInfo('Republic Day', 'गणतंत्र दिवस', 'holiday', 'National holiday, 26 January.'),
  'independence_day': FestivalInfo('Independence Day', 'स्वतंत्रता दिवस', 'holiday', 'National holiday, 15 August.'),
  'gandhi_jayanti': FestivalInfo('Gandhi Jayanti', 'गांधी जयंती', 'holiday', 'National holiday, 2 October.'),
  'ambedkar_jayanti': FestivalInfo('Ambedkar Jayanti', 'अम्बेडकर जयंती', 'holiday', 'Birth anniversary of Dr B. R. Ambedkar, 14 April.'),
  'christmas': FestivalInfo('Christmas', 'क्रिसमस', 'holiday', 'Christian festival, 25 December.',
      ['Gifts', 'Cake & food', 'Decoration', 'Clothes']),
  'good_friday': FestivalInfo('Good Friday', 'गुड फ्राइडे', 'holiday', 'Christian observance, the Friday before Easter.'),
  'easter': FestivalInfo('Easter', 'ईस्टर', 'festival', 'Christian festival, Sunday after Good Friday.'),
  'eid_ul_fitr': FestivalInfo('Eid-ul-Fitr (approx.)', 'ईद-उल-फ़ित्र (अनुमानित)', 'holiday',
      'End of Ramadan. Exact date depends on moon sighting and can differ by a day.',
      ['Eidi (gifts)', 'New clothes', 'Sewaiyan & food', 'Charity (zakat)']),
  'eid_ul_adha': FestivalInfo('Eid-ul-Adha / Bakrid (approx.)', 'ईद-उल-अज़हा / बकरीद (अनुमानित)', 'holiday',
      'Festival of sacrifice. Exact date depends on moon sighting and can differ by a day.',
      ['Qurbani', 'Clothes', 'Food', 'Charity']),
  'muharram': FestivalInfo('Muharram / Ashura (approx.)', 'मुहर्रम / आशूरा (अनुमानित)', 'holiday',
      'Day of mourning, 10th of Muharram. Exact date depends on moon sighting.'),
  'milad_un_nabi': FestivalInfo('Milad-un-Nabi (approx.)', 'ईद-ए-मिलाद (अनुमानित)', 'holiday',
      'Birthday of Prophet Muhammad. Exact date depends on moon sighting.'),

  // ---- Eclipses (only those visible from India) ----
  'chandra_grahan': FestivalInfo('Chandra Grahan (Lunar eclipse)', 'चंद्र ग्रहण', 'eclipse',
      'Lunar eclipse visible from India. Sutak is observed from about 9 hours before.'),
  'surya_grahan': FestivalInfo('Surya Grahan (Solar eclipse)', 'सूर्य ग्रहण', 'eclipse',
      'Solar eclipse visible from India. Sutak is observed from about 12 hours before.'),

  // ---- Vrats (derived per day) ----
  'ekadashi': FestivalInfo('Ekadashi', 'एकादशी', 'vrat', 'Fasting day dedicated to Lord Vishnu.'),
  'pradosh_vrat': FestivalInfo('Pradosh Vrat', 'प्रदोष व्रत', 'vrat', 'Evening worship of Lord Shiva on Trayodashi.'),
  'sankashti': FestivalInfo('Sankashti Chaturthi', 'संकष्टी चतुर्थी', 'vrat', 'Fast for Lord Ganesha, broken after moonrise.'),
  'masik_shivaratri': FestivalInfo('Masik Shivaratri', 'मासिक शिवरात्रि', 'vrat', 'Monthly night of Lord Shiva (Krishna Chaturdashi).'),
  'purnima': FestivalInfo('Purnima', 'पूर्णिमा', 'vrat', 'Full moon day.'),
  'amavasya': FestivalInfo('Amavasya', 'अमावस्या', 'vrat', 'New moon day.'),
};

/* ============================== LOGIC ============================== */

class Panchang {
  static final Map<int, PanchangDay?> _dayCache = {};
  static final Map<int, Map<int, List<String>>> _eventCache = {};

  static const String _b36 = '0123456789abcdefghijklmnopqrstuvwxyz';

  static DateTime get firstDate => DateTime(kPanchangStartYear, 1, 1);
  static DateTime get lastDate => DateTime(kPanchangEndYear, 12, 31);

  static bool inRange(DateTime d) {
    return d.year >= kPanchangStartYear && d.year <= kPanchangEndYear;
  }

  static int _b36Int(String s) {
    var n = 0;
    for (final ch in s.split('')) {
      n = n * 36 + _b36.indexOf(ch);
    }
    return n;
  }

  static Map<int, List<String>> _eventsForMonth(int monthIndex) {
    return _eventCache.putIfAbsent(monthIndex, () {
      final out = <int, List<String>>{};
      final s = kPanchangEventMonths[monthIndex];
      if (s.isEmpty) return out;
      for (final part in s.split(',')) {
        final i = part.indexOf(':');
        if (i < 0) continue;
        final day = int.parse(part.substring(0, i));
        out.putIfAbsent(day, () => <String>[]).add(part.substring(i + 1));
      }
      return out;
    });
  }

  static PanchangDay? day(DateTime date) {
    if (!inRange(date)) return null;
    final key = date.year * 10000 + date.month * 100 + date.day;
    return _dayCache.putIfAbsent(key, () {
      final mi = (date.year - kPanchangStartYear) * 12 + (date.month - 1);
      final row = kPanchangMonths[mi];
      final start = (date.day - 1) * 10;
      if (start + 10 > row.length) return null;
      final r = row.substring(start, start + 10);
      final mc = _b36Int(r[2]);
      final pc = _b36Int(r[3]);
      return PanchangDay(
        date: DateTime(date.year, date.month, date.day),
        tithi: _b36Int(r[0]),
        nakshatra: _b36Int(r[1]),
        monthIdx: mc % 12,
        adhika: mc >= 12,
        pMonthIdx: pc % 12,
        pAdhika: pc >= 12,
        tithiEnd: _b36Int(r.substring(4, 7)),
        nakEnd: _b36Int(r.substring(7, 10)),
        events: List<String>.from(_eventsForMonth(mi)[date.day] ?? const <String>[]),
      );
    });
  }

  /* ---------- names ---------- */

  static String tithiName(int t, String lang) {
    final hi = lang == 'hi';
    if (t == 30) return hi ? 'अमावस्या' : 'Amavasya';
    final n = t <= 15 ? t : t - 15;
    if (n == 15) return hi ? 'पूर्णिमा' : 'Purnima';
    return hi ? _tithiHi[n - 1] : _tithiEn[n - 1];
  }

  static String pakshaName(int t, String lang) {
    final shukla = t <= 15;
    if (lang == 'hi') return shukla ? 'शुक्ल' : 'कृष्ण';
    return shukla ? 'Shukla' : 'Krishna';
  }

  // "Shukla Panchami" — Purnima / Amavasya need no paksha.
  static String tithiLabel(int t, String lang) {
    if (t == 15 || t == 30) return tithiName(t, lang);
    return '${pakshaName(t, lang)} ${tithiName(t, lang)}';
  }

  static String tithiShort(int t, String lang) {
    if (lang == 'hi') return tithiName(t, lang);
    if (t == 30) return 'Amav';
    final n = t <= 15 ? t : t - 15;
    if (n == 15) return 'Purn';
    return _tithiShortEn[n - 1];
  }

  static String monthName(int idx, bool adhika, String lang) {
    final name = lang == 'hi' ? _monthHi[idx] : _monthEn[idx];
    if (!adhika) return name;
    return lang == 'hi' ? 'अधिक $name' : 'Adhika $name';
  }

  static String nakshatraName(int n, String lang) {
    return lang == 'hi' ? _nakHi[n - 1] : _nakEn[n - 1];
  }

  // "Kartika Krishna Chaturdashi" in the chosen month system.
  static String hinduDateLine(PanchangDay p, bool purnimanta, String lang) {
    final month = purnimanta ? monthName(p.pMonthIdx, p.pAdhika, lang) : monthName(p.monthIdx, p.adhika, lang);
    return '$month ${tithiLabel(p.tithi, lang)}';
  }

  // Vikram Samvat (Chaitra-based). The year changes on Chaitra Shukla Pratipada.
  static int vikramSamvat(PanchangDay p) {
    final y = p.date.year;
    if (p.monthIdx >= 8 && p.date.month <= 4) return y + 56;
    return y + 57;
  }

  static String formatMinutes(int mins, String lang) {
    final dayOffset = mins ~/ 1440;
    final m = mins % 1440;
    final h = m ~/ 60;
    final mm = m % 60;
    final ap = h >= 12 ? 'PM' : 'AM';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    final t = '$h12:${mm.toString().padLeft(2, '0')} $ap';
    if (dayOffset > 0) return lang == 'hi' ? '$t (अगले दिन)' : '$t (next day)';
    return t;
  }

  /* ---------- events ---------- */

  static FestivalInfo? info(String code) => _catalog[code];

  static String categoryOf(String code) => _catalog[code]?.category ?? 'festival';

  static bool isMajor(String code) {
    final c = categoryOf(code);
    return c != 'vrat';
  }

  static List<String> expensesFor(String code) => _catalog[code]?.expenses ?? const <String>[];

  static String ekadashiName(PanchangDay p, String lang) {
    final hi = lang == 'hi';
    final shukla = p.tithi <= 15;
    String name;
    if (p.pAdhika) {
      name = shukla ? (hi ? 'पद्मिनी' : 'Padmini') : (hi ? 'परमा' : 'Parama');
    } else if (shukla) {
      name = hi ? _ekaShuklaHi[p.pMonthIdx] : _ekaShuklaEn[p.pMonthIdx];
    } else {
      name = hi ? _ekaKrishnaHi[p.pMonthIdx] : _ekaKrishnaEn[p.pMonthIdx];
    }
    return hi ? '$name एकादशी' : '$name Ekadashi';
  }

  // Display name of an event on a given day (some are named per month).
  static String eventName(String code, PanchangDay? p, String lang) {
    final hi = lang == 'hi';
    final f = _catalog[code];
    if (p != null) {
      if (code == 'ekadashi') return ekadashiName(p, lang);
      if (code == 'purnima') return '${monthName(p.monthIdx, p.adhika, lang)} ${hi ? 'पूर्णिमा' : 'Purnima'}';
      if (code == 'amavasya') return '${monthName(p.monthIdx, p.adhika, lang)} ${hi ? 'अमावस्या' : 'Amavasya'}';
      if (code == 'pradosh_vrat') {
        final tag = p.shukla ? (hi ? 'शुक्ल' : 'Shukla') : (hi ? 'कृष्ण' : 'Krishna');
        final base = (hi ? f?.hi : f?.en) ?? code;
        return '$base ($tag)';
      }
    }
    if (f == null) return code;
    return hi ? f.hi : f.en;
  }

  // All occurrences from [from] for the next [days] days.
  static List<PanchangOccurrence> upcoming(DateTime from, {int days = 365, bool majorOnly = true}) {
    final out = <PanchangOccurrence>[];
    var d = DateTime(from.year, from.month, from.day);
    if (d.isBefore(firstDate)) d = firstDate;
    for (var i = 0; i < days; i++) {
      if (d.isAfter(lastDate)) break;
      final p = day(d);
      if (p != null) {
        for (final c in p.events) {
          if (majorOnly && !isMajor(c)) continue;
          out.add(PanchangOccurrence(d, c));
        }
      }
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  static PanchangOccurrence? nextFestival(DateTime from, {int days = 120}) {
    final list = upcoming(from, days: days);
    for (final o in list) {
      final c = categoryOf(o.code);
      if (c == 'festival') return o;
    }
    return list.isEmpty ? null : list.first;
  }
}
