import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 2. Home and discovery.

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.label, this.icon, this.bg, this.fg, this.route);
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String route;

  @override
  Widget build(BuildContext context) {
    return CaboCard(
      color: bg,
      radius: 18,
      onTap: () => go(context, route),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, size: 32, color: fg),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: CaboText.h3.copyWith(fontSize: 15, color: CaboColors.ink),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const CaboLogo(size: 36),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: CaboColors.green,
                      ),
                      onPressed: () => go(context, '/notifications'),
                    ),
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: CaboColors.yellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Good morning, Tunde!', style: CaboText.h1),
            Text(
              'Where would you like to go today?',
              style: CaboText.muted.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 16),
            SearchBox(
              hint: 'Search destinations, rides or places',
              onTap: () => go(context, '/search'),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    'Ride\nHailing',
                    Icons.local_taxi_rounded,
                    CaboColors.greenSoft,
                    CaboColors.green,
                    '/where-to',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    'Tours &\nExperiences',
                    Icons.tour_rounded,
                    CaboColors.yellowSoft,
                    Color(0xFFE0A800),
                    '/tours',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    'Explore',
                    Icons.explore_rounded,
                    Color(0xFFE6F0FB),
                    CaboColors.blue,
                    '/explore',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    'Airport\nShuttle',
                    Icons.flight_land_rounded,
                    Color(0xFFFDEDE1),
                    CaboColors.orange,
                    '/shuttle',
                  ),
                ),
              ],
            ),
            const SectionTitle('Upcoming'),
            CaboCard(
              onTap: () => go(context, '/shuttle-assigned'),
              child: Row(
                children: [
                  const IconBadge(
                    Icons.flight_land_rounded,
                    color: CaboColors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Airport pickup • Sat 10 Oct, 06:30',
                          style: CaboText.h3.copyWith(fontSize: 14),
                        ),
                        Text(
                          'MMIA Terminal 2 → Ikoyi • Driver assigned',
                          style: CaboText.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: CaboColors.muted),
                ],
              ),
            ),
            SectionTitle(
              'Popular Destinations',
              action: 'See all',
              onAction: () => go(context, '/explore'),
            ),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => DestinationCard(
                  places[i],
                  width: 112,
                  onTap: () => go(context, '/attraction'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CaboCard(
              color: CaboColors.greenSoft,
              onTap: () => go(context, '/mobility'),
              child: Row(
                children: [
                  const IconBadge(Icons.accessible_forward_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Accessible rides & tours', style: CaboText.h3),
                        Text(
                          'Vehicles and guides for every traveller',
                          style: CaboText.muted,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: CaboColors.green),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RiderNav(0),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget group(
      String title,
      List<(IconData, String, String, String)> items,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        for (final (icon, name, sub, route) in items)
          MenuTile(
            icon: icon,
            title: name,
            subtitle: sub,
            onTap: () => go(context, route),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => back(context),
            ),
            const Expanded(child: SearchBox(value: 'lekki')),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          group('Places', const [
            (
              Icons.place_rounded,
              'Lekki Phase 1',
              'Neighbourhood, Lagos',
              '/choose-ride',
            ),
            (
              Icons.shopping_bag_rounded,
              'The Palms Shopping Mall',
              'Lekki • 6.1 km',
              '/choose-ride',
            ),
            (
              Icons.toll_rounded,
              'Lekki Toll Gate',
              'Lekki-Epe Expressway',
              '/choose-ride',
            ),
          ]),
          group('Tours', const [
            (
              Icons.forest_rounded,
              'Lekki Conservation Centre tour',
              '4 hours • ₦15,000',
              '/tour-detail',
            ),
            (
              Icons.palette_rounded,
              'Nike Art Gallery visit',
              '2 hours • ₦12,000',
              '/tour-detail',
            ),
          ]),
          group('Attractions', const [
            (
              Icons.park_rounded,
              'Lekki Conservation Centre',
              'Nature • ★ 4.8',
              '/attraction',
            ),
            (
              Icons.beach_access_rounded,
              'Elegushi Beach',
              'Beaches • ★ 4.3',
              '/attraction',
            ),
          ]),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.local_taxi_rounded,
        CaboColors.green,
        'Your driver is assigned',
        'Emeka will meet you at MMIA Arrivals, Exit B on Sat 10 Oct.',
        '5 min ago',
        '/shuttle-assigned',
      ),
      (
        Icons.qr_code_2_rounded,
        CaboColors.blue,
        'Tour ticket ready',
        'Lekki Conservation Centre, Sun 11 Oct, 9:00. Show your QR at check-in.',
        '1 h ago',
        '/ticket',
      ),
      (
        Icons.local_offer_rounded,
        CaboColors.orange,
        '20% off your first tour',
        'Use code WELCOME20 at checkout. Ends Sunday.',
        'Yesterday',
        '/promos',
      ),
      (
        Icons.receipt_long_rounded,
        CaboColors.muted,
        'Receipt for your ride',
        'Eko Hotel → Nike Art Gallery • ₦3,500',
        'Mon',
        '/receipt',
      ),
    ];
    return CaboScaffold(
      title: 'Notifications',
      children: [
        for (final (icon, color, title, body, time, route) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              onTap: () => go(context, route),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon, color: color),
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
                        Text(body, style: CaboText.muted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(time, style: CaboText.label.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MobilityScreen extends StatelessWidget {
  const MobilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Mobility Inclusive',
      bottom: CaboButton(
        'Book Now',
        onPressed: () => go(context, '/choose-ride'),
      ),
      children: [
        const Scene(SceneKind.van, height: 190),
        const SizedBox(height: 18),
        Text('Accessible Rides & Tours', style: CaboText.h2),
        const SizedBox(height: 6),
        Text(
          'We are committed to making travel inclusive for everyone. Our fleet and tour '
          'experiences accommodate individuals with mobility and visual impairments.',
          style: CaboText.body,
        ),
        const SizedBox(height: 14),
        const CheckRow('Standard vehicles'),
        const CheckRow('Premium vehicles'),
        const CheckRow('Group transport'),
        const CheckRow('Wheelchair-accessible vans with ramps'),
        const CheckRow('Guides trained to assist visually impaired guests'),
        const SizedBox(height: 10),
        CaboCard(
          color: CaboColors.surface,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: CaboColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set your needs once in Profile → Accessibility and we will match you every time.',
                  style: CaboText.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
