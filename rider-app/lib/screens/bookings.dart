import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 9. Bookings and support.

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget booking(
      IconData icon,
      Color color,
      String title,
      String sub,
      String status,
      Color statusColor,
      String route,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: () => go(context, route),
        child: Row(
          children: [
            IconBadge(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CaboText.h3.copyWith(fontSize: 15)),
                  Text(sub, style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Pill(status, color: statusColor),
          ],
        ),
      ),
    );
    return CaboScaffold(
      title: 'My bookings',
      showBack: false,
      bottomNav: const RiderNav(1),
      children: [
        const ChipPicker(
          options: ['Upcoming', 'Active', 'Past'],
          initial: {0},
          single: true,
        ),
        const SectionTitle('Active'),
        booking(
          Icons.local_taxi_rounded,
          CaboColors.green,
          'Ride to Nike Art Gallery',
          'Emeka N. • arriving in 4 min',
          'Live',
          CaboColors.red,
          '/driver-on-way',
        ),
        const SectionTitle('Upcoming'),
        booking(
          Icons.flight_land_rounded,
          CaboColors.orange,
          'Airport pickup',
          'Sat 10 Oct, 06:30 • MMIA → Ikoyi',
          'Driver assigned',
          CaboColors.green,
          '/shuttle-assigned',
        ),
        booking(
          Icons.tour_rounded,
          CaboColors.blue,
          'Lekki Conservation Centre',
          'Sun 18 Oct, 09:00 • 2 guests',
          'Ticket',
          CaboColors.blue,
          '/ticket',
        ),
        booking(
          Icons.schedule_rounded,
          CaboColors.green,
          'Ride to MMIA Terminal 2',
          'Sun 18 Oct, 08:30 • Comfort',
          'Scheduled',
          CaboColors.muted,
          '/schedule-ride',
        ),
        const SectionTitle('Past'),
        booking(
          Icons.local_taxi_rounded,
          CaboColors.muted,
          'Ikoyi → Terra Kulture',
          'Mon 12 Oct • ${'₦2,900'}',
          'Completed',
          CaboColors.muted,
          '/past-trip',
        ),
        booking(
          Icons.tour_rounded,
          CaboColors.muted,
          'Lagos Island Heritage Walk',
          'Sun 11 Oct • Leave a review',
          'Review',
          CaboColors.orange,
          '/write-review',
        ),
      ],
    );
  }
}

