import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 5. Earnings and payouts.

const _periods = ['today', 'week', 'month'];
const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

Future<Json> _earnings(AppState state, String period) async =>
    unwrap(await state.api.get('/driver/earnings', query: {'period': period})) as Json;

String _short(String address) => address.split(',').first;

/// Bank shown as "GTBank ••6789".
String bankLabel(Json? driver) {
  final number = driver?.strOrNull('bank_account_number');
  if (number == null) return 'No bank account added';
  return '${driver!.str('bank_name')} ••${number.substring(number.length > 4 ? number.length - 4 : 0)}';
}

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return CaboScaffold(
      title: 'Earnings',
      showBack: false,
      bottomNav: const DriverNav(2),
      children: [
        ChipPicker(
          options: const ['Today', 'This week', 'This month'],
          initial: {_period},
          single: true,
          onChanged: (s) => setState(() => _period = s.first),
        ),
        const SizedBox(height: 18),
        Loader<Json>(
          key: ValueKey(_period),
          load: () => _earnings(state, _periods[_period]),
          builder: (context, e, _) {
            final days = e.list('by_day');
            final owed = e.integer('cash_commission_owed');
            final split = [
              ('Trip earnings', e.integer('earnings'), CaboColors.brightGreen),
              ('Tips', e.integer('tips'), CaboColors.orange),
            ];
            final total = e.integer('earnings') + e.integer('tips');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Since ${fmtDay(e.date('from'))}', style: CaboText.muted),
                Text(naira(total), style: CaboText.display.copyWith(color: CaboColors.brightGreen)),
                Text('${plural(e.integer('trips'), 'trip')} • ${fmtDuration(e.integer('online_minutes'))} on trips', style: CaboText.muted),
                const SizedBox(height: 16),
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        for (final (_, v, c) in split)
                          if (v > 0)
                            Expanded(
                              flex: v,
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
                        Text(naira(v), style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                InfoRow('Fares paid by riders', naira(e.integer('fares'))),
                InfoRow('Cabo commission', '− ${naira(e.integer('commission'))}'),
                const SizedBox(height: 10),
                if (days.isNotEmpty)
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
                        BarChart(
                          values: [for (final d in days) d.number('earnings')],
                          labels: [for (final d in days) '${d.date('date')?.day ?? ''}'],
                          highlight: _best(days),
                          height: 110,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                MenuTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Payouts',
                  subtitle: 'Balance ${naira(e.integer('balance'))} • next payout ${fmtDay(e.date('next_weekly_payout'))}',
                  onTap: () => go(context, '/payouts'),
                ),
                MenuTile(
                  icon: Icons.money_rounded,
                  title: 'Cash balance',
                  subtitle: owed > 0 ? 'You owe Cabo ${naira(owed)} in commission' : 'Nothing owed on cash trips',
                  color: CaboColors.orange,
                  onTap: () => go(context, '/cash-balance'),
                ),
                MenuTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Trip history',
                  subtitle: 'All your rides',
                  color: CaboColors.blue,
                  onTap: () => go(context, '/trip-history'),
                ),
                MenuTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'Incentives and bonuses',
                  subtitle: 'Coming soon',
                  color: CaboColors.brightGreen,
                  onTap: () => go(context, '/incentives'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

int _best(List<Json> days) {
  var best = 0;
  for (var i = 1; i < days.length; i++) {
    if (days[i].number('earnings') > days[best].number('earnings')) best = i;
  }
  return best;
}

class EarningsChartScreen extends StatelessWidget {
  const EarningsChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _earnings(state, 'week'),
      builder: (context, e, _) {
        final from = e.date('from') ?? DateTime.now();
        // One bar for each day of the week, including days with no trips.
        final byDate = {for (final d in e.list('by_day')) d.str('date').substring(0, 10): d};
        final week = [
          for (var i = 0; i < 7; i++)
            byDate[from.add(Duration(days: i)).toIso8601String().substring(0, 10)] ?? <String, dynamic>{'earnings': 0, 'trips': 0},
        ];
        final total = e.integer('earnings');
        final best = _best(week);
        final hours = e.integer('online_minutes') / 60;
        const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return CaboScaffold(
          title: 'This week',
          children: [
            Center(child: Text('Week from ${fmtDate(from)}', style: CaboText.h3)),
            const SizedBox(height: 20),
            CaboCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(naira(total), style: CaboText.h1.copyWith(color: CaboColors.brightGreen)),
                  Text(
                    total == 0
                        ? 'No completed trips yet this week.'
                        : '${names[(from.weekday - 1 + best) % 7]} was your best day: ${naira(week[best].number('earnings'))}',
                    style: CaboText.muted,
                  ),
                  const SizedBox(height: 20),
                  BarChart(
                    values: [for (final d in week) d.number('earnings')],
                    labels: [for (var i = 0; i < 7; i++) _weekdays[(from.weekday - 1 + i) % 7]],
                    highlight: best,
                    height: 200,
                    valueLabel: naira,
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
                StatTile('On trips', fmtDuration(e.integer('online_minutes')), icon: Icons.schedule_rounded),
                StatTile('Per hour', hours > 0 ? naira(total / hours) : '—', icon: Icons.speed_rounded),
                StatTile('Trips', '${e.integer('trips')}', icon: Icons.route_rounded),
              ],
            ),
            const SectionTitle('Daily breakdown'),
            for (var i = 0; i < 7; i++)
              InfoRow(
                names[(from.weekday - 1 + i) % 7],
                '${naira(week[i].number('earnings'))} • ${plural(week[i].integer('trips'), 'trip')}',
              ),
          ],
        );
      },
    );
  }
}

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  static const _filters = [('All', null), ('Completed', 'completed'), ('Cancelled', 'cancelled')];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final status = _filters[_filter].$2;
    return CaboScaffold(
      title: 'Trip history',
      children: [
        ChipPicker(
          options: [for (final f in _filters) f.$1],
          initial: {_filter},
          single: true,
          onChanged: (s) => setState(() => _filter = s.first),
        ),
        const SizedBox(height: 16),
        Loader<List<Json>>(
          key: ValueKey(status),
          load: () async => (await state.api.get('/driver/trips', query: {'status': ?status}) as Json).list('data'),
          builder: (context, trips, _) => Column(
            children: [
              if (trips.isEmpty) const EmptyNotice('No trips here yet.', icon: Icons.receipt_long_rounded),
              for (final t in trips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CaboCard(
                    onTap: () {
                      state.select(pastTrip: t);
                      go(context, '/trip-earnings-detail');
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconBadge(
                          Icons.directions_car_rounded,
                          color: t.str('status') == 'completed' ? CaboColors.brightGreen : CaboColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_short(t.str('pickup_address'))} → ${_short(t.str('dropoff_address'))}',
                                style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                [
                                  fmtDayTime(t.date('completed_at') ?? t.date('created_at')),
                                  paymentLabels[t.str('payment_method')] ?? '',
                                  if (t.str('status') != 'completed') humanize(t.str('status')),
                                ].join(' • '),
                                style: CaboText.muted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(naira(t.integer('driver_earnings') + t.integer('tip')), style: CaboText.h3),
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

class TripEarningsDetailScreen extends StatelessWidget {
  const TripEarningsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () async {
        if (state.pastTrip != null) return state.pastTrip;
        final trips = (await state.api.get('/driver/trips') as Json).list('data');
        return trips.firstOrNull;
      },
      builder: (context, t, _) {
        if (t == null) {
          return CaboScaffold(
            title: 'Trip earnings',
            children: const [EmptyNotice('You have not taken a trip yet.', icon: Icons.receipt_long_rounded)],
          );
        }
        return CaboScaffold(
          title: 'Trip earnings',
          bottom: CaboButton(
            'Report a fare problem',
            style: CaboButtonStyle.secondary,
            onPressed: () {
              state.select(pastTrip: t);
              go(context, '/report-incident');
            },
          ),
          children: [
            const SizedBox(
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: CaboMap(
                  route: Routes.trip,
                  labels: false,
                  markers: [MapMarker(Offset(0.56, 0.36), MarkerKind.pickup), MapMarker(Offset(0.8, 0.82), MarkerKind.dropoff)],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('${_short(t.str('pickup_address'))} → ${_short(t.str('dropoff_address'))}', style: CaboText.h2),
            Text(
              [
                fmtDayTime(t.date('completed_at') ?? t.date('created_at')),
                '${t.number('distance_km').toStringAsFixed(1)} km',
                ?t.obj('ride_type')?.strOrNull('name'),
                humanize(t.str('status')),
              ].join(' • '),
              style: CaboText.muted,
            ),
            const SizedBox(height: 16),
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Fare paid by rider', naira(t.integer('fare_total'))),
                  if (t.integer('fare_stops') > 0) InfoRow('Of which added stops', naira(t.integer('fare_stops'))),
                  if (t.integer('tolls') > 0) InfoRow('Of which tolls', naira(t.integer('tolls'))),
                  InfoRow('Cabo commission', '− ${naira(t.integer('commission'))}', valueColor: CaboColors.red),
                  if (t.integer('tip') > 0) InfoRow('Tip', '+ ${naira(t.integer('tip'))}', valueColor: CaboColors.brightGreen),
                  const Divider(height: 20),
                  InfoRow(
                    'Net earnings',
                    naira(t.integer('driver_earnings') + t.integer('tip')),
                    bold: true,
                    valueColor: CaboColors.brightGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Rider', t.obj('rider')?.str('first_name') ?? '—'),
                  InfoRow('Payment', paymentLabels[t.str('payment_method')] ?? humanize(t.str('payment_method'))),
                  InfoRow('Trip ID', t.str('reference')),
                  if (t.strOrNull('cancellation_reason') != null) InfoRow('Cancelled', humanize(t.str('cancellation_reason'))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  Future<void> _cashOut(BuildContext context, int available, int minimum, Future<void> Function() reload) async {
    final state = AppScope.read(context);
    final amount = TextEditingController(text: '$available');
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cash out now'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can cash out between ${naira(minimum)} and ${naira(available)}.'),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(prefixText: '₦ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(int.tryParse(amount.text.replaceAll(',', '').trim())),
            child: const Text('Cash out'),
          ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;
    final ok = await runAction(context, () async {
      final res = await state.api.post('/driver/payouts/instant', {'amount': chosen}) as Json;
      await state.refreshDriver();
      if (context.mounted)
        showMessage(context, '${naira(res.obj('data')?.integer('amount') ?? chosen)} is on its way to ${bankLabel(state.driver)}.');
    });
    if (ok) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<(Json, List<Json>)>(
      load: () async {
        final res = await Future.wait<dynamic>([_earnings(state, 'week'), state.api.get('/driver/payouts'), state.refreshDriver()]);
        return (res[0] as Json, (res[1] as Json).list('data'));
      },
      builder: (context, data, reload) {
        final (e, payouts) = data;
        final drivers = state.config.obj('drivers');
        final feePercent = drivers?.number('instant_cashout_fee_percent', 1.5) ?? 1.5;
        final minimum = drivers?.integer('minimum_cashout', 5000) ?? 5000;
        final balance = e.integer('balance');
        final owed = e.integer('cash_commission_owed');
        final available = (balance - owed).clamp(0, balance);
        final hasBank = state.driver?.strOrNull('bank_account_number') != null;
        return CaboScaffold(
          title: 'Payouts',
          children: [
            CaboCard(
              color: CaboColors.surfaceHigh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available balance', style: CaboText.muted),
                  Text(naira(available), style: CaboText.display.copyWith(color: CaboColors.brightGreen)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (owed > 0) '${naira(owed)} cash commission is settled first.',
                      'Next automatic payout: ${fmtDay(e.date('next_weekly_payout'))} to ${bankLabel(state.driver)}.',
                    ].join(' '),
                    style: CaboText.muted,
                  ),
                  const SizedBox(height: 16),
                  if (!hasBank)
                    CaboButton('Add bank details', icon: Icons.account_balance_rounded, onPressed: () => go(context, '/bank-details'))
                  else
                    CaboButton(
                      'Cash out now',
                      icon: Icons.bolt_rounded,
                      onPressed: available < minimum ? null : () => _cashOut(context, available, minimum, reload),
                    ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      available < minimum
                          ? 'Instant cash-out starts at ${naira(minimum)}.'
                          : 'Instant cash-out fee: ${feePercent.toStringAsFixed(1)}% (${naira((available * feePercent / 100).ceil())} on the full balance)',
                      style: CaboText.muted.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Payout history'),
            if (payouts.isEmpty) const EmptyNotice('No payouts yet.', icon: Icons.account_balance_rounded),
            for (final p in payouts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: MenuTile(
                  icon: p.str('type') == 'instant' ? Icons.bolt_rounded : Icons.account_balance_rounded,
                  title: naira(p.integer('amount')),
                  subtitle: [
                    fmtDay(p.date('created_at')),
                    p.str('bank_name'),
                    if (p.integer('fee') > 0) 'fee ${naira(p.integer('fee'))}',
                  ].join(' • '),
                  color: p.str('type') == 'instant' ? CaboColors.yellow : CaboColors.brightGreen,
                  trailing: Pill(
                    humanize(p.str('status')),
                    color: switch (p.str('status')) {
                      'paid' => CaboColors.brightGreen,
                      'failed' => CaboColors.red,
                      _ => CaboColors.yellow,
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CashBalanceScreen extends StatelessWidget {
  const CashBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<(Json, List<Json>)>(
      load: () async {
        final res = await Future.wait<dynamic>([
          _earnings(state, 'week'),
          state.api.get('/driver/trips', query: {'status': 'completed'}),
        ]);
        return (
          res[0] as Json,
          [
            for (final t in (res[1] as Json).list('data'))
              if (t.str('payment_method') == 'cash') t,
          ],
        );
      },
      builder: (context, data, _) {
        final (e, cashTrips) = data;
        final owed = e.integer('cash_commission_owed');
        final limit = e.integer('cash_debt_limit', 20000);
        return CaboScaffold(
          title: 'Cash balance',
          bottom: CaboButton('Go to payouts', style: CaboButtonStyle.secondary, onPressed: () => go(context, '/payouts')),
          children: [
            CaboCard(
              color: CaboColors.orange.withValues(alpha: 0.14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You owe Cabo', style: CaboText.muted),
                  Text(naira(owed), style: CaboText.display.copyWith(color: CaboColors.orange)),
                  const SizedBox(height: 6),
                  Text(
                    'Commission on cash trips. It is taken from your earnings balance at your next payout or cash-out.',
                    style: CaboText.muted,
                  ),
                  const SizedBox(height: 12),
                  Bar(limit == 0 ? 0 : (owed / limit).clamp(0, 1).toDouble(), color: CaboColors.orange),
                  const SizedBox(height: 6),
                  Text('Limit ${naira(limit)}. Above this you cannot go online until it is settled.', style: CaboText.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: StatTile('Earnings balance', naira(e.integer('balance')), icon: Icons.payments_rounded)),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile('Commission owed', naira(owed), icon: Icons.percent_rounded, color: CaboColors.orange),
                ),
              ],
            ),
            const SectionTitle('Recent cash trips'),
            if (cashTrips.isEmpty) Text('No cash trips yet.', style: CaboText.muted),
            for (final t in cashTrips.take(10))
              InfoRow(
                '${_short(t.str('pickup_address'))} → ${_short(t.str('dropoff_address'))}',
                '${naira(t.integer('fare_total'))} • fee ${naira(t.integer('commission'))}',
              ),
          ],
        );
      },
    );
  }
}

class IncentivesScreen extends StatelessWidget {
  const IncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.emoji_events_rounded,
      color: CaboColors.brightGreen,
      title: 'Incentives are coming soon',
      message:
          'Weekly quests and bonuses will appear here when Cabo launches them. '
          'For now, surge areas on the hotspots map are the way to earn more per trip.',
      primary: 'See demand hotspots',
      onPrimary: () => replace(context, '/hotspots'),
      secondary: 'Back',
      onSecondary: () => back(context),
    );
  }
}
