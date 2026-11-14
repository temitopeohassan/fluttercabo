import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 3. Ride requests and trips.

String _short(String address) => address.split(',').first;
String _riderName(Json? trip) => trip?.obj('rider')?.strOrNull('first_name') ?? 'your rider';

void _toHome(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);

/// Shown by trip screens opened without a trip in hand.
class _NoTrip extends StatelessWidget {
  const _NoTrip(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, title),
      body: EmptyNotice(
        'You have no trip in hand. Go online to receive ride requests.',
        icon: Icons.local_taxi_rounded,
        action: 'Back to home',
        onAction: () => _toHome(context),
      ),
    );
  }
}

/// Keeps a trip screen in step with the server: picks up added stops and fare
/// changes, and leaves the screen if the rider or support cancels the trip.
mixin _TripWatch<T extends StatefulWidget> on State<T> {
  Timer? _poll;
  AppState? _watched;

  /// The statuses this screen is for.
  Set<String> get statuses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_watched != null) return;
    final state = _watched = AppScope.read(context);
    if (state.trip == null) {
      _check();
    }
    if (!kScreenshotMode) _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Future<void> _check() async {
    final state = _watched!;
    try {
      await state.loadCurrentTrip();
    } on ApiException {
      return; // Try again on the next tick.
    }
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final status = state.trip?.str('status');
    if (status == null || statuses.contains(status)) return;
    if (status == 'cancelled') {
      showMessage(context, 'This trip was cancelled.', error: true);
      _toHome(context);
    } else {
      final route = AppState.tripRoute(state.trip);
      if (route != null) replace(context, route);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}

class _RiderRow extends StatelessWidget {
  const _RiderRow(this.trip, {this.subtitle});
  final Json trip;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final rider = trip.obj('rider');
    final needs = rider?['accessibility'];
    return Row(
      children: [
        Avatar(initials(rider?.strOrNull('first_name')), size: 50, color: CaboColors.yellowSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_riderName(trip), style: CaboText.h3),
              Text(
                subtitle ??
                    [
                      if (rider?.numberOrNull('rating') != null) '★ ${rider!.number('rating').toStringAsFixed(1)}',
                      ?trip.obj('ride_type')?.strOrNull('name'),
                      paymentLabels[trip.str('payment_method')] ?? '',
                    ].join(' • '),
                style: CaboText.muted,
              ),
              if (needs is Map && needs.isNotEmpty)
                Text(
                  'Needs: ${[for (final e in needs.entries) e.key == 'notes' ? '${e.value}' : humanize('${e.key}').toLowerCase()].join(', ')}',
                  style: CaboText.label.copyWith(color: CaboColors.yellow),
                ),
            ],
          ),
        ),
        RoundAction(Icons.chat_bubble_rounded, onTap: () => go(context, '/chat-rider')),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop(this.color, this.label, this.title, [this.trailing = '']);
  final Color color;
  final String label;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CaboText.label),
                Text(title, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(trailing, style: CaboText.label.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// A banner with the next place to drive to and a button that opens the
/// phone's maps app for turn-by-turn directions.
class _NavBanner extends StatelessWidget {
  const _NavBanner(this.label, this.address, this.lat, this.lng);
  final String label;
  final String address;
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CaboColors.deepGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CaboText.label),
                Text(address, style: CaboText.h3, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CaboButton(
            'Navigate',
            icon: Icons.navigation_rounded,
            height: 44,
            expand: false,
            onPressed: () => openNavigation(context, lat, lng),
          ),
        ],
      ),
    );
  }
}

