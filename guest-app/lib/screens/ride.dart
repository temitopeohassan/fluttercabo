import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 3. Cabo Ride.

const _pickup = Offset(0.56, 0.36);
const _dropoff = Offset(0.8, 0.82);

class _MapTopBar extends StatelessWidget {
  const _MapTopBar(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundAction(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 44,
          onTap: () => back(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Text(title, textAlign: TextAlign.center, style: CaboText.h3),
          ),
        ),
        const SizedBox(width: 54),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop(this.color, this.label, this.title);
  final Color color;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 12, color: color),
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
        ],
      ),
    );
  }
}

class WhereToScreen extends StatelessWidget {
  const WhereToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Where to?',
      children: [
        CaboCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: CaboColors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Eko Hotel & Suites, Victoria Island',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 30),
                child: Divider(height: 20),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: CaboColors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      autofocus: false,
                      initialValue: 'Nike Art',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final (icon, label, route) in const [
              (Icons.home_rounded, 'Hotel', '/choose-ride'),
              (Icons.work_rounded, 'Work', '/choose-ride'),
              (Icons.map_rounded, 'On map', '/pick-on-map'),
              (Icons.schedule_rounded, 'Later', '/schedule-ride'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CaboCard(
                    color: CaboColors.surface,
                    onTap: () => go(context, route),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Icon(icon, color: CaboColors.green),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: CaboText.label.copyWith(color: CaboColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SectionTitle('Results'),
        MenuTile(
          icon: Icons.palette_rounded,
          title: 'Nike Art Gallery',
          subtitle: '2 Elegushi Beach Rd, Lekki • 14.6 km',
          onTap: () => go(context, '/confirm-pickup'),
        ),
        MenuTile(
          icon: Icons.place_rounded,
          title: 'Nike Lake Resort',
          subtitle: 'Enugu • not served by Cabo yet',
          color: CaboColors.muted,
        ),
        const SectionTitle('Recent'),
        for (final (name, sub) in const [
          ('Murtala Muhammed Airport, Terminal 2', 'Ikeja'),
          ('Terra Kulture', 'Tiamiyu Savage St, Victoria Island'),
          ('The Palms Shopping Mall', 'Lekki'),
        ])
          MenuTile(
            icon: Icons.history_rounded,
            title: name,
            subtitle: sub,
            color: CaboColors.muted,
            onTap: () => go(context, '/confirm-pickup'),
          ),
      ],
    );
  }
}

class PickOnMapScreen extends StatelessWidget {
  const PickOnMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const Stack(
        children: [
          Positioned.fill(child: CaboMap()),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(
                Icons.location_on_rounded,
                size: 52,
                color: CaboColors.red,
              ),
            ),
          ),
        ],
      ),
      top: const _MapTopBar('Move the map to set destination'),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nike Art Gallery', style: CaboText.h2),
          Text('2 Elegushi Beach Rd, Lekki', style: CaboText.muted),
          const SizedBox(height: 16),
          CaboButton(
            'Confirm destination',
            onPressed: () => go(context, '/confirm-pickup'),
          ),
        ],
      ),
    );
  }
}

class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({super.key});

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    const spots = [
      (
        'Eko Hotel main entrance',
        'By the fountain • 20 m',
        Icons.hotel_rounded,
      ),
      (
        'Eko Hotel side gate',
        'Adetokunbo Ademola St • 150 m',
        Icons.door_sliding_rounded,
      ),
      (
        'Kuramo Waters bus stop',
        'Landmark drivers know well • 300 m',
        Icons.directions_bus_rounded,
      ),
    ];
    return MapLayout(
      map: const CaboMap(
        markers: [
          MapMarker(_pickup, MarkerKind.pickup, label: 'Main entrance'),
        ],
      ),
      top: const _MapTopBar('Confirm pickup'),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meet your driver at a landmark', style: CaboText.h3),
          const SizedBox(height: 10),
          for (var i = 0; i < spots.length; i++)
            SelectTile(
              icon: spots[i].$3,
              title: spots[i].$1,
              subtitle: spots[i].$2,
              selected: selected == i,
              onTap: () => setState(() => selected = i),
            ),
          const SizedBox(height: 4),
          CaboButton(
            'Confirm pickup',
            onPressed: () => go(context, '/choose-ride'),
          ),
        ],
      ),
    );
  }
}

