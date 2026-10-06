import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 4. Scheduled jobs (shuttles and tours).

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.tour,
    required this.when,
    required this.route,
    required this.payout,
    required this.tags,
    this.accepted = false,
  });

  final bool tour;
  final String when;
  final String route;
  final String payout;
  final List<String> tags;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CaboCard(
        onTap: () => go(context, tour ? '/tour-overview' : '/job-detail'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(
                  tour ? 'Tour' : 'Airport shuttle',
                  color: tour ? CaboColors.brightGreen : CaboColors.blue,
                  icon: tour ? Icons.tour_rounded : Icons.flight_land_rounded,
                ),
                const Spacer(),
                Text(
                  payout,
                  style: CaboText.h2.copyWith(color: CaboColors.yellow),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(route, style: CaboText.h3),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: CaboColors.muted,
                ),
                const SizedBox(width: 6),
                Text(when, style: CaboText.muted),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in tags) Pill(t, color: CaboColors.muted),
              ],
            ),
            const SizedBox(height: 12),
            accepted
                ? const Pill(
                    'Accepted',
                    color: CaboColors.brightGreen,
                    icon: Icons.check,
                  )
                : CaboButton('Accept job', height: 44, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class JobsBoardScreen extends StatelessWidget {
  const JobsBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Jobs',
      showBack: false,
      bottomNav: const DriverNav(1),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.calendar_month_rounded,
            color: CaboColors.yellow,
          ),
          onPressed: () => go(context, '/schedule'),
        ),
      ],
      children: [
        const ChipPicker(
          options: ['All', 'Airport shuttles', 'Tours', 'This weekend'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 16),
        const _JobCard(
          tour: false,
          when: 'Sat 10 Oct • 06:30 pickup',
          route: 'MMIA Terminal 2 → Ikoyi',
          payout: '₦25,000',
          tags: ['Comfort or above', '3 passengers', '4 bags'],
        ),
        const _JobCard(
          tour: true,
          when: 'Sun 11 Oct • 09:00 – 14:00',
          route: 'Lagos Island Heritage Walk',
          payout: '₦45,000',
          tags: ['Certified guide', 'English', '4 guests'],
          accepted: true,
        ),
        const _JobCard(
          tour: false,
          when: 'Mon 12 Oct • 21:15 pickup',
          route: 'MMIA International → Lekki Phase 1',
          payout: '₦28,500',
          tags: ['XL', 'Flight BA75', 'Name board'],
        ),
      ],
    );
  }
}

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, 'Job details'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 220,
            child: CaboMap(
              route: Routes.airport,
              labels: false,
              markers: [
                MapMarker(Offset(0.2, 0.12), MarkerKind.airport),
                MapMarker(
                  Offset(0.62, 0.75),
                  MarkerKind.dropoff,
                  label: 'Ikoyi',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pill(
                  'Airport shuttle',
                  color: CaboColors.blue,
                  icon: Icons.flight_land_rounded,
                ),
                const SizedBox(height: 10),
                Text('MMIA Terminal 2 → Ikoyi', style: CaboText.h1),
                Text(
                  'Sat 10 Oct • pickup 06:30 • about 55 min',
                  style: CaboText.muted,
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: const [
                    StatTile('Passengers', '3', icon: Icons.people_alt_rounded),
                    StatTile('Luggage', '4 bags', icon: Icons.luggage_rounded),
                    StatTile(
                      'Vehicle',
                      'Comfort',
                      icon: Icons.directions_car_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const CaboCard(
                  child: Column(
                    children: [
                      InfoRow('Flight', 'VS411 from London Heathrow'),
                      InfoRow('Scheduled arrival', '05:55'),
                      InfoRow('Drop-off', 'Radisson Blu, Ozumba Mbadiwe'),
                      InfoRow('Distance', '31 km'),
                      Divider(height: 20),
                      InfoRow(
                        'Payout',
                        '₦25,000',
                        bold: true,
                        valueColor: CaboColors.yellow,
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Notes from rider'),
                CaboCard(
                  child: Text(
                    'Travelling with two children. Please bring a child seat if you have one.',
                    style: CaboText.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Accept job',
          onPressed: () => go(context, '/schedule'),
        ),
      ),
    );
  }
}

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // October 2026 starts on a Thursday.
    const jobDays = {10, 11, 12, 17, 24};
    const selected = 10;
    return CaboScaffold(
      title: 'My schedule',
      children: [
        Row(
          children: [
            Text('October 2026', style: CaboText.h2),
            const Spacer(),
            const Icon(Icons.chevron_left, color: CaboColors.muted),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
        const SizedBox(height: 14),
        CaboCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                    Expanded(
                      child: Center(child: Text(d, style: CaboText.label)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                children: [
                  for (var i = 0; i < 3; i++) const SizedBox(),
                  for (var day = 1; day <= 31; day++)
                    Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: day == selected ? CaboColors.yellow : null,
                        shape: BoxShape.circle,
                        border: day == 6
                            ? Border.all(color: CaboColors.muted)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: CaboText.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: day == selected
                                  ? CaboColors.onYellow
                                  : Colors.white,
                            ),
                          ),
                          if (jobDays.contains(day))
                            Icon(
                              Icons.circle,
                              size: 5,
                              color: day == selected
                                  ? CaboColors.onYellow
                                  : CaboColors.brightGreen,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('Saturday 10 October'),
        _ScheduleItem(
          '06:30',
          'Airport pickup',
          'MMIA T2 → Ikoyi • VS411',
          '₦25,000',
          CaboColors.blue,
          () => go(context, '/airport-pickup'),
        ),
        _ScheduleItem(
          '15:00',
          'Airport drop-off',
          'Lekki → MMIA Domestic',
          '₦18,000',
          CaboColors.blue,
          () => go(context, '/job-detail'),
        ),
        const SectionTitle('Sunday 11 October'),
        _ScheduleItem(
          '09:00',
          'Lagos Island Heritage Walk',
          '4 guests • Tinubu Square',
          '₦45,000',
          CaboColors.brightGreen,
          () => go(context, '/tour-overview'),
        ),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem(
    this.time,
    this.title,
    this.subtitle,
    this.pay,
    this.color,
    this.onTap,
  );
  final String time;
  final String title;
  final String subtitle;
  final String pay;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(width: 4, height: 44, color: color),
            const SizedBox(width: 12),
            SizedBox(width: 52, child: Text(time, style: CaboText.h3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(subtitle, style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(pay, style: CaboText.label.copyWith(color: CaboColors.yellow)),
          ],
        ),
      ),
    );
  }
}

class AirportPickupScreen extends StatelessWidget {
  const AirportPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Airport pickup',
      bottom: Row(
        children: [
          Expanded(
            child: CaboButton(
              'Name board',
              style: CaboButtonStyle.secondary,
              onPressed: () => go(context, '/name-board'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CaboButton(
              'Navigate',
              icon: Icons.navigation_rounded,
              onPressed: () => go(context, '/navigate-pickup'),
            ),
          ),
        ],
      ),
      children: [
        CaboCard(
          color: CaboColors.blue.withValues(alpha: 0.16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('VS411', style: CaboText.h2),
                  const SizedBox(width: 10),
                  const Pill(
                    'Landed',
                    color: CaboColors.brightGreen,
                    icon: Icons.flight_land,
                  ),
                  const Spacer(),
                  Text(
                    'Early 8 min',
                    style: CaboText.label.copyWith(
                      color: CaboColors.brightGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LHR', style: CaboText.h1),
                      Text('London 22:35', style: CaboText.muted),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(color: CaboColors.blue, indent: 10),
                        ),
                        Transform.rotate(
                          angle: 1.5708,
                          child: const Icon(
                            Icons.flight,
                            color: CaboColors.blue,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: CaboColors.blue, endIndent: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('LOS', style: CaboText.h1),
                      Text('Lagos 05:47', style: CaboText.muted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: const [
            StatTile('Terminal', 'International', icon: Icons.domain_rounded),
            StatTile('Baggage belt', 'Belt 4', icon: Icons.luggage_rounded),
          ],
        ),
        const SectionTitle('Meeting point'),
        CaboCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.meeting_room_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arrivals hall, Exit B', style: CaboText.h3),
                    Text(
                      'Stand by the Cabo sign next to the money exchange. '
                      'Park in the short-stay car park, row C.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Rider'),
        CaboCard(
          child: Row(
            children: [
              const Avatar('AO', color: CaboColors.yellowSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amara Okafor + 2', style: CaboText.h3),
                    Text('4 bags • going to Ikoyi', style: CaboText.muted),
                  ],
                ),
              ),
              RoundAction(Icons.call_rounded, size: 44, onTap: () {}),
              const SizedBox(width: 8),
              RoundAction(
                Icons.chat_bubble_rounded,
                size: 44,
                onTap: () => go(context, '/chat-rider'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NameBoardScreen extends StatelessWidget {
  const NameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: CaboColors.onYellow,
                    size: 32,
                  ),
                  onPressed: () => back(context),
                ),
              ),
              const Spacer(),
              const CaboLogo(size: 60, color: CaboColors.deepGreen),
              const SizedBox(height: 40),
              Text(
                'WELCOME TO LAGOS',
                style: CaboText.h3.copyWith(
                  color: CaboColors.green,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(
                  'AMARA\nOKAFOR',
                  textAlign: TextAlign.center,
                  style: CaboText.display.copyWith(
                    fontSize: 72,
                    color: CaboColors.onYellow,
                    height: 1.05,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CaboColors.yellow,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Your Cabo driver: Emeka',
                  style: CaboText.h3.copyWith(color: CaboColors.onYellow),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Turn your screen to full brightness',
                style: CaboText.muted.copyWith(color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _guests = [
  ('Amara Okafor', 'United Kingdom', 'AO', true),
  ('Tom Okafor', 'United Kingdom', 'TO', true),
  ('Daniel Kamau', 'Kenya', 'DK', false),
  ('Léa Martin', 'France', 'LM', false),
];

class TourOverviewScreen extends StatelessWidget {
  const TourOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF2A65A), Color(0xFF1C5A3A)],
                    ),
                  ),
                  child: CustomPaint(
                    painter: SkylinePainter(
                      buildingColor: const Color(0xFF0C3B27),
                      water: true,
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => back(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pill(
                  'Tour • by Eko Heritage Tours',
                  color: CaboColors.brightGreen,
                  icon: Icons.tour_rounded,
                ),
                const SizedBox(height: 10),
                Text('Lagos Island Heritage Walk', style: CaboText.h1),
                Text(
                  'Sun 11 Oct • 09:00 – 14:00 • ₦45,000',
                  style: CaboText.muted,
                ),
                const SizedBox(height: 14),
                CaboCard(
                  child: Row(
                    children: [
                      const IconBadge(Icons.place_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Meeting point', style: CaboText.label),
                            Text(
                              'Federal Palace Hotel lobby, V.I.',
                              style: CaboText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SectionTitle('Guests (${_guests.length})'),
                for (final (name, country, initials, _) in _guests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Avatar(
                          initials,
                          size: 40,
                          color: CaboColors.yellowSoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name, style: CaboText.body)),
                        Text(country, style: CaboText.muted),
                      ],
                    ),
                  ),
                const SectionTitle('Itinerary'),
                for (final (time, stop) in const [
                  ('09:00', 'Pickup at Federal Palace Hotel'),
                  ('09:30', 'Tinubu Square and Old Secretariat'),
                  ('10:30', 'Brazilian Quarter, Popo Aguda'),
                  ('11:45', 'Nike Art Gallery'),
                  ('13:30', 'Lunch at Terra Kulture'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          child: Text(time, style: CaboText.label),
                        ),
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: CaboColors.yellow,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(stop, style: CaboText.body)),
                      ],
                    ),
                  ),
                const SectionTitle('Guest notes'),
                CaboCard(
                  child: Text(
                    'Léa is vegetarian. Daniel would like extra time for photos at the Brazilian Quarter.',
                    style: CaboText.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Check in guests',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () => go(context, '/guest-check-in'),
        ),
      ),
    );
  }
}

class TourInProgressScreen extends StatelessWidget {
  const TourInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stops = [
      ('Tinubu Square', '30 min', 2),
      ('Brazilian Quarter', '45 min', 2),
      ('Nike Art Gallery', '60 min • 22 min left', 1),
      ('Terra Kulture (lunch)', '75 min', 0),
    ];
    return Scaffold(
      appBar: caboAppBar(context, 'Tour in progress'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          CaboCard(
            color: CaboColors.yellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW AT',
                  style: CaboText.label.copyWith(color: CaboColors.onYellow),
                ),
                Text(
                  'Nike Art Gallery',
                  style: CaboText.h1.copyWith(color: CaboColors.onYellow),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: CaboColors.onYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '22 min left at this stop',
                      style: CaboText.body.copyWith(
                        color: CaboColors.onYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.63,
                    minHeight: 8,
                    color: CaboColors.deepGreen,
                    backgroundColor: Color(0x33062B1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CaboCard(
            child: Row(
              children: [
                const IconBadge(
                  Icons.restaurant_rounded,
                  color: CaboColors.brightGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT STOP', style: CaboText.label),
                      Text(
                        'Terra Kulture, V.I.',
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('6.4 km • 18 min drive', style: CaboText.muted),
                    ],
                  ),
                ),
                RoundAction(
                  Icons.navigation_rounded,
                  color: CaboColors.brightGreen,
                  iconColor: CaboColors.onYellow,
                  onTap: () => go(context, '/trip-in-progress'),
                ),
              ],
            ),
          ),
          const SectionTitle('Itinerary', action: '4 guests on board'),
          for (final (i, (name, time, state)) in stops.indexed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      state == 2
                          ? Icons.check_circle
                          : state == 1
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: state == 2
                          ? CaboColors.brightGreen
                          : state == 1
                          ? CaboColors.yellow
                          : CaboColors.muted,
                    ),
                    if (i < stops.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: CaboColors.outline,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: state == 0 ? CaboColors.muted : Colors.white,
                        ),
                      ),
                      Text(time, style: CaboText.muted.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Finish tour',
          style: CaboButtonStyle.green,
          onPressed: () => replace(context, '/tour-completed'),
        ),
      ),
    );
  }
}

class GuestCheckInScreen extends StatelessWidget {
  const GuestCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Guest check-in',
      bottom: CaboButton(
        'Start tour (2 of 4 checked in)',
        onPressed: () => go(context, '/tour-in-progress'),
      ),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                size: 120,
                color: Colors.white24,
              ),
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(painter: _ViewfinderPainter()),
              ),
              Positioned(
                bottom: 14,
                child: Text(
                  'Point at the guest\'s QR ticket',
                  style: CaboText.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Guests', action: 'Mark manually'),
        for (final (name, country, initials, checked) in _guests)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Avatar(initials, size: 40, color: CaboColors.yellowSoft),
                  const SizedBox(width: 12),
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
                          country,
                          style: CaboText.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  checked
                      ? const Pill(
                          'Checked in',
                          color: CaboColors.brightGreen,
                          icon: Icons.check,
                        )
                      : const Pill('Waiting', color: CaboColors.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CaboColors.yellow
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + l * dx, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + l * dy), p);
    }
    canvas.drawLine(
      Offset(10, h / 2),
      Offset(w - 10, h / 2),
      p
        ..color = CaboColors.red
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TourCompletedScreen extends StatelessWidget {
  const TourCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Tour completed',
      showBack: false,
      bottom: CaboButton(
        'Back to jobs',
        onPressed: () => replace(context, '/jobs'),
      ),
      children: [
        const SizedBox(height: 8),
        const Center(
          child: HeroIllustration(Icons.emoji_events_rounded, size: 150),
        ),
        const SizedBox(height: 10),
        Center(child: Text('Great tour, Emeka!', style: CaboText.h1)),
        Center(
          child: Text('Lagos Island Heritage Walk', style: CaboText.muted),
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: const [
            StatTile('Duration', '5h 05m'),
            StatTile('Stops', '5 of 5'),
            StatTile('Guests', '4'),
          ],
        ),
        const SizedBox(height: 12),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Tour payout', '₦45,000'),
              InfoRow('Tips', '+ ₦12,000', valueColor: CaboColors.brightGreen),
              Divider(height: 20),
              InfoRow(
                'Total',
                '₦57,000',
                bold: true,
                valueColor: CaboColors.yellow,
              ),
            ],
          ),
        ),
        const SectionTitle('Guest ratings'),
        for (final (name, rating, comment) in const [
          ('Amara', 5.0, 'Emeka made the history come alive!'),
          ('Daniel', 5.0, 'Knowledgeable and very patient.'),
          ('Léa', 4.0, 'Lovely day, a bit rushed at lunch.'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Stars(rating, size: 16),
                    ],
                  ),
                  Text('"$comment"', style: CaboText.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
