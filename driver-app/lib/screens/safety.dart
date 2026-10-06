import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 7. Safety and support.

class SafetyToolkitScreen extends StatelessWidget {
  const SafetyToolkitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Safety toolkit',
      children: [
        Center(
          child: GestureDetector(
            onTap: () => go(context, '/emergency'),
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CaboColors.red.withValues(alpha: 0.18),
              ),
              child: Center(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CaboColors.red,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SOS',
                        style: CaboText.display.copyWith(fontSize: 36),
                      ),
                      Text(
                        'Hold for 2 s',
                        style: CaboText.label.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Calls emergency services and alerts Cabo Safety',
            style: CaboText.muted,
            textAlign: TextAlign.center,
          ),
        ),
        const SectionTitle('Share trip'),
        const ToggleTile(
          'Share every trip automatically',
          subtitle: 'Trusted contacts can follow your live location',
          icon: Icons.share_location_rounded,
        ),
        for (final (initials, name, rel) in const [
          ('NN', 'Ngozi Nwosu', 'Wife'),
          ('CN', 'Chidi Nwosu', 'Brother'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Avatar(initials, size: 40, color: CaboColors.yellowSoft),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: CaboText.body)),
                Text(rel, style: CaboText.muted),
              ],
            ),
          ),
        const SectionTitle('Tools'),
        MenuTile(
          icon: Icons.report_rounded,
          title: 'Report an incident',
          subtitle: 'Rider misconduct, accident or damage',
          color: CaboColors.orange,
          onTap: () => go(context, '/report-incident'),
        ),
        MenuTile(
          icon: Icons.inventory_2_rounded,
          title: 'Lost items',
          subtitle: '1 item reported by a rider',
          onTap: () => go(context, '/lost-item'),
        ),
        const SectionTitle('Safety tips'),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (icon, tip) in const [
                (
                  Icons.verified_user_rounded,
                  'Always verify the rider PIN before starting',
                ),
                (
                  Icons.nightlight_round,
                  'Use well-lit pickup points after dark',
                ),
                (
                  Icons.speed_rounded,
                  'Stay within speed limits on Third Mainland',
                ),
              ])
                Container(
                  width: 210,
                  margin: const EdgeInsets.only(right: 10),
                  child: CaboCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: CaboColors.yellow),
                        const SizedBox(height: 8),
                        Text(tip, style: CaboText.body.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A0D10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A0D10),
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
          Text(
            'Stay calm. Help is on the way.',
            style: CaboText.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CaboButton(
            'Call 112',
            icon: Icons.call_rounded,
            style: CaboButtonStyle.danger,
            height: 72,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          CaboButton(
            'Alert Cabo Safety team',
            icon: Icons.support_agent_rounded,
            style: CaboButtonStyle.light,
            height: 64,
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          CaboCard(
            color: Colors.white.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: CaboColors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your location',
                      style: CaboText.label.copyWith(color: Colors.white70),
                    ),
                    const Spacer(),
                    const Pill(
                      'Live',
                      color: CaboColors.red,
                      icon: Icons.circle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ozumba Mbadiwe Avenue, near Civic Centre, Victoria Island',
                  style: CaboText.h3,
                ),
                const SizedBox(height: 4),
                Text('6.4362° N, 3.4300° E', style: CaboText.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CaboCard(
            color: Colors.white.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared with',
                  style: CaboText.label.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                for (final t in const [
                  'Cabo Safety team (24/7)',
                  'Ngozi Nwosu',
                  'Chidi Nwosu',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: CaboColors.brightGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(t, style: CaboText.body),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const CaboCard(
            color: Color(0x14FFFFFF),
            child: Column(
              children: [
                InfoRow('Current trip', 'Eko Hotel → Nike Art Gallery'),
                InfoRow('Vehicle', 'Silver Toyota Corolla • LND 482 KJ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportIncidentScreen extends StatelessWidget {
  const ReportIncidentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Report an incident',
      bottom: CaboButton(
        'Submit report',
        onPressed: () => go(context, '/support-tickets'),
      ),
      children: [
        Text('What happened?', style: CaboText.h2),
        const SizedBox(height: 14),
        const SingleChoice(
          icons: [
            Icons.person_off_rounded,
            Icons.car_crash_rounded,
            Icons.build_rounded,
            Icons.more_horiz_rounded,
          ],
          options: [
            ('Rider misconduct', 'Abuse, threats or harassment'),
            ('Accident', 'A collision during a trip'),
            ('Vehicle damage', 'Damage caused by a rider'),
            ('Something else', null),
          ],
          initial: 2,
        ),
        const SizedBox(height: 6),
        const CaboField(
          'Trip',
          value: 'Today 19:08 • Eko Hotel → Nike Art Gallery',
          icon: Icons.receipt_long_rounded,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        const CaboField(
          'Describe what happened',
          value: 'Rear seat cover was torn when the rider loaded a large suitcase.',
          maxLines: 3,
        ),
        Text('Photos', style: CaboText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 84,
                height: 84,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: i == 0 ? CaboColors.surfaceHigh : CaboColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CaboColors.outline),
                ),
                child: Icon(
                  i == 0 ? Icons.image_rounded : Icons.add_a_photo_outlined,
                  color: i == 0 ? Colors.white54 : CaboColors.yellow,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class LostItemScreen extends StatelessWidget {
  const LostItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Lost item',
      bottom: CaboButton('Confirm return', onPressed: () => back(context)),
      children: [
        CaboCard(
          color: CaboColors.yellow.withValues(alpha: 0.14),
          child: Row(
            children: [
              const IconBadge(Icons.phone_iphone_rounded, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Black iPhone in a green case', style: CaboText.h3),
                    Text(
                      'Probably on the back seat, left side',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CaboCard(
          child: Column(
            children: [
              InfoRow('Reported by', 'Daniel K.'),
              InfoRow('Trip', 'Yesterday 21:05 • Yaba → Surulere'),
              InfoRow('Reported', '40 min ago'),
            ],
          ),
        ),
        const SectionTitle('Did you find it?'),
        const ChipPicker(
          options: ['Yes, I have it', 'Not found'],
          initial: {0},
          single: true,
        ),
        const SectionTitle('How will you return it?'),
        const SingleChoice(
          options: [
            ('Meet the rider', 'You earn a ₦2,000 return fee'),
            ('Drop at Cabo Hub Yaba', 'Open daily 08:00 – 20:00'),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: CaboButton(
                'Call rider',
                style: CaboButtonStyle.secondary,
                icon: Icons.call_rounded,
                height: 48,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaboButton(
                'Message',
                style: CaboButtonStyle.secondary,
                icon: Icons.chat_bubble_rounded,
                height: 48,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Help centre',
      children: [
        TextFormField(
          style: CaboText.body,
          decoration: const InputDecoration(
            hintText: 'Search help articles',
            prefixIcon: Icon(Icons.search, color: CaboColors.muted),
          ),
        ),
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
              (Icons.payments_rounded, 'Earnings & payouts'),
              (Icons.description_rounded, 'Documents'),
              (Icons.directions_car_rounded, 'Trips & fares'),
              (Icons.flight_rounded, 'Airport & tours'),
            ])
              CaboCard(
                onTap: () {},
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: CaboColors.yellow),
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
          'When do I get paid?',
          'How is the Cabo commission calculated?',
          'What happens if a rider does not show up?',
          'How do I renew an expired document?',
          'How do I become a driver-guide?',
        ].indexed)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              tilePadding: EdgeInsets.zero,
              iconColor: CaboColors.yellow,
              collapsedIconColor: CaboColors.muted,
              title: Text(
                q,
                style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Earnings from Monday to Sunday are paid every Monday by 10:00 to your bank account. '
                    'You can also cash out instantly for a 1.5% fee.',
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
            const Avatar('AD', size: 40, color: CaboColors.brightGreen),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ada, Cabo Support', style: CaboText.h3),
                Text(
                  'Online • replies in ~2 min',
                  style: CaboText.muted.copyWith(
                    fontSize: 12,
                    color: CaboColors.brightGreen,
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
              children: [
                Center(child: Text('Today', style: CaboText.label)),
                const SizedBox(height: 12),
                const ChatBubble(
                  'Hi, my payout for last week is ₦4,000 less than the earnings screen showed.',
                  mine: true,
                  time: '10:12',
                ),
                const ChatBubble(
                  'Hi Emeka, I am Ada. Thanks for reaching out. Let me check your payout for 28 Sep – 4 Oct.',
                  mine: false,
                  time: '10:13',
                ),
                const ChatBubble(
                  'I can see a Lekki toll of ₦4,000 was not added to one shuttle job. '
                  'I have raised a fare adjustment for you.',
                  mine: false,
                  time: '10:16',
                ),
                CaboCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => go(context, '/support-tickets'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        color: CaboColors.yellow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ticket #48213 • Fare adjustment ₦4,000',
                          style: CaboText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Pill('In review'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const ChatBubble('Thank you, Ada!', mine: true, time: '10:17'),
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
    const tickets = [
      (
        '#48213',
        'Fare adjustment: missing Lekki toll',
        'Updated 10 min ago',
        'In review',
        CaboColors.yellow,
      ),
      (
        '#48190',
        'Vehicle damage: torn seat cover',
        'Updated yesterday',
        'Open',
        CaboColors.blue,
      ),
      (
        '#47702',
        'Fare dispute: rider says route was long',
        'Updated 2 Oct',
        'Resolved',
        CaboColors.brightGreen,
      ),
      (
        '#47011',
        'Payout delayed',
        'Updated 21 Sep',
        'Resolved',
        CaboColors.brightGreen,
      ),
    ];
    return CaboScaffold(
      title: 'Support tickets',
      bottom: CaboButton(
        'New request',
        icon: Icons.add_rounded,
        onPressed: () => go(context, '/support-chat'),
      ),
      children: [
        const ChipPicker(
          options: ['Open (2)', 'Resolved (2)', 'All'],
          initial: {2},
          single: true,
        ),
        const SizedBox(height: 16),
        for (final (id, title, updated, status, color) in tickets)
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
                  const SizedBox(height: 6),
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
