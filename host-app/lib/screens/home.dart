import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 2. Home and going online.

const _lagosHeat = [
  HeatZone(Offset(0.18, 0.12), 0.32, 0.9, label: 'MMIA ×1.8'),
  HeatZone(Offset(0.38, 0.7), 0.3, 0.7, label: 'V.I. ×1.5'),
  HeatZone(Offset(0.78, 0.78), 0.26, 0.45, label: 'Lekki ×1.3'),
  HeatZone(Offset(0.55, 0.28), 0.2, 0.3, label: 'Ikoyi ×1.2'),
];

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => replace(context, '/account'),
          child: const Avatar('EN', size: 46),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: online ? CaboColors.brightGreen : CaboColors.deepGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 12),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: online ? CaboColors.onYellow : CaboColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    online ? "You're online" : "You're offline",
                    style: CaboText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: online ? CaboColors.onYellow : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          children: [
            RoundAction(
              Icons.notifications_rounded,
              color: CaboColors.deepGreen,
              size: 46,
              onTap: () => go(context, '/notifications'),
            ),
            const Positioned(
              right: 4,
              top: 4,
              child: CircleAvatar(
                radius: 5,
                backgroundColor: CaboColors.yellow,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HomeOfflineScreen extends StatelessWidget {
  const HomeOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        markers: [MapMarker(Offset(0.42, 0.62), MarkerKind.driver)],
      ),
      top: const _HomeTopBar(online: false),
      bottomNav: const DriverNav(0),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => go(context, '/hotspots'),
            child: CaboCard(
              color: CaboColors.orange.withValues(alpha: 0.16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: CaboColors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'High demand at MMIA Airport • ×1.8',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: CaboColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                'Today',
                '₦18,450',
                onTap: () => replace(context, '/earnings'),
              ),
              const _MiniStat('Acceptance', '92%'),
              const _MiniStat('Rating', '4.92 ★'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RoundAction(
                Icons.tune_rounded,
                size: 60,
                onTap: () => go(context, '/ride-preferences'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CaboButton(
                  'GO ONLINE',
                  icon: Icons.power_settings_new_rounded,
                  height: 64,
                  onPressed: () => replace(context, '/home-online'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, {this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: CaboText.h2),
            Text(label, style: CaboText.muted.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class HomeOnlineScreen extends StatelessWidget {
  const HomeOnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        heat: _lagosHeat,
        markers: [MapMarker(Offset(0.42, 0.56), MarkerKind.driver)],
      ),
      top: const _HomeTopBar(online: true),
      bottomNav: const DriverNav(0),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => go(context, '/incoming-request'),
            child: Row(
              children: [
                const Pulse(animate: !kScreenshotMode, size: 64),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finding trips for you', style: CaboText.h3),
                      Text(
                        'Average wait in Victoria Island: 3 min',
                        style: CaboText.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CaboCard(
                  onTap: () => go(context, '/ride-preferences'),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: CaboColors.yellow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rides, shuttles',
                          style: CaboText.label.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CaboCard(
                  onTap: () => go(context, '/hotspots'),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: CaboColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '4 hotspots',
                          style: CaboText.label.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CaboButton(
            'Go offline',
            style: CaboButtonStyle.secondary,
            icon: Icons.power_settings_new_rounded,
            onPressed: () => replace(context, '/home'),
          ),
        ],
      ),
    );
  }
}

class HotspotsScreen extends StatelessWidget {
  const HotspotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const zones = [
      (
        'Murtala Muhammed Airport',
        '12 riders waiting • 22 min away',
        '×1.8',
        0.9,
      ),
      ('Victoria Island', 'Evening rush until 21:00 • 8 min away', '×1.5', 0.7),
      (
        'Lekki Phase 1',
        'Concert at Landmark Beach • 15 min away',
        '×1.3',
        0.45,
      ),
      ('Ikoyi', 'Steady demand • 6 min away', '×1.2', 0.3),
    ];
    return Scaffold(
      appBar: caboAppBar(context, 'Demand hotspots'),
      body: Column(
        children: [
          const SizedBox(
            height: 330,
            child: CaboMap(
              heat: _lagosHeat,
              markers: [MapMarker(Offset(0.42, 0.56), MarkerKind.driver)],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                Text(
                  'Surge prices apply to new requests in these areas. Updated 2 min ago.',
                  style: CaboText.muted,
                ),
                const SizedBox(height: 12),
                for (final (name, info, surge, heat) in zones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CaboCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                CaboColors.yellow,
                                CaboColors.red,
                                heat,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              surge,
                              style: CaboText.h3.copyWith(
                                color: CaboColors.onYellow,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                Text(
                                  info,
                                  style: CaboText.muted.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.navigation_rounded,
                            color: CaboColors.yellow,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RidePreferencesScreen extends StatelessWidget {
  const RidePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Ride preferences',
      bottom: CaboButton('Save preferences', onPressed: () => back(context)),
      children: [
        const SectionTitle('Ride tiers'),
        const ToggleTile(
          'Standard',
          subtitle: 'Everyday rides',
          icon: Icons.directions_car_rounded,
        ),
        const ToggleTile(
          'Comfort',
          subtitle: 'Newer cars, extra legroom',
          icon: Icons.airline_seat_recline_extra_rounded,
        ),
        const ToggleTile(
          'XL',
          subtitle: 'Your vehicle does not qualify (needs 6+ seats)',
          initial: false,
          icon: Icons.airport_shuttle_rounded,
        ),
        const ToggleTile(
          'Premium',
          subtitle: 'Reach Premium tier to unlock',
          initial: false,
          icon: Icons.workspace_premium_rounded,
        ),
        const SectionTitle('Job types'),
        const ToggleTile('On-demand rides', icon: Icons.bolt_rounded),
        const ToggleTile(
          'Airport shuttles',
          icon: Icons.flight_takeoff_rounded,
        ),
        MenuTile(
          icon: Icons.tour_rounded,
          title: 'Tours',
          subtitle: 'Get certified as a driver-guide first',
          trailing: const Pill(
            'Locked',
            color: CaboColors.muted,
            icon: Icons.lock,
          ),
          onTap: () => go(context, '/tour-certification'),
        ),
        const SectionTitle('Destination filter'),
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Only get trips heading towards a place, like home at the end of a shift.',
                style: CaboText.muted,
              ),
              const SizedBox(height: 12),
              const CaboField(
                'Heading to',
                value: 'Home • Surulere',
                icon: Icons.home_rounded,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: CaboColors.yellow,
                  ),
                  const SizedBox(width: 6),
                  Text('2 of 2 uses left today', style: CaboText.label),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const today = [
      (
        Icons.event_available_rounded,
        CaboColors.brightGreen,
        'New airport job available',
        'MMIA T2 → Ikoyi, Sat 10 Oct, 06:30 • ₦25,000',
        '10 min ago',
        '/job-detail',
      ),
      (
        Icons.payments_rounded,
        CaboColors.yellow,
        'Payout sent',
        '₦96,400 is on its way to GTBank ••6789',
        '2 h ago',
        '/payouts',
      ),
      (
        Icons.warning_amber_rounded,
        CaboColors.orange,
        'Insurance expires in 12 days',
        'Renew now to keep driving without interruption',
        '5 h ago',
        '/documents',
      ),
    ];
    const earlier = [
      (
        Icons.emoji_events_rounded,
        CaboColors.yellow,
        'Quest unlocked',
        'Complete 25 trips this week for a ₦10,000 bonus',
        'Mon',
        '/incentives',
      ),
      (
        Icons.campaign_rounded,
        CaboColors.blue,
        'Detty December is coming',
        'Visitor demand triples in December. Get tour-certified early.',
        'Sun',
        '/learning-centre',
      ),
      (
        Icons.star_rounded,
        CaboColors.yellow,
        'New compliment',
        '"Knows Lagos really well" from a rider',
        'Sat',
        '/ratings',
      ),
    ];
    Widget list(
      List<(IconData, Color, String, String, String, String)> items,
    ) => Column(
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
    return CaboScaffold(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () {},
          child: Text(
            'Mark all read',
            style: CaboText.label.copyWith(color: CaboColors.yellow),
          ),
        ),
      ],
      children: [
        const SectionTitle('Today'),
        list(today),
        const SectionTitle('Earlier'),
        list(earlier),
      ],
    );
  }
}
