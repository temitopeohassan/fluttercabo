import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 4. Cabo Shuttle. Fixed-price airport pickups and drop-offs.

const _airport = 'Murtala Muhammed International (LOS)';

class CountStepper extends StatefulWidget {
  const CountStepper(
    this.label,
    this.initial, {
    super.key,
    this.icon,
    this.subtitle,
    this.onChanged,
    this.min = 0,
    this.max = 10,
  });
  final String label;
  final int initial;
  final IconData? icon;
  final String? subtitle;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  State<CountStepper> createState() => _CountStepperState();
}

class _CountStepperState extends State<CountStepper> {
  late int value = widget.initial;

  void _set(int v) {
    final next = v.clamp(widget.min, widget.max);
    if (next == value) return;
    setState(() => value = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback onTap) => Material(
      color: CaboColors.greenSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: CaboColors.green, size: 20),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            IconBadge(widget.icon!, size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.subtitle != null)
                  Text(widget.subtitle!, style: CaboText.muted),
              ],
            ),
          ),
          btn(
            Icons.remove_rounded,
            'Fewer ${widget.label.toLowerCase()}',
            () => _set(value - 1),
          ),
          SizedBox(
            width: 40,
            child: Center(child: Text('$value', style: CaboText.h2)),
          ),
          btn(
            Icons.add_rounded,
            'More ${widget.label.toLowerCase()}',
            () => _set(value + 1),
          ),
        ],
      ),
    );
  }
}

bool _isPickup(Json booking) =>
    booking.str('direction', 'airport_pickup') == 'airport_pickup';

/// The flight's date and time as entered on the first step.
DateTime? _flightTime(Json draft) => draft['flight_time'] as DateTime?;

class ShuttleScreen extends StatefulWidget {
  const ShuttleScreen({super.key});

  @override
  State<ShuttleScreen> createState() => _ShuttleScreenState();
}

class _ShuttleScreenState extends State<ShuttleScreen> {
  final _flight = TextEditingController();
  Map<String, String> _errors = {};
  bool _started = false;

