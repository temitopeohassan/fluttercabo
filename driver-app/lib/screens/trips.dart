import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 3. Ride requests and trips.

class _RiderRow extends StatelessWidget {
  const _RiderRow({this.subtitle = '★ 4.9 • Comfort'});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Avatar('AO', size: 50, color: CaboColors.yellowSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amara O.', style: CaboText.h3),
              Text(subtitle, style: CaboText.muted),
            ],
          ),
        ),
        ...[
          RoundAction(Icons.call_rounded, onTap: () {}),
          const SizedBox(width: 10),
          RoundAction(
            Icons.chat_bubble_rounded,
            onTap: () => go(context, '/chat-rider'),
          ),
        ],
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop(this.color, this.label, this.title, this.subtitle);
  final Color color;
  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CaboText.label),
                Text(
                  title,
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(subtitle, style: CaboText.label.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class IncomingRequestScreen extends StatefulWidget {
  const IncomingRequestScreen({super.key});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen>
    with SingleTickerProviderStateMixin {
  static const seconds = 15;
  late final AnimationController timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: seconds),
    value: 0.73,
  );

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) timer.reverse();
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: Routes.toPickup,
        routeColor: CaboColors.brightGreen,
        markers: [
          MapMarker(Offset(0.3, 0.78), MarkerKind.driver),
          MapMarker(Offset(0.56, 0.36), MarkerKind.pickup, label: 'Eko Hotel'),
        ],
      ),
      top: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CaboColors.yellow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'New ride request',
              style: CaboText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: CaboColors.onYellow,
              ),
            ),
          ),
          const Spacer(),
          Container(
            decoration: const BoxDecoration(
              color: CaboColors.deepGreen,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: AnimatedBuilder(
              animation: timer,
              builder: (context, _) => Ring(
                value: timer.value,
                size: 60,
                stroke: 6,
                child: Text(
                  '${(timer.value * seconds).ceil()}',
                  style: CaboText.h2,
                ),
              ),
            ),
          ),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Pill('Comfort', icon: Icons.directions_car_rounded),
              SizedBox(width: 8),
              Pill(
                'First-time visitor',
                color: CaboColors.brightGreen,
                icon: Icons.flight_land_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₦6,800', style: CaboText.display),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('est. fare • card', style: CaboText.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _Stop(
            CaboColors.brightGreen,
            'PICKUP • 4 min away',
            'Eko Hotel & Suites, Victoria Island',
            '1.2 km',
          ),
          const _Stop(
            CaboColors.red,
            'DROP-OFF • 32 min trip',
            'Nike Art Gallery, Lekki',
            '14.6 km',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: CaboColors.yellow,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text('4.9 rider rating • 3 trips', style: CaboText.muted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CaboButton(
                  'Decline',
                  style: CaboButtonStyle.secondary,
                  height: 64,
                  onPressed: () => back(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CaboButton(
                  'Accept',
                  height: 64,
                  onPressed: () => replace(context, '/navigate-pickup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NavigateToPickupScreen extends StatelessWidget {
  const NavigateToPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: Routes.toPickup,
        routeColor: CaboColors.brightGreen,
        markers: [
          MapMarker(Offset(0.3, 0.7), MarkerKind.driver),
          MapMarker(Offset(0.56, 0.36), MarkerKind.pickup, label: 'Amara'),
        ],
      ),
      top: const NavInstruction(
        distance: '300 m',
        street: 'Adeola Odeku Street',
        then: 'Ahmadu Bello Way',
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '4 min',
                style: CaboText.h1.copyWith(color: CaboColors.brightGreen),
              ),
              const SizedBox(width: 10),
              Text(
                '1.2 km to pickup',
                style: CaboText.muted.copyWith(fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => go(context, '/cancel-trip'),
                child: Text(
                  'Cancel',
                  style: CaboText.label.copyWith(color: CaboColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _RiderRow(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.place_rounded,
                color: CaboColors.brightGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eko Hotel & Suites, main entrance',
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CaboButton(
            "I've arrived",
            icon: Icons.where_to_vote_rounded,
            onPressed: () => replace(context, '/arrived-pickup'),
          ),
        ],
      ),
    );
  }
}

class ArrivedAtPickupScreen extends StatelessWidget {
  const ArrivedAtPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        markers: [
          MapMarker(Offset(0.55, 0.42), MarkerKind.driver),
          MapMarker(Offset(0.6, 0.36), MarkerKind.pickup),
        ],
      ),
      top: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CaboColors.brightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: CaboColors.onYellow,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Amara has been notified that you have arrived',
                style: CaboText.body.copyWith(
                  color: CaboColors.onYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Ring(
                value: 0.74,
                size: 104,
                color: CaboColors.yellow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('03:42', style: CaboText.h2),
                    Text(
                      'waiting',
                      style: CaboText.muted.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting for Amara', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      '5 min free waiting, then ₦50 per minute.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _RiderRow(subtitle: 'Eko Hotel & Suites, main entrance'),
          const SizedBox(height: 16),
          CaboButton(
            'Start trip',
            onPressed: () => go(context, '/verify-rider'),
          ),
          const SizedBox(height: 10),
          const CaboButton(
            'No-show available in 1:18',
            style: CaboButtonStyle.secondary,
            height: 48,
          ),
        ],
      ),
    );
  }
}

class ChatWithRiderScreen extends StatelessWidget {
  const ChatWithRiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const replies = [
      "I've arrived",
      "I'm at the entrance",
      '2 minutes away',
      'Heavy traffic',
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => back(context),
              )
            : null,
        titleSpacing: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Avatar('AO', size: 40, color: CaboColors.yellowSoft),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amara O.', style: CaboText.h3),
                Text(
                  'Speaks French, English',
                  style: CaboText.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CaboColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: CaboColors.yellow,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Messages are translated automatically',
                    style: CaboText.muted.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ChatBubble(
                  "Hi, I'm at the main entrance. I'm wearing a blue dress.",
                  mine: false,
                  time: '19:02',
                  note: 'Translated from French',
                ),
                ChatBubble(
                  "Great, I'm 2 minutes away in a silver Toyota Corolla, LND 482 KJ.",
                  mine: true,
                  time: '19:03',
                ),
                ChatBubble(
                  'Can you wait a moment? I am getting my bag from reception.',
                  mine: false,
                  time: '19:05',
                  note: 'Translated from French',
                ),
                ChatBubble(
                  'No problem, take your time. I am parked by the entrance.',
                  mine: true,
                  time: '19:05',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: replies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: CaboColors.yellow),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  replies[i],
                  style: CaboText.label.copyWith(color: CaboColors.yellow),
                ),
              ),
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: ChatInput(),
            ),
          ),
        ],
      ),
    );
  }
}

