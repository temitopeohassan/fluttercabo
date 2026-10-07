import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 5. Earnings and payouts.

const _week = [14200.0, 21800.0, 18450.0, 26300.0, 31500.0, 19650.0, 10700.0];
const _hours = [5.0, 7.0, 6.0, 8.0, 9.0, 6.0, 4.0];
const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String naira(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '₦$b';
}

class EarningsDashboardScreen extends StatelessWidget {
  const EarningsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const split = [
      ('Rides', 86400.0, CaboColors.brightGreen),
      ('Shuttles', 25000.0, CaboColors.blue),
      ('Tours', 20000.0, CaboColors.yellow),
      ('Tips', 11200.0, CaboColors.orange),
    ];
    final total = split.fold(0.0, (a, s) => a + s.$2);
    return CaboScaffold(
      title: 'Earnings',
      showBack: false,
      bottomNav: const DriverNav(2),
      children: [
        const ChipPicker(
          options: ['Today', 'This week', 'This month'],
          initial: {1},
          single: true,
        ),
        const SizedBox(height: 18),
        Text('5 – 11 Oct', style: CaboText.muted),
        Text(
          naira(total),
          style: CaboText.display.copyWith(color: CaboColors.brightGreen),
        ),
        Text('62 trips • 45 h online', style: CaboText.muted),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              for (final (_, v, c) in split)
                Expanded(
                  flex: (v / 1000).round(),
                  child: Container(height: 12, color: c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final (label, v, c) in split)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: c),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: CaboText.body)),
                Text(
                  naira(v),
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        CaboCard(
          onTap: () => go(context, '/earnings-chart'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Daily earnings', style: CaboText.h3),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: CaboColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              const BarChart(
                values: _week,
                labels: _days,
                highlight: 4,
                height: 110,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MenuTile(
          icon: Icons.account_balance_rounded,
          title: 'Payouts',
          subtitle: 'Next payout Mon 12 Oct • ₦96,400',
          onTap: () => go(context, '/payouts'),
        ),
        MenuTile(
          icon: Icons.money_rounded,
          title: 'Cash balance',
          subtitle: 'You owe Cabo ₦5,760 in commission',
          color: CaboColors.orange,
          onTap: () => go(context, '/cash-balance'),
        ),
        MenuTile(
          icon: Icons.emoji_events_rounded,
          title: 'Incentives and bonuses',
          subtitle: '18 of 25 trips for a ₦10,000 bonus',
          color: CaboColors.brightGreen,
          onTap: () => go(context, '/incentives'),
        ),
        MenuTile(
          icon: Icons.receipt_long_rounded,
          title: 'Trip history',
          subtitle: 'All completed jobs',
          color: CaboColors.blue,
          onTap: () => go(context, '/trip-history'),
        ),
      ],
    );
  }
}

class EarningsChartScreen extends StatelessWidget {
  const EarningsChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = _week.reduce((a, b) => a + b);
    final hours = _hours.reduce((a, b) => a + b);
    return CaboScaffold(
      title: 'This week',
      children: [
        Row(
          children: [
            const Icon(Icons.chevron_left, color: Colors.white),
            Expanded(
              child: Center(
                child: Text('5 – 11 October 2026', style: CaboText.h3),
              ),
            ),
            const Icon(Icons.chevron_right, color: CaboColors.muted),
          ],
        ),
        const SizedBox(height: 20),
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                naira(total),
                style: CaboText.h1.copyWith(color: CaboColors.brightGreen),
              ),
              Text('Friday was your best day: ₦31,500', style: CaboText.muted),
              const SizedBox(height: 20),
              BarChart(
                values: _week,
                labels: _days,
                highlight: 4,
                height: 200,
                secondary: _hours,
                valueLabel: (v) => naira(v),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.square_rounded,
                    size: 12,
                    color: CaboColors.brightGreen,
                  ),
                  const SizedBox(width: 6),
                  Text('Earnings', style: CaboText.label),
                  const SizedBox(width: 18),
                  const Icon(
                    Icons.square_rounded,
                    size: 12,
                    color: CaboColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text('Hours online', style: CaboText.label),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            StatTile(
              'Hours online',
              '${hours.round()} h',
              icon: Icons.schedule_rounded,
            ),
            StatTile(
              'Per hour',
              naira(total / hours),
              icon: Icons.speed_rounded,
            ),
            const StatTile('Trips', '62', icon: Icons.route_rounded),
          ],
        ),
        const SectionTitle('Daily breakdown'),
        for (var i = 0; i < 7; i++)
          InfoRow(
            [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ][i],
            '${naira(_week[i])} • ${_hours[i].round()} h',
          ),
      ],
    );
  }
}

