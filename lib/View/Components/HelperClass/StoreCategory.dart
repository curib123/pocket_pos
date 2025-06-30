import 'package:flutter/material.dart';

class StoreCategory {
  static const List<String> all = [
    // Food & Beverages
    "Groceries", "Fruits & Vegetables", "Snacks", "Dairy Products", "Frozen Foods", "Beverages", "Canned Goods", "Bakery", "Meat & Poultry", "Seafood",

    // Household Items
    "Cleaning Supplies", "Laundry Products", "Kitchen Supplies", "Bathroom Essentials", "Paper Products", "Storage & Organization",

    // Personal Care
    "Toiletries", "Skincare", "Haircare", "Oral Care", "Health & Wellness",

    // Electronics
    "Mobile Phones", "Accessories", "Home Appliances", "Chargers & Batteries", "Computers & Tablets",

    // Clothing & Apparel
    "Men's Clothing", "Women's Clothing", "Children's Clothing", "Footwear", "Fashion Accessories",

    // Office & School Supplies
    "Stationery", "Notebooks & Paper", "Writing Instruments", "Art Materials", "Office Equipment",

    // Baby Products
    "Baby Food", "Diapers", "Baby Care",

    // Pet Supplies
    "Pet Food", "Pet Care", "Pet Accessories",

    // Home & Living
    "Furniture", "Lighting", "Home Decor", "Bedding & Linens", "Tools & Hardware",

    // Automotive
    "Car Accessories", "Motor Oils", "Car Maintenance",

    // Others
    "Toys & Games", "Sports & Fitness", "Books & Magazines", "Gifts & Stationery", "Seasonal Items", "Miscellaneous",
  ];

  static const Map<String, IconData> icons = {
    // Food & Beverages
    "Groceries": Icons.shopping_cart,
    "Fruits & Vegetables": Icons.eco,
    "Snacks": Icons.fastfood,
    "Dairy Products": Icons.local_cafe,
    "Frozen Foods": Icons.ac_unit,
    "Beverages": Icons.wine_bar,
    "Canned Goods": Icons.kitchen,
    "Bakery": Icons.cake,
    "Meat & Poultry": Icons.set_meal,
    "Seafood": Icons.lunch_dining,

    // Household Items
    "Cleaning Supplies": Icons.cleaning_services,
    "Laundry Products": Icons.local_laundry_service,
    "Kitchen Supplies": Icons.kitchen,
    "Bathroom Essentials": Icons.bathtub,
    "Paper Products": Icons.description,
    "Storage & Organization": Icons.inventory,

    // Personal Care
    "Toiletries": Icons.soap,
    "Skincare": Icons.face,
    "Haircare": Icons.cut,
    "Oral Care": Icons.masks,
    "Health & Wellness": Icons.favorite,

    // Electronics
    "Mobile Phones": Icons.phone_android,
    "Accessories": Icons.headphones,
    "Home Appliances": Icons.microwave,
    "Chargers & Batteries": Icons.battery_charging_full,
    "Computers & Tablets": Icons.computer,

    // Clothing & Apparel
    "Men's Clothing": Icons.male,
    "Women's Clothing": Icons.female,
    "Children's Clothing": Icons.child_care,
    "Footwear": Icons.hiking,
    "Fashion Accessories": Icons.watch,

    // Office & School Supplies
    "Stationery": Icons.create,
    "Notebooks & Paper": Icons.book,
    "Writing Instruments": Icons.edit,
    "Art Materials": Icons.brush,
    "Office Equipment": Icons.print,

    // Baby Products
    "Baby Food": Icons.baby_changing_station,
    "Diapers": Icons.bed,
    "Baby Care": Icons.family_restroom,

    // Pet Supplies
    "Pet Food": Icons.pets,
    "Pet Care": Icons.medical_services,
    "Pet Accessories": Icons.style,

    // Home & Living
    "Furniture": Icons.weekend,
    "Lighting": Icons.lightbulb,
    "Home Decor": Icons.wallpaper,
    "Bedding & Linens": Icons.bedroom_baby,
    "Tools & Hardware": Icons.handyman,

    // Automotive
    "Car Accessories": Icons.car_repair,
    "Motor Oils": Icons.local_gas_station,
    "Car Maintenance": Icons.build,

    // Others
    "Toys & Games": Icons.toys,
    "Sports & Fitness": Icons.fitness_center,
    "Books & Magazines": Icons.menu_book,
    "Gifts & Stationery": Icons.card_giftcard,
    "Seasonal Items": Icons.calendar_today,
    "Miscellaneous": Icons.all_inbox,
  };