class VerifyRiderScreen extends StatelessWidget {
  const VerifyRiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Verify rider',
      bottom: CaboButton(
        'Start trip',
        icon: Icons.play_arrow_rounded,
        onPressed: () => replace(context, '/trip-in-progress'),
      ),
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Avatar('AO', size: 96, color: CaboColors.yellowSoft),
        ),
        const SizedBox(height: 12),
        Center(child: Text('Amara Okafor', style: CaboText.h1)),
        Center(
          child: Text(
            'Going to Nike Art Gallery, Lekki',
            style: CaboText.muted,
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Ask the rider for their 4-digit trip PIN',
            style: CaboText.h3,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        const CodeBoxes('27', length: 4),
        const SizedBox(height: 28),
        CaboCard(
          child: Row(
            children: [
              const IconBadge(Icons.badge_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No PIN? Confirm the rider says their name is Amara before starting.',
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

class TripInProgressScreen extends StatelessWidget {
  const TripInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: Routes.trip,
        markers: [
          MapMarker(Offset(0.62, 0.52), MarkerKind.driver),
          MapMarker(Offset(0.78, 0.6), MarkerKind.stop, label: 'Stop'),
          MapMarker(
            Offset(0.8, 0.82),
            MarkerKind.dropoff,
            label: 'Nike Art Gallery',
          ),
        ],
      ),
      top: const Column(
        children: [
          NavInstruction(
            distance: '1.4 km',
            street: 'Ozumba Mbadiwe Avenue',
            then: 'Lekki-Epe Expressway',
            icon: Icons.straight_rounded,
          ),
          SizedBox(height: 10),
          _RouteChange(),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '18 min',
                style: CaboText.h1.copyWith(color: CaboColors.yellow),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '9.2 km • arrive 19:42',
                  style: CaboText.muted.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          Text('Dropping off Amara', style: CaboText.h3),
          const SizedBox(height: 8),
          const _Stop(
            CaboColors.blue,
            'ADDED STOP',
            'Shoprite, The Palms Lekki',
            '3.1 km',
          ),
          const _Stop(
            CaboColors.red,
            'DROP-OFF',
            'Nike Art Gallery, Lekki',
            '9.2 km',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              RoundAction(
                Icons.shield_rounded,
                color: CaboColors.blue.withValues(alpha: 0.2),
                iconColor: CaboColors.blue,
                onTap: () => go(context, '/safety'),
              ),
              const SizedBox(width: 10),
              RoundAction(
                Icons.chat_bubble_rounded,
                onTap: () => go(context, '/chat-rider'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CaboButton(
                  'End trip',
                  style: CaboButtonStyle.green,
                  onPressed: () => replace(context, '/end-trip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteChange extends StatelessWidget {
  const _RouteChange();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CaboColors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_location_alt_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Amara added a stop. Fare updated to ₦7,600.',
              style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class EndTripScreen extends StatelessWidget {
  const EndTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: [Offset(0.7, 0.62), Offset(0.78, 0.72), Offset(0.8, 0.82)],
        markers: [
          MapMarker(Offset(0.78, 0.74), MarkerKind.driver),
          MapMarker(Offset(0.8, 0.82), MarkerKind.dropoff),
        ],
      ),
      top: const NavInstruction(
        distance: 'Arrived',
        street: 'Nike Art Gallery, on your right',
        icon: Icons.flag_rounded,
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drop off Amara', style: CaboText.h2),
          const SizedBox(height: 4),
          Text(
            'Remind the rider to check for their belongings before they get out.',
            style: CaboText.muted,
          ),
          const SizedBox(height: 14),
          const InfoRow('Trip fare', '₦7,600', bold: true),
          const InfoRow('Payment', 'Cash'),
          const SizedBox(height: 16),
          SlideToComplete(
            label: 'Slide to complete',
            onComplete: () => replace(context, '/collect-payment'),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => replace(context, '/collect-payment'),
              child: Text(
                'Tap here if sliding is difficult',
                style: CaboText.label.copyWith(color: CaboColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectPaymentScreen extends StatelessWidget {
  const CollectPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Collect payment',
      showBack: false,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaboButton(
            'Cash collected',
            icon: Icons.check_rounded,
            onPressed: () => replace(context, '/trip-summary'),
          ),
          const SizedBox(height: 10),
          const CaboButton(
            'Rider paid a different amount',
            style: CaboButtonStyle.secondary,
            height: 48,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 16),
        const Center(
          child: HeroIllustration(Icons.payments_rounded, size: 150),
        ),
        const SizedBox(height: 16),
        Center(child: Text('Collect from Amara', style: CaboText.h3)),
        Center(
          child: Text(
            '₦7,600',
            style: CaboText.display.copyWith(
              fontSize: 56,
              color: CaboColors.yellow,
            ),
          ),
        ),
        Center(child: Text('Cash trip', style: CaboText.muted)),
        const SizedBox(height: 24),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Trip fare', '₦6,800'),
              InfoRow('Added stop', '₦400'),
              InfoRow('Lekki toll gate', '₦400'),
              Divider(height: 20),
              InfoRow(
                'Amount due',
                '₦7,600',
                bold: true,
                valueColor: CaboColors.yellow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Trip complete',
      showBack: false,
      bottom: Row(
        children: [
          Expanded(
            child: CaboButton(
              'Done',
              style: CaboButtonStyle.secondary,
              onPressed: () => replace(context, '/home-online'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CaboButton(
              'Rate Amara',
              onPressed: () => go(context, '/rate-rider'),
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 12),
        const Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: CaboColors.brightGreen,
            child: Icon(
              Icons.check_rounded,
              size: 48,
              color: CaboColors.onYellow,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'You earned',
            style: CaboText.muted.copyWith(fontSize: 15),
          ),
        ),
        Center(
          child: Text(
            '₦7,160',
            style: CaboText.display.copyWith(color: CaboColors.brightGreen),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Pill(
            '+ ₦1,000 tip from Amara',
            color: CaboColors.yellow,
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(height: 22),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Fare paid by rider', '₦7,600'),
              InfoRow('Cabo commission (20%)', '− ₦1,440'),
              InfoRow('Tip', '+ ₦1,000', valueColor: CaboColors.brightGreen),
              Divider(height: 20),
              InfoRow('Your earnings', '₦7,160', bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Distance', '14.6 km'),
              InfoRow('Duration', '34 min'),
              InfoRow('Payment', 'Cash'),
              InfoRow('Route', 'Eko Hotel → Nike Art Gallery'),
            ],
          ),
        ),
      ],
    );
  }
}

class RateRiderScreen extends StatefulWidget {
  const RateRiderScreen({super.key});

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  int stars = 5;

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Rate rider',
      bottom: CaboButton(
        'Submit',
        onPressed: () => replace(context, '/home-online'),
      ),
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Avatar('AO', size: 96, color: CaboColors.yellowSoft),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('How was your trip with Amara?', style: CaboText.h2),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 48,
                onPressed: () => setState(() => stars = i),
                icon: Icon(
                  i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: CaboColors.yellow,
                ),
              ),
          ],
        ),
        Center(
          child: Text(
            'Excellent',
            style: CaboText.h3.copyWith(color: CaboColors.yellow),
          ),
        ),
        const SectionTitle('What went well?'),
        const ChipPicker(
          options: [
            'Polite',
            'On time',
            'Great conversation',
            'Respectful of car',
            'Clear directions',
          ],
          initial: {0, 1, 2},
        ),
        const SizedBox(height: 20),
        const CaboField(
          'Feedback (optional)',
          hint: 'Tell us more about this rider',
          maxLines: 3,
        ),
      ],
    );
  }
}

class CancelTripScreen extends StatelessWidget {
  const CancelTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Cancel trip',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaboButton(
            'Cancel trip',
            style: CaboButtonStyle.danger,
            onPressed: () => replace(context, '/home-online'),
          ),
          const SizedBox(height: 10),
          CaboButton(
            'Keep trip',
            style: CaboButtonStyle.secondary,
            height: 48,
            onPressed: () => back(context),
          ),
        ],
      ),
      children: [
        Text('Why are you cancelling?', style: CaboText.h2),
        const SizedBox(height: 16),
        const SingleChoice(
          initial: 1,
          options: [
            ('Rider asked me to cancel', null),
            ('Rider is not at the pickup point', null),
            ('Too many passengers or bags', null),
            ('I feel unsafe', 'Cabo Safety will follow up with you'),
            ('Problem with my vehicle', null),
            ('Other', null),
          ],
        ),
        CaboCard(
          color: CaboColors.orange.withValues(alpha: 0.14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: CaboColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cancellations count towards your cancellation rate (now 2.1%). '
                  'Keep it under 5% to stay eligible for Premium and tours.',
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
