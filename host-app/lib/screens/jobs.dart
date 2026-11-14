import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 4. Scheduled jobs (airport shuttles and tours).

typedef _Jobs = ({List<Json> assigned, List<Json> open, List<Json> tours});

Future<_Jobs> _loadJobs(AppState state) async {
  final res = await Future.wait<dynamic>([state.api.get('/driver/jobs/shuttles'), state.api.get('/driver/jobs/tours')]);
  final shuttles = unwrap(res[0]) as Json;
  return (assigned: shuttles.list('assigned'), open: shuttles.list('open'), tours: asJsonList(unwrap(res[1])));
}

bool _isPickup(Json s) => s.str('direction') == 'airport_pickup';
String _shuttleTitle(Json s) => _isPickup(s) ? 'Airport pickup' : 'Airport drop-off';
String _shuttleRoute(Json s) {
  final airport = s.strOrNull('terminal') ?? 'Airport';
  final other = s.str('address').split(',').first;
  return _isPickup(s) ? '$airport → $other' : '$other → $airport';
}

int _guests(Json slot) => slot.list('bookings').fold(0, (sum, b) => sum + b.integer('guests'));

void _openShuttle(BuildContext context, Json s) {
  AppScope.read(context).select(shuttle: s);
  go(context, s['driver_id'] == null ? '/job-detail' : '/airport-pickup');
}

