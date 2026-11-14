import 'package:flutter/material.dart';

import '../widgets/widgets.dart';
import 'onboarding.dart' show trainingLessons;

// 6. Performance and growth.

Future<Json> _performance(AppState state) async => unwrap(await state.api.get('/driver/performance')) as Json;

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _performance(state),
      builder: (context, p, _) {
        final count = p.integer('ratings_count');
        final breakdown = p.obj('rating_breakdown') ?? const {};
        final feedback = p.list('recent_feedback');
        return CaboScaffold(
          title: 'Ratings',
          children: [
            CaboCard(
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(p.number('rating').toStringAsFixed(2), style: CaboText.display.copyWith(fontSize: 48)),
                      Stars(p.number('rating')),
                      const SizedBox(height: 4),
                      Text(count == 0 ? 'No ratings yet' : plural(count, 'rating'), style: CaboText.muted.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      children: [
                        for (final stars in const [5, 4, 3, 2, 1])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(width: 14, child: Text('$stars', style: CaboText.label)),
                                const SizedBox(width: 6),
                                Expanded(child: Bar(count == 0 ? 0 : breakdown.integer('$stars') / count, height: 7)),
                                SizedBox(
                                  width: 30,
                                  child: Text('${breakdown.integer('$stars')}', textAlign: TextAlign.end, style: CaboText.label),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Recent feedback'),
            if (feedback.isEmpty) const EmptyNotice('Comments from riders appear here.', icon: Icons.rate_review_rounded),
            for (final f in feedback)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CaboCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stars(f.number('driver_rating'), size: 16),
                          const Spacer(),
                          Text(timeAgo(f.date('completed_at')), style: CaboText.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('"${f.str('driver_feedback')}"', style: CaboText.body),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PerformanceStatsScreen extends StatelessWidget {
  const PerformanceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    Widget metric(String label, String value, double ring, Color color, String target, bool ok) => CaboCard(
      child: Row(
        children: [
          Ring(
            value: ring.clamp(0, 1).toDouble(),
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
                    ? const Pill('On track', color: CaboColors.brightGreen, icon: Icons.check)
                    : const Pill('Needs work', color: CaboColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
    return Loader<Json>(
      load: () => _performance(state),
      builder: (context, p, _) {
        final acceptance = p.number('acceptance_rate');
        final cancellation = p.number('cancellation_rate');
        return CaboScaffold(
          title: 'Performance',
          children: [
            Text('Host since ${fmtDate(p.date('member_since'))}', style: CaboText.muted),
            const SizedBox(height: 12),
            metric(
              'Acceptance rate',
              '${acceptance.round()}%',
              acceptance / 100,
              CaboColors.brightGreen,
              'Aim for 85% or more',
              acceptance >= 85,
            ),
            const SizedBox(height: 12),
            metric(
              'Cancellation rate',
              '${cancellation.toStringAsFixed(1)}%',
              cancellation / 10,
              CaboColors.yellow,
              'Keep it under 5%',
              cancellation < 5,
            ),
            const SizedBox(height: 12),
            metric(
              'Rider rating',
              p.number('rating').toStringAsFixed(2),
              p.number('rating') / 5,
              CaboColors.blue,
              'From ${plural(p.integer('ratings_count'), 'rating')}',
              p.number('rating') >= 4.7 || p.integer('ratings_count') == 0,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: StatTile('Trips completed', '${p.integer('completed_trips')}', icon: Icons.route_rounded)),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    'In the last 30 days',
                    '${p.integer('completed_trips_30_days')}',
                    icon: Icons.calendar_month_rounded,
                    color: CaboColors.brightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MenuTile(icon: Icons.star_rounded, title: 'Ratings and feedback', onTap: () => go(context, '/ratings')),
            MenuTile(icon: Icons.workspace_premium_rounded, title: 'Tiers and badges', onTap: () => go(context, '/tiers')),
          ],
        );
      },
    );
  }
}

class TiersScreen extends StatelessWidget {
  const TiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    Widget req(String text, bool done) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: done ? CaboColors.brightGreen : CaboColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: CaboText.body)),
        ],
      ),
    );
    return Loader<Json>(
      load: () => _performance(state),
      builder: (context, p, _) {
        final guide = p.flag('is_tour_guide');
        final trips = p.integer('completed_trips');
        final badges = [
          (Icons.local_fire_department_rounded, '100 trips', trips >= 100),
          (Icons.military_tech_rounded, '1,000 trips', trips >= 1000),
          (Icons.star_rounded, 'Rated 4.8+', p.number('rating') >= 4.8 && p.integer('ratings_count') > 0),
          (Icons.thumb_up_rounded, '90% acceptance', p.number('acceptance_rate') >= 90),
          (Icons.school_rounded, 'Trained', p.flag('training_completed')),
          (Icons.tour_rounded, 'Driver-guide', guide),
        ];
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
                            Text(humanize(p.str('tier', 'standard')), style: CaboText.h2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Cabo reviews tiers regularly. These are what the team looks at:', style: CaboText.muted),
                  const SizedBox(height: 8),
                  req('Rating 4.85 or higher (yours is ${p.number('rating').toStringAsFixed(2)})', p.number('rating') >= 4.85),
                  req(
                    'Acceptance rate 85% or higher (yours is ${p.number('acceptance_rate').round()}%)',
                    p.number('acceptance_rate') >= 85,
                  ),
                  req(
                    'Cancellation rate under 5% (yours is ${p.number('cancellation_rate').toStringAsFixed(1)}%)',
                    p.number('cancellation_rate') < 5,
                  ),
                  req('Hospitality training completed', p.flag('training_completed')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CaboCard(
              onTap: () => go(context, '/tour-certification'),
              child: Row(
                children: [
                  const IconBadge(Icons.tour_rounded, color: CaboColors.brightGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tour guide eligibility', style: CaboText.h3),
                        Text(guide ? 'You are a certified driver-guide' : 'Not certified yet', style: CaboText.muted),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: CaboColors.muted),
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
                for (final (icon, label, earned) in badges)
                  Opacity(
                    opacity: earned ? 1 : 0.4,
                    child: CaboCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: earned ? CaboColors.yellow : CaboColors.surfaceHigh,
                            child: Icon(icon, color: earned ? CaboColors.onYellow : CaboColors.muted),
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
      },
    );
  }
}

class TourCertificationScreen extends StatelessWidget {
  const TourCertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guide = AppScope.of(context).driver?.flag('is_tour_guide') ?? false;
    const topics = [
      'Lagos history in 20 minutes',
      'Guiding a group safely',
      'Storytelling for visitors',
      'Lagos Island heritage sites',
      'Lekki and the coast',
      'Handling difficult situations',
    ];
    return CaboScaffold(
      title: 'Tour guide certification',
      bottom: guide
          ? CaboButton('See my tour jobs', onPressed: () => replace(context, '/jobs'))
          : CaboButton('Ask to be certified', onPressed: () => go(context, '/support-chat')),
      children: [
        CaboCard(
          borderColor: guide ? CaboColors.brightGreen : null,
          child: Row(
            children: [
              IconBadge(
                guide ? Icons.verified_rounded : Icons.tour_rounded,
                color: guide ? CaboColors.brightGreen : CaboColors.yellow,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(guide ? 'Certified' : 'Not certified yet', color: guide ? CaboColors.brightGreen : CaboColors.yellow),
                    const SizedBox(height: 8),
                    Text('Cabo driver-guide', style: CaboText.h3),
                    Text(
                      guide
                          ? 'Tours you are assigned to guide appear on your jobs board.'
                          : 'Certified hosts guide tours for partner operators. The Cabo team runs the course in person.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('What the course covers'),
        for (final title in topics)
          MenuTile(
            icon: guide ? Icons.check_rounded : Icons.menu_book_rounded,
            color: guide ? CaboColors.brightGreen : CaboColors.yellow,
            title: title,
          ),
      ],
    );
  }
}

class LearningCentreScreen extends StatelessWidget {
  const LearningCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trained = AppScope.of(context).driver?.flag('training_completed') ?? false;
    return CaboScaffold(
      title: 'Learning centre',
      children: [
        CaboCard(
          onTap: () => go(context, '/training'),
          child: Row(
            children: [
              IconBadge(Icons.school_rounded, color: trained ? CaboColors.brightGreen : CaboColors.yellow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Host training', style: CaboText.h3),
                    Text(trained ? 'Completed' : 'Not completed yet', style: CaboText.muted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CaboColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CaboCard(
          onTap: () => go(context, '/tour-certification'),
          child: Row(
            children: [
              const IconBadge(Icons.tour_rounded, color: CaboColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tour guide certification', style: CaboText.h3),
                    Text('Guide tours for extra income', style: CaboText.muted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CaboColors.muted),
            ],
          ),
        ),
        const SectionTitle('Training topics'),
        for (final (title, time, icon) in trainingLessons) MenuTile(icon: icon, title: title, subtitle: time),
        const SizedBox(height: 8),
        Text('Video lessons in the app are coming soon. Until then the Cabo team covers these in person.', style: CaboText.muted),
      ],
    );
  }
}
