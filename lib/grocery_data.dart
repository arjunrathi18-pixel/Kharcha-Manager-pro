import 'package:flutter/material.dart';

class GroceryItem {
  final String nameEn;
  final String nameHi;
  const GroceryItem(this.nameEn, this.nameHi);
  String get label => nameHi.isEmpty ? nameEn : '$nameEn ($nameHi)';
}

class GroceryCategory {
  final String key;
  final String label;
  final IconData icon;
  final List<GroceryItem> items;
  const GroceryCategory(this.key, this.label, this.icon, this.items);
}

const vegGroceryCategories = [
  GroceryCategory('pulses', 'Pulses (Dal)', Icons.grain, [
    GroceryItem('Arhar Dal (Toor Dal)', 'अरहर दाल'),
    GroceryItem('Moong Dal', 'मूंग दाल'),
    GroceryItem('Masoor Dal', 'मसूर दाल'),
    GroceryItem('Chana Dal', 'चना दाल'),
    GroceryItem('Urad Dal', 'उड़द दाल'),
    GroceryItem('Rajma', 'राजमा'),
    GroceryItem('Kabuli Chana', 'काबुली चना'),
    GroceryItem('Soybean', 'सोयाबीन'),
  ]),
  GroceryCategory('grains', 'Grains & Rice', Icons.rice_bowl, [
    GroceryItem('Wheat Flour (Atta)', 'गेहूं का आटा'),
    GroceryItem('Basmati Rice', 'बासमती चावल'),
    GroceryItem('Regular Rice', 'सामान्य चावल'),
    GroceryItem('Maize Flour (Makka Atta)', 'मक्का आटा'),
    GroceryItem('Semolina (Suji)', 'सूजी'),
    GroceryItem('Poha', 'पोहा'),
    GroceryItem('Vermicelli (Seviyan)', 'सेवईयां'),
  ]),
  GroceryCategory('oil', 'Oil & Ghee', Icons.opacity, [
    GroceryItem('Mustard Oil', 'सरसों का तेल'),
    GroceryItem('Sunflower Oil', 'सूरजमुखी तेल'),
    GroceryItem('Groundnut Oil', 'मूंगफली का तेल'),
    GroceryItem('Refined Oil', 'रिफाइंड तेल'),
    GroceryItem('Ghee', 'घी'),
    GroceryItem('Coconut Oil', 'नारियल तेल'),
  ]),
  GroceryCategory('vegetables', 'Vegetables', Icons.eco, [
    GroceryItem('Potato', 'आलू'),
    GroceryItem('Onion', 'प्याज'),
    GroceryItem('Tomato', 'टमाटर'),
    GroceryItem('Brinjal', 'बैंगन'),
    GroceryItem('Cauliflower', 'फूलगोभी'),
    GroceryItem('Cabbage', 'पत्तागोभी'),
    GroceryItem('Capsicum', 'शिमला मिर्च'),
    GroceryItem('Lady Finger (Bhindi)', 'भिंडी'),
    GroceryItem('Green Peas', 'हरी मटर'),
    GroceryItem('Carrot', 'गाजर'),
    GroceryItem('Cucumber', 'खीरा'),
    GroceryItem('Spinach', 'पालक'),
    GroceryItem('Garlic', 'लहसुन'),
    GroceryItem('Ginger', 'अदरक'),
    GroceryItem('Green Chilli', 'हरी मिर्च'),
    GroceryItem('Beans', 'सेम/फली'),
  ]),
  GroceryCategory('fruits', 'Fruits', Icons.apple, [
    GroceryItem('Banana', 'केला'),
    GroceryItem('Apple', 'सेब'),
    GroceryItem('Mango', 'आम'),
    GroceryItem('Orange', 'संतरा'),
    GroceryItem('Papaya', 'पपीता'),
    GroceryItem('Grapes', 'अंगूर'),
    GroceryItem('Guava', 'अमरूद'),
    GroceryItem('Pomegranate', 'अनार'),
    GroceryItem('Watermelon', 'तरबूज'),
  ]),
  GroceryCategory('spices', 'Spices & Masala', Icons.local_fire_department, [
    GroceryItem('Turmeric Powder (Haldi)', 'हल्दी पाउडर'),
    GroceryItem('Red Chilli Powder', 'लाल मिर्च पाउडर'),
    GroceryItem('Coriander Powder (Dhania)', 'धनिया पाउडर'),
    GroceryItem('Cumin Seeds (Jeera)', 'जीरा'),
    GroceryItem('Mustard Seeds (Rai)', 'राई'),
    GroceryItem('Garam Masala', 'गरम मसाला'),
    GroceryItem('Salt (Namak)', 'नमक'),
    GroceryItem('Black Pepper (Kali Mirch)', 'काली मिर्च'),
    GroceryItem('Asafoetida (Hing)', 'हींग'),
    GroceryItem('Bay Leaf (Tej Patta)', 'तेज पत्ता'),
  ]),
  GroceryCategory('dairy', 'Dairy', Icons.icecream, [
    GroceryItem('Curd (Dahi)', 'दही'),
    GroceryItem('Paneer', 'पनीर'),
    GroceryItem('Butter', 'मक्खन'),
    GroceryItem('Cheese', 'चीज'),
    GroceryItem('Milk Powder', 'मिल्क पाउडर'),
  ]),
  GroceryCategory('bakery_others', 'Bakery & Others', Icons.bakery_dining, [
    GroceryItem('Bread', 'ब्रेड'),
    GroceryItem('Sugar (Chini)', 'चीनी'),
    GroceryItem('Jaggery (Gud)', 'गुड़'),
    GroceryItem('Tea Leaves (Chai Patti)', 'चाय पत्ती'),
    GroceryItem('Coffee', 'कॉफी'),
    GroceryItem('Biscuits', 'बिस्कुट'),
  ]),
];

const nonVegGroceryCategories = [
  GroceryCategory('meat', 'Meat', Icons.set_meal, [
    GroceryItem('Chicken', 'चिकन'),
    GroceryItem('Mutton', 'मटन'),
    GroceryItem('Beef', 'बीफ'),
    GroceryItem('Pork', 'पोर्क'),
  ]),
  GroceryCategory('fish', 'Fish & Seafood', Icons.phishing, [
    GroceryItem('Rohu Fish', 'रोहू मछली'),
    GroceryItem('Pomfret', 'पॉमफ्रेट'),
    GroceryItem('Prawns', 'झींगा'),
    GroceryItem('Crab', 'केकड़ा'),
  ]),
  GroceryCategory('eggs', 'Eggs', Icons.egg, [
    GroceryItem('Chicken Eggs', 'मुर्गी के अंडे'),
    GroceryItem('Duck Eggs', 'बत्तख के अंडे'),
  ]),
];
