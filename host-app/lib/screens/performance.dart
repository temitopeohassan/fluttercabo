import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 6. Performance and growth.

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const dist = [(5, 0.86), (4, 0.10), (3, 0.03), (2, 0.01), (1, 0.0)];
    return CaboScaffold(
      title: 'Ratings',
      children: [
        CaboCard(
          child: Row(
            children: [
              Column(
                children: [
                  Text('4.92', style: CaboText.display.copyWith(fontSize: 48)),
                  const Stars(4.92),
                  const SizedBox(height: 4),
                  Text(
                    'Last 500 trips',
                    style: CaboText.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    for (final (stars, share) in dist)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text('$stars', style: CaboText.label),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Bar(share, height: 7)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Compliments'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            for (final (icon, label, count) in const [
              (Icons.cleaning_services_rounded, 'Clean car', 142),
              (Icons.map_rounded, 'Knows Lagos', 118),
              (Icons.forum_rounded, 'Great chat', 96),
              (Icons.shield_rounded, 'Safe driving', 131),
              (Icons.luggage_rounded, 'Helped with bags', 64),
              (Icons.music_note_rounded, 'Good music', 37),
            ])
              CaboCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: CaboColors.yellow, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: CaboText.label.copyWith(color: Colors.white),
                    ),
                    Text(
                      '$count',
                      style: CaboText.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SectionTitle('Recent feedback'),
        for (final (rating, text, ago) in const [
          (
            5.0,
            'Emeka waited patiently at the airport and knew every shortcut.',
            'Today',
          ),
          (
            5.0,
            'Very professional. Gave us great restaurant tips in V.I.',
            'Yesterday',
          ),
          (4.0, 'Good ride, but the AC could have been colder.', 'Sat'),
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
                      Stars(rating, size: 16),
                      const Spacer(),
                      Text(ago, style: CaboText.label),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('"$text"', style: CaboText.body),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PerformanceStatsScreen extends StatelessWidget {
  const PerformanceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget metric(
      String label,
      String value,
      double ring,
      Color color,
      String target,
      bool ok,
    ) => CaboCard(
      child: Row(
        children: [
          Ring(
            value: ring,
            size: 84,
            stroke: 8,
            color: color,
            child: Text(value, style: CaboText.h3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CaboText.h3),
                const SizedBox(height: 4),
                Text(target, style: CaboText.muted),
                const SizedBox(height: 8),
                ok
                    ? const Pill(
                        'On track',
                        color: CaboColors.brightGreen,
                        icon: Icons.check,
                      )
                    : const Pill('Needs work', color: CaboColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
    return CaboScaffold(
      title: 'Performance',
      children: [
        Text('Last 30 days', style: CaboText.muted),
        const SizedBox(height: 12),
        metric(
          'Acceptance rate',
          '92%',
          0.92,
          CaboColors.brightGreen,
          'Premium needs 85% or more',
          true,
        ),
        const SizedBox(height: 12),
        metric(
          'Cancellation rate',
          '2.1%',
          0.21,
          CaboColors.yellow,
          'Keep it under 5%',
          true,
        ),
        const SizedBox(height: 12),
        metric(
          'Hours online',
          '164 h',
          0.68,
          CaboColors.blue,
          'Premium needs 240 h in 60 days',
          false,
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: StatTile(
                'Trips completed',
                '248',
                icon: Icons.route_rounded,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: StatTile(
                'On-time airport pickups',
                '100%',
                icon: Icons.flight_land_rounded,
                color: CaboColors.brightGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TiersScreen extends StatelessWidget {
  const TiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget req(String text, bool done) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: done ? CaboColors.brightGreen : CaboColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: CaboText.body)),
        ],
      ),
    );
    return CaboScaffold(
      title: 'Tiers and badges',
      children: [
        CaboCard(
          color: CaboColors.surfaceHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(Icons.workspace_premium_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current tier', style: CaboText.label),
                        Text('Standard', style: CaboText.h2),
                      ],
                    ),
                  ),
                  const Pill('Next: Premium'),
                ],
              ),
              const SizedBox(height: 14),
              const Bar(0.5),
              const SizedBox(height: 6),
              Text('2 of 4 requirements met', style: CaboText.muted),
              const SizedBox(height: 8),
              req('Rating 4.85 or higher', true),
              req('Acceptance rate 85% or higher', true),
              req('Vehicle 2020 or newer (yours is 2019)', false),
              req('240 hours online in 60 days (164 so far)', false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CaboCard(
          onTap: () => go(context, '/tour-certification'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(
                    Icons.tour_rounded,
                    color: CaboColors.brightGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tour Guide eligibility', style: CaboText.h3),
                        Text(
                          'Certification 3 of 6 lessons',
                          style: CaboText.muted,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: CaboColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              const Bar(0.5, color: CaboColors.brightGreen),
            ],
          ),
        ),
        const SectionTitle('Badges'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: [
            for (final (icon, label, earned) in const [
              (Icons.flight_rounded, 'Airport pro', true),
              (Icons.nightlight_round, 'Night owl', true),
              (Icons.local_fire_department_rounded, '100 trips', true),
              (Icons.diversity_3_rounded, 'Tourist favourite', false),
              (Icons.translate_rounded, 'Multilingual', true),
              (Icons.military_tech_rounded, '1,000 trips', false),
            ])
              Opacity(
                opacity: earned ? 1 : 0.4,
                child: CaboCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: earned
                            ? CaboColors.yellow
                            : CaboColors.surfaceHigh,
                        child: Icon(
                          icon,
                          color: earned
                              ? CaboColors.onYellow
                              : CaboColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: CaboText.label.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TourCertificationScreen extends StatelessWidget {
  const TourCertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lessons = [
      ('Lagos history in 20 minutes', true),
      ('Guiding a group safely', true),
      ('Storytelling for visitors', true),
      ('Lagos Island heritage sites', false),
      ('Lekki and the coast', false),
      ('Handling difficult situations', false),
    ];
    return CaboScaffold(
      title: 'Tour guide certification',
      bottom: CaboButton(
        'Continue lesson 4',
        onPressed: () => go(context, '/training-quiz'),
      ),
      children: [
        CaboCard(
          child: Row(
            children: [
              Ring(
                value: 0.5,
                size: 90,
                color: CaboColors.brightGreen,
                child: Text('3/6', style: CaboText.h2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill('In progress', color: CaboColors.yellow),
                    const SizedBox(height: 8),
                    Text('Become a Cabo driver-guide', style: CaboText.h3),
                    Text(
                      'Earn ₦30,000 – ₦60,000 per tour',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Steps'),
        for (final (title, done) in lessons)
          MenuTile(
            icon: done ? Icons.check_rounded : Icons.play_arrow_rounded,
            color: done ? CaboColors.brightGreen : CaboColors.yellow,
            title: title,
            subtitle: done ? 'Completed' : '12 min lesson',
            onTap: () {},
          ),
        MenuTile(
          icon: Icons.assignment_rounded,
          color: CaboColors.muted,
          title: 'Assessment',
          subtitle: '20 questions + a practice tour with a Cabo mentor',
          trailing: const Icon(Icons.lock_rounded, color: CaboColors.muted),
        ),
        MenuTile(
          icon: Icons.verified_rounded,
          color: CaboColors.muted,
          title: 'Certified driver-guide',
          subtitle: 'Unlocks tour jobs on the Jobs board',
          trailing: const Icon(Icons.lock_rounded, color: CaboColors.muted),
        ),
      ],
    );
  }
}

class LearningCentreScreen extends StatelessWidget {
  const LearningCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Learning centre',
      children: [
        CaboCard(
          color: CaboColors.yellow,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURED',
                      style: CaboText.label.copyWith(
                        color: CaboColors.onYellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get ready for Detty December',
                      style: CaboText.h2.copyWith(color: CaboColors.onYellow),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visitor demand triples. Here is how top drivers plan their month.',
                      style: CaboText.body.copyWith(color: CaboColors.onYellow),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.celebration_rounded,
                size: 64,
                color: CaboColors.onYellow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ChipPicker(
          options: [
            'All',
            'Earn more',
            'Serving tourists',
            'Safety',
            'App tips',
          ],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 12),
        for (final (icon, title, meta) in const [
          (
            Icons.trending_up_rounded,
            '5 ways to earn more on airport runs',
            'Earn more • 4 min read',
          ),
          (
            Icons.waving_hand_rounded,
            'Greeting visitors: phrases in French and Spanish',
            'Serving tourists • 3 min',
          ),
          (
            Icons.restaurant_rounded,
            'Restaurants riders always ask about',
            'Serving tourists • 5 min',
          ),
          (
            Icons.health_and_safety_rounded,
            'Driving safely at night in Lagos',
            'Safety • 6 min',
          ),
          (
            Icons.phone_android_rounded,
            'Using the destination filter',
            'App tips • 2 min',
          ),
        ])
          MenuTile(icon: icon, title: title, subtitle: meta, onTap: () {}),
      ],
    );
  }
}