  Json get _draft => AppScope.read(context).shuttleDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _draft.putIfAbsent('direction', () => 'airport_pickup');
    _flight.text = _draft.str('flight_number');
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _flightTime(_draft) ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null) return;
    setState(
      () => _draft['flight_time'] = DateTime(
        date.year,
        date.month,
        date.day,
        current.hour,
        current.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final current =
        _flightTime(_draft) ?? DateTime.now().add(const Duration(days: 1));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(
      () => _draft['flight_time'] = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _continue() {
    final flight = _flight.text.replaceAll(' ', '').toUpperCase();
    final when = _flightTime(_draft);
    final errors = <String, String>{
      if (!RegExp(r'^[A-Z0-9]{2}\d{1,4}$').hasMatch(flight))
        'flight': 'Enter the flight number, e.g. BA75.',
      if (when == null)
        'time': 'Choose the flight date and time.'
      else if (when.isBefore(DateTime.now().add(const Duration(hours: 3))))
        'time': 'Book at least 3 hours before the flight.',
      if (_draft['place'] == null) 'place': 'Choose your hotel or address.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    _draft['flight_number'] = flight;
    go(context, '/shuttle-flight');
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _isPickup(_draft);
    final when = _flightTime(_draft);
    final place = _draft['place'] as Json?;
    return CaboScaffold(
      title: 'Airport shuttle',
      bottom: CaboButton('Continue', onPressed: _continue),
      children: [
        ChipPicker(
          options: const ['Pickup from airport', 'Drop-off at airport'],
          initial: {pickup ? 0 : 1},
          single: true,
          onChanged: (s) => setState(
            () => _draft['direction'] = s.first == 0
                ? 'airport_pickup'
                : 'airport_dropoff',
          ),
        ),
        const SizedBox(height: 18),
        const CaboField(
          'Airport',
          value: _airport,
          icon: Icons.flight_rounded,
          readOnly: true,
        ),
        CaboField(
          'Flight number',
          controller: _flight,
          hint: 'e.g. BA75',
          icon: Icons.confirmation_number_outlined,
          error: _errors['flight'],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField(
                'Date',
                key: ValueKey('date-$when'),
                value: when == null ? null : fmtDay(when),
                hint: 'Choose',
                icon: Icons.event_rounded,
                readOnly: true,
                onTap: _pickDate,
                error: _errors['time'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField(
                pickup ? 'Lands' : 'Departs',
                key: ValueKey('time-$when'),
                value: when == null ? null : fmtTime(when),
                hint: 'Choose',
                icon: pickup
                    ? Icons.flight_land_rounded
                    : Icons.flight_takeoff_rounded,
                readOnly: true,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        CaboField(
          pickup ? 'Drop-off' : 'Pickup',
          key: ValueKey('place-${place?.str('address')}'),
          value: place?.str('address'),
          hint: 'Hotel or address',
          icon: Icons.location_on_outlined,
          readOnly: true,
          error: _errors['place'],
          onTap: () async {
            final chosen = await pickPlace(
              context,
              title: pickup
                  ? 'Where are you staying?'
                  : 'Where do we pick you up?',
              allowCurrent: !pickup,
            );
            if (chosen != null) setState(() => _draft['place'] = chosen);
          },
        ),
        CaboCard(
          color: CaboColors.greenSoft,
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: CaboColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fixed price, no surge. Book at least 3 hours before your flight.',
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

class ShuttleFlightScreen extends StatelessWidget {
  const ShuttleFlightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final draft = state.shuttleDraft;
    final when = _flightTime(draft);
    if (when == null) return const _NoDraft();
    final pickup = _isPickup(draft);
    final freeWait =
        state.config.obj('waiting')?.integer('airport_free_minutes', 60) ?? 60;
    final collect = pickup
        ? when.add(const Duration(minutes: 45))
        : when.subtract(const Duration(hours: 4));
    return CaboScaffold(
      title: 'Your flight',
      bottom: CaboButton(
        'This is my flight',
        onPressed: () => go(context, '/shuttle-vehicle'),
      ),
      children: [
        CaboCard(
          color: const Color(0xFFE6F0FB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(draft.str('flight_number'), style: CaboText.h2),
                  const Spacer(),
                  Text(
                    pickup ? 'Arriving in Lagos' : 'Leaving Lagos',
                    style: CaboText.label,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickup ? 'Lands' : 'Departs', style: CaboText.muted),
                      Text(fmtTime(when), style: CaboText.h1),
                      Text(fmtDay(when), style: CaboText.muted),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(color: CaboColors.blue, indent: 10),
                        ),
                        Transform.rotate(
                          angle: 1.5708,
                          child: const Icon(
                            Icons.flight,
                            color: CaboColors.blue,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: CaboColors.blue, endIndent: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Cabo pickup', style: CaboText.muted),
                      Text(fmtTime(collect), style: CaboText.h1),
                      Text(fmtDay(collect), style: CaboText.muted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (icon, title, body) in [
          if (pickup) ...[
            (
              Icons.radar_rounded,
              'We watch your flight',
              'If you land early or late, Cabo moves your pickup time and tells your driver.',
            ),
            (
              Icons.hourglass_bottom_rounded,
              '$freeWait minutes free waiting',
              'Counted from when you land, for immigration and bags.',
            ),
            (
              Icons.badge_rounded,
              'Name board at arrivals',
              'Your driver holds a Cabo board with your name in the arrivals hall.',
            ),
          ] else ...[
            (
              Icons.schedule_rounded,
              'Picked up 4 hours before departure',
              'Enough time for Lagos traffic, check-in and security.',
            ),
            (
              Icons.luggage_rounded,
              'Help with your bags',
              'Your driver loads and unloads your luggage.',
            ),
          ],
        ])
          MenuTile(icon: icon, title: title, subtitle: body),
      ],
    );
  }
}

class _NoDraft extends StatelessWidget {
  const _NoDraft();

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Airport shuttle',
      children: [
        EmptyNotice(
          'Start by entering your flight details.',
          icon: Icons.flight_rounded,
          action: 'Enter flight details',
          onAction: () => replace(context, '/shuttle'),
        ),
      ],
    );
  }
}

class ShuttleVehicleScreen extends StatefulWidget {
  const ShuttleVehicleScreen({super.key});

  @override
  State<ShuttleVehicleScreen> createState() => _ShuttleVehicleScreenState();
}

class _ShuttleVehicleScreenState extends State<ShuttleVehicleScreen> {
  List<Json>? _quotes;
  String? _error;
  int _run = 0;
  bool _started = false;

  Json get _draft => AppScope.read(context).shuttleDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _draft.putIfAbsent('passengers', () => 1);
    _draft.putIfAbsent('large_bags', () => 1);
    _draft.putIfAbsent('small_bags', () => 0);
    if (_draft['place'] != null) _quote();
  }

  Future<void> _quote() async {
    final run = ++_run;
    final place = _draft['place'] as Json;
    try {
      final quotes = asJsonList(
        unwrap(
          await AppScope.read(context).api.post('/rider/shuttles/quote', {
            'direction': _draft.str('direction'),
            'lat': place.number('lat'),
            'lng': place.number('lng'),
            'passengers': _draft.integer('passengers', 1),
            'large_bags': _draft.integer('large_bags'),
          }),
        ),
      );
      if (!mounted || run != _run) return;
      setState(() {
        _quotes = quotes;
        _error = null;
        if (!quotes.any((q) => q.str('ride_type') == _draft.str('ride_type'))) {
          _draft['ride_type'] = quotes.isEmpty
              ? null
              : quotes.first.str('ride_type');
        }
      });
    } catch (e) {
      if (mounted && run == _run) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draft['place'] == null) return const _NoDraft();
    final state = AppScope.read(context);
    Json? chosen;
    for (final q in _quotes ?? const <Json>[]) {
      if (q.str('ride_type') == _draft.str('ride_type')) chosen = q;
    }
    return CaboScaffold(
      title: 'Vehicle and luggage',
      bottom: CaboButton(
        chosen == null
            ? 'Continue'
            : 'Continue • ${naira(chosen.integer('price'))}',
        onPressed: chosen == null
            ? null
            : () {
                _draft['price'] = chosen!.integer('price');
                _draft['ride_name'] = chosen.str('name');
                go(context, '/shuttle-review');
              },
      ),
      children: [
        CountStepper(
          'Passengers',
          _draft.integer('passengers', 1),
          icon: Icons.people_alt_rounded,
          min: 1,
          max: 7,
          onChanged: (v) {
            _draft['passengers'] = v;
            _quote();
          },
        ),
        CountStepper(
          'Large bags',
          _draft.integer('large_bags'),
          icon: Icons.luggage_rounded,
          subtitle: 'Checked suitcases',
          onChanged: (v) => _draft['large_bags'] = v,
        ),
        CountStepper(
          'Small bags',
          _draft.integer('small_bags'),
          icon: Icons.backpack_rounded,
          subtitle: 'Carry-on',
          onChanged: (v) => _draft['small_bags'] = v,
        ),
        const SectionTitle('Vehicle class'),
        if (_error != null) ErrorNotice(_error!, onRetry: _quote),
        if (_error == null && _quotes == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: CaboColors.green),
            ),
          ),
        for (final q in _quotes ?? const <Json>[])
          SelectTile(
            icon: Icons.directions_car_filled_rounded,
            title: q.str('name'),
            subtitle: 'Up to ${plural(q.integer('seats'), 'passenger')}',
            selected: _draft.str('ride_type') == q.str('ride_type'),
            onTap: () =>
                setState(() => _draft['ride_type'] = q.str('ride_type')),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(naira(q.integer('price')), style: CaboText.h3),
                if (state.homePrice(q.integer('price')).isNotEmpty)
                  Text(
                    state.homePrice(q.integer('price')),
                    style: CaboText.label,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class ShuttleReviewScreen extends StatefulWidget {
  const ShuttleReviewScreen({super.key});

  @override
  State<ShuttleReviewScreen> createState() => _ShuttleReviewScreenState();
}

class _ShuttleReviewScreenState extends State<ShuttleReviewScreen> {
  static const _methods = ['card', 'bank_transfer', 'wallet'];
  int _method = 0;

  Future<void> _pay() async {
    final state = AppScope.read(context);
    final d = state.shuttleDraft;
    final place = d['place'] as Json;
    final booking = unwrap(
      await state.api.post('/rider/shuttles', {
        'direction': d.str('direction'),
        'lat': place.number('lat'),
        'lng': place.number('lng'),
        'address': place.str('address'),
        'passengers': d.integer('passengers', 1),
        'large_bags': d.integer('large_bags'),
        'small_bags': d.integer('small_bags'),
        'ride_type': d.str('ride_type'),
        'flight_number': d.str('flight_number'),
        'flight_time': _flightTime(d)!.toUtc().toIso8601String(),
        'payment_method': _methods[_method],
      }),
    ) as Json;
    state.shuttleDraft = {};
    state.select(shuttle: booking);
    state.refreshRider().catchError((_) {});
    if (mounted)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/shuttle-confirmed',
        (r) => r.settings.name == '/home',
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final d = state.shuttleDraft;
    if (d['place'] == null || d['price'] == null) return const _NoDraft();
    final pickup = _isPickup(d);
    final place = d['place'] as Json;
    final price = d.integer('price');
    final balance = state.rider?.integer('wallet_balance') ?? 0;
    final when = _flightTime(d)!;
    return CaboScaffold(
      title: 'Review and pay',
      bottom: ActionButton(
        'Pay ${naira(price)}',
        busyLabel: 'Booking…',
        onPressed: _pay,
      ),
      children: [
        CaboCard(
          child: Column(
            children: [
              InfoRow(pickup ? 'Pickup' : 'Drop-off', 'MMIA, Lagos airport'),
              InfoRow(
                'Flight',
                '${d.str('flight_number')} • ${pickup ? 'lands' : 'departs'} ${fmtDayTime(when)}',
              ),
              InfoRow(pickup ? 'Drop-off' : 'Pickup', place.str('name')),
              InfoRow(
                'Vehicle',
                '${d.str('ride_name')} • ${plural(d.integer('passengers', 1), 'passenger')}',
              ),
              InfoRow(
                'Luggage',
                '${d.integer('large_bags')} large, ${d.integer('small_bags')} small',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Fixed fare', naira(price), bold: true),
              if (state.homePrice(price).isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(state.homePrice(price), style: CaboText.label),
                ),
            ],
          ),
        ),
        const SectionTitle('Pay with'),
        SingleChoice(
          initial: _method,
          onChanged: (i) => _method = i,
          icons: const [
            Icons.credit_card_rounded,
            Icons.account_balance_rounded,
            Icons.account_balance_wallet_rounded,
          ],
          options: [
            ('Card', null),
            ('Bank transfer', 'Pay to a virtual account'),
            (
              'Cabo Wallet',
              'Balance ${naira(balance)}${balance < price ? ' • not enough' : ''}',
            ),
          ],
        ),
        Text(
          'Cash is not accepted for shuttles. Free cancellation up to 12 hours before pickup.',
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class ShuttleConfirmedScreen extends StatelessWidget {
  const ShuttleConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = AppScope.read(context).shuttle;
    if (b == null) return const _NoDraft();
    final pickup = _isPickup(b);
    return StateScreen(
      icon: Icons.check_circle_rounded,
      title: pickup ? 'Airport pickup booked' : 'Airport drop-off booked',
      message:
          '${fmtDayTime(b.date('pickup_at'))}, ${pickup ? 'from the airport to' : 'to the airport from'} '
          '${b.str('address')}. We assign your driver before pickup and tell you in the app.',
      primary: 'View booking',
      onPrimary: () => replace(context, '/shuttle-assigned'),
      secondary: 'Back to home',
      onSecondary: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false),
      extra: CaboCard(
        color: CaboColors.surface,
        child: Column(
          children: [
            InfoRow('Booking', b.str('reference')),
            InfoRow(
              'Paid',
              '${naira(b.integer('price'))} • ${paymentLabels[b.str('payment_method')] ?? ''}',
            ),
            InfoRow('Flight', b.str('flight_number')),
          ],
        ),
      ),
    );
  }
}

class ShuttleAssignedScreen extends StatelessWidget {
  const ShuttleAssignedScreen({super.key});

  Future<Json> _load(AppState state) async {
    var id = state.shuttle?.integer('id');
    if (id == null || id == 0) {
      // Opened without a selection: show the next upcoming shuttle.
      final list = (await state.api.get('/rider/shuttles') as Json).list(
        'data',
      );
      final upcoming = list.where(
        (s) => {
          'confirmed',
          'driver_assigned',
          'in_progress',
        }.contains(s.str('status')),
      );
      if (upcoming.isEmpty)
        throw ApiException('You have no airport shuttle booked.');
      id = upcoming.last.integer('id');
    }
    return unwrap(await state.api.get('/rider/shuttles/$id')) as Json;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final freeWait =
        state.config.obj('waiting')?.integer('airport_free_minutes', 60) ?? 60;
    return Loader<Json>(
      load: () => _load(state),
      builder: (context, b, reload) {
        final pickup = _isPickup(b);
        final driver = b.obj('driver');
        final status = b.str('status');
        final open = status == 'confirmed' || status == 'driver_assigned';
        final refundable =
            (b.date('pickup_at') ?? DateTime.now())
                .difference(DateTime.now())
                .inHours >=
            12;
        return CaboScaffold(
          title: pickup ? 'Airport pickup' : 'Airport drop-off',
          bottom: open
              ? ActionButton(
                  'Cancel booking',
                  style: CaboButtonStyle.secondary,
                  busyLabel: 'Cancelling…',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel this booking?'),
                        content: Text(
                          refundable
                              ? 'You will get a full refund of ${naira(b.integer('price'))}.'
                              : 'Pickup is less than 12 hours away, so there is no refund.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Keep booking'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Cancel booking'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await state.api.post(
                      '/rider/shuttles/${b.integer('id')}/cancel',
                    );
                    if (context.mounted)
                      showMessage(context, 'Booking cancelled.');
                    await reload();
                  },
                )
              : null,
          children: [
            CaboCard(
              color: status == 'cancelled'
                  ? CaboColors.yellowSoft
                  : CaboColors.greenSoft,
              child: Row(
                children: [
                  Icon(
                    status == 'cancelled'
                        ? Icons.cancel_rounded
                        : Icons.verified_rounded,
                    color: status == 'cancelled'
                        ? CaboColors.orange
                        : CaboColors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      switch (status) {
                        'confirmed' =>
                          'Booked. We will assign your driver before pickup.',
                        'driver_assigned' =>
                          'Driver assigned for ${fmtDayTime(b.date('pickup_at'))}.',
                        'in_progress' => 'Your driver is on the job now.',
                        'completed' =>
                          'Completed on ${fmtDay(b.date('pickup_at'))}.',
                        _ => 'This booking was cancelled.',
                      },
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (driver != null)
              DriverCard({
                'driver': driver,
                'vehicle': driver.obj('active_vehicle'),
              }, actions: false),
            const SectionTitle('Trip'),
            CaboCard(
              child: Column(
                children: [
                  InfoRow(
                    'Flight',
                    '${b.str('flight_number')} • ${humanize(b.str('flight_status'))}',
                  ),
                  InfoRow(
                    pickup ? 'Lands' : 'Departs',
                    fmtDayTime(b.date('flight_time')),
                  ),
                  InfoRow('Pickup time', fmtDayTime(b.date('pickup_at'))),
                  InfoRow(pickup ? 'Drop-off' : 'Pickup', b.str('address')),
                  InfoRow('Car', b.obj('ride_type')?.str('name') ?? ''),
                  InfoRow('Paid', naira(b.integer('price')), bold: true),
                ],
              ),
            ),
            if (pickup && b.strOrNull('meeting_point') != null) ...[
              const SectionTitle('Meeting point'),
              CaboCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBadge(Icons.meeting_room_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(b.str('meeting_point'), style: CaboText.body),
                    ),
                  ],
                ),
              ),
            ],
            if (pickup && b.strOrNull('name_board') != null) ...[
              const SectionTitle('Look for this board'),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CaboColors.yellow, width: 3),
                ),
                child: Column(
                  children: [
                    const CaboLogo(size: 30),
                    const SizedBox(height: 10),
                    Text(
                      b.str('name_board'),
                      textAlign: TextAlign.center,
                      style: CaboText.h1.copyWith(letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (pickup) InfoRow('Free waiting', '$freeWait min after landing'),
            InfoRow('Booking', b.str('reference')),
          ],
        );
      },
    );
  }
}
