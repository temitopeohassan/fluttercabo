import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 5. Cabo Tours.

const _tour = Tour(
  'Lekki Conservation Centre',
  'Eko Nature Trails',
  SceneKind.nature,
  'Nature & Wildlife',
  15000,
  '4 hours',
  4.8,
  '2.3k',
  area: 'Lekki',
);

const _categoryIcons = {
  'Island Tours': Icons.sailing_rounded,
  'Cultural': Icons.account_balance_rounded,
  'City Tours': Icons.location_city_rounded,
  'Nightlife': Icons.nightlife_rounded,
  'Nature & Wildlife': Icons.forest_rounded,
  'Food': Icons.restaurant_rounded,
};

class ToursHomeScreen extends StatelessWidget {
  const ToursHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Tours & Experiences', style: CaboText.h1),
            Text(
              'Curated by trusted local guides',
              style: CaboText.muted.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 14),
            SearchBox(
              hint: 'Search tours',
              onTap: () => go(context, '/tour-list'),
            ),
            const SectionTitle('Categories'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                for (final c in tourCategories)
                  CaboCard(
                    color: CaboColors.surface,
                    onTap: () => go(context, '/tour-list'),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categoryIcons[c],
                          color: CaboColors.green,
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c,
                          textAlign: TextAlign.center,
                          style: CaboText.label.copyWith(color: CaboColors.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SectionTitle(
              'Featured',
              action: 'See all',
              onAction: () => go(context, '/tour-list'),
            ),
            GestureDetector(
              onTap: () => go(context, '/tour-detail'),
              child: Stack(
                children: [
                  const Scene(SceneKind.beach, height: 180),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarkwa Bay Boat Trip',
                                  style: CaboText.h3,
                                ),
                                Text(
                                  '6 hours • ★ 4.7 • from ${naira(25000)}',
                                  style: CaboText.muted,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: CaboColors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Popular this week'),
            for (final t in tours.take(3))
              TourTile(t, onTap: () => go(context, '/tour-detail')),
          ],
        ),
      ),
      bottomNavigationBar: const RiderNav(2),
    );
  }
}

class TourListScreen extends StatelessWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'All tours',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: CaboColors.green),
          onPressed: () => go(context, '/tour-filters'),
        ),
      ],
      children: [
        const ChipPicker(
          options: [
            'All',
            'Under ₦20k',
            'This weekend',
            'Groups',
            'Accessible',
          ],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 14),
        Text('${tours.length} tours in Lagos', style: CaboText.label),
        const SizedBox(height: 10),
        for (final (i, t) in tours.indexed)
          TourTile(t, saved: i == 1, onTap: () => go(context, '/tour-detail')),
      ],
    );
  }
}

class TourFiltersScreen extends StatefulWidget {
  const TourFiltersScreen({super.key});

  @override
  State<TourFiltersScreen> createState() => _TourFiltersScreenState();
}

