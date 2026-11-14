import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 6. Cabo Explore.

SceneKind _scene(Json a) => sceneFor('${a.str('category')} ${a.str('name')}');

/// Starts a ride to an attraction or tour meeting point.
void rideTo(
  BuildContext context, {
  required String name,
  required String address,
  required double lat,
  required double lng,
}) {
  AppScope.read(context)
      .setDropoff({'name': name, 'address': address, 'lat': lat, 'lng': lng});
  go(context, '/where-to');
}

void _rideToAttraction(BuildContext context, Json a) => rideTo(
  context,
  name: a.str('name'),
  address: a.strOrNull('address') == null
      ? a.str('name')
      : '${a.str('name')}, ${a.str('address')}',
  lat: a.number('lat'),
  lng: a.number('lng'),
);

void _openAttraction(BuildContext context, Json a) {
  AppScope.read(context).select(attraction: a);
  go(context, '/attraction');
}

Future<List<Json>> _attractions(AppState state) async {
  state.loadWishlist().catchError((_) {});
  return asJsonList(unwrap(await state.api.get('/attractions')));
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () => _attractions(state),
      builder: (context, all, _) {
        final categories = {for (final a in all) a.str('category')}.toList()
          ..sort();
        final shown = all
            .where((a) => _category == null || a.str('category') == _category)
            .toList();
        return CaboScaffold(
          title: 'Explore Lagos',
          actions: [
            IconButton(
              tooltip: 'Wishlist',
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: CaboColors.red,
              ),
              onPressed: () => go(context, '/wishlist'),
            ),
            IconButton(
              tooltip: 'Map',
              icon: const Icon(Icons.map_rounded, color: CaboColors.green),
              onPressed: () => go(context, '/explore-map'),
            ),
          ],
          children: [
            ChipPicker(
              options: ['All', ...categories],
              initial: const {0},
              single: true,
              onChanged: (s) => setState(
                () => _category = s.first == 0 ? null : categories[s.first - 1],
              ),
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              const EmptyNotice(
                'No attractions here yet.',
                icon: Icons.explore_rounded,
              ),
            for (final a in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => _openAttraction(context, a),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NetPhoto(
                        state.imageUrl(a),
                        fallback: _scene(a),
                        height: 150,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.str('name'), style: CaboText.h3),
                                Text(
                                  [
                                    a.str('category'),
                                    a.str('area'),
                                    ?a.strOrNull('opening_hours'),
                                  ].join(' • '),
                                  style: CaboText.muted,
                                ),
                              ],
                            ),
                          ),
                          if (a.numberOrNull('rating') != null) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: CaboColors.yellow,
                              size: 18,
                            ),
                            Text(
                              a.number('rating').toStringAsFixed(1),
                              style: CaboText.label.copyWith(
                                color: CaboColors.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
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

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  // The drawn map has no real coordinates, so pins sit at fixed spots.
  static const _spots = [
    Offset(0.82, 0.78),
    Offset(0.62, 0.66),
    Offset(0.3, 0.88),
    Offset(0.2, 0.36),
    Offset(0.5, 0.5),
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () => _attractions(state),
      builder: (context, all, _) {
        final shown = all.take(_spots.length).toList();
        if (shown.isEmpty) {
          return Scaffold(
            appBar: caboAppBar(context, 'Explore map'),
            body: const EmptyNotice(
              'No attractions here yet.',
              icon: Icons.explore_rounded,
            ),
          );
        }
        final a = shown[_selected.clamp(0, shown.length - 1)];
        return MapLayout(
          map: CaboMap(
            markers: [
              for (final (i, p) in shown.indexed)
                MapMarker(
                  _spots[i],
                  i == _selected ? MarkerKind.dropoff : MarkerKind.pickup,
                  label: p.str('name'),
                ),
            ],
          ),
          top: Row(
            children: [
              RoundAction(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 44,
                onTap: () => back(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchBox(
                  hint: 'Search attractions',
                  onTap: () => go(context, '/search'),
                ),
              ),
            ],
          ),
          panel: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ChoiceChip(
                    label: Text(shown[i].str('name')),
                    selected: i == _selected,
                    onSelected: (_) => setState(() => _selected = i),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: NetPhoto(
                      state.imageUrl(a),
                      fallback: _scene(a),
                      height: 84,
                      radius: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _openAttraction(context, a),
                          child: Text(a.str('name'), style: CaboText.h3),
                        ),
                        Text(
                          [
                            a.str('category'),
                            a.str('area'),
                            ?a.strOrNull('opening_hours'),
                          ].join(' • '),
                          style: CaboText.muted,
                        ),
                        const SizedBox(height: 8),
                        CaboButton(
                          'Ride there',
                          height: 40,
                          expand: false,
                          onPressed: () => _rideToAttraction(context, a),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class AttractionScreen extends StatelessWidget {
  const AttractionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Loader<Json>(
      load: () async {
        final chosen = state.attraction;
        state.loadWishlist().catchError((_) {});
        if (chosen != null)
          return unwrap(
            await state.api.get('/attractions/${chosen.str('slug')}'),
          ) as Json;
        final all = await _attractions(state);
        if (all.isEmpty)
          throw ApiException('No attractions are available yet.');
        return all.first;
      },
      builder: (context, a, _) {
        final saved = state.isSaved('attraction', a.integer('id'));
        final fee = a.integer('entry_fee');
        return Scaffold(
          appBar: caboAppBar(
            context,
            a.str('name'),
            actions: [
              IconButton(
                tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
                icon: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: CaboColors.red,
                ),
                onPressed: () => runAction(
                  context,
                  () => state.toggleSaved('attraction', a.integer('id')),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              NetPhoto(state.imageUrl(a), fallback: _scene(a), height: 200),
              const SizedBox(height: 14),
              Text(a.str('name'), style: CaboText.h1),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: CaboColors.yellow,
                    size: 18,
                  ),
                  Flexible(
                    child: Text(
                      [
                        if (a.numberOrNull('rating') != null)
                          ' ${a.number('rating').toStringAsFixed(1)} (${compact(a.integer('reviews_count'))})',
                        a.str('category'),
                        a.str('area'),
                      ].join(' • '),
                      style: CaboText.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FactRow([
                (
                  Icons.schedule_rounded,
                  'Open',
                  a.str('opening_hours', 'Check locally'),
                ),
                (
                  Icons.confirmation_number_rounded,
                  'Entry',
                  fee == 0 ? 'Free' : naira(fee),
                ),
                (Icons.place_rounded, 'Area', a.str('area')),
              ]),
              const SectionTitle('About'),
              Text(a.str('description'), style: CaboText.body),
              if (a.strOrNull('address') != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: CaboColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(a.str('address'), style: CaboText.muted),
                    ),
                  ],
                ),
              ],
              if (a.strings('visitor_tips').isNotEmpty) ...[
                const SectionTitle('Visitor tips'),
                for (final tip in a.strings('visitor_tips')) CheckRow(tip),
              ],
              if (a.strOrNull('safety_notes') != null) ...[
                const SectionTitle('Safety notes'),
                CaboCard(
                  color: CaboColors.yellowSoft,
                  child: Text(
                    a.str('safety_notes'),
                    style: CaboText.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            child: CaboButton(
              'Ride There',
              icon: Icons.local_taxi_rounded,
              onPressed: () => _rideToAttraction(context, a),
            ),
          ),
        );
      },
    );
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () async {
        await state.loadWishlist(force: true);
        return asJsonList(unwrap(await state.api.get('/rider/wishlist')));
      },
      builder: (context, items, reload) {
        final tours = [
          for (final i in items)
            if (i.str('item_type') == 'tour') i.obj('item')!,
        ];
        final places = [
          for (final i in items)
            if (i.str('item_type') == 'attraction') i.obj('item')!,
        ];
        Future<void> remove(String type, Json item) async {
          await runAction(
            context,
            () => state.toggleSaved(type, item.integer('id')),
          );
          await reload();
        }

        return CaboScaffold(
          title: 'Wishlist',
          bottom: CaboButton(
            'My Lagos plan',
            onPressed: () => go(context, '/itinerary'),
          ),
          children: [
            ChipPicker(
              key: ValueKey('${tours.length}-${places.length}'),
              options: [
                'All (${items.length})',
                'Tours (${tours.length})',
                'Places (${places.length})',
              ],
              initial: {_filter},
              single: true,
              onChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              EmptyNotice(
                'Tap the heart on a tour or attraction to save it here.',
                icon: Icons.favorite_border_rounded,
                action: 'Explore Lagos',
                onAction: () => go(context, '/explore'),
              ),
            if (_filter != 2)
              for (final t in tours)
                TourTile(
                  t,
                  saved: true,
                  onSave: () => remove('tour', t),
                  onTap: () {
                    state.select(tour: t);
                    go(context, '/tour-detail');
                  },
                ),
            if (_filter != 1)
              for (final p in places)
                MenuTile(
                  icon: Icons.place_rounded,
                  title: p.str('name'),
                  subtitle: '${p.str('category')} • ${p.str('area')}',
                  trailing: IconButton(
                    tooltip: 'Remove from wishlist',
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: CaboColors.red,
                    ),
                    onPressed: () => remove('attraction', p),
                  ),
                  onTap: () => _openAttraction(context, p),
                ),
          ],
        );
      },
    );
  }
}

class _PlanItem {
  _PlanItem(
    this.at,
    this.icon,
    this.title,
    this.subtitle,
    this.open, {
    this.ride = false,
  });
  final DateTime at;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback open;
  final bool ride;
}

/// The guest's plan, built from what they have booked: tours, airport
/// shuttles and scheduled rides, day by day.
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  Future<List<_PlanItem>> _load(BuildContext context) async {
    final state = AppScope.read(context);
    final nav = state.navigatorKey.currentState;
    final results = await Future.wait([
      state.api.get('/rider/tour-bookings', query: {'status': 'upcoming'}),
      state.api.get('/rider/shuttles'),
      state.api.get('/rider/trips', query: {'status': 'scheduled'}),
    ]);
    final items = <_PlanItem>[];
    for (final b in (results[0] as Json).list('data')) {
      final at = b.obj('slot')?.date('starts_at');
      if (at == null) continue;
      items.add(
        _PlanItem(
          at,
          Icons.tour_rounded,
          b.obj('tour')?.str('title') ?? 'Tour',
          'Tour • ${plural(b.integer('guests'), 'guest')} • ticket ready',
          () {
            state.select(tourBooking: b);
            nav?.pushNamed('/ticket');
          },
        ),
      );
    }
    for (final s in (results[1] as Json).list('data')) {
      final at = s.date('pickup_at');
      if (at == null ||
          at.isBefore(DateTime.now()) ||
          s.str('status') == 'cancelled')
        continue;
      items.add(
        _PlanItem(
          at,
          Icons.flight_rounded,
          s.str('direction') == 'airport_pickup'
              ? 'Airport pickup'
              : 'Ride to the airport',
          '${s.str('flight_number')} • ${s.str('address')}',
          () {
            state.select(shuttle: s);
            nav?.pushNamed('/shuttle-assigned');
          },
          ride: true,
        ),
      );
    }
    for (final t in (results[2] as Json).list('data')) {
      final at = t.date('scheduled_at');
      if (at == null) continue;
      items.add(
        _PlanItem(
          at,
          Icons.local_taxi_rounded,
          'Ride to ${t.str('dropoff_address').split(',').first}',
          'Scheduled • ${naira(t.integer('fare_total'))}',
          () {
            state.select(pastTrip: t);
            nav?.pushNamed('/past-trip');
          },
          ride: true,
        ),
      );
    }
    return items..sort((a, b) => a.at.compareTo(b.at));
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'My Lagos plan',
      children: [
        Loader<List<_PlanItem>>(
          load: () => _load(context),
          builder: (context, items, _) {
            if (items.isEmpty) {
              return EmptyNotice(
                'Your booked tours, airport shuttles and scheduled rides appear here, day by day.',
                icon: Icons.event_note_rounded,
                action: 'Browse tours',
                onAction: () => go(context, '/tours'),
              );
            }
            String? lastDay;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items) ...[
                  if (fmtDay(item.at) != lastDay)
                    SectionTitle(lastDay = fmtDay(item.at)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(fmtTime(item.at), style: CaboText.label),
                        ),
                        Expanded(
                          child: CaboCard(
                            color: item.ride
                                ? CaboColors.greenSoft
                                : Colors.white,
                            padding: const EdgeInsets.all(12),
                            onTap: item.open,
                            child: Row(
                              children: [
                                Icon(item.icon, color: CaboColors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: CaboText.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.subtitle,
                                        style: CaboText.muted.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        CaboButton(
          'Add something from your wishlist',
          style: CaboButtonStyle.secondary,
          icon: Icons.add_rounded,
          onPressed: () => go(context, '/wishlist'),
        ),
      ],
    );
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.celebration_rounded,
      color: CaboColors.orange,
      title: 'Events are coming soon',
      message:
          'Concerts, festivals and tickets from partner venues will appear here. '
          'For now, find things to do under Tours and Explore.',
      primary: 'Browse tours',
      onPrimary: () => replace(context, '/tours'),
      secondary: 'Back',
      top: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => back(context),
      ),
    );
  }
}
