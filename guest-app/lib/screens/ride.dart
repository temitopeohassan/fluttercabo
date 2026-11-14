import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/widgets.dart';

// 3. Cabo Ride.
//
// The map is still a drawn stand-in (see CaboMap), so marker positions are
// fixed. Addresses, fares, drivers and trip status all come from the API.

const _pickup = Offset(0.56, 0.36);
const _dropoff = Offset(0.8, 0.82);

String _short(String address) => address.split(',').first.trim();

IconData _rideIcon(String code) => switch (code) {
  'economy' => Icons.directions_car_rounded,
  'comfort' => Icons.directions_car_filled_rounded,
  'suv' => Icons.airport_shuttle_rounded,
  _ => Icons.local_taxi_rounded,
};

void _goHome(BuildContext context) =>
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);

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

/// Pickup, stops and drop-off of a trip from the API.
class _TripStops extends StatelessWidget {
  const _TripStops(this.trip);
  final Json trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Stop(CaboColors.green, 'PICKUP', trip.str('pickup_address')),
        for (final s in trip.list('stops'))
          _Stop(CaboColors.blue, 'STOP', s.str('address')),
        _Stop(CaboColors.red, 'DROP-OFF', trip.str('dropoff_address')),
      ],
    );
  }
}

class WhereToScreen extends StatefulWidget {
  const WhereToScreen({super.key});

