import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 8. Safety.

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Safety centre',
      children: [
        CaboCard(
          color: CaboColors.red.withValues(alpha: 0.08),
          onTap: () => go(context, '/sos'),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: CaboColors.red,
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency SOS', style: CaboText.h3),
                    Text(
                      'Calls 112, alerts your contacts and Cabo support with your live location.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('How we keep you safe'),
        for (final (icon, title, body) in const [
          (
            Icons.verified_user_rounded,
            'Vetted drivers',
            'ID, police and driving record checks, vehicle inspection and hospitality training.',
          ),
          (
            Icons.pin_rounded,
            'Trip PIN',
            'Your trip only starts when the driver enters your 4-digit PIN.',
          ),
          (
            Icons.share_location_rounded,
            'Live trip sharing',
            'Send a link anyone can open, no app needed.',
          ),
          (
            Icons.support_agent_rounded,
            '24/7 support',
            'We answer SOS alerts within 2 minutes, day or night.',
          ),
        ])
          MenuTile(icon: icon, title: title, subtitle: body),
        const SectionTitle('Tips for visitors'),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (icon, tip) in const [
                (
                  Icons.directions_car_rounded,
                  'Check the plate number before you get in',
                ),
                (
                  Icons.nightlight_round,
                  'At night, wait inside the venue until your driver arrives',
                ),
                (
                  Icons.payments_rounded,
                  'Pay in the app rather than with cash where you can',
                ),
              ])
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 10),
                  child: CaboCard(
                    color: CaboColors.greenSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: CaboColors.green),
                        const SizedBox(height: 8),
                        Text(tip, style: CaboText.body.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        MenuTile(
          icon: Icons.contacts_rounded,
          title: 'Trusted contacts',
          subtitle: '2 contacts',
          onTap: () => go(context, '/trusted-contacts'),
        ),
      ],
    );
  }
}

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F1),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => back(context),
        ),
        title: const Text('Emergency'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CaboColors.red.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Container(
                  width: 136,
                  height: 136,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CaboColors.red,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SOS',
                        style: CaboText.display.copyWith(
                          color: Colors.white,
                          fontSize: 38,
                        ),
                      ),
                      Text(
                        'Hold 2 seconds',
                        style: CaboText.label.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CaboButton(
            'Call 112',
            icon: Icons.call_rounded,
            style: CaboButtonStyle.danger,
            height: 60,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          const CaboCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow('Your location', 'Ozumba Mbadiwe Ave, Victoria Island'),
                InfoRow('Trip', 'Emeka N. • Silver Corolla • LND 482 KJ'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CaboCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('When you press SOS we alert', style: CaboText.label),
                const SizedBox(height: 6),
                const CheckRow('Cabo Safety team (replies within 2 min)'),
                const CheckRow('Bisi Bakare (mother)'),
                const CheckRow('Kemi Adeyemi (friend)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AreYouOkScreen extends StatelessWidget {
  const AreYouOkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: [Offset(0.62, 0.52), Offset(0.7, 0.4), Offset(0.85, 0.35)],
        routeColor: CaboColors.orange,
        markers: [MapMarker(Offset(0.85, 0.35), MarkerKind.driver)],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconBadge(
            Icons.help_rounded,
            color: CaboColors.orange,
            size: 60,
          ),
          const SizedBox(height: 10),
          Text('Is everything OK?', style: CaboText.h1),
          const SizedBox(height: 6),
          Text(
            'Your car has left the planned route and stopped for 4 minutes.',
            textAlign: TextAlign.center,
            style: CaboText.muted.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
          CaboButton("I'm OK", onPressed: () => back(context)),
          const SizedBox(height: 10),
          CaboButton(
            'I need help',
            style: CaboButtonStyle.danger,
            onPressed: () => go(context, '/sos'),
          ),
        ],
      ),
    );
  }
}

class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Trusted contacts',
      bottom: CaboButton(
        'Add a contact',
        icon: Icons.person_add_rounded,
        onPressed: () {},
      ),
      children: [
        Text(
          'They get your live location when you press SOS, and trip links if you choose.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        for (final (initials, name, rel, phone) in const [
          ('BB', 'Bisi Bakare', 'Mother', '+44 7700 900 118'),
          ('KA', 'Kemi Adeyemi', 'Friend', '+234 802 555 0192'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              child: Row(
                children: [
                  Avatar(initials, size: 44, color: CaboColors.greenSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: CaboText.h3),
                        Text('$rel • $phone', style: CaboText.muted),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, color: CaboColors.muted),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const ToggleTile(
          'Share night trips automatically',
          subtitle: 'Trips between 20:00 and 06:00',
          icon: Icons.nightlight_round,
        ),
      ],
    );
  }
}