class ChooseRideScreen extends StatefulWidget {
  const ChooseRideScreen({super.key});

  @override
  State<ChooseRideScreen> createState() => _ChooseRideScreenState();
}

class _ChooseRideScreenState extends State<ChooseRideScreen> {
  int selected = 1;

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        'Economy',
        Icons.directions_car_rounded,
        '4 min away • 2.3 km',
        2500,
        4,
        null,
      ),
      (
        'Comfort',
        Icons.directions_car_filled_rounded,
        '8 min away • 3.5 km',
        3500,
        4,
        null,
      ),
      (
        'SUV',
        Icons.airport_shuttle_rounded,
        '10 min away • 5.2 km',
        5000,
        6,
        '×1.2',
      ),
      (
        'Premium',
        Icons.local_taxi_rounded,
        '12 min away • 6.0 km',
        7500,
        4,
        null,
      ),
    ];
    return Scaffold(
      appBar: caboAppBar(context, 'Book a Ride'),
      body: Column(
        children: [
          const Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: CaboMap(
                  route: [
                    _pickup,
                    Offset(0.62, 0.52),
                    Offset(0.78, 0.6),
                    _dropoff,
                  ],
                  markers: [
                    MapMarker(_pickup, MarkerKind.pickup, label: 'Eko Hotel'),
                    MapMarker(
                      _dropoff,
                      MarkerKind.dropoff,
                      label: 'Nike Art Gallery',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              children: [
                for (var i = 0; i < options.length; i++)
                  RideOption(
                    name: options[i].$1,
                    icon: options[i].$2,
                    eta: options[i].$3,
                    fare: options[i].$4,
                    seats: options[i].$5,
                    surge: options[i].$6,
                    selected: selected == i,
                    onTap: () => setState(() => selected = i),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => go(context, '/payment-method'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_rounded,
                                color: CaboColors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Visa •• 4242',
                                style: CaboText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: CaboColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => go(context, '/fare-breakdown'),
                      child: Text(
                        'Fare details',
                        style: CaboText.label.copyWith(color: CaboColors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Request Ride',
          onPressed: () => go(context, '/finding-driver'),
        ),
      ),
    );
  }
}

class FareBreakdownScreen extends StatelessWidget {
  const FareBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Fare breakdown',
      children: [
        Center(child: Text('Comfort • upfront fare', style: CaboText.muted)),
        Center(
          child: Text(
            naira(3500),
            style: CaboText.display.copyWith(color: CaboColors.green),
          ),
        ),
        Center(
          child: Text('${gbp(3500)} at today\'s rate', style: CaboText.muted),
        ),
        const SizedBox(height: 20),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Base fare', naira(700)),
              InfoRow('Distance (14.6 km)', naira(1800)),
              InfoRow('Time (about 32 min)', naira(600)),
              InfoRow('Lekki toll gate', naira(400)),
              const InfoRow('Discounts', '₦0'),
              const Divider(height: 20),
              InfoRow('Total', naira(3500), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              color: CaboColors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This price is fixed unless you add a stop or change the destination. '
                'Card payments are held at booking and charged when the trip ends.',
                style: CaboText.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Payment method',
      bottom: CaboButton('Use Visa •• 4242', onPressed: () => back(context)),
      children: [
        const SingleChoice(
          icons: [
            Icons.credit_card_rounded,
            Icons.account_balance_wallet_rounded,
            Icons.account_balance_rounded,
            Icons.payments_rounded,
          ],
          options: [
            ('Visa •• 4242', 'UK card • held at booking, charged at the end'),
            ('Cabo Wallet', 'Balance ₦12,400'),
            ('Bank transfer', 'Pay to a virtual account'),
            ('Cash', 'Pay the driver at the end of the ride'),
          ],
        ),
        MenuTile(
          icon: Icons.add_card_rounded,
          title: 'Add a card',
          subtitle: 'Visa, Mastercard or Verve',
          onTap: () => go(context, '/add-card'),
        ),
        MenuTile(
          icon: Icons.local_offer_rounded,
          title: 'Promo code',
          subtitle: 'WELCOME20 applies to tours',
          color: CaboColors.orange,
          onTap: () => go(context, '/promos'),
        ),
      ],
    );
  }
}

class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const Stack(
        children: [
          Positioned.fill(child: CaboMap()),
          Align(
            alignment: Alignment(0.12, -0.28),
            child: Pulse(animate: !kScreenshotMode, size: 160),
          ),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => replace(context, '/driver-on-way'),
            child: Text('Finding your driver…', style: CaboText.h2),
          ),
          const SizedBox(height: 4),
          Text(
            'Matching you with the nearest vetted Comfort driver.',
            textAlign: TextAlign.center,
            style: CaboText.muted,
          ),
          const SizedBox(height: 14),
          const LinearProgressIndicator(value: kScreenshotMode ? 0.45 : null),
          const SizedBox(height: 18),
          const _Stop(CaboColors.green, 'PICKUP', 'Eko Hotel main entrance'),
          const _Stop(CaboColors.red, 'DROP-OFF', 'Nike Art Gallery, Lekki'),
          const SizedBox(height: 14),
          CaboButton(
            'Cancel request',
            style: CaboButtonStyle.secondary,
            onPressed: () => back(context),
          ),
        ],
      ),
    );
  }
}

class DriverOnTheWayScreen extends StatelessWidget {
  const DriverOnTheWayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: [
          Offset(0.3, 0.7),
          Offset(0.3, 0.55),
          Offset(0.52, 0.5),
          _pickup,
        ],
        markers: [
          MapMarker(Offset(0.3, 0.68), MarkerKind.driver),
          MapMarker(_pickup, MarkerKind.pickup, label: 'You'),
        ],
      ),
      top: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CaboColors.green,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Emeka arrives in 4 min at the main entrance',
                style: CaboText.h3.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DriverCard(),
          const SizedBox(height: 14),
          CaboCard(
            color: CaboColors.yellowSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Give this PIN to your driver to start the trip',
                    style: CaboText.body,
                  ),
                ),
                Text('2741', style: CaboText.h1.copyWith(letterSpacing: 4)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CaboButton(
                  'Share trip',
                  style: CaboButtonStyle.secondary,
                  icon: Icons.share_rounded,
                  height: 48,
                  onPressed: () => go(context, '/share-trip'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CaboButton(
                  'Cancel',
                  style: CaboButtonStyle.secondary,
                  height: 48,
                  onPressed: () => go(context, '/cancel-ride'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CaboButton(
            'Driver arrived? Start trip',
            onPressed: () => replace(context, '/trip-in-progress'),
          ),
        ],
      ),
    );
  }
}

class ChatWithDriverScreen extends StatelessWidget {
  const ChatWithDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const replies = [
      "I'm at the entrance",
      'Wearing a blue shirt',
      'Coming now',
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
            const Avatar('EN', size: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emeka N.', style: CaboText.h3),
                Text(
                  'Silver Corolla • LND 482 KJ',
                  style: CaboText.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: CaboColors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CaboColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: CaboColors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calls and chats are private. Your number stays hidden.',
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
                  "Good morning, I'm 2 minutes away.",
                  mine: false,
                  time: '08:58',
                ),
                ChatBubble(
                  "Great, I'm by the fountain at the main entrance.",
                  mine: true,
                  time: '08:59',
                ),
                ChatBubble(
                  'No problem. Silver Corolla, LND 482 KJ.',
                  mine: false,
                  time: '09:00',
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
                  border: Border.all(color: CaboColors.green),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  replies[i],
                  style: CaboText.label.copyWith(color: CaboColors.green),
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

class TripInProgressScreen extends StatelessWidget {
  const TripInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: [Offset(0.62, 0.52), Offset(0.78, 0.6), _dropoff],
        markers: [
          MapMarker(Offset(0.62, 0.52), MarkerKind.driver),
          MapMarker(_dropoff, MarkerKind.dropoff, label: 'Nike Art Gallery'),
        ],
      ),
      top: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Text('Arrive 9:42 • 18 min', style: CaboText.h3),
          ),
          const Spacer(),
          RoundAction(
            Icons.sos_rounded,
            color: CaboColors.red,
            iconColor: Colors.white,
            size: 56,
            onTap: () => go(context, '/sos'),
          ),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('On the way to Nike Art Gallery', style: CaboText.h2),
          const SizedBox(height: 4),
          Text('9.2 km left • Comfort • Visa •• 4242', style: CaboText.muted),
          const SizedBox(height: 14),
          const DriverCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (icon, label, route) in const [
                (Icons.share_rounded, 'Share', '/share-trip'),
                (Icons.add_location_alt_rounded, 'Add stop', '/add-stop'),
                (Icons.shield_rounded, 'Safety', '/safety'),
                (Icons.flag_rounded, 'Arrived', '/trip-complete'),
              ])
                Expanded(
                  child: RoundAction(
                    icon,
                    label: label,
                    color: CaboColors.greenSoft,
                    iconColor: CaboColors.green,
                    onTap: () => go(context, route),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShareTripScreen extends StatelessWidget {
  const ShareTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Share trip',
      children: [
        CaboCard(
          color: CaboColors.greenSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live trip link', style: CaboText.label),
              const SizedBox(height: 4),
              Text(
                'cabo.ng/t/7Q4-2291',
                style: CaboText.h2.copyWith(color: CaboColors.green),
              ),
              const SizedBox(height: 6),
              Text(
                'Shows your driver, car and live location. Opens in any browser, no app needed. '
                'Expires when the trip ends.',
                style: CaboText.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CaboButton(
                'WhatsApp',
                icon: Icons.chat_rounded,
                height: 50,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaboButton(
                'Copy link',
                style: CaboButtonStyle.secondary,
                icon: Icons.copy_rounded,
                height: 50,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SectionTitle('Trusted contacts'),
        const ToggleTile('Bisi Bakare', subtitle: 'Mother • +44 7700 900 118'),
        const ToggleTile(
          'Kemi Adeyemi',
          subtitle: 'Friend • +234 802 555 0192',
          initial: false,
        ),
        const SizedBox(height: 8),
        const ToggleTile(
          'Share every trip automatically',
          subtitle: 'With the contacts switched on above',
          initial: false,
        ),
      ],
    );
  }
}

class AddStopScreen extends StatelessWidget {
  const AddStopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Add a stop',
      bottom: CaboButton(
        'Add stop • new fare ${naira(3900)}',
        onPressed: () => back(context),
      ),
      children: [
        const _Stop(CaboColors.green, 'PICKUP', 'Eko Hotel main entrance'),
        const _Stop(CaboColors.blue, 'STOP', 'Shoprite, The Palms Lekki'),
        const _Stop(CaboColors.red, 'DROP-OFF', 'Nike Art Gallery, Lekki'),
        const SizedBox(height: 14),
        const SearchBox(value: 'Shoprite'),
        const SizedBox(height: 8),
        for (final (name, sub) in const [
          ('Shoprite, The Palms Lekki', 'On your route • +4 min'),
          ('Shoprite, Ikota', '+12 min'),
        ])
          MenuTile(
            icon: Icons.shopping_cart_rounded,
            title: name,
            subtitle: sub,
            onTap: () {},
          ),
        const SizedBox(height: 10),
        CaboCard(
          color: CaboColors.yellowSoft,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: CaboColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your fare goes from ${naira(3500)} to ${naira(3900)}. Your driver sees the new route straight away.',
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

class ScheduleRideScreen extends StatefulWidget {
  const ScheduleRideScreen({super.key});

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
  int day = 2;
  int time = 3;

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Fri', '16'),
      ('Sat', '17'),
      ('Sun', '18'),
      ('Mon', '19'),
      ('Tue', '20'),
      ('Wed', '21'),
      ('Thu', '22'),
    ];
    const times = [
      '07:00',
      '07:30',
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
    ];
    return CaboScaffold(
      title: 'Schedule a ride',
      bottom: CaboButton(
        'Schedule for Sun 18 Oct, 08:30',
        onPressed: () => go(context, '/bookings'),
      ),
      children: [
        Text(
          'Book up to 7 days ahead. We assign a driver the evening before.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SectionTitle('Day'),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => setState(() => day = i),
              child: Container(
                width: 58,
                decoration: BoxDecoration(
                  color: i == day ? CaboColors.green : CaboColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[i].$1,
                      style: CaboText.label.copyWith(
                        color: i == day ? Colors.white70 : CaboColors.muted,
                      ),
                    ),
                    Text(
                      days[i].$2,
                      style: CaboText.h2.copyWith(
                        color: i == day ? Colors.white : CaboColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('Pickup time'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < times.length; i++)
              GestureDetector(
                onTap: () => setState(() => time = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == time ? CaboColors.green : CaboColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    times[i],
                    style: CaboText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: i == time ? Colors.white : CaboColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        CaboCard(
          child: Column(
            children: [
              const _Stop(
                CaboColors.green,
                'PICKUP',
                'Eko Hotel main entrance',
              ),
              const _Stop(
                CaboColors.red,
                'DROP-OFF',
                'Murtala Muhammed Airport, T2',
              ),
              const Divider(height: 18),
              InfoRow('Comfort • fixed fare', naira(14500), bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

class CancelRideScreen extends StatelessWidget {
  const CancelRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Cancel ride',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaboButton(
            'Cancel ride',
            style: CaboButtonStyle.danger,
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false),
          ),
          const SizedBox(height: 10),
          CaboButton(
            'Keep my ride',
            style: CaboButtonStyle.secondary,
            height: 48,
            onPressed: () => back(context),
          ),
        ],
      ),
      children: [
        CaboCard(
          color: CaboColors.yellowSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: CaboColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Free cancellation ended 1 minute ago. A ${naira(500)} fee goes to your driver for their time.',
                  style: CaboText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Why are you cancelling?'),
        const SingleChoice(
          initial: 1,
          options: [
            ('Driver is taking too long', null),
            ('I changed my plans', null),
            ('Wrong pickup location', null),
            ('I feel unsafe', 'Cabo Safety will follow up with you'),
            ('Other', null),
          ],
        ),
      ],
    );
  }
}

class TripCompleteScreen extends StatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  State<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends State<TripCompleteScreen> {
  int tip = 2;

  @override
  Widget build(BuildContext context) {
    const tips = [0, 200, 500, 1000];
    return CaboScaffold(
      title: 'Trip complete',
      showBack: false,
      bottom: CaboButton(
        'Pay & rate Emeka',
        onPressed: () => go(context, '/rate-driver'),
      ),
      children: [
        const SizedBox(height: 8),
        const Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: CaboColors.greenSoft,
            child: Icon(Icons.check_rounded, size: 44, color: CaboColors.green),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            "You've arrived at Nike Art Gallery",
            style: CaboText.h2,
            textAlign: TextAlign.center,
          ),
        ),
        Center(child: Text('14.6 km • 34 min', style: CaboText.muted)),
        const SizedBox(height: 18),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Trip fare', naira(3500)),
              InfoRow(
                'Tip for Emeka',
                naira(tips[tip]),
                valueColor: CaboColors.green,
              ),
              const Divider(height: 20),
              InfoRow(
                'Total (Visa •• 4242)',
                naira(3500 + tips[tip]),
                bold: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(gbp(3500 + tips[tip]), style: CaboText.label),
              ),
            ],
          ),
        ),
        const SectionTitle('Add a tip'),
        Row(
          children: [
            for (var i = 0; i < tips.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => tip = i),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == tip ? CaboColors.green : CaboColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        i == 0 ? 'No tip' : naira(tips[i]),
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: i == tip ? Colors.white : CaboColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.mail_outline_rounded,
              size: 18,
              color: CaboColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Receipt sent to tunde.bakare@gmail.com',
                style: CaboText.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({super.key});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int stars = 5;

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Rate your driver',
      bottom: CaboButton(
        'Submit',
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (_) => false),
      ),
      children: [
        const SizedBox(height: 16),
        const Center(child: Avatar('EN', size: 96)),
        const SizedBox(height: 12),
        Center(
          child: Text('How was your ride with Emeka?', style: CaboText.h2),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 46,
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
            style: CaboText.h3.copyWith(color: CaboColors.green),
          ),
        ),
        const SectionTitle('What stood out?'),
        const ChipPicker(
          options: [
            'Safe driving',
            'Clean car',
            'Knows Lagos',
            'Friendly',
            'Great music',
            'On time',
          ],
          initial: {0, 2, 5},
        ),
        const SizedBox(height: 18),
        const CaboField(
          'Anything else? (optional)',
          hint: 'Tell us about your trip',
          maxLines: 3,
        ),
      ],
    );
  }
}