class _TourFiltersScreenState extends State<TourFiltersScreen> {
  RangeValues price = const RangeValues(5000, 30000);

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Filters',
      actions: [
        TextButton(
          onPressed: () {},
          child: Text(
            'Reset',
            style: CaboText.label.copyWith(color: CaboColors.green),
          ),
        ),
      ],
      bottom: CaboButton('Show 4 tours', onPressed: () => back(context)),
      children: [
        const SectionTitle('Price per person'),
        Text(
          '${naira(price.start.round())} – ${naira(price.end.round())}',
          style: CaboText.h3,
        ),
        RangeSlider(
          values: price,
          min: 0,
          max: 60000,
          divisions: 12,
          onChanged: (v) => setState(() => price = v),
        ),
        const SectionTitle('Date'),
        const ChipPicker(
          options: ['Today', 'Tomorrow', 'This weekend', 'Pick dates'],
          initial: {2},
          single: true,
        ),
        const SectionTitle('Duration'),
        const ChipPicker(
          options: ['Up to 2 h', '2 – 4 h', 'Half day', 'Full day'],
          initial: {1, 2},
        ),
        const SectionTitle('Rating'),
        const ChipPicker(
          options: ['Any', '4.0+', '4.5+'],
          initial: {2},
          single: true,
        ),
        const SectionTitle('Group size'),
        const ChipPicker(
          options: ['Solo', '2 – 4', '5 – 10', '10+'],
          initial: {1},
          single: true,
        ),
        const SectionTitle('Language'),
        const ChipPicker(
          options: ['English', 'French', 'Yoruba', 'Spanish'],
          initial: {0},
        ),
      ],
    );
  }
}

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(
        context,
        'Book a Tour',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Stack(
            children: [
              const Scene(SceneKind.nature, height: 200),
              Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      color: CaboColors.red,
                      size: 20,
                    ),
                    onPressed: () => go(context, '/wishlist'),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == 0 ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == 0 ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_tour.name, style: CaboText.h1),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => go(context, '/tour-reviews'),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: CaboColors.yellow,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text('4.8', style: CaboText.h3),
                const SizedBox(width: 4),
                Text('(2.3k reviews)', style: CaboText.muted),
                const Spacer(),
                Text('by ${_tour.partner}', style: CaboText.label),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FactRow([
            (Icons.schedule_rounded, 'Duration', '4 hours'),
            (Icons.place_rounded, 'Location', 'Lekki, Lagos'),
            (Icons.groups_rounded, 'Group Size', '1 – 10'),
          ]),
          const SectionTitle('Description'),
          Text(
            'Explore the Lekki Conservation Centre, home to rich biodiversity, the famous canopy '
            'walkway and nature trails. Spot monkeys, peacocks and crocodiles with a trained naturalist.',
            style: CaboText.body,
          ),
          const SizedBox(height: 14),
          MenuTile(
            icon: Icons.route_rounded,
            title: 'Itinerary and what is included',
            subtitle: '5 stops • entry fee and guide included',
            onTap: () => go(context, '/tour-itinerary'),
          ),
          MenuTile(
            icon: Icons.reviews_rounded,
            title: 'Reviews',
            subtitle: '"The canopy walk was unforgettable!"',
            onTap: () => go(context, '/tour-reviews'),
          ),
          const MenuTile(
            icon: Icons.event_busy_rounded,
            title: 'Free cancellation',
            subtitle: 'Up to 24 hours before the tour starts',
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  naira(_tour.price),
                  style: CaboText.h2.copyWith(color: CaboColors.green),
                ),
                Text('per person • ${gbp(_tour.price)}', style: CaboText.label),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CaboButton(
                'Book Now',
                onPressed: () => go(context, '/tour-date'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TourItineraryScreen extends StatelessWidget {
  const TourItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stops = [
      (
        '09:00',
        'Meet at the visitor centre',
        'Lekki-Epe Expressway, opposite Chevron',
      ),
      (
        '09:15',
        'Nature trail and boardwalk',
        'Monkeys, peacocks and tortoises',
      ),
      ('10:15', 'Canopy walkway', '401 m, the longest in Africa'),
      ('11:30', 'Tree house and picnic area', 'Snacks and water break'),
      ('12:30', 'Family park and gift shop', 'Tour ends'),
    ];
    return CaboScaffold(
      title: 'Itinerary',
      children: [
        for (final (i, (time, title, sub)) in stops.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 50, child: Text(time, style: CaboText.label)),
              Column(
                children: [
                  const Icon(Icons.circle, size: 14, color: CaboColors.green),
                  if (i < stops.length - 1)
                    Container(width: 2, height: 44, color: CaboColors.line),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(sub, style: CaboText.muted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        const SectionTitle('Included'),
        const CheckRow('Entry fee and canopy walkway ticket'),
        const CheckRow('Certified naturalist guide'),
        const CheckRow('Bottled water and snacks'),
        const SectionTitle('Not included'),
        const CheckRow(
          'Transport to the meeting point (add a Cabo ride)',
          done: false,
        ),
        const CheckRow('Tips for your guide', done: false),
        const SectionTitle('Your guide'),
        CaboCard(
          child: Row(
            children: [
              const Avatar('FA', size: 52, color: CaboColors.greenSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Funke Adebayo', style: CaboText.h3),
                    Text(
                      'Naturalist • 8 years • English, Yoruba',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: CaboColors.green),
            ],
          ),
        ),
        const SectionTitle('Cancellation policy'),
        Text(
          'Full refund up to 24 hours before. 50% refund up to 6 hours before. No refund after that.',
          style: CaboText.body,
        ),
      ],
    );
  }
}

class TourReviewsScreen extends StatelessWidget {
  const TourReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const dist = [(5, 0.82), (4, 0.13), (3, 0.03), (2, 0.01), (1, 0.01)];
    return CaboScaffold(
      title: 'Reviews',
      children: [
        CaboCard(
          child: Row(
            children: [
              Column(
                children: [
                  Text('4.8', style: CaboText.display),
                  const Stars(4.8),
                  Text('2,314 reviews', style: CaboText.label),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final (s, v) in dist)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text('$s', style: CaboText.label),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Bar(
                                v,
                                color: CaboColors.yellow,
                                height: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final (name, from, rating, text, ago) in const [
          (
            'Amara',
            'United Kingdom',
            5.0,
            'The canopy walk was unforgettable! Funke knew every bird by name.',
            '2 days ago',
          ),
          (
            'Daniel',
            'Kenya',
            5.0,
            'Great half-day trip. The Cabo ride there was waiting for us after.',
            'Last week',
          ),
          (
            'Léa',
            'France',
            4.0,
            'Beautiful park. Bring mosquito spray and comfortable shoes.',
            '3 weeks ago',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(name.substring(0, 1), size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: CaboText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('$from • $ago', style: CaboText.label),
                          ],
                        ),
                      ),
                      Stars(rating, size: 15),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(text, style: CaboText.body),
                  const SizedBox(height: 4),
                  const Pill('Verified booking', icon: Icons.verified_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TourDateScreen extends StatefulWidget {
  const TourDateScreen({super.key});

  @override
  State<TourDateScreen> createState() => _TourDateScreenState();
}

class _TourDateScreenState extends State<TourDateScreen> {
  int day = 2;
  int slot = 0;

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Fri', '16', 3),
      ('Sat', '17', 0),
      ('Sun', '18', 6),
      ('Mon', '19', 8),
      ('Tue', '20', 10),
    ];
    const slots = [
      ('09:00', '6 spots left'),
      ('13:00', '2 spots left'),
      ('15:30', 'Sold out'),
    ];
    return CaboScaffold(
      title: 'Date and guests',
      bottom: CaboButton(
        'Continue • ${naira(30000)}',
        onPressed: () => go(context, '/tour-addons'),
      ),
      children: [
        Text(_tour.name, style: CaboText.h3),
        const SectionTitle('October'),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final soldOut = days[i].$3 == 0;
              final sel = i == day;
              return GestureDetector(
                onTap: soldOut ? null : () => setState(() => day = i),
                child: Opacity(
                  opacity: soldOut ? 0.4 : 1,
                  child: Container(
                    width: 62,
                    decoration: BoxDecoration(
                      color: sel ? CaboColors.green : CaboColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[i].$1,
                          style: CaboText.label.copyWith(
                            color: sel ? Colors.white70 : CaboColors.muted,
                          ),
                        ),
                        Text(
                          days[i].$2,
                          style: CaboText.h2.copyWith(
                            color: sel ? Colors.white : CaboColors.ink,
                          ),
                        ),
                        Text(
                          soldOut ? 'Full' : '${days[i].$3} left',
                          style: CaboText.label.copyWith(
                            fontSize: 10,
                            color: sel ? Colors.white70 : CaboColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SectionTitle('Time'),
        for (var i = 0; i < slots.length; i++)
          Opacity(
            opacity: i == 2 ? 0.45 : 1,
            child: SelectTile(
              icon: Icons.schedule_rounded,
              title: slots[i].$1,
              subtitle: slots[i].$2,
              selected: slot == i,
              onTap: i == 2 ? () {} : () => setState(() => slot = i),
            ),
          ),
        const SectionTitle('Guests'),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Adults × 2', naira(30000)),
              const InfoRow('Children × 0', '₦0'),
            ],
          ),
        ),
      ],
    );
  }
}

class TourAddonsScreen extends StatelessWidget {
  const TourAddonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Add-ons',
      bottom: CaboButton(
        'Continue to payment',
        onPressed: () => go(context, '/tour-checkout'),
      ),
      children: [
        CaboCard(
          color: CaboColors.greenSoft,
          borderColor: CaboColors.green,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.local_taxi_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cabo ride to the meeting point', style: CaboText.h3),
                    Text(
                      'Booked automatically for Sun 18 Oct, pickup 08:20 from Eko Hotel.',
                      style: CaboText.muted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+ ${naira(6500)}',
                      style: CaboText.h3.copyWith(color: CaboColors.green),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_box_rounded, color: CaboColors.green),
            ],
          ),
        ),
        const SectionTitle('From Eko Nature Trails'),
        for (final (icon, title, sub, price, on) in const [
          (
            Icons.photo_camera_rounded,
            'Photographer',
            '40+ edited photos within 48 hours',
            12000,
            false,
          ),
          (
            Icons.lunch_dining_rounded,
            'Picnic lunch',
            'Jollof rice, plantain and drinks',
            5000,
            true,
          ),
          (
            Icons.lock_person_rounded,
            'Private upgrade',
            'Just your group and the guide',
            20000,
            false,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              borderColor: on ? CaboColors.green : null,
              child: Row(
                children: [
                  IconBadge(icon, color: CaboColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: CaboText.h3),
                        Text(sub, style: CaboText.muted),
                        Text(
                          '+ ${naira(price)}',
                          style: CaboText.label.copyWith(color: CaboColors.ink),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    on
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: on ? CaboColors.green : CaboColors.muted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TourCheckoutScreen extends StatelessWidget {
  const TourCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Checkout',
      bottom: CaboButton(
        'Pay ${naira(33200)}',
        onPressed: () => go(context, '/tour-confirmed'),
      ),
      children: [
        Row(
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: Scene(SceneKind.nature, height: 72, radius: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tour.name, style: CaboText.h3),
                  Text('Sun 18 Oct • 09:00 • 2 adults', style: CaboText.muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Tour × 2', naira(30000)),
              InfoRow('Picnic lunch', naira(5000)),
              InfoRow('Cabo ride to meeting point', naira(6500)),
              InfoRow(
                'Promo WELCOME20',
                '− ${naira(8300)}',
                valueColor: CaboColors.green,
              ),
              const Divider(height: 20),
              InfoRow('Total', naira(33200), bold: true),
              Align(
                alignment: Alignment.centerRight,
                child: Text(gbp(33200), style: CaboText.label),
              ),
            ],
          ),
        ),
        const SectionTitle('Pay with'),
        const SingleChoice(
          icons: [
            Icons.credit_card_rounded,
            Icons.account_balance_rounded,
            Icons.account_balance_wallet_rounded,
          ],
          options: [
            ('Visa •• 4242', null),
            ('Bank transfer', 'Pay to a virtual account'),
            ('Cabo Wallet', 'Balance ₦12,400'),
          ],
        ),
        CaboField(
          'Company name for invoice (optional)',
          hint: 'e.g. Bakare Consulting Ltd',
        ),
      ],
    );
  }
}

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Bank transfer',
      bottom: CaboButton(
        "I've sent the money",
        onPressed: () => go(context, '/tour-confirmed'),
      ),
      children: [
        Text('Transfer exactly', style: CaboText.muted.copyWith(fontSize: 15)),
        Text(
          naira(33200),
          style: CaboText.display.copyWith(color: CaboColors.green),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: const Pill(
            'Expires in 29:41',
            icon: Icons.timer_outlined,
            color: CaboColors.orange,
          ),
        ),
        const SizedBox(height: 18),
        CaboCard(
          child: Column(
            children: [
              for (final (label, value) in const [
                ('Bank', 'Wema Bank'),
                ('Account number', '7821 004 593'),
                ('Account name', 'CABO / TUNDE BAKARE'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: CaboText.label),
                            Text(value, style: CaboText.h3),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.copy_rounded,
                        color: CaboColors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'This account is only for this booking. We confirm automatically as soon as the money arrives.',
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class TourConfirmedScreen extends StatelessWidget {
  const TourConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.confirmation_number_rounded,
      title: "You're going!",
      message:
          '${_tour.name}, Sun 18 Oct at 09:00. Your ride to the meeting point is booked too.',
      primary: 'View ticket',
      onPrimary: () => go(context, '/ticket'),
      secondary: 'Add to calendar',
      onSecondary: () {},
      extra: const CaboCard(
        color: CaboColors.surface,
        child: Column(
          children: [
            InfoRow('Booking', 'CB-TR-88214'),
            InfoRow('Guests', '2 adults'),
            InfoRow('Ride', 'Pickup 08:20, Eko Hotel'),
            InfoRow('Email', 'Confirmation sent'),
          ],
        ),
      ),
    );
  }
}

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaboColors.green,
      appBar: AppBar(
        backgroundColor: CaboColors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => back(context),
        ),
        title: Text(
          'Your ticket',
          style: CaboText.h3.copyWith(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  _tour.name,
                  style: CaboText.h2,
                  textAlign: TextAlign.center,
                ),
                Text('Sun 18 Oct 2026 • 09:00', style: CaboText.muted),
                const SizedBox(height: 18),
                const FakeQr(size: 210),
                const SizedBox(height: 12),
                Text(
                  'CB-TR-88214',
                  style: CaboText.h3.copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show this to your guide at check-in',
                  style: CaboText.muted,
                ),
                const Divider(height: 32),
                const InfoRow('Guests', 'Tunde Bakare + 1'),
                const InfoRow('Meeting point', 'Visitor centre gate'),
                const InfoRow('Guide', 'Funke Adebayo'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CaboButton(
            'Reschedule or cancel',
            style: CaboButtonStyle.light,
            onPressed: () => go(context, '/tour-cancel'),
          ),
        ],
      ),
    );
  }
}

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int stars = 5;

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Review your tour',
      bottom: CaboButton('Post review', onPressed: () => back(context)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: const Pill(
            'Checked in Sun 11 Oct',
            icon: Icons.verified_rounded,
          ),
        ),
        const SizedBox(height: 10),
        Text('Lagos Island Heritage Walk', style: CaboText.h2),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 42,
                onPressed: () => setState(() => stars = i),
                icon: Icon(
                  i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: CaboColors.yellow,
                ),
              ),
          ],
        ),
        const SectionTitle('Highlights'),
        const ChipPicker(
          options: [
            'Great guide',
            'Good value',
            'Well organised',
            'Safe',
            'Fun for groups',
          ],
          initial: {0, 2},
        ),
        const SizedBox(height: 18),
        const CaboField(
          'Your review',
          value: 'Emeka brought Lagos history to life. The Brazilian Quarter was the highlight.',
          maxLines: 4,
        ),
        Text('Add photos', style: CaboText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: CaboColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CaboColors.line),
                ),
                child: i == 0
                    ? const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        child: Scene(SceneKind.heritage, radius: 0),
                      )
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        color: CaboColors.green,
                      ),
              ),
          ],
        ),
      ],
    );
  }
}

class TourCancelScreen extends StatelessWidget {
  const TourCancelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Change booking',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaboButton('Reschedule', onPressed: () => go(context, '/tour-date')),
          const SizedBox(height: 10),
          CaboButton(
            'Cancel and refund ${naira(33200)}',
            style: CaboButtonStyle.secondary,
            height: 48,
            onPressed: () => back(context),
          ),
        ],
      ),
      children: [
        CaboCard(
          child: Row(
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: Scene(SceneKind.nature, height: 64, radius: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tour.name, style: CaboText.h3),
                    Text(
                      'Sun 18 Oct • 09:00 • 2 adults',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Refund policy'),
        for (final (period, refund, active) in const [
          ('More than 24 hours before', 'Full refund', true),
          ('6 – 24 hours before', '50% refund', false),
          ('Less than 6 hours before', 'No refund', false),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  active
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: active ? CaboColors.green : CaboColors.muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(period, style: CaboText.body)),
                Text(
                  refund,
                  style: CaboText.label.copyWith(
                    color: active ? CaboColors.green : CaboColors.muted,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        CaboCard(
          color: CaboColors.greenSoft,
          child: Text(
            'You are more than 24 hours away, so you get everything back, including the ride add-on. '
            'Card refunds take 3 – 5 working days.',
            style: CaboText.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class PrivateTourScreen extends StatelessWidget {
  const PrivateTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Request a private tour',
      bottom: CaboButton('Send request', onPressed: () => back(context)),
      children: [
        Text(
          'Tell local partners what you would like. You will get quotes within 24 hours.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SectionTitle('Interests'),
        const ChipPicker(
          options: [
            'History',
            'Art',
            'Food',
            'Beaches',
            'Nightlife',
            'Shopping',
            'Nature',
          ],
          initial: {0, 1, 2},
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: CaboField(
                'Date',
                value: 'Tue 20 Oct',
                icon: Icons.event_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CaboField(
                'Guests',
                value: '6 adults',
                icon: Icons.groups_rounded,
              ),
            ),
          ],
        ),
        const CaboField(
          'Budget per person',
          value: '₦40,000 – ₦60,000',
          icon: Icons.payments_outlined,
        ),
        const CaboField(
          'Anything else?',
          value: 'Family reunion trip. One guest uses a wheelchair.',
          maxLines: 3,
        ),
      ],
    );
  }
}