  @override
  State<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends State<WhereToScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _search = 0;
  List<Json> _results = [];
  List<Json> _all = [];
  List<Json> _saved = [];
  List<Json> _recent = [];
  String? _locationError;
  bool _locating = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final state = AppScope.read(context);
    if (state.dropoff != null) _query.text = state.dropoff!.str('name');
    if (state.pickup == null) _locate();
    _loadShortcuts();
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final state = AppScope.read(context);
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final place = await state.currentPlace();
      if (state.pickup == null) state.setPickup(place);
    } catch (e) {
      if (mounted) _locationError = errorText(e);
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _loadShortcuts() async {
    final api = AppScope.read(context).api;
    try {
      final results = await Future.wait([
        api.get('/rider/saved-places'),
        api.get('/rider/trips'),
      ]);
      final seen = <String>{};
      final recent = <Json>[];
      for (final t in (results[1] as Json).list('data')) {
        if (seen.add(t.str('dropoff_address')) && recent.length < 3) {
          recent.add({
            'name': _short(t.str('dropoff_address')),
            'address': t.str('dropoff_address'),
            'lat': t.number('dropoff_lat'),
            'lng': t.number('dropoff_lng'),
          });
        }
      }
      if (!mounted) return;
      setState(() {
        _saved = [
          for (final p in asJsonList(unwrap(results[0])))
            {
              'name': p.str('label'),
              'address': p.str('address'),
              'lat': p.number('lat'),
              'lng': p.number('lng'),
            },
        ];
        _recent = recent;
      });
    } on ApiException {
      // Shortcuts are optional; search still works.
    }
  }

  Future<void> _run() async {
    final run = ++_search;
    try {
      final state = AppScope.read(context);
      final list = await state.destinations(_query.text.trim());
      if (_query.text.trim().isEmpty) _all = list;
      if (mounted && run == _search) setState(() => _results = list);
    } on ApiException catch (e) {
      if (mounted && run == _search)
        showMessage(context, e.message, error: true);
    }
  }

  /// Past drop-offs that are still tourism locations.
  List<Json> get _recentDestinations => [
    for (final r in _recent)
      ?AppState.destinationAt(_all, r.number('lat'), r.number('lng')),
  ];

  void _choose(Json place) {
    final state = AppScope.read(context);
    if (state.pickup == null) {
      showMessage(context, 'Choose your pickup point first.', error: true);
      return;
    }
    state.setDropoff(place);
    go(context, '/confirm-pickup');
  }

  Future<void> _choosePickup() async {
    final state = AppScope.read(context);
    final known = await state.searchPlaces().catchError((_) => <Json>[]);
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Json>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlacePicker(
        title: 'Pickup point',
        places: [..._saved, ...known],
        onLocate: state.currentPlace,
      ),
    );
    if (chosen != null) state.setPickup(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pickup = state.pickup;
    return CaboScaffold(
      title: 'Where to?',
      // A destination chosen elsewhere (an attraction or search) can be confirmed straight away.
      bottom: state.dropoff != null && pickup != null
          ? CaboButton(
              'Continue to ${_short(state.dropoff!.str('name'))}',
              onPressed: () => go(context, '/confirm-pickup'),
            )
          : null,
      children: [
        CaboCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              InkWell(
                onTap: _choosePickup,
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: CaboColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pickup?.str('address') ??
                            (_locating
                                ? 'Finding your location…'
                                : 'Choose your pickup point'),
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: pickup == null
                              ? CaboColors.muted
                              : CaboColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      'Change',
                      style: CaboText.label.copyWith(color: CaboColors.green),
                    ),
                  ],
                ),
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
                    child: TextField(
                      controller: _query,
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          _run,
                        );
                      },
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search for a destination',
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
        if (_locationError != null && pickup == null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CaboCard(
              color: CaboColors.yellowSoft,
              onTap: _choosePickup,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    color: CaboColors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_locationError Or tap here to choose a pickup point.',
                      style: CaboText.body.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (state.scheduledAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CaboCard(
              color: CaboColors.greenSoft,
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: CaboColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pickup on ${fmtDayTime(state.scheduledAt)}',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => state.setSchedule(null),
                    child: const Text('Ride now'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Shortcut(
                Icons.map_rounded,
                'Nearby',
                () => go(context, '/pick-on-map'),
              ),
            ),
            Expanded(
              child: _Shortcut(
                Icons.schedule_rounded,
                'Later',
                () => go(context, '/schedule-ride'),
              ),
            ),
          ],
        ),
        SectionTitle(
          _query.text.trim().isEmpty ? 'Tourism locations' : 'Results',
        ),
        if (_results.isEmpty)
          EmptyNotice(
            _query.text.trim().isEmpty
                ? 'No tourism locations are available yet.'
                : 'No tourism location matches "${_query.text.trim()}". Cabo rides go to Lagos attractions.',
            icon: Icons.search_off_rounded,
          ),
        for (final p in _results.take(12))
          MenuTile(
            icon: Icons.attractions_rounded,
            title: p.str('name'),
            subtitle: p.str('address'),
            onTap: () => _choose(p),
          ),
        if (_recentDestinations.isNotEmpty && _query.text.trim().isEmpty) ...[
          const SectionTitle('Recent'),
          for (final p in _recentDestinations)
            MenuTile(
              icon: Icons.history_rounded,
              title: p.str('name'),
              subtitle: p.str('address'),
              color: CaboColors.muted,
              onTap: () => _choose(p),
            ),
        ],
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CaboCard(
        color: CaboColors.surface,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: CaboColors.green),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaboText.label.copyWith(color: CaboColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing a place, with "use my location" at the top.
class _PlacePicker extends StatelessWidget {
  const _PlacePicker({
    required this.title,
    required this.places,
    this.onLocate,
  });
  final String title;
  final List<Json> places;
  final Future<Json> Function()? onLocate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Text(title, style: CaboText.h2),
            const SizedBox(height: 8),
            if (onLocate != null)
              MenuTile(
                icon: Icons.my_location_rounded,
                title: 'Use my current location',
                onTap: () async {
                  try {
                    final place = await onLocate!();
                    if (context.mounted) Navigator.of(context).pop(place);
                  } catch (e) {
                    if (context.mounted)
                      showMessage(context, errorText(e), error: true);
                  }
                },
              ),
            for (final p in places)
              MenuTile(
                icon: Icons.place_rounded,
                title: p.str('name'),
                subtitle: p.str('address'),
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
  }
}

/// Known places sorted by distance from [from].
List<(Json, double)> _nearest(List<Json> places, Json from) {
  final list = [
    for (final p in places)
      (
        p,
        AppState.distanceKm(
          from.number('lat'),
          from.number('lng'),
          p.number('lat'),
          p.number('lng'),
        ),
      ),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return list;
}

String _km(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

class PickOnMapScreen extends StatelessWidget {
  const PickOnMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
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
      top: const _MapTopBar('Tourism locations near you'),
      panel: Loader<List<(Json, double)>>(
        padding: const EdgeInsets.all(12),
        load: () async {
          final from = state.pickup ?? await state.currentPlace();
          return _nearest(
            await state.destinations(),
            from,
          ).where((p) => p.$2 > 0.05).take(6).toList();
        },
        builder: (context, places, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a destination', style: CaboText.h2),
            Text(
              'Cabo rides go to Lagos tourism locations. Closest first.',
              style: CaboText.muted,
            ),
            const SizedBox(height: 6),
            for (final (place, km) in places)
              MenuTile(
                icon: Icons.place_rounded,
                title: place.str('name'),
                subtitle: '${place.str('address')} • ${_km(km)}',
                onTap: () {
                  if (state.pickup == null) {
                    showMessage(
                      context,
                      'Choose your pickup point first.',
                      error: true,
                    );
                    return;
                  }
                  state.setDropoff(place);
                  go(context, '/confirm-pickup');
                },
              ),
          ],
        ),
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
    final state = AppScope.read(context);
    final pickup = state.pickup;
    if (pickup == null || state.dropoff == null) {
      return Scaffold(
        appBar: caboAppBar(context, 'Confirm pickup'),
        body: EmptyNotice(
          'Choose where you are going first.',
          icon: Icons.place_rounded,
          action: 'Choose destination',
          onAction: () => replace(context, '/where-to'),
        ),
      );
    }
    return Loader<List<Json>>(
      // Offer the exact spot plus well-known landmarks within 400 m.
      load: () async => [
        pickup,
        for (final (p, km) in _nearest(await state.searchPlaces(), pickup))
          if (km > 0.03 && km <= 0.4) {...p, 'distance': km},
      ].take(3).toList(),
      builder: (context, spots, _) => MapLayout(
        map: CaboMap(
          markers: [
            MapMarker(
              _pickup,
              MarkerKind.pickup,
              label: _short(spots[selected].str('name')),
            ),
          ],
        ),
        top: const _MapTopBar('Confirm pickup'),
        panel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spots.length > 1
                  ? 'Meet your driver at a landmark'
                  : 'Meet your driver here',
              style: CaboText.h3,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < spots.length; i++)
              SelectTile(
                icon: i == 0 ? Icons.my_location_rounded : Icons.place_rounded,
                title: spots[i].str('name'),
                subtitle: i == 0
                    ? spots[i].str('address')
                    : 'Landmark drivers know • ${_km(spots[i].number('distance'))}',
                selected: selected == i,
                onTap: () => setState(() => selected = i),
              ),
            const SizedBox(height: 4),
            CaboButton(
              'Confirm pickup',
              onPressed: () {
                if (selected != 0) state.setPickup(spots[selected]);
                go(context, '/choose-ride');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChooseRideScreen extends StatelessWidget {
  const ChooseRideScreen({super.key});

  Future<void> _request(BuildContext context) async {
    final state = AppScope.read(context);
    final scheduled = state.scheduledAt != null;
    try {
      await state.requestRide();
    } on ApiException catch (e) {
      if (e.fields.containsKey('pickup_lat') && context.mounted) {
        go(context, '/outside-area');
        return;
      }
      rethrow;
    }
    if (!context.mounted) return;
    if (scheduled) {
      showMessage(context, 'Ride scheduled. You can see it under Bookings.');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/bookings', (r) => r.settings.name == '/home');
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/finding-driver',
        (r) => r.settings.name == '/home',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.pickup == null || state.dropoff == null) {
      return Scaffold(
        appBar: caboAppBar(context, 'Book a Ride'),
        body: EmptyNotice(
          'Choose where you are going to see prices.',
          icon: Icons.local_taxi_rounded,
          action: 'Choose destination',
          onAction: () => replace(context, '/where-to'),
        ),
      );
    }
    return Scaffold(
      appBar: caboAppBar(context, 'Book a Ride'),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: CaboMap(
                  route: const [
                    _pickup,
                    Offset(0.62, 0.52),
                    Offset(0.78, 0.6),
                    _dropoff,
                  ],
                  markers: [
                    MapMarker(
                      _pickup,
                      MarkerKind.pickup,
                      label: _short(state.pickup!.str('name')),
                    ),
                    MapMarker(
                      _dropoff,
                      MarkerKind.dropoff,
                      label: _short(state.dropoff!.str('name')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Loader<bool>(
              load: () async {
                if (state.estimates.isEmpty) await state.loadEstimates();
                return true;
              },
              builder: (context, _, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                children: [
                  for (final e in state.estimates)
                    RideOption(
                      name: e.str('name'),
                      icon: _rideIcon(e.str('ride_type')),
                      eta:
                          '${e.number('distance_km').toStringAsFixed(1)} km • about ${e.integer('duration_minutes')} min',
                      fare: e.integer('fare_total'),
                      homeFare: state.homePrice(e.integer('fare_total')),
                      seats: e.integer('seats', 4),
                      surge: e.number('surge_multiplier', 1) > 1
                          ? '×${e.number('surge_multiplier')}'
                          : null,
                      selected: state.rideType == e.str('ride_type'),
                      onTap: () => state.chooseRide(e.str('ride_type')),
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
                                  paymentLabels[state.paymentMethod] ?? 'Card',
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
                          style: CaboText.label.copyWith(
                            color: CaboColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: ActionButton(
          state.scheduledAt == null
              ? 'Request Ride'
              : 'Schedule for ${fmtDayTime(state.scheduledAt)}',
          busyLabel: 'Requesting…',
          enabled: state.estimates.isNotEmpty,
          onPressed: () => _request(context),
        ),
      ),
    );
  }
}

class FareBreakdownScreen extends StatelessWidget {
  const FareBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = state.estimate;
    if (e == null) {
      return CaboScaffold(
        title: 'Fare breakdown',
        children: const [
          EmptyNotice(
            'Choose a destination to see the fare.',
            icon: Icons.receipt_long_rounded,
          ),
        ],
      );
    }
    final total = e.integer('fare_total');
    final home = state.homePrice(total);
    final surge = e.number('surge_multiplier', 1);
    return CaboScaffold(
      title: 'Fare breakdown',
      children: [
        Center(
          child: Text('${e.str('name')} • upfront fare', style: CaboText.muted),
        ),
        Center(
          child: Text(
            naira(total),
            style: CaboText.display.copyWith(color: CaboColors.green),
          ),
        ),
        if (home.isNotEmpty)
          Center(child: Text("$home at today's rate", style: CaboText.muted)),
        const SizedBox(height: 20),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Base fare', naira(e.integer('fare_base'))),
              InfoRow(
                'Distance (${e.number('distance_km').toStringAsFixed(1)} km)',
                naira(e.integer('fare_distance')),
              ),
              InfoRow(
                'Time (about ${e.integer('duration_minutes')} min)',
                naira(e.integer('fare_time')),
              ),
              if (surge > 1)
                InfoRow('Busy area (${e.str('zone')})', '× $surge'),
              if (e.integer('fare_stops') > 0)
                InfoRow('Extra stops', naira(e.integer('fare_stops'))),
              if (e.integer('tolls') > 0)
                InfoRow('Lekki toll gate', naira(e.integer('tolls'))),
              InfoRow(
                'Discounts',
                e.integer('discount') > 0
                    ? '−${naira(e.integer('discount'))}'
                    : '₦0',
              ),
              const Divider(height: 20),
              InfoRow('Total', naira(total), bold: true),
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
                'This price is fixed unless you add a stop or keep your driver waiting. '
                'A short ride never costs less than the minimum fare for its type.',
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

  static const _methods = ['card', 'wallet', 'bank_transfer', 'cash'];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final balance = state.rider?.integer('wallet_balance') ?? 0;
    return CaboScaffold(
      title: 'Payment method',
      bottom: CaboButton(
        'Use ${paymentLabels[state.paymentMethod]}',
        onPressed: () => back(context),
      ),
      children: [
        SingleChoice(
          initial: _methods.indexOf(state.paymentMethod).clamp(0, 3),
          onChanged: (i) => state.choosePayment(_methods[i]),
          icons: const [
            Icons.credit_card_rounded,
            Icons.account_balance_wallet_rounded,
            Icons.account_balance_rounded,
            Icons.payments_rounded,
          ],
          options: [
            ('Card', 'Charged when the trip ends'),
            ('Cabo Wallet', 'Balance ${naira(balance)}'),
            ('Bank transfer', 'Pay to a virtual account'),
            ('Cash', 'Pay the driver at the end of the ride'),
          ],
        ),
        MenuTile(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Top up your wallet',
          subtitle: 'Add money by card or bank transfer',
          onTap: () => go(context, '/top-up'),
        ),
        MenuTile(
          icon: Icons.local_offer_rounded,
          title: 'Promo code',
          subtitle: state.promoCode == null
              ? 'Add a code'
              : '${state.promoCode} applied',
          color: CaboColors.orange,
          onTap: () => go(context, '/promos'),
        ),
      ],
    );
  }
}

/// Keeps a ride screen in step with the trip: polls the API while the
/// screen is open and moves to the screen that matches the trip's status.
mixin _TripWatcher<T extends StatefulWidget> on State<T> {
  /// The route this screen is shown at.
  String get route;

  late AppState _state;
  bool _watching = false;
  bool _leaving = false;
  Object? loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_watching) return;
    _watching = true;
    _state = AppScope.read(context);
    _state.addListener(_sync);
    _state.watchTrip();
    if (_state.trip == null) {
      _state.findActiveTrip().then(
        (t) {
          if (mounted && t == null) setState(() => loadError = 'none');
        },
        onError: (Object e) {
          if (mounted) setState(() => loadError = e);
        },
      );
    }
  }

  @override
  void dispose() {
    _state.removeListener(_sync);
    _state.unwatchTrip();
    super.dispose();
  }

  /// Call before navigating away on purpose, so [_sync] does not also navigate.
  void leaving() => _leaving = true;

  void _sync() {
    final trip = _state.trip;
    if (!mounted || _leaving || trip == null) return;
    final status = trip.str('status');
    if (status == 'cancelled' || status == 'no_show') {
      _leaving = true;
      final by = trip.str('cancelled_by');
      showMessage(
        context,
        status == 'no_show'
            ? 'Your driver waited and then left. The ride was cancelled.'
            : by == 'rider'
            ? 'Ride cancelled.'
            : 'Your ride was cancelled by ${by == 'driver' ? 'the driver' : 'Cabo'}. You have not been charged.',
      );
      _goHome(context);
      return;
    }
    final target = AppState.tripRoute(trip);
    if (target != null && target != route) {
      _leaving = true;
      Navigator.of(context).pushReplacementNamed(target);
    } else {
      setState(() {});
    }
  }

  /// Shown while the trip loads, or when there is no ride in progress.
  Widget noTrip(String title) {
    return Scaffold(
      appBar: caboAppBar(context, title),
      body: loadError == null
          ? const Center(
              child: CircularProgressIndicator(color: CaboColors.green),
            )
          : loadError == 'none'
          ? EmptyNotice(
              'You have no ride in progress.',
              icon: Icons.local_taxi_rounded,
              action: 'Book a ride',
              onAction: () => replace(context, '/where-to'),
            )
          : ErrorNotice(errorText(loadError!)),
    );
  }
}

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with _TripWatcher {
  @override
  String get route => '/finding-driver';

  @override
  Widget build(BuildContext context) {
    final trip = _state.trip;
    if (trip == null) return noTrip('Finding a driver');
    final waited = DateTime.now().difference(
      trip.date('created_at') ?? DateTime.now(),
    );
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
          Text('Finding your driver…', style: CaboText.h2),
          const SizedBox(height: 4),
          Text(
            waited.inMinutes >= 3
                ? 'This is taking longer than usual. You can keep waiting or cancel for free.'
                : 'Matching you with the nearest vetted ${trip.obj('ride_type')?.str('name') ?? ''} driver.',
            textAlign: TextAlign.center,
            style: CaboText.muted,
          ),
          const SizedBox(height: 14),
          const LinearProgressIndicator(value: kScreenshotMode ? 0.45 : null),
          const SizedBox(height: 18),
          _TripStops(trip),
          const SizedBox(height: 14),
          ActionButton(
            'Cancel request',
            style: CaboButtonStyle.secondary,
            busyLabel: 'Cancelling…',
            onPressed: () async {
              leaving();
              try {
                await _state.cancelTrip('Cancelled while finding a driver');
              } catch (_) {
                _leaving = false;
                rethrow;
              }
              if (context.mounted) {
                showMessage(
                  context,
                  'Request cancelled. You have not been charged.',
                );
                _goHome(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class DriverOnTheWayScreen extends StatefulWidget {
  const DriverOnTheWayScreen({super.key});

  @override
  State<DriverOnTheWayScreen> createState() => _DriverOnTheWayScreenState();
}

class _DriverOnTheWayScreenState extends State<DriverOnTheWayScreen>
    with _TripWatcher {
  @override
  String get route => '/driver-on-way';

  @override
  Widget build(BuildContext context) {
    final trip = _state.trip;
    if (trip == null) return noTrip('Your driver');
    final name =
        trip.obj('driver')?.str('first_name', 'Your driver') ?? 'Your driver';
    final arrived = trip.str('status') == 'arrived';
    final waitingFee = trip.integer('waiting_fee');
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
          color: arrived ? CaboColors.yellow : CaboColors.green,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              arrived ? Icons.where_to_vote_rounded : Icons.schedule_rounded,
              color: arrived ? CaboColors.onYellow : Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                arrived
                    ? '$name has arrived at ${_short(trip.str('pickup_address'))}'
                    : '$name is on the way to ${_short(trip.str('pickup_address'))}',
                style: CaboText.h3.copyWith(
                  color: arrived ? CaboColors.onYellow : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DriverCard(trip),
          const SizedBox(height: 14),
          CaboCard(
            color: CaboColors.yellowSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Give this PIN to your driver once you are in the car',
                    style: CaboText.body,
                  ),
                ),
                Text(
                  trip.str('pin'),
                  style: CaboText.h1.copyWith(letterSpacing: 4),
                ),
              ],
            ),
          ),
          if (waitingFee > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Waiting time so far adds ${naira(waitingFee)} to your fare.',
                style: CaboText.muted.copyWith(color: CaboColors.orange),
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
        ],
      ),
    );
  }
}

class ChatWithDriverScreen extends StatelessWidget {
  const ChatWithDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat with your driver',
      message:
          'In-app chat and private calls are coming soon. For now your driver meets you at the pickup '
          'point shown in the app, and you can reach Cabo support at any time.',
      primary: 'Contact support',
      onPrimary: () => go(context, '/help'),
      secondary: 'Back',
      top: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => back(context),
      ),
    );
  }
}

class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen>
    with _TripWatcher {
  @override
  String get route => '/trip-in-progress';

  @override
  Widget build(BuildContext context) {
    final trip = _state.trip;
    if (trip == null) return noTrip('Your trip');
    final arrival = (trip.date('started_at') ?? DateTime.now()).add(
      Duration(minutes: trip.integer('duration_minutes')),
    );
    final left = arrival.difference(DateTime.now()).inMinutes;
    final dest = _short(trip.str('dropoff_address'));
    return MapLayout(
      map: CaboMap(
        route: const [Offset(0.62, 0.52), Offset(0.78, 0.6), _dropoff],
        markers: [
          const MapMarker(Offset(0.62, 0.52), MarkerKind.driver),
          MapMarker(_dropoff, MarkerKind.dropoff, label: dest),
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
            child: Text(
              left > 0
                  ? 'Arrive about ${fmtTime(arrival)} • $left min'
                  : 'Arriving soon',
              style: CaboText.h3,
            ),
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
          Text('On the way to $dest', style: CaboText.h2),
          const SizedBox(height: 4),
          Text(
            '${trip.number('distance_km').toStringAsFixed(1)} km • ${trip.obj('ride_type')?.str('name') ?? ''} • '
            '${naira(trip.integer('fare_total'))} by ${(paymentLabels[trip.str('payment_method')] ?? '').toLowerCase()}',
            style: CaboText.muted,
          ),
          const SizedBox(height: 14),
          DriverCard(trip, actions: false),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (icon, label, route) in const [
                (Icons.share_rounded, 'Share', '/share-trip'),
                (Icons.add_location_alt_rounded, 'Add stop', '/add-stop'),
                (Icons.shield_rounded, 'Safety', '/safety'),
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

class _ShareData {
  _ShareData(this.url, this.contacts);
  final String url;
  final List<Json> contacts;
}

class ShareTripScreen extends StatelessWidget {
  const ShareTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final api = state.api;
    return CaboScaffold(
      title: 'Share trip',
      children: [
        Loader<_ShareData>(
          load: () async {
            final trip = state.trip ?? await state.findActiveTrip();
            if (trip == null)
              throw ApiException(
                'You can share a trip once you have a ride in progress.',
              );
            final results = await Future.wait([
              api.post('/rider/trips/${trip.integer('id')}/share'),
              api.get('/rider/emergency-contacts'),
            ]);
            return _ShareData(
              (unwrap(results[0]) as Json).str('url'),
              asJsonList(unwrap(results[1])),
            );
          },
          builder: (context, data, reload) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaboCard(
                color: CaboColors.greenSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live trip link', style: CaboText.label),
                    const SizedBox(height: 4),
                    SelectableText(
                      data.url,
                      style: CaboText.h3.copyWith(color: CaboColors.green),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Shows your driver, car and where they were last seen. Opens in any browser, no app needed.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CaboButton(
                'Copy link',
                icon: Icons.copy_rounded,
                height: 50,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: data.url));
                  if (context.mounted)
                    showMessage(
                      context,
                      'Link copied. Paste it into WhatsApp, SMS or email.',
                    );
                },
              ),
              SectionTitle(
                'Trusted contacts',
                action: 'Manage',
                onAction: () => go(context, '/trusted-contacts'),
              ),
              if (data.contacts.isEmpty)
                const EmptyNotice(
                  'Add a trusted contact so Cabo\'s safety team can reach someone for you.',
                  icon: Icons.group_add_rounded,
                ),
              for (final c in data.contacts)
                ToggleTile(
                  c.str('name'),
                  key: ValueKey(c.integer('id')),
                  subtitle:
                      '${c.str('relationship')} • ${c.str('phone')}\nShare every trip automatically',
                  initial: c.flag('share_trips_automatically'),
                  onChanged: (v) => runAction(
                    context,
                    () => api.put(
                      '/rider/emergency-contacts/${c.integer('id')}',
                      {
                        'name': c.str('name'),
                        'phone': c.str('phone'),
                        'relationship': c.strOrNull('relationship'),
                        'share_trips_automatically': v,
                      },
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

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key});

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Json> _results = [];
  Json? _chosen;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final list = await AppScope.read(context)
          .destinations(_query.text.trim());
      if (mounted) setState(() => _results = list);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  Future<void> _add() async {
    final state = AppScope.read(context);
    final before = state.trip!.integer('fare_total');
    final res = await state.api.post(
      '/rider/trips/${state.trip!.integer('id')}/stops',
      {
        'address': _chosen!.str('address'),
        'lat': _chosen!.number('lat'),
        'lng': _chosen!.number('lng'),
      },
    );
    final after = (unwrap(res) as Json).integer('fare_total');
    await state.refreshTrip();
    if (!mounted) return;
    showMessage(
      context,
      'Stop added. Your fare went from ${naira(before)} to ${naira(after)}.',
    );
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trip = state.trip;
    if (trip == null) {
      return CaboScaffold(
        title: 'Add a stop',
        children: const [
          EmptyNotice(
            'You can add a stop during a ride.',
            icon: Icons.add_location_alt_rounded,
          ),
        ],
      );
    }
    final stopFee =
        state.config.obj('pricing')?.integer('stop_fee', 300) ?? 300;
    return CaboScaffold(
      title: 'Add a stop',
      bottom: ActionButton(
        _chosen == null
            ? 'Choose a stop'
            : 'Add ${_short(_chosen!.str('name'))}',
        enabled: _chosen != null,
        busyLabel: 'Adding…',
        onPressed: _add,
      ),
      children: [
        _Stop(CaboColors.green, 'PICKUP', trip.str('pickup_address')),
        for (final s in trip.list('stops'))
          _Stop(CaboColors.blue, 'STOP', s.str('address')),
        if (_chosen != null)
          _Stop(CaboColors.blue, 'NEW STOP', _chosen!.str('address')),
        _Stop(CaboColors.red, 'DROP-OFF', trip.str('dropoff_address')),
        const SizedBox(height: 14),
        TextField(
          controller: _query,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), _run);
          },
          decoration: InputDecoration(
            hintText: 'Search for a stop',
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
          ),
        ),
        const SizedBox(height: 8),
        for (final p in _results.take(8))
          MenuTile(
            icon: Icons.place_rounded,
            title: p.str('name'),
            subtitle: p.str('address'),
            trailing: _chosen == p
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: CaboColors.green,
                  )
                : null,
            onTap: () => setState(() => _chosen = p),
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
                  'Each stop adds ${naira(stopFee)} plus the extra distance and time. You see the new fare '
                  'as soon as the stop is added, and your driver sees the new route. Up to three stops.',
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
  int day = 0;
  int? time;

  static const _times = [
    '05:00',
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '10:00', //
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00', '21:00', '22:00',
  ];

  DateTime _at(int dayIndex, String hhmm) {
    final d = DateTime.now().add(Duration(days: dayIndex));
    final parts = hhmm.split(':');
    return DateTime(
      d.year,
      d.month,
      d.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final now = DateTime.now();
    // The server needs at least 15 minutes' notice.
    final earliest = now.add(const Duration(minutes: 20));
    final chosen = time == null ? null : _at(day, _times[time!]);
    return CaboScaffold(
      title: 'Schedule a ride',
      bottom: CaboButton(
        chosen == null
            ? 'Choose a pickup time'
            : 'Schedule for ${fmtDayTime(chosen)}',
        onPressed: chosen == null
            ? null
            : () {
                state.setSchedule(chosen);
                back(context);
              },
      ),
      children: [
        Text(
          'Book up to 7 days ahead. Choose your destination next and you will see the fixed fare before you confirm.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SectionTitle('Day'),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = now.add(Duration(days: i));
              return GestureDetector(
                onTap: () => setState(() {
                  day = i;
                  time = null;
                }),
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
                        i == 0 ? 'Today' : weekdayShort(d),
                        style: CaboText.label.copyWith(
                          color: i == day ? Colors.white70 : CaboColors.muted,
                        ),
                      ),
                      Text(
                        '${d.day}',
                        style: CaboText.h2.copyWith(
                          color: i == day ? Colors.white : CaboColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
            for (var i = 0; i < _times.length; i++)
              Builder(
                builder: (context) {
                  final available = _at(day, _times[i]).isAfter(earliest);
                  return GestureDetector(
                    onTap: available ? () => setState(() => time = i) : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == time
                            ? CaboColors.green
                            : CaboColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _times[i],
                        style: CaboText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: i == time
                              ? Colors.white
                              : available
                              ? CaboColors.ink
                              : CaboColors.line,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class CancelRideScreen extends StatefulWidget {
  const CancelRideScreen({super.key});

  @override
  State<CancelRideScreen> createState() => _CancelRideScreenState();
}

class _CancelRideScreenState extends State<CancelRideScreen> {
  static const _reasons = [
    ('Driver is taking too long', null),
    ('I changed my plans', null),
    ('Wrong pickup location', null),
    ('I feel unsafe', 'Cabo Safety will follow up with you'),
    ('Other', null),
  ];
  int _reason = 1;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final trip = state.trip;
    if (trip == null) {
      return CaboScaffold(
        title: 'Cancel ride',
        children: const [
          EmptyNotice(
            'You have no ride to cancel.',
            icon: Icons.local_taxi_rounded,
          ),
        ],
      );
    }
    final rules = state.config.obj('cancellation');
    final freeMinutes = rules?.integer('free_minutes', 2) ?? 2;
    final fee = rules?.integer('rider_fee', 500) ?? 500;
    final accepted = trip.date('accepted_at');
    final free =
        accepted == null ||
        (trip.str('status') == 'accepted' &&
            DateTime.now().difference(accepted).inMinutes < freeMinutes);
    return CaboScaffold(
      title: 'Cancel ride',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton(
            'Cancel ride',
            style: CaboButtonStyle.danger,
            busyLabel: 'Cancelling…',
            onPressed: () async {
              final res = await state.cancelTrip(_reasons[_reason].$1);
              if (!context.mounted) return;
              showMessage(context, res.str('message', 'Ride cancelled.'));
              _goHome(context);
            },
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
          color: free ? CaboColors.greenSoft : CaboColors.yellowSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                free
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                color: free ? CaboColors.green : CaboColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  free
                      ? 'You can cancel for free right now. After your driver has been on the way for '
                            '$freeMinutes minutes, a ${naira(fee)} fee applies.'
                      : 'Free cancellation has ended. A ${naira(fee)} fee goes to your driver for their time.',
                  style: CaboText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Why are you cancelling?'),
        SingleChoice(
          initial: _reason,
          onChanged: (i) => _reason = i,
          options: _reasons,
        ),
      ],
    );
  }
}

/// Tip chosen on the trip-complete screen, sent with the rating.
int _pendingTip = 0;

class TripCompleteScreen extends StatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  State<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends State<TripCompleteScreen> {
  static const tips = [0, 200, 500, 1000];
  int tip = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () async {
        if (state.trip == null)
          throw ApiException('There is no finished ride to show.');
        // Fetch the final fare, which can include waiting time.
        await state.refreshTrip();
        return state.trip!;
      },
      builder: (context, trip, _) {
        final fare = trip.integer('fare_total');
        final driver =
            trip.obj('driver')?.str('first_name', 'your driver') ??
            'your driver';
        final method = paymentLabels[trip.str('payment_method')] ?? 'Card';
        final home = state.homePrice(fare + tips[tip]);
        final email = state.rider?.strOrNull('email');
        return CaboScaffold(
          title: 'Trip complete',
          showBack: false,
          bottom: CaboButton(
            'Rate $driver',
            onPressed: () {
              _pendingTip = tips[tip];
              go(context, '/rate-driver');
            },
          ),
          children: [
            const SizedBox(height: 8),
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: CaboColors.greenSoft,
                child: Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: CaboColors.green,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "You've arrived at ${_short(trip.str('dropoff_address'))}",
                style: CaboText.h2,
                textAlign: TextAlign.center,
              ),
            ),
            Center(
              child: Text(
                '${trip.number('distance_km').toStringAsFixed(1)} km • ${trip.integer('duration_minutes')} min',
                style: CaboText.muted,
              ),
            ),
            const SizedBox(height: 18),
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Trip fare', naira(fare)),
                  InfoRow(
                    'Tip for $driver',
                    naira(tips[tip]),
                    valueColor: CaboColors.green,
                  ),
                  const Divider(height: 20),
                  InfoRow(
                    'Total ($method)',
                    naira(fare + tips[tip]),
                    bold: true,
                  ),
                  if (home.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(home, style: CaboText.label),
                    ),
                ],
              ),
            ),
            if (trip.str('payment_method') == 'cash')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Pay ${naira(fare)} in cash to your driver. A tip added here is charged to your card.',
                  style: CaboText.muted,
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
                            color: i == tip
                                ? CaboColors.green
                                : CaboColors.surface,
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
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: CaboColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email == null ? 'Your receipt is under Bookings.' : 'Your receipt is under Bookings. Add-ons such as tips appear there too.',
                    style: CaboText.muted,
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

class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({super.key});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  static const _labels = [
    '',
    'Poor',
    'Below average',
    'OK',
    'Good',
    'Excellent',
  ];
  static const _tags = [
    'Safe driving',
    'Clean car',
    'Knows Lagos',
    'Friendly',
    'Great music',
    'On time',
  ];
  final _note = TextEditingController();
  int stars = 5;
  Set<int> _picked = {};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppScope.read(context);
    final feedback = [
      for (final i in _picked.toList()..sort()) _tags[i],
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ].join('. ');
    await state.api.post('/rider/trips/${state.trip!.integer('id')}/rating', {
      'rating': stars,
      if (feedback.isNotEmpty)
        'feedback': feedback.length > 255
            ? feedback.substring(0, 255)
            : feedback,
      'tip': _pendingTip,
    });
    _pendingTip = 0;
    state.trip = null;
    unawaited(state.refreshRider().catchError((_) {}));
    if (!mounted) return;
    showMessage(context, 'Thanks for your feedback.');
    _goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final trip = AppScope.read(context).trip;
    if (trip == null) {
      return CaboScaffold(
        title: 'Rate your driver',
        children: const [
          EmptyNotice(
            'There is no finished ride to rate.',
            icon: Icons.star_outline_rounded,
          ),
        ],
      );
    }
    final driver = trip.obj('driver');
    final name = driver?.str('first_name', 'your driver') ?? 'your driver';
    return CaboScaffold(
      title: 'Rate your driver',
      bottom: ActionButton(
        _pendingTip > 0 ? 'Submit and tip ${naira(_pendingTip)}' : 'Submit',
        busyLabel: 'Sending…',
        onPressed: _submit,
      ),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Avatar(
            initials('$name ${driver?.str('last_name') ?? ''}'),
            size: 96,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'How was your ride with $name?',
            style: CaboText.h2,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 46,
                tooltip: '$i ${i == 1 ? 'star' : 'stars'}',
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
            _labels[stars],
            style: CaboText.h3.copyWith(color: CaboColors.green),
          ),
        ),
        const SectionTitle('What stood out?'),
        ChipPicker(options: _tags, onChanged: (s) => _picked = s),
        const SizedBox(height: 18),
        CaboField(
          'Anything else? (optional)',
          controller: _note,
          hint: 'Tell us about your trip',
          maxLines: 3,
        ),
      ],
    );
  }
}
