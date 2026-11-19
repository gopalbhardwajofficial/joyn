import 'package:flutter/material.dart';

class ClipartItem {
  final String key;
  final String name;
  final IconData icon;
  final String category;

  const ClipartItem({
    required this.key,
    required this.name,
    required this.icon,
    required this.category,
  });
}

class ClipartService {
  static const List<String> categories = [
    'Mine',
    'Emoji',
    'Halloween',
    'Weather',
    'Thanksgiving Day',
    'Animals',
    'Logistics',
    'Warning',
  ];

  static const List<ClipartItem> cliparts = [
    // Halloween
    ClipartItem(key: 'moon', name: 'Moon', icon: Icons.nightlight_round, category: 'Halloween'),
    ClipartItem(key: 'pumpkin', name: 'Pumpkin', icon: Icons.sentiment_very_satisfied, category: 'Halloween'),
    ClipartItem(key: 'demon', name: 'Demon', icon: Icons.sports_kabaddi, category: 'Halloween'),
    ClipartItem(key: 'spiderweb', name: 'Web', icon: Icons.blur_on, category: 'Halloween'),
    ClipartItem(key: 'witch', name: 'Witch', icon: Icons.auto_awesome, category: 'Halloween'),
    ClipartItem(key: 'bat', name: 'Bat', icon: Icons.pest_control, category: 'Halloween'),
    ClipartItem(key: 'cat', name: 'Cat', icon: Icons.pets, category: 'Halloween'),
    ClipartItem(key: 'skull', name: 'Skull', icon: Icons.dangerous, category: 'Halloween'),

    // Emoji
    ClipartItem(key: 'heart', name: 'Heart', icon: Icons.favorite, category: 'Emoji'),
    ClipartItem(key: 'star', name: 'Star', icon: Icons.star, category: 'Emoji'),
    ClipartItem(key: 'smile', name: 'Smile', icon: Icons.sentiment_satisfied_alt, category: 'Emoji'),
    ClipartItem(key: 'gift', name: 'Gift', icon: Icons.card_giftcard, category: 'Emoji'),
    ClipartItem(key: 'balloon', name: 'Balloon', icon: Icons.bubble_chart, category: 'Emoji'),
    ClipartItem(key: 'envelope', name: 'Envelope', icon: Icons.mail_outline, category: 'Emoji'),
    ClipartItem(key: 'celebration', name: 'Sparkle', icon: Icons.celebration, category: 'Emoji'),
    ClipartItem(key: 'thumb_up', name: 'Like', icon: Icons.thumb_up, category: 'Emoji'),

    // Logistics
    ClipartItem(key: 'box', name: 'Package', icon: Icons.inventory_2, category: 'Logistics'),
    ClipartItem(key: 'truck', name: 'Delivery', icon: Icons.local_shipping, category: 'Logistics'),
    ClipartItem(key: 'qr_scan', name: 'Scan', icon: Icons.qr_code_scanner, category: 'Logistics'),
    ClipartItem(key: 'receipt', name: 'Receipt', icon: Icons.receipt_long, category: 'Logistics'),
    ClipartItem(key: 'store', name: 'Store', icon: Icons.storefront, category: 'Logistics'),
    ClipartItem(key: 'pallet', name: 'Warehouse', icon: Icons.warehouse, category: 'Logistics'),

    // Warning
    ClipartItem(key: 'fragile', name: 'Fragile', icon: Icons.wine_bar, category: 'Warning'),
    ClipartItem(key: 'keep_dry', name: 'Keep Dry', icon: Icons.umbrella, category: 'Warning'),
    ClipartItem(key: 'this_way_up', name: 'This Way Up', icon: Icons.arrow_upward, category: 'Warning'),
    ClipartItem(key: 'recycle', name: 'Recycle', icon: Icons.recycling, category: 'Warning'),
    ClipartItem(key: 'warning_sign', name: 'Warning', icon: Icons.warning_amber_rounded, category: 'Warning'),
    ClipartItem(key: 'fire', name: 'Flammable', icon: Icons.local_fire_department, category: 'Warning'),

    // Weather
    ClipartItem(key: 'sun', name: 'Sunny', icon: Icons.wb_sunny, category: 'Weather'),
    ClipartItem(key: 'cloud', name: 'Cloudy', icon: Icons.cloud, category: 'Weather'),
    ClipartItem(key: 'rain', name: 'Rain', icon: Icons.water_drop, category: 'Weather'),
    ClipartItem(key: 'snow', name: 'Snow', icon: Icons.ac_unit, category: 'Weather'),

    // Animals
    ClipartItem(key: 'dog', name: 'Dog', icon: Icons.cruelty_free, category: 'Animals'),
    ClipartItem(key: 'bird', name: 'Bird', icon: Icons.flutter_dash, category: 'Animals'),
  ];

  static IconData getIcon(String key) {
    final item = cliparts.firstWhere(
      (c) => c.key == key,
      orElse: () => const ClipartItem(key: 'star', name: 'Star', icon: Icons.star, category: 'Emoji'),
    );
    return item.icon;
  }
}

