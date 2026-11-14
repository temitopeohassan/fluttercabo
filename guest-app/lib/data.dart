import 'widgets/scenes.dart';

/// Sample content used across screens until the backend exists.

/// Naira to pounds at a fixed sample rate; the PRD shows home currency as an
/// estimate next to every naira price.
String gbp(int naira) => '≈ £${(naira / 2000).toStringAsFixed(2)}';

String naira(int amount) {
  final s = amount.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '₦$b';
}

class Place {
  const Place(
    this.name,
    this.area,
    this.scene,
    this.rating,
    this.reviews, {
    this.category = 'Nature',
    this.fee = 0,
    this.hours = '8:00 – 17:00',
  });
  final String name;
  final String area;
  final SceneKind scene;
  final double rating;
  final String reviews;
  final String category;
  final int fee;
  final String hours;
}

const places = [
  Place(
    'Lekki Conservation Centre',
    'Lekki',
    SceneKind.nature,
    4.8,
    '2.3k',
    fee: 3000,
  ),
  Place(
    'Nike Art Gallery',
    'Lekki',
    SceneKind.art,
    4.7,
    '1.8k',
    category: 'Art',
    hours: '10:00 – 18:00',
  ),
  Place(
    'Tarkwa Bay Beach',
    'Lagos Harbour',
    SceneKind.beach,
    4.6,
    '1.1k',
    category: 'Beaches',
    fee: 2000,
    hours: 'Open daily',
  ),
  Place(
    'Freedom Park',
    'Lagos Island',
    SceneKind.heritage,
    4.5,
    '940',
    category: 'History',
    fee: 1000,
    hours: '9:00 – 22:00',
  ),
];

class Tour {
  const Tour(
    this.name,
    this.partner,
    this.scene,
    this.category,
    this.price,
    this.duration,
    this.rating,
    this.reviews, {
    this.group = '1 – 10',
    this.area = 'Lagos',
  });
  final String name;
  final String partner;
  final SceneKind scene;
  final String category;
  final int price;
  final String duration;
  final double rating;
  final String reviews;
  final String group;
  final String area;
}

const tours = [
  Tour(
    'Lekki Conservation Centre',
    'Eko Nature Trails',
    SceneKind.nature,
    'Nature & Wildlife',
    15000,
    '4 hours',
    4.8,
    '2.3k',
    area: 'Lekki',
  ),
  Tour(
    'Tarkwa Bay Boat Trip',
    'Funmi Island Tours',
    SceneKind.beach,
    'Island Tours',
    25000,
    '6 hours',
    4.7,
    '860',
    group: '2 – 12',
  ),
  Tour(
    'Lagos Island Heritage Walk',
    'Eko Heritage Tours',
    SceneKind.heritage,
    'Cultural',
    18000,
    '5 hours',
    4.9,
    '540',
    area: 'Lagos Island',
  ),
  Tour(
    'Lagos Street Food Tour',
    'Taste of Eko',
    SceneKind.food,
    'Food',
    22000,
    '3 hours',
    4.8,
    '710',
    group: '1 – 8',
  ),
  Tour(
    'Victoria Island Nightlife',
    'Lagos After Dark',
    SceneKind.nightlife,
    'Nightlife',
    30000,
    '5 hours',
    4.5,
    '320',
    area: 'Victoria Island',
  ),
  Tour(
    'Nike Art Gallery Visit',
    'Eko Heritage Tours',
    SceneKind.art,
    'City Tours',
    12000,
    '2 hours',
    4.7,
    '1.2k',
    area: 'Lekki',
  ),
];

const tourCategories = [
  'Island Tours',
  'Cultural',
  'City Tours',
  'Nightlife',
  'Nature & Wildlife',
  'Food',
];