const _trips = [
  (
    'Today, 19:42',
    'Eko Hotel → Nike Art Gallery',
    'Ride • Cash',
    7160.0,
    Icons.directions_car_rounded,
  ),
  (
    'Today, 17:10',
    'Ikoyi → Lekki Phase 1',
    'Ride • Card',
    4350.0,
    Icons.directions_car_rounded,
  ),
  (
    'Today, 06:30',
    'MMIA T2 → Ikoyi',
    'Airport shuttle',
    25000.0,
    Icons.flight_land_rounded,
  ),
  (
    'Yesterday, 21:05',
    'Yaba → Surulere',
    'Ride • Card',
    2900.0,
    Icons.directions_car_rounded,
  ),
  (
    'Sun 4 Oct',
    'Lagos Island Heritage Walk',
    'Tour • 4 guests',
    57000.0,
    Icons.tour_rounded,
  ),
  (
    'Sat 3 Oct',
    'Victoria Island → MMIA',
    'Airport shuttle',
    18000.0,
    Icons.flight_takeoff_rounded,
  ),
];

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Trip history',
      children: [
        const ChipPicker(
          options: ['All', 'Rides', 'Shuttles', 'Tours'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 16),
        for (final (date, route, type, amount, icon) in _trips)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              onTap: () => go(context, '/trip-earnings-detail'),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconBadge(icon, color: CaboColors.brightGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route,
                          style: CaboText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$date • $type',
                          style: CaboText.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(naira(amount), style: CaboText.h3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TripEarningsDetailScreen extends StatelessWidget {
  const TripEarningsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Trip earnings',
      bottom: CaboButton(
        'Report a fare problem',
        style: CaboButtonStyle.secondary,
        onPressed: () => go(context, '/support-tickets'),
      ),
      children: [
        const SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: CaboMap(
              route: Routes.trip,
              labels: false,
              markers: [
                MapMarker(Offset(0.56, 0.36), MarkerKind.pickup),
                MapMarker(Offset(0.8, 0.82), MarkerKind.dropoff),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Eko Hotel → Nike Art Gallery', style: CaboText.h2),
        Text('Today, 19:08 – 19:42 • 14.6 km • Comfort', style: CaboText.muted),
        const SizedBox(height: 16),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Trip fare', '₦6,800'),
              InfoRow('Added stop', '₦400'),
              InfoRow(
                'Cabo commission (20%)',
                '− ₦1,440',
                valueColor: CaboColors.red,
              ),
              InfoRow('Lekki toll (passed through)', '₦400'),
              InfoRow('Tip', '+ ₦1,000', valueColor: CaboColors.brightGreen),
              Divider(height: 20),
              InfoRow(
                'Net earnings',
                '₦7,160',
                bold: true,
                valueColor: CaboColors.brightGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Rider', 'Amara O.'),
              InfoRow('Payment', 'Cash'),
              InfoRow('Trip ID', 'CB-7Q4-2291'),
            ],
          ),
        ),
      ],
    );
  }
}

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Payouts',
      children: [
        CaboCard(
          color: CaboColors.surfaceHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available balance', style: CaboText.muted),
              Text(
                '₦96,400',
                style: CaboText.display.copyWith(color: CaboColors.brightGreen),
              ),
              const SizedBox(height: 4),
              Text(
                'Next automatic payout: Monday 12 Oct to GTBank ••6789',
                style: CaboText.muted,
              ),
              const SizedBox(height: 16),
              CaboButton(
                'Cash out now',
                icon: Icons.bolt_rounded,
                onPressed: () {},
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Instant cash-out fee: 1.5% (₦1,446)',
                  style: CaboText.muted.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Payout history'),
        for (final (date, amount, status) in const [
          ('Mon 5 Oct', '₦112,850', 'Paid'),
          ('Wed 30 Sep', '₦20,000', 'Instant'),
          ('Mon 28 Sep', '₦88,300', 'Paid'),
          ('Mon 21 Sep', '₦104,120', 'Paid'),
          ('Mon 14 Sep', '₦79,640', 'Paid'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MenuTile(
              icon: status == 'Instant'
                  ? Icons.bolt_rounded
                  : Icons.account_balance_rounded,
              title: amount,
              subtitle: '$date • GTBank ••6789',
              color: status == 'Instant'
                  ? CaboColors.yellow
                  : CaboColors.brightGreen,
              trailing: Pill(
                status,
                color: status == 'Instant'
                    ? CaboColors.yellow
                    : CaboColors.brightGreen,
              ),
            ),
          ),
      ],
    );
  }
}

class CashBalanceScreen extends StatelessWidget {
  const CashBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Cash balance',
      bottom: CaboButton('Settle ₦5,760 now', onPressed: () {}),
      children: [
        CaboCard(
          color: CaboColors.orange.withValues(alpha: 0.14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You owe Cabo', style: CaboText.muted),
              Text(
                '₦5,760',
                style: CaboText.display.copyWith(color: CaboColors.orange),
              ),
              const SizedBox(height: 6),
              Text(
                'Commission on cash trips. It is taken from your next payout automatically, '
                'or you can settle it now.',
                style: CaboText.muted,
              ),
              const SizedBox(height: 12),
              const Bar(0.29, color: CaboColors.orange),
              const SizedBox(height: 6),
              Text(
                'Limit ₦20,000. Above this you can only take card trips.',
                style: CaboText.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: StatTile(
                'Cash collected this week',
                '₦29,200',
                icon: Icons.payments_rounded,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: StatTile(
                'Commission owed',
                '₦5,760',
                icon: Icons.percent_rounded,
                color: CaboColors.orange,
              ),
            ),
          ],
        ),
        const SectionTitle('Cash trips'),
        for (final (route, cash, fee) in const [
          ('Eko Hotel → Nike Art Gallery', '₦7,600', '₦1,440'),
          ('Surulere → Yaba', '₦3,200', '₦640'),
          ('Ikeja GRA → Maryland', '₦4,500', '₦900'),
          ('Lekki → Ajah', '₦6,800', '₦1,360'),
          ('V.I. → Ikoyi', '₦7,100', '₦1,420'),
        ])
          InfoRow(route, '$cash • fee $fee'),
      ],
    );
  }
}

class IncentivesScreen extends StatelessWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const quests = [
      (
        'Weekly quest',
        'Complete 25 trips this week',
        18,
        25,
        '₦10,000',
        'Ends Sun 23:59',
      ),
      (
        'Airport weekend',
        '5 airport trips Fri – Sun',
        2,
        5,
        '₦7,500',
        'Starts Fri 00:00',
      ),
      (
        'Peak hours streak',
        '3 trips in a row, 17:00 – 20:00',
        1,
        3,
        '₦2,000',
        'Today',
      ),
    ];
    return CaboScaffold(
      title: 'Incentives',
      children: [
        CaboCard(
          color: CaboColors.brightGreen.withValues(alpha: 0.14),
          child: Row(
            children: [
              const IconBadge(
                Icons.savings_rounded,
                color: CaboColors.brightGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonuses earned this month', style: CaboText.muted),
                    Text(
                      '₦24,500',
                      style: CaboText.h1.copyWith(
                        color: CaboColors.brightGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Active quests'),
        for (final (title, body, done, target, reward, ends) in quests)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CaboCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title.toUpperCase(), style: CaboText.label),
                      const Spacer(),
                      Pill(reward, solid: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: CaboText.h3),
                  const SizedBox(height: 12),
                  Bar(done / target),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$done of $target',
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(ends, style: CaboText.muted.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