class IncomingRequestScreen extends StatefulWidget {
  const IncomingRequestScreen({super.key});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> with SingleTickerProviderStateMixin {
  static const seconds = 30;
  late final AnimationController timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: seconds),
    value: 1,
  );
  Json? _offer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      timer.reverse().whenComplete(() {
        // The offer has timed out; leave it for other hosts.
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) back(context);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final state = AppScope.read(context);
    _offer = state.offer ?? state.requests.firstOrNull;
    if (_offer == null) {
      state.loadRequests().then((_) {
        if (mounted) setState(() => _offer = state.requests.firstOrNull);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final r = _offer;
    if (r == null) {
      return Scaffold(
        appBar: caboAppBar(context, 'Ride requests'),
        body: EmptyNotice(
          state.isOnline ? 'No ride requests near you right now.' : 'Go online to receive ride requests.',
          icon: Icons.notifications_none_rounded,
          action: 'Back to home',
          onAction: () => _toHome(context),
        ),
      );
    }
    final away = r.numberOrNull('pickup_distance_km');
    return MapLayout(
      map: CaboMap(
        route: Routes.toPickup,
        routeColor: CaboColors.brightGreen,
        markers: [
          const MapMarker(Offset(0.3, 0.78), MarkerKind.driver),
          MapMarker(const Offset(0.56, 0.36), MarkerKind.pickup, label: _short(r.str('pickup_address'))),
        ],
      ),
      top: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: CaboColors.yellow, borderRadius: BorderRadius.circular(30)),
            child: Text(
              'New ride request',
              style: CaboText.body.copyWith(fontWeight: FontWeight.w700, color: CaboColors.onYellow),
            ),
          ),
          const Spacer(),
          Container(
            decoration: const BoxDecoration(color: CaboColors.deepGreen, shape: BoxShape.circle),
            padding: const EdgeInsets.all(4),
            child: AnimatedBuilder(
              animation: timer,
              builder: (context, _) => Ring(
                value: timer.value,
                size: 60,
                stroke: 6,
                child: Text('${(timer.value * seconds).ceil()}', style: CaboText.h2),
              ),
            ),
          ),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Pill(r.obj('ride_type')?.str('name') ?? 'Ride', icon: Icons.directions_car_rounded),
              if (r.number('surge_multiplier', 1) > 1)
                Pill(
                  'Surge ×${r.number('surge_multiplier').toStringAsFixed(1)}',
                  color: CaboColors.orange,
                  icon: Icons.local_fire_department_rounded,
                ),
              if (r.list('stops').isNotEmpty) Pill(plural(r.list('stops').length, 'stop'), color: CaboColors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(naira(r.integer('driver_earnings')), style: CaboText.display),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'you earn • fare ${naira(r.integer('fare_total'))} • ${(paymentLabels[r.str('payment_method')] ?? '').toLowerCase()}',
                    style: CaboText.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Stop(CaboColors.brightGreen, 'PICKUP', r.str('pickup_address'), away == null ? '' : '${away.toStringAsFixed(1)} km away'),
          _Stop(
            CaboColors.red,
            'DROP-OFF • ${r.integer('duration_minutes')} min trip',
            r.str('dropoff_address'),
            '${r.number('distance_km').toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: CaboColors.yellow, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_riderName(r)} • ${r.obj('rider')?.numberOrNull('rating')?.toStringAsFixed(1) ?? 'new'} rider rating',
                style: CaboText.muted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  'Decline',
                  style: CaboButtonStyle.secondary,
                  height: 64,
                  onPressed: () async {
                    await state.decline(r);
                    if (context.mounted) back(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ActionButton(
                  'Accept',
                  height: 64,
                  onPressed: () async {
                    try {
                      await state.accept(r);
                    } on ApiException catch (e) {
                      // Another host got there first.
                      if (e.statusCode != 409) rethrow;
                      await state.loadRequests();
                      if (context.mounted) {
                        showMessage(context, e.message, error: true);
                        back(context);
                      }
                      return;
                    }
                    if (context.mounted) replace(context, '/navigate-pickup');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NavigateToPickupScreen extends StatefulWidget {
  const NavigateToPickupScreen({super.key});

  @override
  State<NavigateToPickupScreen> createState() => _NavigateToPickupScreenState();
}

class _NavigateToPickupScreenState extends State<NavigateToPickupScreen> with _TripWatch {
  @override
  Set<String> get statuses => const {'accepted'};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = state.trip;
    if (t == null || t.str('status') != 'accepted') return const _NoTrip('Navigate to pickup');
    return MapLayout(
      map: CaboMap(
        route: Routes.toPickup,
        routeColor: CaboColors.brightGreen,
        markers: [
          const MapMarker(Offset(0.3, 0.7), MarkerKind.driver),
          MapMarker(const Offset(0.56, 0.36), MarkerKind.pickup, label: _riderName(t)),
        ],
      ),
      top: _NavBanner('PICKUP', t.str('pickup_address'), t.number('pickup_lat'), t.number('pickup_lng')),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Pick up ${_riderName(t)}', style: CaboText.h2)),
              TextButton(
                onPressed: () => go(context, '/cancel-trip'),
                child: Text('Cancel', style: CaboText.label.copyWith(color: CaboColors.red)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RiderRow(t),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: CaboColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Going to ${t.str('dropoff_address')}', style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActionButton(
            "I've arrived",
            icon: Icons.where_to_vote_rounded,
            onPressed: () async {
              await state.tripAction('arrive');
              if (context.mounted) replace(context, '/arrived-pickup');
            },
          ),
        ],
      ),
    );
  }
}

class ArrivedAtPickupScreen extends StatefulWidget {
  const ArrivedAtPickupScreen({super.key});

  @override
  State<ArrivedAtPickupScreen> createState() => _ArrivedAtPickupScreenState();
}

class _ArrivedAtPickupScreenState extends State<ArrivedAtPickupScreen> with _TripWatch {
  Timer? _tick;

  @override
  Set<String> get statuses => const {'arrived'};

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = state.trip;
    if (t == null || t.str('status') != 'arrived') return const _NoTrip('Arrived at pickup');
    final waiting = state.config.obj('waiting');
    final free = waiting?.integer('free_minutes', 5) ?? 5;
    final fee = waiting?.integer('fee_per_minute', 50) ?? 50;
    final elapsed = DateTime.now().difference(t.date('arrived_at') ?? DateTime.now());
    final left = Duration(minutes: free) - elapsed;
    String clock(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return MapLayout(
      map: const CaboMap(markers: [MapMarker(Offset(0.55, 0.42), MarkerKind.driver), MapMarker(Offset(0.6, 0.36), MarkerKind.pickup)]),
      top: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: CaboColors.brightGreen, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: CaboColors.onYellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_riderName(t)} has been notified that you have arrived',
                style: CaboText.body.copyWith(color: CaboColors.onYellow, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Ring(
                value: (elapsed.inSeconds / (free * 60)).clamp(0, 1).toDouble(),
                size: 104,
                color: CaboColors.yellow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(clock(elapsed.isNegative ? Duration.zero : elapsed), style: CaboText.h2),
                    Text('waiting', style: CaboText.muted.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting for ${_riderName(t)}', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text('$free min free waiting, then ${naira(fee)} per minute.', style: CaboText.muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RiderRow(t, subtitle: t.str('pickup_address')),
          const SizedBox(height: 16),
          CaboButton('Start trip', onPressed: () => go(context, '/verify-rider')),
          const SizedBox(height: 10),
          ActionButton(
            left.isNegative || left == Duration.zero ? 'Rider did not show up' : 'No-show available in ${clock(left)}',
            style: CaboButtonStyle.secondary,
            height: 48,
            enabled: left.isNegative || left == Duration.zero,
            onPressed: () async {
              await state.tripAction('cancel', {'reason': 'no_show'});
              if (!context.mounted) return;
              showMessage(context, 'Marked as a no-show.');
              _toHome(context);
            },
          ),
        ],
      ),
    );
  }
}

class ChatWithRiderScreen extends StatelessWidget {
  const ChatWithRiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.chat_bubble_rounded,
      title: 'Rider chat is coming soon',
      message:
          'For now, meet your rider at the pickup point shown in the app. '
          'They are told when you arrive. If you cannot find them, contact Cabo support.',
      primary: 'Back to trip',
      onPrimary: () => back(context),
      secondary: 'Contact support',
      onSecondary: () => go(context, '/help'),
    );
  }
}

class VerifyRiderScreen extends StatefulWidget {
  const VerifyRiderScreen({super.key});

  @override
  State<VerifyRiderScreen> createState() => _VerifyRiderScreenState();
}

class _VerifyRiderScreenState extends State<VerifyRiderScreen> {
  String _pin = '';
  String? _error;

  void _key(String k) {
    setState(() {
      _error = null;
      if (k == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += k;
      }
    });
  }

  Future<void> _start() async {
    if (_pin.length != 4) {
      setState(() => _error = 'Enter all 4 digits.');
      return;
    }
    try {
      await AppScope.read(context).tripAction('start', {'pin': _pin});
    } on ApiException catch (e) {
      if (e.fields['pin'] == null) rethrow;
      if (mounted) {
        setState(() {
          _error = e.fields['pin'];
          _pin = '';
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/trip-in-progress', ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.read(context).trip;
    if (t == null || t.str('status') != 'arrived') return const _NoTrip('Verify rider');
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return CaboScaffold(
      title: 'Verify rider',
      bottom: ActionButton('Start trip', icon: Icons.play_arrow_rounded, onPressed: _start),
      children: [
        Center(child: Avatar(initials(_riderName(t)), size: 80, color: CaboColors.yellowSoft)),
        const SizedBox(height: 10),
        Center(child: Text(_riderName(t), style: CaboText.h1)),
        Center(child: Text('Going to ${_short(t.str('dropoff_address'))}', style: CaboText.muted)),
        const SizedBox(height: 22),
        Center(
          child: Text('Ask the rider for their 4-digit trip PIN', style: CaboText.h3, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 14),
        CodeBoxes(_pin, length: 4),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                _error!,
                style: CaboText.label.copyWith(color: CaboColors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2.4,
          children: [
            for (final k in keys)
              k.isEmpty
                  ? const SizedBox()
                  : InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _key(k),
                      child: Center(
                        child: k == '<'
                            ? const Icon(Icons.backspace_outlined, color: CaboColors.muted, semanticLabel: 'Delete')
                            : Text(k, style: CaboText.h1.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 8),
        Text('The PIN is in the rider\'s app. The trip only starts when it matches.', style: CaboText.muted, textAlign: TextAlign.center),
      ],
    );
  }
}

class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> with _TripWatch {
  @override
  Set<String> get statuses => const {'in_progress'};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = state.trip;
    if (t == null || t.str('status') != 'in_progress') return const _NoTrip('Trip in progress');
    final stops = t.list('stops');
    final next = stops.isNotEmpty ? stops.first : null;
    return MapLayout(
      map: CaboMap(
        route: Routes.trip,
        markers: [
          const MapMarker(Offset(0.62, 0.52), MarkerKind.driver),
          if (stops.isNotEmpty) const MapMarker(Offset(0.78, 0.6), MarkerKind.stop, label: 'Stop'),
          MapMarker(const Offset(0.8, 0.82), MarkerKind.dropoff, label: _short(t.str('dropoff_address'))),
        ],
      ),
      top: _NavBanner(
        next == null ? 'DROP-OFF' : 'NEXT STOP',
        next?.str('address') ?? t.str('dropoff_address'),
        next?.number('lat') ?? t.number('dropoff_lat'),
        next?.number('lng') ?? t.number('dropoff_lng'),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(naira(t.integer('fare_total')), style: CaboText.h1.copyWith(color: CaboColors.yellow)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${t.number('distance_km').toStringAsFixed(1)} km • about ${t.integer('duration_minutes')} min',
                  style: CaboText.muted.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          Text('Dropping off ${_riderName(t)}', style: CaboText.h3),
          const SizedBox(height: 8),
          for (final s in stops) _Stop(CaboColors.blue, 'STOP', s.str('address')),
          _Stop(CaboColors.red, 'DROP-OFF', t.str('dropoff_address')),
          const SizedBox(height: 14),
          Row(
            children: [
              RoundAction(
                Icons.shield_rounded,
                color: CaboColors.blue.withValues(alpha: 0.2),
                iconColor: CaboColors.blue,
                onTap: () => go(context, '/safety'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CaboButton('End trip', style: CaboButtonStyle.green, onPressed: () => go(context, '/end-trip')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EndTripScreen extends StatelessWidget {
  const EndTripScreen({super.key});

  Future<void> _complete(BuildContext context) async {
    final state = AppScope.read(context);
    final ok = await runAction(context, () => state.tripAction('complete'));
    if (!ok || !context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(state.cashToCollect > 0 ? '/collect-payment' : '/trip-summary', ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).trip;
    if (t == null || t.str('status') != 'in_progress') return const _NoTrip('End trip');
    return MapLayout(
      map: const CaboMap(
        route: [Offset(0.7, 0.62), Offset(0.78, 0.72), Offset(0.8, 0.82)],
        markers: [MapMarker(Offset(0.78, 0.74), MarkerKind.driver), MapMarker(Offset(0.8, 0.82), MarkerKind.dropoff)],
      ),
      top: Row(
        children: [RoundAction(Icons.arrow_back_ios_new_rounded, color: CaboColors.deepGreen, size: 46, onTap: () => back(context))],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drop off ${_riderName(t)}', style: CaboText.h2),
          const SizedBox(height: 4),
          Text('Remind the rider to check for their belongings before they get out.', style: CaboText.muted),
          const SizedBox(height: 14),
          InfoRow('Drop-off', _short(t.str('dropoff_address'))),
          InfoRow('Trip fare', naira(t.integer('fare_total')), bold: true),
          InfoRow('Payment', paymentLabels[t.str('payment_method')] ?? humanize(t.str('payment_method'))),
          const SizedBox(height: 16),
          SlideToComplete(label: 'Slide to complete', onComplete: () => _complete(context)),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => _complete(context),
              child: Text('Tap here if sliding is difficult', style: CaboText.label.copyWith(color: CaboColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectPaymentScreen extends StatelessWidget {
  const CollectPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = state.trip;
    if (t == null || t.str('status') != 'completed' || t.str('payment_method') != 'cash') return const _NoTrip('Collect payment');
    final paid = t.str('payment_status') == 'paid';
    return CaboScaffold(
      title: 'Collect payment',
      showBack: false,
      bottom: paid
          ? CaboButton('Continue', onPressed: () => replace(context, '/trip-summary'))
          : ActionButton(
              'Cash collected',
              icon: Icons.check_rounded,
              onPressed: () async {
                await state.tripAction('collect-cash');
                if (context.mounted) replace(context, '/trip-summary');
              },
            ),
      children: [
        const SizedBox(height: 16),
        const Center(child: HeroIllustration(Icons.payments_rounded, size: 150)),
        const SizedBox(height: 16),
        Center(child: Text('Collect from ${_riderName(t)}', style: CaboText.h3)),
        Center(
          child: Text(naira(t.integer('fare_total')), style: CaboText.display.copyWith(fontSize: 56, color: CaboColors.yellow)),
        ),
        Center(child: Text(paid ? 'Cash collected' : 'Cash trip', style: CaboText.muted)),
        const SizedBox(height: 24),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Trip fare', naira(t.integer('fare_total') - t.integer('fare_stops') - t.integer('tolls'))),
              if (t.integer('fare_stops') > 0) InfoRow('Added stops', naira(t.integer('fare_stops'))),
              if (t.integer('tolls') > 0) InfoRow('Tolls', naira(t.integer('tolls'))),
              const Divider(height: 20),
              InfoRow('Amount due', naira(t.integer('fare_total')), bold: true, valueColor: CaboColors.yellow),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cabo\'s commission of ${naira(t.integer('commission'))} on this cash trip is added to your cash balance.',
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).trip;
    if (t == null || t.str('status') != 'completed') return const _NoTrip('Trip complete');
    final rated = t['rider_rating'] != null;
    return CaboScaffold(
      title: 'Trip complete',
      showBack: false,
      bottom: Row(
        children: [
          Expanded(
            child: CaboButton(
              'Done',
              style: rated ? CaboButtonStyle.primary : CaboButtonStyle.secondary,
              onPressed: () => _toHome(context),
            ),
          ),
          if (!rated) ...[
            const SizedBox(width: 12),
            Expanded(flex: 2, child: CaboButton('Rate ${_riderName(t)}', onPressed: () => go(context, '/rate-rider'))),
          ],
        ],
      ),
      children: [
        const SizedBox(height: 12),
        const Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: CaboColors.brightGreen,
            child: Icon(Icons.check_rounded, size: 48, color: CaboColors.onYellow),
          ),
        ),
        const SizedBox(height: 14),
        Center(child: Text('You earned', style: CaboText.muted.copyWith(fontSize: 15))),
        Center(
          child: Text(
            naira(t.integer('driver_earnings') + t.integer('tip')),
            style: CaboText.display.copyWith(color: CaboColors.brightGreen),
          ),
        ),
        if (t.integer('tip') > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Pill('+ ${naira(t.integer('tip'))} tip from ${_riderName(t)}', color: CaboColors.yellow, icon: Icons.favorite_rounded),
          ),
        ],
        const SizedBox(height: 22),
        TripEarningsCard(t),
        const SizedBox(height: 12),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Distance', '${t.number('distance_km').toStringAsFixed(1)} km'),
              InfoRow('Duration', '${t.integer('duration_minutes')} min'),
              InfoRow('Payment', paymentLabels[t.str('payment_method')] ?? humanize(t.str('payment_method'))),
              InfoRow('Route', '${_short(t.str('pickup_address'))} → ${_short(t.str('dropoff_address'))}'),
            ],
          ),
        ),
      ],
    );
  }
}

/// How a trip's fare splits between the host and Cabo.
class TripEarningsCard extends StatelessWidget {
  const TripEarningsCard(this.trip, {super.key});
  final Json trip;

  @override
  Widget build(BuildContext context) {
    final t = trip;
    return CaboCard(
      child: Column(
        children: [
          InfoRow('Fare paid by rider', naira(t.integer('fare_total'))),
          InfoRow('Cabo commission', '− ${naira(t.integer('commission'))}'),
          if (t.integer('tip') > 0) InfoRow('Tip', '+ ${naira(t.integer('tip'))}', valueColor: CaboColors.brightGreen),
          const Divider(height: 20),
          InfoRow('Your earnings', naira(t.integer('driver_earnings') + t.integer('tip')), bold: true),
        ],
      ),
    );
  }
}

class RateRiderScreen extends StatefulWidget {
  const RateRiderScreen({super.key});

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  static const _labels = ['Poor', 'Below average', 'Okay', 'Good', 'Excellent'];
  static const _tags = ['Polite', 'On time', 'Great conversation', 'Respectful of car', 'Clear directions'];
  final _feedback = TextEditingController();
  int stars = 5;
  Set<int> _picked = {};

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = [for (final i in _picked) _tags[i], if (_feedback.text.trim().isNotEmpty) _feedback.text.trim()].join('. ');
    await AppScope.read(context).tripAction('rating', {'rating': stars, if (text.isNotEmpty) 'feedback': text});
    if (!mounted) return;
    showMessage(context, 'Thanks for rating your rider.');
    _toHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.read(context).trip;
    if (t == null || t.str('status') != 'completed') return const _NoTrip('Rate rider');
    return CaboScaffold(
      title: 'Rate rider',
      bottom: ActionButton('Submit', onPressed: _submit),
      children: [
        const SizedBox(height: 20),
        Center(child: Avatar(initials(_riderName(t)), size: 96, color: CaboColors.yellowSoft)),
        const SizedBox(height: 14),
        Center(
          child: Text('How was your trip with ${_riderName(t)}?', style: CaboText.h2, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 48,
                tooltip: '$i stars',
                onPressed: () => setState(() => stars = i),
                icon: Icon(i <= stars ? Icons.star_rounded : Icons.star_outline_rounded, color: CaboColors.yellow),
              ),
          ],
        ),
        Center(
          child: Text(_labels[stars - 1], style: CaboText.h3.copyWith(color: CaboColors.yellow)),
        ),
        const SectionTitle('What went well?'),
        ChipPicker(options: _tags, onChanged: (s) => _picked = s),
        const SizedBox(height: 20),
        CaboField('Feedback (optional)', controller: _feedback, hint: 'Tell us more about this rider', maxLines: 3),
      ],
    );
  }
}

class CancelTripScreen extends StatefulWidget {
  const CancelTripScreen({super.key});

  @override
  State<CancelTripScreen> createState() => _CancelTripScreenState();
}

class _CancelTripScreenState extends State<CancelTripScreen> {
  static const _reasons = [
    ('Rider asked me to cancel', null),
    ('Rider is not at the pickup point', null),
    ('Too many passengers or bags', null),
    ('I feel unsafe', 'Cabo Safety will follow up with you'),
    ('Problem with my vehicle', null),
    ('Other', null),
  ];
  int _reason = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final t = state.trip;
    if (t == null || !const {'accepted', 'arrived'}.contains(t.str('status'))) return const _NoTrip('Cancel trip');
    final rate = state.driver?.number('cancellation_rate') ?? 0;
    return CaboScaffold(
      title: 'Cancel trip',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton(
            'Cancel trip',
            style: CaboButtonStyle.danger,
            onPressed: () async {
              await state.tripAction('cancel', {'reason': _reasons[_reason].$1});
              if (!context.mounted) return;
              showMessage(context, 'Trip cancelled.');
              _toHome(context);
            },
          ),
          const SizedBox(height: 10),
          CaboButton('Keep trip', style: CaboButtonStyle.secondary, height: 48, onPressed: () => back(context)),
        ],
      ),
      children: [
        Text('Why are you cancelling?', style: CaboText.h2),
        const SizedBox(height: 16),
        SingleChoice(initial: _reason, options: _reasons, onChanged: (i) => _reason = i),
        CaboCard(
          color: CaboColors.orange.withValues(alpha: 0.14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: CaboColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cancellations count towards your cancellation rate (now ${rate.toStringAsFixed(1)}%). '
                  'A low rate keeps you eligible for higher tiers and tours.',
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
