import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 4. Cabo Shuttle.

class CountStepper extends StatefulWidget {
  const CountStepper(
    this.label,
    this.initial, {
    super.key,
    this.icon,
    this.subtitle,
  });
  final String label;
  final int initial;
  final IconData? icon;
  final String? subtitle;

  @override
  State<CountStepper> createState() => _CountStepperState();
}

class _CountStepperState extends State<CountStepper> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => Material(
      color: CaboColors.greenSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: CaboColors.green, size: 20),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            IconBadge(widget.icon!, size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.subtitle != null)
                  Text(widget.subtitle!, style: CaboText.muted),
              ],
            ),
          ),
          btn(
            Icons.remove_rounded,
            () => setState(() => value = (value - 1).clamp(0, 20)),
          ),
          SizedBox(
            width: 40,
            child: Center(child: Text('$value', style: CaboText.h2)),
          ),
          btn(
            Icons.add_rounded,
            () => setState(() => value = (value + 1).clamp(0, 20)),
          ),
        ],
      ),
    );
  }
}

class ShuttleScreen extends StatelessWidget {
  const ShuttleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Airport shuttle',
      bottom: CaboButton(
        'Continue',
        onPressed: () => go(context, '/shuttle-flight'),
      ),
      children: [
        const ChipPicker(
          options: ['Pickup from airport', 'Drop-off at airport'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 18),
        const CaboField(
          'Airport',
          value: 'Murtala Muhammed International (LOS)',
          icon: Icons.flight_rounded,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        const CaboField(
          'Flight number',
          value: 'VS411',
          icon: Icons.confirmation_number_outlined,
        ),
        const Row(
          children: [
            Expanded(
              child: CaboField(
                'Date',
                value: 'Sat 10 Oct',
                icon: Icons.event_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CaboField(
                'Lands',
                value: '05:55',
                icon: Icons.flight_land_rounded,
              ),
            ),
          ],
        ),
        const CaboField(
          'Drop-off',
          value: 'Radisson Blu, Ozumba Mbadiwe, Ikoyi',
          icon: Icons.location_on_outlined,
        ),
        CaboCard(
          color: CaboColors.greenSoft,
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: CaboColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fixed price, no surge. Book at least 3 hours before pickup.',
                  style: CaboText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShuttleFlightScreen extends StatelessWidget {
  const ShuttleFlightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Your flight',
      bottom: CaboButton(
        'This is my flight',
        onPressed: () => go(context, '/shuttle-vehicle'),
      ),
      children: [
        CaboCard(
          color: const Color(0xFFE6F0FB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('VS411', style: CaboText.h2),
                  const SizedBox(width: 8),
                  const Pill('On time', icon: Icons.check),
                  const Spacer(),
                  Text('Virgin Atlantic', style: CaboText.label),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LHR', style: CaboText.h1),
                      Text('Fri 22:35', style: CaboText.muted),
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
                      Text('Sat 05:55', style: CaboText.muted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (icon, title, body) in const [
          (
            Icons.radar_rounded,
            'We track your flight',
            'If you land early or late, your pickup time moves with it.',
          ),
          (
            Icons.hourglass_bottom_rounded,
            '60 minutes free waiting',
            'Counted from when you land, for immigration and bags.',
          ),
          (
            Icons.badge_rounded,
            'Name board at arrivals',
            'Your driver holds a Cabo board with your name at Exit B.',
          ),
        ])
          MenuTile(icon: icon, title: title, subtitle: body),
      ],
    );
  }
}

class ShuttleVehicleScreen extends StatefulWidget {
  const ShuttleVehicleScreen({super.key});

  @override
  State<ShuttleVehicleScreen> createState() => _ShuttleVehicleScreenState();
}

class _ShuttleVehicleScreenState extends State<ShuttleVehicleScreen> {
  int vehicle = 0;

  @override
  Widget build(BuildContext context) {
    const vehicles = [
      (
        'Comfort',
        'Up to 3 passengers, 3 bags',
        Icons.directions_car_filled_rounded,
        25000,
      ),
      (
        'XL',
        'Up to 6 passengers, 6 bags',
        Icons.airport_shuttle_rounded,
        32000,
      ),
      ('Premium', 'Executive sedan, up to 3', Icons.local_taxi_rounded, 40000),
    ];
    return CaboScaffold(
      title: 'Vehicle and luggage',
      bottom: CaboButton(
        'Continue • ${naira(vehicles[vehicle].$4)}',
        onPressed: () => go(context, '/shuttle-review'),
      ),
      children: [
        const CountStepper('Passengers', 3, icon: Icons.people_alt_rounded),
        const CountStepper(
          'Large bags',
          3,
          icon: Icons.luggage_rounded,
          subtitle: 'Checked suitcases',
        ),
        const CountStepper(
          'Small bags',
          1,
          icon: Icons.backpack_rounded,
          subtitle: 'Carry-on',
        ),
        const SectionTitle('Vehicle class'),
        for (var i = 0; i < vehicles.length; i++)
          SelectTile(
            icon: vehicles[i].$3,
            title: vehicles[i].$1,
            subtitle: vehicles[i].$2,
            selected: vehicle == i,
            onTap: () => setState(() => vehicle = i),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(naira(vehicles[i].$4), style: CaboText.h3),
                Text(gbp(vehicles[i].$4), style: CaboText.label),
              ],
            ),
          ),
      ],
    );
  }
}

class ShuttleReviewScreen extends StatelessWidget {
  const ShuttleReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Review and pay',
      bottom: CaboButton(
        'Pay ${naira(25000)}',
        onPressed: () => go(context, '/shuttle-confirmed'),
      ),
      children: [
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Pickup', 'MMIA International, Arrivals'),
              InfoRow('Flight', 'VS411 • lands Sat 05:55'),
              InfoRow('Drop-off', 'Radisson Blu, Ikoyi'),
              InfoRow('Vehicle', 'Comfort • 3 passengers'),
              InfoRow('Luggage', '3 large, 1 small'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Fixed fare', naira(25000), bold: true),
              Align(
                alignment: Alignment.centerRight,
                child: Text(gbp(25000), style: CaboText.label),
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
            ('Bank transfer', 'Virtual account, confirmed instantly'),
            ('Cabo Wallet', 'Balance ₦12,400 • not enough'),
          ],
        ),
        Text(
          'Cash is not accepted for shuttles. Free cancellation up to 24 hours before pickup.',
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class ShuttleConfirmedScreen extends StatelessWidget {
  const ShuttleConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.check_circle_rounded,
      title: 'Airport pickup booked',
      message: 'Sat 10 Oct, from MMIA to Radisson Blu Ikoyi. Your driver is assigned at least 12 hours before pickup.',
      primary: 'View booking',
      onPrimary: () => go(context, '/shuttle-assigned'),
      secondary: 'Add to calendar',
      onSecondary: () {},
      extra: CaboCard(
        color: CaboColors.surface,
        child: Column(
          children: [
            const InfoRow('Booking', 'CB-SH-40192'),
            InfoRow('Paid', '${naira(25000)} • Visa •• 4242'),
            const InfoRow('Confirmation', 'Sent to tunde.bakare@gmail.com'),
          ],
        ),
      ),
    );
  }
}

class ShuttleAssignedScreen extends StatelessWidget {
  const ShuttleAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Airport pickup',
      bottom: CaboButton(
        'Message Emeka',
        icon: Icons.chat_bubble_rounded,
        onPressed: () => go(context, '/chat-driver'),
      ),
      children: [
        CaboCard(
          color: CaboColors.greenSoft,
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: CaboColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Driver assigned. VS411 is on time, landing 05:55.',
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const DriverCard(),
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
                      'After customs, turn left. Emeka waits by the money exchange '
                      'with a Cabo name board.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Look for this board'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CaboColors.yellow, width: 3),
          ),
          child: Column(
            children: [
              const CaboLogo(size: 30),
              const SizedBox(height: 10),
              Text(
                'TUNDE BAKARE',
                style: CaboText.h1.copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoRow('Free waiting', '60 min after landing'),
        const InfoRow('Booking', 'CB-SH-40192'),
      ],
    );
  }
}
