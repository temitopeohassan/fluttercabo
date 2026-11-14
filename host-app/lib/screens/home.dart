import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 2. Home and going online.

/// Where surge areas sit on the drawn map, which has no real coordinates.
const _spots = [Offset(0.38, 0.7), Offset(0.78, 0.78), Offset(0.55, 0.28), Offset(0.18, 0.12), Offset(0.7, 0.45)];

/// Service areas where fares are raised right now, busiest first.
List<Json> surgeAreas(AppState state) {
  final areas = [
    for (final a in state.config.list('service_areas'))
      if (a.number('surge_multiplier', 1) > 1) a,
  ];
  areas.sort((a, b) => b.number('surge_multiplier').compareTo(a.number('surge_multiplier')));
  return areas;
}

String _surge(Json area) => '×${area.number('surge_multiplier').toStringAsFixed(1)}';

List<HeatZone> _heat(AppState state) => [
  for (final (i, a) in surgeAreas(state).take(_spots.length).indexed)
    HeatZone(
      _spots[i],
      0.3 - i * 0.03,
      ((a.number('surge_multiplier') - 1) * 1.2).clamp(0.25, 0.9),
      label: '${a.str('name')} ${_surge(a)}',
    ),
];

/// Tells the host why they cannot go online, with a way to fix it.
Future<void> showBlockers(BuildContext context, List<String> blockers) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You cannot go online yet', style: CaboText.h2),
            const SizedBox(height: 10),
            for (final b in blockers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: CaboColors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b, style: CaboText.body)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            CaboButton(
              'Check my application',
              onPressed: () {
                Navigator.of(sheet).pop();
                go(context, '/application-status');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.online, required this.unread});
  final bool online;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Row(
      children: [
        GestureDetector(onTap: () => replace(context, '/account'), child: Avatar(initials(state.fullName), size: 46)),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: online ? CaboColors.brightGreen : CaboColors.deepGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: online ? CaboColors.onYellow : CaboColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    online ? "You're online" : "You're offline",
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w700, color: online ? CaboColors.onYellow : Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          children: [
            RoundAction(Icons.notifications_rounded, color: CaboColors.deepGreen, size: 46, onTap: () => go(context, '/notifications')),
            if (unread) const Positioned(right: 4, top: 4, child: CircleAvatar(radius: 5, backgroundColor: CaboColors.yellow)),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, {this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: CaboText.h2),
            Text(label, style: CaboText.muted.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// The home map. Shows the offline panel or, once online, live ride requests.
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  AppState? _state;
  int? _today;
  bool _unread = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state != null) return;
    final state = _state = AppScope.read(context);
    state.watchRequests();
    _refresh();
  }

  @override
  void dispose() {
    _state?.unwatchRequests();
    super.dispose();
  }

  Future<void> _refresh() async {
    final state = _state!;
    try {
      final res = await Future.wait<dynamic>([
        state.api.get('/driver/earnings', query: {'period': 'today'}),
        state.api.get('/driver/notifications'),
        state.refreshDriver(),
        state.loadCurrentTrip(),
      ]);
      if (!mounted) return;
      setState(() {
        _today = (unwrap(res[0]) as Json).integer('earnings');
        _unread = (res[1] as Json).integer('unread') > 0;
      });
      if (state.isOnline) await state.loadRequests();
    } on ApiException catch (e) {
      if (mounted && !e.isUnauthorized) showMessage(context, e.message, error: true);
    }
  }

  Future<void> _goOnline() async {
    final state = _state!;
    try {
      await state.goOnline();
      await state.loadRequests();
    } on ApiException catch (e) {
      final blockers = [for (final b in (e.data?['blockers'] as List?) ?? const []) '$b'];
      if (blockers.isEmpty) rethrow;
      if (mounted) await showBlockers(context, blockers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final online = state.isOnline;
    final d = state.driver ?? const {};
    final hot = surgeAreas(state);
    final trip = state.onTrip ? state.trip : null;
    return MapLayout(
      map: CaboMap(heat: online ? _heat(state) : const [], markers: const [MapMarker(Offset(0.42, 0.6), MarkerKind.driver)]),
      top: _HomeTopBar(online: online, unread: _unread),
      bottomNav: const DriverNav(0),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trip != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CaboCard(
                borderColor: CaboColors.yellow,
                onTap: () => go(context, AppState.tripRoute(trip)!),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_taxi_rounded, color: CaboColors.yellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Trip in hand • ${humanize(trip.str('status'))}',
                        style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: CaboColors.muted),
                  ],
                ),
              ),
            ),
          if (!online) ...[
            if (hot.isNotEmpty)
              CaboCard(
                color: CaboColors.orange.withValues(alpha: 0.16),
                onTap: () => go(context, '/hotspots'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: CaboColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'High demand in ${hot.first.str('name')} • ${_surge(hot.first)}',
                        style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: CaboColors.muted),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniStat('Today', _today == null ? '—' : naira(_today!), onTap: () => replace(context, '/earnings')),
                _MiniStat('Acceptance', '${d.number('acceptance_rate').round()}%', onTap: () => go(context, '/performance')),
                _MiniStat('Rating', '${d.number('rating').toStringAsFixed(2)} ★', onTap: () => go(context, '/ratings')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                RoundAction(Icons.tune_rounded, size: 60, onTap: () => go(context, '/ride-preferences')),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    'GO ONLINE',
                    icon: Icons.power_settings_new_rounded,
                    height: 64,
                    busyLabel: 'Going online…',
                    onPressed: _goOnline,
                  ),
                ),
              ],
            ),
          ] else ...[
            if (state.requests.isEmpty)
              Row(
                children: [
                  const Pulse(animate: !kScreenshotMode, size: 64),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip == null ? 'Finding trips for you' : 'Finish your trip to get new requests', style: CaboText.h3),
                        Text('New requests within 8 km appear here.', style: CaboText.muted),
                      ],
                    ),
                  ),
                ],
              )
            else
              for (final r in state.requests.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CaboCard(
                    borderColor: CaboColors.yellow,
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      state.select(offer: r);
                      go(context, '/incoming-request');
                    },
                    child: Row(
                      children: [
                        const IconBadge(Icons.notifications_active_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.obj('ride_type')?.str('name') ?? 'Ride'} • ${naira(r.integer('driver_earnings'))}',
                                style: CaboText.h3,
                              ),
                              Text(
                                [
                                  if (r.numberOrNull('pickup_distance_km') != null)
                                    '${r.number('pickup_distance_km').toStringAsFixed(1)} km away',
                                  'to ${r.str('dropoff_address').split(',').first}',
                                ].join(' • '),
                                style: CaboText.muted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: CaboColors.muted),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CaboCard(
                    onTap: () => go(context, '/ride-preferences'),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: CaboColors.yellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Preferences', style: CaboText.label.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CaboCard(
                    onTap: () => go(context, '/hotspots'),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: CaboColors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(plural(hot.length, 'hotspot'), style: CaboText.label.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ActionButton(
              'Go offline',
              style: CaboButtonStyle.secondary,
              icon: Icons.power_settings_new_rounded,
              enabled: trip == null,
              onPressed: state.goOffline,
            ),
          ],
        ],
      ),
    );
  }
}