class PastTripScreen extends StatelessWidget {
  const PastTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Trip details',
      bottom: Row(
        children: [
          Expanded(
            child: CaboButton(
              'Get help',
              style: CaboButtonStyle.secondary,
              onPressed: () => go(context, '/report-issue'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CaboButton(
              'Rebook',
              onPressed: () => go(context, '/choose-ride'),
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: CaboMap(
              labels: false,
              route: [Offset(0.5, 0.3), Offset(0.4, 0.55), Offset(0.36, 0.7)],
              markers: [
                MapMarker(Offset(0.5, 0.3), MarkerKind.pickup),
                MapMarker(Offset(0.36, 0.7), MarkerKind.dropoff),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Ikoyi → Terra Kulture', style: CaboText.h2),
        Text(
          'Mon 12 Oct, 19:05 – 19:27 • 6.2 km • Economy',
          style: CaboText.muted,
        ),
        const SizedBox(height: 14),
        const CaboCard(child: DriverCard(actions: false)),
        const SizedBox(height: 12),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Fare', naira(2900)),
              const InfoRow('Payment', 'Visa •• 4242'),
              const InfoRow('Your rating', '★★★★★'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        MenuTile(
          icon: Icons.receipt_long_rounded,
          title: 'Receipt',
          subtitle: 'Download or email',
          onTap: () => go(context, '/receipt'),
        ),
      ],
    );
  }
}

class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Report an issue',
      bottom: CaboButton(
        'Send to support',
        onPressed: () => go(context, '/support-tickets'),
      ),
      children: [
        Text('Ikoyi → Terra Kulture • Mon 12 Oct', style: CaboText.muted),
        const SectionTitle('What happened?'),
        const SingleChoice(
          initial: 0,
          icons: [
            Icons.backpack_rounded,
            Icons.payments_rounded,
            Icons.sentiment_dissatisfied_rounded,
            Icons.undo_rounded,
          ],
          options: [
            ('I lost an item', 'We will contact the driver for you'),
            ('I was overcharged', null),
            ('Driver behaviour', null),
            ('Request a refund', null),
          ],
        ),
        const CaboField(
          'Details',
          value: 'Left a black camera bag on the back seat.',
          maxLines: 3,
        ),
      ],
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Help centre',
      children: [
        const SearchBox(hint: 'Search help'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            for (final (icon, label) in const [
              (Icons.local_taxi_rounded, 'Rides'),
              (Icons.flight_land_rounded, 'Airport shuttles'),
              (Icons.tour_rounded, 'Tours'),
              (Icons.payments_rounded, 'Payments'),
            ])
              CaboCard(
                color: CaboColors.surface,
                onTap: () {},
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: CaboColors.green),
                    Text(
                      label,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SectionTitle('Popular questions'),
        for (final (i, q) in const [
          'Why do I pay in naira?',
          'Can I pay with a foreign card?',
          'What if my flight is delayed?',
          'How do refunds for tours work?',
        ].indexed)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              tilePadding: EdgeInsets.zero,
              iconColor: CaboColors.green,
              title: Text(
                q,
                style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'All prices in Nigeria are charged in naira. We show an estimate in your home '
                    'currency using the day\'s exchange rate. Your bank does the final conversion.',
                    style: CaboText.muted,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        CaboButton(
          'Chat with support',
          icon: Icons.support_agent_rounded,
          onPressed: () => go(context, '/support-chat'),
        ),
      ],
    );
  }
}

class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Avatar('AD', size: 40, color: CaboColors.green),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ada, Cabo Support', style: CaboText.h3),
                Text(
                  'Online • replies in ~2 min',
                  style: CaboText.muted.copyWith(
                    fontSize: 12,
                    color: CaboColors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ChatBubble(
                  'Hi, I left my camera bag in a car on Monday evening.',
                  mine: true,
                  time: '10:02',
                ),
                ChatBubble(
                  'Hi Tunde, sorry to hear that. I can see your trip from Ikoyi to Terra Kulture with Emeka.',
                  mine: false,
                  time: '10:03',
                ),
                ChatBubble(
                  'Emeka has found the bag. He can drop it at your hotel this evening for a ₦2,000 return fee.',
                  mine: false,
                  time: '10:09',
                ),
                ChatBubble('Perfect, thank you!', mine: true, time: '10:10'),
              ],
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ChatInput(),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Support tickets',
      children: [
        for (final (id, title, updated, status, color) in const [
          (
            '#51832',
            'Lost item: camera bag',
            'Updated 5 min ago',
            'Resolving',
            CaboColors.orange,
          ),
          (
            '#51007',
            'Refund for cancelled tour',
            'Updated 2 days ago',
            'Refunded',
            CaboColors.green,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              onTap: () => go(context, '/support-chat'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(id, style: CaboText.label),
                      const Spacer(),
                      Pill(status, color: color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: CaboText.h3),
                  Text(updated, style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Rewards',
      bottom: CaboButton(
        'Invite friends',
        icon: Icons.share_rounded,
        onPressed: () {},
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CaboColors.yellowSoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CaboColors.yellow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cabo points', style: CaboText.label),
              Text('1,240', style: CaboText.display),
              const SizedBox(height: 8),
              const Bar(0.62, color: CaboColors.orange),
              const SizedBox(height: 6),
              Text(
                '760 points to a free airport pickup',
                style: CaboText.muted,
              ),
            ],
          ),
        ),
        const SectionTitle('Invite a friend'),
        CaboCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You both get ${naira(2000)}', style: CaboText.h3),
                    Text(
                      'When they take their first ride',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CaboColors.greenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'TUNDE24',
                  style: CaboText.h3.copyWith(
                    color: CaboColors.green,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Ways to earn'),
        const MenuTile(
          icon: Icons.local_taxi_rounded,
          title: '10 points per ₦1,000 on rides',
        ),
        const MenuTile(icon: Icons.tour_rounded, title: '2× points on tours'),
        const MenuTile(
          icon: Icons.rate_review_rounded,
          title: '50 points for each tour review',
        ),
      ],
    );
  }
}
