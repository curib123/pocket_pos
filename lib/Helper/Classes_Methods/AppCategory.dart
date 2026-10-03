import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  static const Map<String, String> friendlyNames = {
    "Groceries": "Daily Groceries",
    "Fruits & Vegetables": "Fresh Produce",
    "Snacks": "Quick Bites",
    "Dairy Products": "Milk & Dairy",
    "Frozen Foods": "Frozen Picks",
    "Beverages": "Drinks & Sips",
    "Canned Goods": "Canned Essentials",
    "Bakery": "Bakery Treats",
    "Meat & Poultry": "Meat Corner",
    "Seafood": "Fresh Seafood",

    "Cleaning Supplies": "Cleaning Must-Haves",
    "Laundry Products": "Laundry Essentials",
    "Kitchen Supplies": "Kitchen Tools",
    "Bathroom Essentials": "Bath Time",
    "Paper Products": "Paper Goods",
    "Storage & Organization": "Storage Hacks",

    "Toiletries": "Toiletry Kit",
    "Skincare": "Skincare Goodies",
    "Haircare": "Hair Essentials",
    "Oral Care": "Dental Care",
    "Health & Wellness": "Wellness Zone",

    "Mobile Phones": "Smartphones",
    "Accessories": "Phone Accessories",
    "Home Appliances": "Appliances",
    "Chargers & Batteries": "Chargers & Power",
    "Computers & Tablets": "Computing",

    "Men's Clothing": "Men's Wear",
    "Women's Clothing": "Women's Wear",
    "Children's Clothing": "Kids’ Fashion",
    "Footwear": "Shoes & Kicks",
    "Fashion Accessories": "Style Accessories",

    "Stationery": "Stationery Picks",
    "Notebooks & Paper": "Notebooks",
    "Writing Instruments": "Pens & Markers",
    "Art Materials": "Art Stuff",
    "Office Equipment": "Office Tools",

    "Baby Food": "Baby Meals",
    "Diapers": "Diapers & Wipes",
    "Baby Care": "Baby Essentials",

    "Pet Food": "Pet Snacks",
    "Pet Care": "Pet Wellness",
    "Pet Accessories": "Pet Gear",

    "Furniture": "Home Furniture",
    "Lighting": "Home Lighting",
    "Home Decor": "Decor Vibes",
    "Bedding & Linens": "Sheets & Bedding",
    "Tools & Hardware": "DIY Tools",

    "Car Accessories": "Car Add-ons",
    "Motor Oils": "Motor Fluids",
    "Car Maintenance": "Car Fixes",

    "Toys & Games": "Fun & Games",
    "Sports & Fitness": "Active Life",
    "Books & Magazines": "Reads & Mags",
    "Gifts & Stationery": "Gifts & Cards",
    "Seasonal Items": "Seasonal Picks",
    "Miscellaneous": "Others",
  };

  static const Map<String, IconData> icons = {
    "Groceries": LucideIcons.shoppingCart,
    "Fruits & Vegetables": LucideIcons.apple,
    "Snacks": LucideIcons.pizza,
    "Dairy Products": LucideIcons.glassWater,
    "Frozen Foods": LucideIcons.snowflake,
    "Beverages": LucideIcons.wine,
    "Canned Goods": LucideIcons.box,
    "Bakery": LucideIcons.cakeSlice,
    "Meat & Poultry": LucideIcons.drumstick,
    "Seafood": LucideIcons.fish,

    "Cleaning Supplies": LucideIcons.sprayCan,
    "Laundry Products": LucideIcons.shirt,
    "Kitchen Supplies": LucideIcons.pocketKnife,
    "Bathroom Essentials": LucideIcons.showerHead,
    "Paper Products": LucideIcons.fileText,
    "Storage & Organization": LucideIcons.archive,

    "Toiletries": LucideIcons.partyPopper,
    "Skincare": LucideIcons.sparkles,
    "Haircare": LucideIcons.scissors,
    "Oral Care": LucideIcons.smile,
    "Health & Wellness": LucideIcons.heartPulse,

    "Mobile Phones": LucideIcons.smartphone,
    "Accessories": LucideIcons.headphones,
    "Home Appliances": LucideIcons.airVent,
    "Chargers & Batteries": LucideIcons.batteryCharging,
    "Computers & Tablets": LucideIcons.monitor,

    "Men's Clothing": LucideIcons.shirt,
    "Women's Clothing": LucideIcons.shirt,
    "Children's Clothing": LucideIcons.user,
    "Footwear": LucideIcons.footprints,
    "Fashion Accessories": LucideIcons.watch,

    "Stationery": LucideIcons.clipboardList,
    "Notebooks & Paper": LucideIcons.bookOpen,
    "Writing Instruments": LucideIcons.pencil,
    "Art Materials": LucideIcons.paintbrush,
    "Office Equipment": LucideIcons.printer,

    "Baby Food": LucideIcons.baby,
    "Diapers": LucideIcons.baby,
    "Baby Care": LucideIcons.baby,

    "Pet Food": LucideIcons.bone,
    "Pet Care": LucideIcons.heart,
    "Pet Accessories": LucideIcons.dog,

    "Furniture": LucideIcons.sofa,
    "Lighting": LucideIcons.lightbulb,
    "Home Decor": LucideIcons.image,
    "Bedding & Linens": LucideIcons.bed,
    "Tools & Hardware": LucideIcons.wrench,

    "Car Accessories": LucideIcons.car,
    "Motor Oils": LucideIcons.droplets,
    "Car Maintenance": LucideIcons.settings,

    "Toys & Games": LucideIcons.gamepad2,
    "Sports & Fitness": LucideIcons.dumbbell,
    "Books & Magazines": LucideIcons.bookOpen,
    "Gifts & Stationery": LucideIcons.gift,
    "Seasonal Items": LucideIcons.sun,
    "Miscellaneous": LucideIcons.boxes,
  };

  static const Map<String, Color> colors = {
    // Food & Beverages
    "Groceries": Color(0xFF76D399),
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
