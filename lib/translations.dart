import 'models.dart';

const sectionLabels = {
  'home': 'Home Expenses',
  'personal': 'Personal Expenses',
  'vehicle': 'Vehicle Expenses',
  'income': 'Income',
  'savings': 'Savings',
};

const hiSectionLabels = {
  'home': 'घरेलू खर्च',
  'personal': 'व्यक्तिगत खर्च',
  'vehicle': 'वाहन खर्च',
  'income': 'आय',
  'savings': 'बचत',
};

const hiNavLabels = {
  'Dashboard': 'डैशबोर्ड',
  'Add': 'जोड़ें',
  'Calendar': 'कैलेंडर',
  'Analytics': 'विश्लेषण',
  'Search': 'खोजें',
};

const hiCategoryLabels = {
  'milk': 'दूध',
  'vegetables': 'सब्जियां',
  'fruits': 'फल',
  'grocery': 'किराना',
  'ration': 'राशन',
  'bakery': 'बेकरी',
  'kitchen': 'रसोई का सामान',
  'rent': 'मकान का किराया',
  'water': 'पानी',
  'electricity': 'बिजली',
  'gas': 'गैस सिलेंडर',
  'internet': 'इंटरनेट',
  'dth': 'डीटीएच',
  'recharge': 'मोबाइल रिचार्ज',
  'maintenance': 'घर रखरखाव',
  'cleaning': 'सफाई',
  'maid': 'नौकरानी वेतन',
  'medicines': 'दवाइयां',
  'hospital': 'अस्पताल',
  'education': 'शिक्षा',
  'gifts': 'उपहार',
  'festival': 'त्यौहार',
  'pets': 'पालतू जानवर',
  'emi': 'ईएमआई',
  'others': 'अन्य',
  'clothes': 'कपड़े',
  'shoes': 'जूते',
  'mobile': 'मोबाइल',
  'laptop': 'लैपटॉप',
  'electronics': 'इलेक्ट्रॉनिक्स',
  'gym': 'जिम',
  'salon': 'सैलून',
  'travel': 'यात्रा',
  'food': 'खाना',
  'entertainment': 'मनोरंजन',
  'shopping': 'शॉपिंग',
  'medicine': 'दवा',
  'insurance': 'बीमा',
  'petrol': 'पेट्रोल',
  'diesel': 'डीजल',
  'cng': 'सीएनजी',
  'service': 'सर्विस',
  'repair': 'मरम्मत',
  'pollution': 'प्रदूषण जांच',
  'washing': 'धुलाई',
  'accessories': 'एसेसरीज',
  'challan': 'चालान',
  'tyres': 'टायर',
  'salary': 'वेतन',
  'business': 'व्यापार',
  'freelance': 'फ्रीलांस',
  'interest': 'ब्याज',
  'investment': 'निवेश',
  'gift': 'उपहार',
  'cash': 'नकद',
  'bank': 'बैंक',
  'fd': 'एफडी',
  'rd': 'आरडी',
  'sip': 'एसआईपी',
  'mutualfund': 'म्यूचुअल फंड',
  'gold': 'सोना',
  'silver': 'चांदी',
  'stocks': 'शेयर',
  'emergency': 'आपातकालीन कोष',
};

String catLabelFor(Category c, String lang) {
  if (lang == 'hi') return hiCategoryLabels[c.key] ?? c.label;
  return c.label;
}

String secLabelFor(String sectionKey, String lang) {
  if (lang == 'hi') return hiSectionLabels[sectionKey] ?? sectionLabels[sectionKey]!;
  return sectionLabels[sectionKey]!;
}

String navLabelFor(String enLabel, String lang) {
  if (lang == 'hi') return hiNavLabels[enLabel] ?? enLabel;
  return enLabel;
}

const hiStrings = {
  'REMAINING BALANCE': 'शेष राशि',
  'Savings': 'बचत',
  'Income(M)': 'आय (माह)',
  'Today': 'आज',
  'This Month (1 - Aaj)': 'इस महीने (1 - आज)',
  'Income (Month)': 'आय (महीना)',
  'Total Savings': 'कुल बचत',
  'This Month by Section': 'इस महीने सेक्शन वार',
  '(tap to view entries)': '(एंट्रीज देखने के लिए टैप करें)',
  'Date': 'तारीख',
  'Amount': 'राशि',
  'Total Amount (editable)': 'कुल राशि (संपादन योग्य)',
  'Note (optional)': 'टिप्पणी (वैकल्पिक)',
  'Save Entry': 'एंट्री सेव करें',
  'Update Entry': 'एंट्री अपडेट करें',
  'Saving...': 'सेव हो रहा है...',
  'Updating...': 'अपडेट हो रहा है...',
  'Category name': 'श्रेणी का नाम',
  'Search notes or category': 'टिप्पणी या श्रेणी खोजें',
  'All': 'सभी',
  'results': 'परिणाम',
  'No matching entries.': 'कोई एंट्री नहीं मिली।',
  'No entries for this date.': 'इस तारीख के लिए कोई एंट्री नहीं।',
  'Add': 'जोड़ें',
  'Dark theme': 'डार्क थीम',
  'Monthly Budgets': 'मासिक बजट',
  'Save Budgets': 'बजट सेव करें',
  'PIN Lock': 'पिन लॉक',
  'Disable PIN': 'पिन बंद करें',
  '4-digit PIN': '4-अंकों का पिन',
  'Set': 'सेट करें',
  'Budgets saved.': 'बजट सेव हो गया।',
  'PIN enabled.': 'पिन चालू हो गया।',
  'PIN disabled.': 'पिन बंद हो गया।',
  'PIN must be 4 digits.': 'पिन 4 अंकों का होना चाहिए।',
};

String tr(String key, String lang) {
  if (lang == 'hi') return hiStrings[key] ?? key;
  return key;
}