  static const Map<String, Color> colors = {
    // Food & Beverages
    "Groceries": Color(0xFF34D399),
    "Fruits & Vegetables": Color(0xFF4ADE80),
    "Snacks": Color(0xFFFBBF24),
    "Dairy Products": Color(0xFFF472B6),
    "Frozen Foods": Color(0xFF60A5FA),
    "Beverages": Color(0xFF818CF8),
    "Canned Goods": Color(0xFFF59E0B),
    "Bakery": Color(0xFFFFA07A),
    "Meat & Poultry": Color(0xFFEF4444),
    "Seafood": Color(0xFF0EA5E9),

    // Household Items
    "Cleaning Supplies": Color(0xFF06B6D4),
    "Laundry Products": Color(0xFF7C3AED),
    "Kitchen Supplies": Color(0xFFA78BFA),
    "Bathroom Essentials": Color(0xFF8B5CF6),
    "Paper Products": Color(0xFFD1D5DB),
    "Storage & Organization": Color(0xFF6EE7B7),

    // Personal Care
    "Toiletries": Color(0xFFF87171),
    "Skincare": Color(0xFFF9A8D4),
    "Haircare": Color(0xFFE879F9),
    "Oral Care": Color(0xFF60A5F9),
    "Health & Wellness": Color(0xFF16A34A),

    // Electronics
    "Mobile Phones": Color(0xFF6366F1),
    "Accessories": Color(0xFF818CF8),
    "Home Appliances": Color(0xFF4F46E5),
    "Chargers & Batteries": Color(0xFF93C5FD),
    "Computers & Tablets": Color(0xFF1D4ED8),

    // Clothing & Apparel
    "Men's Clothing": Color(0xFF3B82F6),
    "Women's Clothing": Color(0xFFEC4899),
    "Children's Clothing": Color(0xFFFB923C),
    "Footwear": Color(0xFF8B5CF6),
    "Fashion Accessories": Color(0xFF9333EA),

    // Office & School Supplies
    "Stationery": Color(0xFFEF4444),
    "Notebooks & Paper": Color(0xFF10B981),
    "Writing Instruments": Color(0xFF6366F1),
    "Art Materials": Color(0xFFFB7185),
    "Office Equipment": Color(0xFF6B7280),

    // Baby Products
    "Baby Food": Color(0xFFFCD34D),
    "Diapers": Color(0xFFFDE68A),
    "Baby Care": Color(0xFFFFEDD5),

    // Pet Supplies
    "Pet Food": Color(0xFFFB923C),
    "Pet Care": Color(0xFFF87171),
    "Pet Accessories": Color(0xFFF472B6),

    // Home & Living
    "Furniture": Color(0xFFD97706),
    "Lighting": Color(0xFFFDE68A),
    "Home Decor": Color(0xFFFCA5A5),
    "Bedding & Linens": Color(0xFFE0E7FF),
    "Tools & Hardware": Color(0xFF4B5563),

    // Automotive
    "Car Accessories": Color(0xFF6B7280),
    "Motor Oils": Color(0xFF9CA3AF),
    "Car Maintenance": Color(0xFF374151),

    // Others
    "Toys & Games": Color(0xFFFB7185),
    "Sports & Fitness": Color(0xFF10B981),
    "Books & Magazines": Color(0xFF6366F1),
    "Gifts & Stationery": Color(0xFFE879F9),
    "Seasonal Items": Color(0xFFFACC15),
    "Miscellaneous": Color(0xFF9CA3AF),
  };
}