void _openTour(BuildContext context, Json slot) {
  AppScope.read(context).select(tourSlot: slot);
  go(context, '/tour-overview');
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.tour, required this.when, required this.route, required this.payout, required this.tags, this.onTap});
  final bool tour;
  final String when;
  final String route;
  final String? payout;
  final List<String> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(tour ? Icons.tour_rounded : Icons.flight_rounded, color: tour ? CaboColors.blue : CaboColors.yellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(when, style: CaboText.label),
                      Text(route, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (payout != null) Text(payout!, style: CaboText.h3.copyWith(color: CaboColors.yellow)),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [for (final t in tags) Pill(t, color: CaboColors.muted)]),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _shuttleCard(BuildContext context, Json s) => _JobCard(
  tour: false,
  when: fmtDayTime(s.date('pickup_at')),
  route: _shuttleRoute(s),
  payout: naira(s.integer('driver_payout')),
  tags: [
    _shuttleTitle(s),
    if (s.strOrNull('flight_number') != null) s.str('flight_number'),
    plural(s.integer('passengers'), 'passenger'),
    if (s.integer('large_bags') > 0) plural(s.integer('large_bags'), 'large bag'),
    if (s['driver_id'] != null) humanize(s.str('status')),
  ],
  onTap: () => _openShuttle(context, s),
);

Widget _tourCard(BuildContext context, Json slot) => _JobCard(
  tour: true,
  when: fmtDayTime(slot.date('starts_at')),
  route: slot.obj('tour')?.str('title') ?? 'Tour',
  payout: null,
  tags: [
    plural(_guests(slot), 'guest'),
    fmtDuration(slot.obj('tour')?.integer('duration_minutes') ?? 0),
  ],
  onTap: () => _openTour(context, slot),
);

class JobsBoardScreen extends StatelessWidget {
  const JobsBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final shuttlesOn = state.preferences.strings('jobs').contains('shuttles');
    return CaboScaffold(
      title: 'Jobs',
      showBack: false,
      bottomNav: const DriverNav(1),
      actions: [
        IconButton(tooltip: 'My schedule', icon: const Icon(Icons.calendar_month_rounded), onPressed: () => go(context, '/schedule')),
      ],
      children: [
        Loader<_Jobs>(
          load: () => _loadJobs(state),
          builder: (context, jobs, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Your jobs'),
              if (jobs.assigned.isEmpty && jobs.tours.isEmpty)
                const EmptyNotice('You have no airport or tour jobs booked.', icon: Icons.event_available_rounded),
              for (final s in jobs.assigned) _shuttleCard(context, s),
              for (final t in jobs.tours) _tourCard(context, t),
              const SectionTitle('Open airport jobs'),
              if (!shuttlesOn)
                CaboCard(
                  onTap: () => go(context, '/ride-preferences'),
                  child: Row(
                    children: [
                      const IconBadge(Icons.flight_takeoff_rounded),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Turn on airport shuttles in your ride preferences to see open jobs.', style: CaboText.body)),
                      const Icon(Icons.chevron_right, color: CaboColors.muted),
                    ],
                  ),
                )
              else if (jobs.open.isEmpty)
                const EmptyNotice('No open airport jobs for your vehicle right now.', icon: Icons.flight_rounded),
              for (final s in jobs.open) _shuttleCard(context, s),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoJob extends StatelessWidget {
  const _NoJob(this.title, this.message);
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, title),
      body: EmptyNotice(message, icon: Icons.event_busy_rounded, action: 'Open jobs board', onAction: () => replace(context, '/jobs')),
    );
  }
}

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () async {
        if (state.shuttle != null) return state.shuttle;
        final jobs = await _loadJobs(state);
        return jobs.open.firstOrNull ?? jobs.assigned.firstOrNull;
      },
      builder: (context, s, _) {
        if (s == null) return const _NoJob('Job detail', 'There are no airport jobs to show right now.');
        final mine = s['driver_id'] != null;
        return CaboScaffold(
          title: _shuttleTitle(s),
          bottom: mine
              ? CaboButton('Open job', onPressed: () => _openShuttle(context, s))
              : ActionButton(
                  'Accept job • ${naira(s.integer('driver_payout'))}',
                  onPressed: () async {
                    try {
                      await state.api.post('/driver/jobs/shuttles/${s.integer('id')}/claim');
                    } on ApiException catch (e) {
                      if (e.statusCode != 409) rethrow;
                      if (context.mounted) {
                        showMessage(context, e.message, error: true);
                        replace(context, '/jobs');
                      }
                      return;
                    }
                    final jobs = await _loadJobs(state);
                    final claimed = jobs.assigned.where((a) => a.integer('id') == s.integer('id')).firstOrNull;
                    if (claimed != null) state.select(shuttle: claimed);
                    if (context.mounted) {
                      showMessage(context, 'Job accepted. It is in your schedule.');
                      replace(context, claimed == null ? '/jobs' : '/airport-pickup');
                    }
                  },
                ),
          children: [
            Text(naira(s.integer('driver_payout')), style: CaboText.display.copyWith(color: CaboColors.yellow)),
            Text('Fixed payout for this job', style: CaboText.muted),
            const SizedBox(height: 16),
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Pickup time', fmtDayTime(s.date('pickup_at'))),
                  InfoRow('Route', _shuttleRoute(s)),
                  if (s.strOrNull('flight_number') != null)
                    InfoRow(
                      'Flight',
                      [s.str('flight_number'), if (s.date('flight_time') != null) fmtTime(s.date('flight_time'))].join(' • '),
                    ),
                  InfoRow('Vehicle', s.obj('ride_type')?.str('name') ?? ''),
                  InfoRow('Passengers', '${s.integer('passengers')}'),
                  InfoRow('Large bags', '${s.integer('large_bags')}'),
                  InfoRow('Reference', s.str('reference')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isPickup(s)
                  ? 'Meet the guest in the arrivals hall with a name board. The price is fixed, so there is no charge for flight delays.'
                  : 'Collect the guest from their address and take them to the airport in good time for their flight.',
              style: CaboText.muted,
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem(this.time, this.title, this.subtitle, this.pay, this.color, this.onTap);
  final String time;
  final String title;
  final String subtitle;
  final String? pay;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 52, child: Text(time, style: CaboText.label)),
          Expanded(
            child: CaboCard(
              onTap: onTap,
              padding: const EdgeInsets.all(12),
              borderColor: color,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                        Text(subtitle, style: CaboText.muted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (pay != null) Text(pay!, style: CaboText.label.copyWith(color: CaboColors.yellow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<_Jobs>(
      load: () => _loadJobs(state),
      builder: (context, jobs, _) {
        final items = <(DateTime, Widget)>[
          for (final s in jobs.assigned)
            (
              s.date('pickup_at') ?? DateTime.now(),
              _ScheduleItem(
                fmtTime(s.date('pickup_at')),
                _shuttleTitle(s),
                _shuttleRoute(s),
                naira(s.integer('driver_payout')),
                CaboColors.yellow,
                () => _openShuttle(context, s),
              ),
            ),
          for (final t in jobs.tours)
            (
              t.date('starts_at') ?? DateTime.now(),
              _ScheduleItem(
                fmtTime(t.date('starts_at')),
                t.obj('tour')?.str('title') ?? 'Tour',
                '${plural(_guests(t), 'guest')} • ${t.obj('tour')?.str('meeting_point') ?? ''}',
                null,
                CaboColors.blue,
                () => _openTour(context, t),
              ),
            ),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        String? day;
        return CaboScaffold(
          title: 'My schedule',
          children: [
            if (items.isEmpty)
              EmptyNotice(
                'Nothing scheduled. Accepted airport jobs and your tours appear here.',
                icon: Icons.calendar_month_rounded,
                action: 'Open jobs board',
                onAction: () => replace(context, '/jobs'),
              ),
            for (final (at, item) in items) ...[if (fmtDay(at) != day) SectionTitle(day = fmtDay(at)), item],
          ],
        );
      },
    );
  }
}

/// The host's shuttle job in hand: the selected one, or the next assigned.
Future<Json?> _myShuttle(AppState state) async {
  final jobs = await _loadJobs(state);
  final id = state.shuttle?.integer('id');
  final s =
      jobs.assigned.where((a) => a.integer('id') == id).firstOrNull ??
      (state.shuttle?['driver_id'] == null ? jobs.assigned.firstOrNull : state.shuttle);
  if (s != null) state.shuttle = s;
  return s;
}

class AirportPickupScreen extends StatelessWidget {
  const AirportPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _myShuttle(state),
      builder: (context, s, reload) {
        if (s == null) return const _NoJob('Airport job', 'You have no airport job in hand.');
        final status = s.str('status');
        final rider = s.obj('rider');
        final phone = rider?.strOrNull('phone');
        final name = [rider?.strOrNull('first_name'), rider?.strOrNull('last_name')].whereType<String>().join(' ');
        Future<void> move(String to, String done) async {
          await state.api.patch('/driver/jobs/shuttles/${s.integer('id')}', {'status': to});
          state.shuttle = {...s, 'status': to};
          if (!context.mounted) return;
          showMessage(context, done);
          if (to == 'completed') {
            replace(context, '/jobs');
          } else {
            await reload();
          }
        }

        return CaboScaffold(
          title: _shuttleTitle(s),
          bottom: switch (status) {
            'driver_assigned' => ActionButton(
              'Start job',
              icon: Icons.play_arrow_rounded,
              onPressed: () => move('in_progress', 'Job started.'),
            ),
            'in_progress' => ActionButton(
              'Complete job • ${naira(s.integer('driver_payout'))}',
              style: CaboButtonStyle.green,
              onPressed: () => move('completed', '${naira(s.integer('driver_payout'))} added to your earnings.'),
            ),
            _ => CaboButton('Back to jobs', style: CaboButtonStyle.secondary, onPressed: () => replace(context, '/jobs')),
          },
          children: [
            Row(
              children: [
                Pill(humanize(status), color: status == 'in_progress' ? CaboColors.brightGreen : CaboColors.yellow),
                const SizedBox(width: 8),
                if (s.strOrNull('flight_number') != null)
                  Pill(
                    '${s.str('flight_number')} • ${humanize(s.str('flight_status'))}',
                    icon: Icons.flight_rounded,
                    color: CaboColors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            CaboCard(
              child: Row(
                children: [
                  Avatar(initials(name), size: 50, color: CaboColors.yellowSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isEmpty ? 'Guest' : name, style: CaboText.h3),
                        Text(
                          '${plural(s.integer('passengers'), 'passenger')} • ${plural(s.integer('large_bags') + s.integer('small_bags'), 'bag')}',
                          style: CaboText.muted,
                        ),
                      ],
                    ),
                  ),
                  if (phone != null) RoundAction(Icons.call_rounded, onTap: () => callNumber(context, phone)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Pickup time', fmtDayTime(s.date('pickup_at'))),
                  InfoRow('Airport', [s.str('airport'), ?s.strOrNull('terminal')].join(' • ')),
                  if (s.date('flight_time') != null)
                    InfoRow(_isPickup(s) ? 'Flight lands' : 'Flight departs', fmtDayTime(s.date('flight_time'))),
                  InfoRow(_isPickup(s) ? 'Take guest to' : 'Collect guest from', s.str('address')),
                  if (s.strOrNull('meeting_point') != null) InfoRow('Meeting point', s.str('meeting_point')),
                  if (s.strOrNull('notes') != null) InfoRow('Notes', s.str('notes')),
                  InfoRow('Your payout', naira(s.integer('driver_payout')), bold: true, valueColor: CaboColors.yellow),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isPickup(s))
              MenuTile(
                icon: Icons.badge_rounded,
                title: 'Show name board',
                subtitle: 'Hold it up in the arrivals hall',
                onTap: () => go(context, '/name-board'),
              ),
            if (s.numberOrNull('lat') != null)
              MenuTile(
                icon: Icons.navigation_rounded,
                title: 'Navigate to ${s.str('address').split(',').first}',
                onTap: () => openNavigation(context, s.number('lat'), s.number('lng')),
              ),
            MenuTile(
              icon: Icons.flight_rounded,
              title: 'Navigate to the airport',
              // Murtala Muhammed International Airport.
              onTap: () => openNavigation(context, 6.5774, 3.3212),
            ),
          ],
        );
      },
    );
  }
}

class NameBoardScreen extends StatelessWidget {
  const NameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _myShuttle(state),
      builder: (context, s, _) {
        final rider = s?.obj('rider');
        final name =
            s?.strOrNull('name_board') ?? [rider?.strOrNull('first_name'), rider?.strOrNull('last_name')].whereType<String>().join(' ');
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CaboLogo(size: 44, hostLabel: false),
                        const SizedBox(height: 28),
                        FittedBox(
                          child: Text(
                            name.isEmpty ? 'Cabo guest' : name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: CaboText.display.copyWith(color: CaboColors.onYellow, fontSize: 64),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (s?.strOrNull('flight_number') != null)
                          Text('Flight ${s!.str('flight_number')}', style: CaboText.h2.copyWith(color: CaboColors.green)),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: CaboColors.onYellow),
                    onPressed: () => back(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The tour slot in hand, refreshed: the selected one, or the next upcoming.
Future<Json?> _mySlot(AppState state) async {
  final tours = (await _loadJobs(state)).tours;
  final id = state.tourSlot?.integer('id');
  final slot = tours.where((t) => t.integer('id') == id).firstOrNull ?? tours.firstOrNull;
  if (slot != null) state.tourSlot = slot;
  return slot;
}

class _GuestRow extends StatelessWidget {
  const _GuestRow(this.booking, {this.onCheckIn});
  final Json booking;
  final Future<void> Function()? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final rider = b.obj('rider');
    final name = [rider?.strOrNull('first_name'), rider?.strOrNull('last_name')].whereType<String>().join(' ');
    final status = b.str('status');
    final phone = rider?.strOrNull('phone');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(initials(name), size: 42, color: CaboColors.yellowSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Guest' : name, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                  Text('${plural(b.integer('guests'), 'guest')} • ${b.str('reference')}', style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (phone != null)
              IconButton(
                tooltip: 'Call $name',
                icon: const Icon(Icons.call_rounded, color: CaboColors.muted),
                onPressed: () => callNumber(context, phone),
              ),
            if (status == 'confirmed' && onCheckIn != null)
              ActionButton('Check in', height: 38, expand: false, onPressed: onCheckIn!)
            else
              Pill(
                status == 'confirmed' ? 'Not arrived' : humanize(status),
                color: status == 'confirmed' ? CaboColors.muted : CaboColors.brightGreen,
                icon: status == 'confirmed' ? null : Icons.check,
              ),
          ],
        ),
      ),
    );
  }
}

class TourOverviewScreen extends StatelessWidget {
  const TourOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _mySlot(state),
      builder: (context, slot, _) {
        if (slot == null) return const _NoJob('Tour job', 'You have no tours to guide right now.');
        final tour = slot.obj('tour');
        final bookings = slot.list('bookings');
        return CaboScaffold(
          title: 'Tour job',
          bottom: CaboButton('Check in guests', icon: Icons.how_to_reg_rounded, onPressed: () => go(context, '/guest-check-in')),
          children: [
            Text(tour?.str('title') ?? 'Tour', style: CaboText.h1),
            const SizedBox(height: 4),
            Text(fmtDayTime(slot.date('starts_at')), style: CaboText.h3.copyWith(color: CaboColors.yellow)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: StatTile('Guests', '${_guests(slot)}', icon: Icons.groups_rounded)),
                const SizedBox(width: 10),
                Expanded(child: StatTile('Capacity', '${slot.integer('capacity')}', icon: Icons.event_seat_rounded)),
                const SizedBox(width: 10),
                Expanded(child: StatTile('Length', fmtDuration(tour?.integer('duration_minutes') ?? 0), icon: Icons.schedule_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            MenuTile(icon: Icons.place_rounded, title: 'Meeting point', subtitle: tour?.str('meeting_point') ?? 'See the tour details'),
            const SectionTitle('Guest list'),
            if (bookings.isEmpty) const EmptyNotice('No guests have booked this tour yet.', icon: Icons.groups_rounded),
            for (final b in bookings) _GuestRow(b),
          ],
        );
      },
    );
  }
}

class GuestCheckInScreen extends StatefulWidget {
  const GuestCheckInScreen({super.key});

  @override
  State<GuestCheckInScreen> createState() => _GuestCheckInScreenState();
}

class _GuestCheckInScreenState extends State<GuestCheckInScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Checks a ticket in by its code. Accepts the code as printed in the guest's QR ("cabo:ticket:…").
  Future<void> _checkIn(String token, Future<void> Function() reload) async {
    final state = AppScope.read(context);
    try {
      final res =
          unwrap(await state.api.post('/driver/jobs/tours/check-in', {'qr_token': token.trim().replaceFirst('cabo:ticket:', '')})) as Json;
      _code.clear();
      if (mounted) {
        setState(() => _error = null);
        showMessage(context, '${res.obj('rider')?.str('first_name') ?? 'Guest'} checked in (${plural(res.integer('guests'), 'guest')}).');
      }
      await reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fields['qr_token'] ?? e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _mySlot(state),
      builder: (context, slot, reload) {
        if (slot == null) return const _NoJob('Guest check-in', 'You have no tours to guide right now.');
        final bookings = slot.list('bookings');
        final arrived = bookings.where((b) => b.str('status') != 'confirmed').length;
        return CaboScaffold(
          title: 'Guest check-in',
          bottom: CaboButton('Start tour', onPressed: () => replace(context, '/tour-in-progress')),
          children: [
            Text(slot.obj('tour')?.str('title') ?? 'Tour', style: CaboText.h2),
            Text('$arrived of ${bookings.length} bookings checked in', style: CaboText.muted),
            const SizedBox(height: 14),
            for (final b in bookings) _GuestRow(b, onCheckIn: () => _checkIn(b.str('qr_token'), reload)),
            const SectionTitle('Enter a ticket code'),
            Text('Type the code shown under the QR on the guest\'s ticket.', style: CaboText.muted),
            const SizedBox(height: 8),
            CaboField('Ticket code', controller: _code, icon: Icons.qr_code_2_rounded, error: _error),
            ActionButton(
              'Check in ticket',
              style: CaboButtonStyle.secondary,
              onPressed: () async {
                if (_code.text.trim().isEmpty) {
                  setState(() => _error = 'Enter the ticket code.');
                  return;
                }
                await _checkIn(_code.text, reload);
              },
            ),
          ],
        );
      },
    );
  }
}

class TourInProgressScreen extends StatelessWidget {
  const TourInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _mySlot(state),
      builder: (context, slot, reload) {
        if (slot == null) return const _NoJob('Tour in progress', 'You have no tours to guide right now.');
        final tour = slot.obj('tour');
        final bookings = slot.list('bookings');
        final onTour = bookings.where((b) => b.str('status') == 'checked_in').fold(0, (sum, b) => sum + b.integer('guests'));
        return CaboScaffold(
          title: 'Tour in progress',
          bottom: ActionButton(
            'Complete tour',
            style: CaboButtonStyle.green,
            onPressed: () async {
              final done = unwrap(await state.api.post('/driver/jobs/tours/${slot.integer('id')}/complete')) as Json;
              state.tourSlot = {...slot, 'bookings': done.list('bookings')};
              if (context.mounted) replace(context, '/tour-completed');
            },
          ),
          children: [
            Text(tour?.str('title') ?? 'Tour', style: CaboText.h1),
            Text(
              'Started ${fmtTime(slot.date('starts_at'))} • ${fmtDuration(tour?.integer('duration_minutes') ?? 0)}',
              style: CaboText.muted,
            ),
            const SizedBox(height: 14),
            CaboCard(
              color: CaboColors.brightGreen.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, color: CaboColors.brightGreen),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${plural(onTour, 'guest')} on tour with you', style: CaboText.h3)),
                  TextButton(onPressed: () => go(context, '/guest-check-in'), child: const Text('Check in more')),
                ],
              ),
            ),
            const SectionTitle('Guests'),
            for (final b in bookings) _GuestRow(b),
            const SizedBox(height: 4),
            MenuTile(
              icon: Icons.shield_rounded,
              title: 'Safety toolkit',
              subtitle: 'Emergency help and incident reports',
              color: CaboColors.blue,
              onTap: () => go(context, '/safety'),
            ),
          ],
        );
      },
    );
  }
}

class TourCompletedScreen extends StatelessWidget {
  const TourCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final slot = AppScope.read(context).tourSlot;
    final bookings = slot?.list('bookings') ?? const <Json>[];
    final completed = bookings.where((b) => b.str('status') == 'completed').toList();
    final missed = bookings.where((b) => b.str('status') == 'confirmed').length;
    return CaboScaffold(
      title: 'Tour completed',
      showBack: false,
      bottom: CaboButton('Back to jobs', onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/jobs', (_) => false)),
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
        Center(
          child: Text(slot?.obj('tour')?.str('title') ?? 'Tour', style: CaboText.h2, textAlign: TextAlign.center),
        ),
        Center(child: Text('Well done. Your guests can now leave a review.', style: CaboText.muted)),
        const SizedBox(height: 20),
        CaboCard(
          child: Column(
            children: [
              InfoRow('Guests who took the tour', '${completed.fold(0, (sum, b) => sum + b.integer('guests'))}'),
              InfoRow('Bookings completed', '${completed.length}'),
              if (missed > 0) InfoRow('Did not arrive', plural(missed, 'booking')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Your pay for guiding is arranged with the tour partner and is not shown in this app yet.', style: CaboText.muted),
      ],
    );
  }
}
