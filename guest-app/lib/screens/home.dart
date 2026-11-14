import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 2. Home and discovery.

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.label, this.icon, this.bg, this.fg, this.route);
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String route;

  @override
  Widget build(BuildContext context) {
    return CaboCard(
      color: bg,
      radius: 18,
      onTap: () => go(context, route),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, size: 32, color: fg),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: CaboText.h3.copyWith(fontSize: 15, color: CaboColors.ink),
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  _HomeData(this.unread, this.upcoming, this.attractions);
  final int unread;

  /// (icon, colour, title, subtitle, action)
  final List<(IconData, Color, String, String, VoidCallback)> upcoming;
  final List<Json> attractions;
}

String _greeting() {
  final h = DateTime.now().hour;
  return h < 12
      ? 'Good morning'
      : h < 17
      ? 'Good afternoon'
      : 'Good evening';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<_HomeData> _load(BuildContext context) async {
    final state = AppScope.read(context);
    final api = state.api;
    final results = await Future.wait([
      api.get('/rider/notifications'),
      api.get('/rider/trips'),
      api.get('/rider/shuttles'),
      api.get('/rider/tour-bookings', query: {'status': 'upcoming'}),
      api.get('/attractions'),
    ]);
    final upcoming =
        <(DateTime, (IconData, Color, String, String, VoidCallback))>[];
    void open(String route, VoidCallback select) {
      select();
      state.navigatorKey.currentState?.pushNamed(route);
    }

    for (final t in (results[1] as Json).list('data')) {
      final status = t.str('status');
      if (AppState.activeStatuses.contains(status)) {
        upcoming.add((
          DateTime.now(),
          (
            Icons.local_taxi_rounded,
            CaboColors.green,
            status == 'requested'
                ? 'Finding your driver'
                : 'Ride ${humanize(status).toLowerCase()}',
            '${t.str('pickup_address')} → ${t.str('dropoff_address')}',
            () => open(AppState.tripRoute(t)!, () => state.trip = t),
          ),
        ));
      } else if (status == 'scheduled') {
        final at = t.date('scheduled_at') ?? DateTime.now();
        upcoming.add((
          at,
          (
            Icons.schedule_rounded,
            CaboColors.blue,
            'Scheduled ride • ${fmtDayTime(at)}',
            '${t.str('pickup_address')} → ${t.str('dropoff_address')}',
            () => open('/past-trip', () => state.select(pastTrip: t)),
          ),
        ));
      }
    }
    for (final s in (results[2] as Json).list('data')) {
      final at = s.date('pickup_at');
      if (at == null ||
          at.isBefore(DateTime.now()) ||
          !{'confirmed', 'driver_assigned'}.contains(s.str('status')))
        continue;
      final pickup = s.str('direction') == 'airport_pickup';
      upcoming.add((
        at,
        (
          Icons.flight_land_rounded,
          CaboColors.orange,
          'Airport ${pickup ? 'pickup' : 'drop-off'} • ${fmtDayTime(at)}',
          '${s.str('flight_number')} • ${s.str('status') == 'driver_assigned' ? 'Driver assigned' : 'Confirmed'}',
          () => open('/shuttle-assigned', () => state.select(shuttle: s)),
        ),
      ));
    }
    for (final b in (results[3] as Json).list('data')) {
      final at = b.obj('slot')?.date('starts_at');
      if (at == null) continue;
      upcoming.add((
        at,
        (
          Icons.tour_rounded,
          const Color(0xFFE0A800),
          '${b.obj('tour')?.str('title')} • ${fmtDayTime(at)}',
          '${plural(b.integer('guests'), 'guest')} • Show your QR ticket at check-in',
          () => open('/ticket', () => state.select(tourBooking: b)),
        ),
      ));
    }
    upcoming.sort((a, b) => a.$1.compareTo(b.$1));
    return _HomeData((results[0] as Json).integer('unread'), [
      for (final u in upcoming.take(4)) u.$2,
    ], asJsonList(unwrap(results[4])));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Loader<_HomeData>(
          load: () => _load(context),
          builder: (context, data, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    const CaboLogo(size: 36),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          tooltip: data.unread > 0
                              ? 'Notifications, ${data.unread} unread'
                              : 'Notifications',
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 28,
                            color: CaboColors.green,
                          ),
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed('/notifications')
                                  .then((_) => reload()),
                        ),
                        if (data.unread > 0)
                          const Positioned(
                            right: 10,
                            top: 10,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: CaboColors.yellow,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('${_greeting()}, ${state.firstName}!', style: CaboText.h1),
                Text(
                  'Where would you like to go today?',
                  style: CaboText.muted.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 16),
                SearchBox(
                  hint: 'Search destinations, rides or places',
                  onTap: () => go(context, '/search'),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        'Ride\nHailing',
                        Icons.local_taxi_rounded,
                        CaboColors.greenSoft,
                        CaboColors.green,
                        '/where-to',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        'Tours &\nExperiences',
                        Icons.tour_rounded,
                        CaboColors.yellowSoft,
                        Color(0xFFE0A800),
                        '/tours',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        'Explore',
                        Icons.explore_rounded,
                        Color(0xFFE6F0FB),
                        CaboColors.blue,
                        '/explore',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        'Airport\nShuttle',
                        Icons.flight_land_rounded,
                        Color(0xFFFDEDE1),
                        CaboColors.orange,
                        '/shuttle',
                      ),
                    ),
                  ],
                ),
                if (data.upcoming.isNotEmpty) ...[
                  const SectionTitle('Upcoming'),
                  for (final (icon, color, title, subtitle, onTap)
                      in data.upcoming)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CaboCard(
                        onTap: onTap,
                        child: Row(
                          children: [
                            IconBadge(icon, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CaboText.h3.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CaboText.muted.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: CaboColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                SectionTitle(
                  'Popular Destinations',
                  action: 'See all',
                  onAction: () => go(context, '/explore'),
                ),
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.attractions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => DestinationCard(
                      data.attractions[i],
                      width: 112,
                      onTap: () {
                        state.select(attraction: data.attractions[i]);
                        go(context, '/attraction');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CaboCard(
                  color: CaboColors.greenSoft,
                  onTap: () => go(context, '/mobility'),
                  child: Row(
                    children: [
                      const IconBadge(Icons.accessible_forward_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accessible rides & tours',
                              style: CaboText.h3,
                            ),
                            Text(
                              'Vehicles and guides for every traveller',
                              style: CaboText.muted,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: CaboColors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const RiderNav(0),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _search = 0;
  bool _loading = false;
  String? _error;
  List<Json> _places = [], _tours = [], _attractions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<void> _run() async {
    final q = _query.text.trim();
    final run = ++_search;
    if (q.length < 2) {
      setState(() => _places = _tours = _attractions = []);
      return;
    }
    setState(() => _loading = true);
    final api = AppScope.read(context).api;
    try {
      final results = await Future.wait([
        Future<dynamic>.value(
          null,
        ), // rides only go to attractions, listed below
        api.get('/tours', query: {'q': q}),
        api.get('/attractions', query: {'q': q}),
      ]);
      if (!mounted || run != _search) return;
      setState(() {
        _places = const [];
        _tours = (results[1] as Json).list('data');
        _attractions = asJsonList(unwrap(results[2]));
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || run != _search) return;
      setState(() {
        _error = errorText(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final empty = _places.isEmpty && _tours.isEmpty && _attractions.isEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => back(context),
            ),
            Expanded(
              child: TextField(
                controller: _query,
                autofocus: !kScreenshotMode,
                onChanged: _changed,
                textInputAction: TextInputAction.search,
                style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search places, tours and attractions',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: CaboColors.muted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null) ErrorNotice(_error!, onRetry: _run),
          if (_error == null && empty && !_loading)
            EmptyNotice(
              _query.text.trim().length < 2
                  ? 'Search for a tour or an attraction to ride to.'
                  : 'Nothing matches "${_query.text.trim()}".',
              icon: Icons.search_rounded,
            ),
          if (_places.isNotEmpty) ...[
            const SectionTitle('Places'),
            for (final p in _places)
              MenuTile(
                icon: p.str('kind') == 'airport'
                    ? Icons.flight_rounded
                    : Icons.place_rounded,
                title: p.str('name'),
                subtitle: p.str('address'),
                onTap: () {
                  state.setDropoff(p);
                  go(context, '/where-to');
                },
              ),
          ],
          if (_tours.isNotEmpty) ...[
            const SectionTitle('Tours'),
            for (final t in _tours)
              MenuTile(
                icon: Icons.tour_rounded,
                title: t.str('title'),
                subtitle:
                    '${fmtDuration(t.integer('duration_minutes'))} • ${naira(t.integer('price'))}',
                onTap: () {
                  state.select(tour: t);
                  go(context, '/tour-detail');
                },
              ),
          ],
          if (_attractions.isNotEmpty) ...[
            const SectionTitle('Attractions'),
            for (final a in _attractions)
              MenuTile(
                icon: Icons.park_rounded,
                title: a.str('name'),
                subtitle: [
                  a.str('category'),
                  if (a.numberOrNull('rating') != null)
                    '★ ${a.number('rating').toStringAsFixed(1)}',
                ].join(' • '),
                onTap: () {
                  state.select(attraction: a);
                  go(context, '/attraction');
                },
              ),
          ],
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, String?) _look(String type) => switch (type) {
    'trip' => (Icons.local_taxi_rounded, CaboColors.green, '/bookings'),
    'shuttle' => (Icons.flight_land_rounded, CaboColors.orange, '/bookings'),
    'tour' => (Icons.qr_code_2_rounded, CaboColors.blue, '/bookings'),
    'promo' => (Icons.local_offer_rounded, CaboColors.orange, '/promos'),
    'support' => (
      Icons.support_agent_rounded,
      CaboColors.blue,
      '/support-tickets',
    ),
    _ => (Icons.notifications_rounded, CaboColors.muted, null),
  };

  @override
  Widget build(BuildContext context) {
    final api = AppScope.read(context).api;
    return Loader<Json>(
      load: () async => await api.get('/rider/notifications') as Json,
      builder: (context, data, reload) {
        final items = data.list('data');
        return CaboScaffold(
          title: 'Notifications',
          actions: [
            if (data.integer('unread') > 0)
              TextButton(
                onPressed: () => runAction(context, () async {
                  await api.post('/rider/notifications/read-all');
                  await reload();
                }),
                child: Text(
                  'Mark all read',
                  style: CaboText.label.copyWith(color: CaboColors.green),
                ),
              ),
          ],
          children: [
            if (items.isEmpty)
              const EmptyNotice(
                'No notifications yet.',
                icon: Icons.notifications_none_rounded,
              ),
            for (final n in items)
              Builder(
                builder: (context) {
                  final (icon, color, route) = _look(n.str('type'));
                  final unread = n['read_at'] == null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CaboCard(
                      color: unread ? CaboColors.greenSoft : Colors.white,
                      onTap: () async {
                        if (unread) {
                          await runAction(
                            context,
                            () => api.post(
                              '/rider/notifications/${n.integer('id')}/read',
                            ),
                          );
                        }
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
                                Text(
                                  n.str('title'),
                                  style: CaboText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(n.str('body'), style: CaboText.muted),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo(n.date('created_at')),
                            style: CaboText.label.copyWith(fontSize: 11),
                          ),
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

class MobilityScreen extends StatelessWidget {
  const MobilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Mobility Inclusive',
      bottom: CaboButton(
        'Book a ride',
        onPressed: () => go(context, '/where-to'),
      ),
      children: [
        const Scene(SceneKind.van, height: 190),
        const SizedBox(height: 18),
        Text('Accessible Rides & Tours', style: CaboText.h2),
        const SizedBox(height: 6),
        Text(
          'We are committed to making travel inclusive for everyone. Our fleet and tour '
          'experiences accommodate individuals with mobility and visual impairments.',
          style: CaboText.body,
        ),
        const SizedBox(height: 14),
        const CheckRow('Standard, Comfort, SUV and Premium vehicles'),
        const CheckRow('Drivers told about your needs before they arrive'),
        const CheckRow('Tours marked when they are wheelchair accessible'),
        const SizedBox(height: 10),
        CaboCard(
          color: CaboColors.surface,
          onTap: () => go(context, '/accessibility'),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: CaboColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set your needs once in Profile → Accessibility and we will match you every time.',
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