class HomeOfflineScreen extends StatelessWidget {
  const HomeOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) => const _Home();
}

class HomeOnlineScreen extends StatelessWidget {
  const HomeOnlineScreen({super.key});

  @override
  Widget build(BuildContext context) => const _Home();
}

class HotspotsScreen extends StatelessWidget {
  const HotspotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Scaffold(
      appBar: caboAppBar(context, 'Demand hotspots'),
      body: Loader<List<Json>>(
        load: () async {
          await state.loadConfig();
          return surgeAreas(state);
        },
        builder: (context, zones, _) => Column(
          children: [
            SizedBox(
              height: 300,
              child: CaboMap(heat: _heat(state), markers: const [MapMarker(Offset(0.42, 0.56), MarkerKind.driver)]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Text('Fares for new requests in these areas are multiplied as shown.', style: CaboText.muted),
                  const SizedBox(height: 12),
                  if (zones.isEmpty)
                    const EmptyNotice('No surge anywhere right now. Fares are at their normal rate.', icon: Icons.trending_flat_rounded),
                  for (final z in zones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CaboCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  CaboColors.yellow,
                                  CaboColors.red,
                                  ((z.number('surge_multiplier') - 1) * 1.2).clamp(0, 1),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_surge(z), style: CaboText.h3.copyWith(color: CaboColors.onYellow)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(z.str('name'), style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    'Within ${z.number('radius_km').toStringAsFixed(0)} km of the centre',
                                    style: CaboText.muted.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Navigate to ${z.str('name')}',
                              icon: const Icon(Icons.navigation_rounded, color: CaboColors.yellow),
                              onPressed: () => openNavigation(context, z.number('center_lat'), z.number('center_lng')),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RidePreferencesScreen extends StatefulWidget {
  const RidePreferencesScreen({super.key});

  @override
  State<RidePreferencesScreen> createState() => _RidePreferencesScreenState();
}

class _RidePreferencesScreenState extends State<RidePreferencesScreen> {
  late Set<String> _types;
  late Set<String> _jobs;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final state = AppScope.read(context);
    final prefs = state.preferences;
    final qualifies = state.vehicle?.strings('ride_types') ?? const <String>[];
    _types = (prefs['ride_types'] is List ? prefs.strings('ride_types') : qualifies).toSet();
    _jobs = (prefs['jobs'] is List ? prefs.strings('jobs') : const ['rides']).toSet();
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    await state.updateDriver({
      'preferences': {...state.preferences, 'ride_types': _types.toList(), 'jobs': _jobs.toList()},
    });
    if (!mounted) return;
    showMessage(context, 'Preferences saved.');
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final qualifies = state.vehicle?.strings('ride_types') ?? const <String>[];
    final guide = state.driver?.flag('is_tour_guide') ?? false;
    const icons = {
      'economy': Icons.directions_car_rounded,
      'comfort': Icons.airline_seat_recline_extra_rounded,
      'xl': Icons.airport_shuttle_rounded,
      'premium': Icons.workspace_premium_rounded,
    };
    void toggle(Set<String> set, String key, bool on) => on ? set.add(key) : set.remove(key);
    return CaboScaffold(
      title: 'Ride preferences',
      bottom: ActionButton('Save preferences', onPressed: _save),
      children: [
        const SectionTitle('Ride types'),
        for (final t in state.config.list('ride_types'))
          qualifies.contains(t.str('code'))
              ? ToggleTile(
                  t.str('name'),
                  subtitle: t.strOrNull('description'),
                  icon: icons[t.str('code')] ?? Icons.directions_car_rounded,
                  initial: _types.contains(t.str('code')),
                  onChanged: (v) => toggle(_types, t.str('code'), v),
                )
              : MenuTile(
                  icon: icons[t.str('code')] ?? Icons.directions_car_rounded,
                  title: t.str('name'),
                  subtitle: 'Your vehicle does not qualify',
                  color: CaboColors.muted,
                  trailing: const Pill('Locked', color: CaboColors.muted, icon: Icons.lock),
                ),
        if (qualifies.isEmpty) Text('Your vehicle has not been approved for any ride type yet.', style: CaboText.muted),
        const SectionTitle('Job types'),
        ToggleTile(
          'On-demand rides',
          icon: Icons.bolt_rounded,
          initial: _jobs.contains('rides'),
          onChanged: (v) => toggle(_jobs, 'rides', v),
        ),
        ToggleTile(
          'Airport shuttles',
          subtitle: 'See open airport jobs on the jobs board',
          icon: Icons.flight_takeoff_rounded,
          initial: _jobs.contains('shuttles'),
          onChanged: (v) => toggle(_jobs, 'shuttles', v),
        ),
        MenuTile(
          icon: Icons.tour_rounded,
          title: 'Tours',
          subtitle: guide ? 'You are a certified driver-guide' : 'Get certified as a driver-guide first',
          trailing: guide
              ? const Pill('Certified', color: CaboColors.brightGreen, icon: Icons.check)
              : const Pill('Locked', color: CaboColors.muted, icon: Icons.lock),
          onTap: () => go(context, '/tour-certification'),
        ),
      ],
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, String?) _look(String type) => switch (type) {
    'trip' => (Icons.local_taxi_rounded, CaboColors.brightGreen, '/trip-history'),
    'shuttle' || 'job' => (Icons.event_available_rounded, CaboColors.brightGreen, '/jobs'),
    'tour' => (Icons.tour_rounded, CaboColors.blue, '/jobs'),
    'payout' || 'earnings' => (Icons.payments_rounded, CaboColors.yellow, '/payouts'),
    'document' => (Icons.warning_amber_rounded, CaboColors.orange, '/documents'),
    'support' => (Icons.support_agent_rounded, CaboColors.blue, '/support-tickets'),
    _ => (Icons.notifications_rounded, CaboColors.muted, null),
  };

  @override
  Widget build(BuildContext context) {
    final api = AppScope.read(context).api;
    return Loader<Json>(
      load: () async => await api.get('/driver/notifications') as Json,
      builder: (context, data, reload) {
        final items = data.list('data');
        return CaboScaffold(
          title: 'Notifications',
          actions: [
            if (data.integer('unread') > 0)
              TextButton(
                onPressed: () => runAction(context, () async {
                  await api.post('/driver/notifications/read-all');
                  await reload();
                }),
                child: Text('Mark all read', style: CaboText.label.copyWith(color: CaboColors.yellow)),
              ),
          ],
          children: [
            if (items.isEmpty) const EmptyNotice('No notifications yet.', icon: Icons.notifications_none_rounded),
            for (final n in items)
              Builder(
                builder: (context) {
                  final (icon, color, route) = _look(n.str('type'));
                  final unread = n['read_at'] == null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CaboCard(
                      color: unread ? CaboColors.surfaceHigh : CaboColors.surface,
                      onTap: () async {
                        if (unread) await runAction(context, () => api.post('/driver/notifications/${n.integer('id')}/read'));
                        if (!context.mounted) return;
                        if (route != null) {
                          go(context, route);
                        } else {
                          await reload();
                        }
                      },
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBadge(icon, color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.str('title'), style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                                Text(n.str('body'), style: CaboText.muted),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(timeAgo(n.date('created_at')), style: CaboText.label.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
