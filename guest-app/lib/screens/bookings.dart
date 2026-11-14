import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/widgets.dart';

// 9. Bookings and support.

String _short(String address) => address.split(',').first;

class _Booking {
  _Booking(
    this.icon,
    this.color,
    this.title,
    this.sub,
    this.status,
    this.statusColor,
    this.open,
    this.group,
    this.at,
  );
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String status;
  final Color statusColor;
  final VoidCallback open;
  final int group; // 0 active, 1 upcoming, 2 past
  final DateTime at;
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _filter = 0;

  Future<List<_Booking>> _load() async {
    final state = AppScope.read(context);
    void open(String route) =>
        state.navigatorKey.currentState?.pushNamed(route);
    final res = await Future.wait([
      state.api.get('/rider/trips'),
      state.api.get('/rider/shuttles'),
      state.api.get('/rider/tour-bookings'),
    ]);
    final now = DateTime.now();
    final items = <_Booking>[];
    for (final t in (res[0] as Json).list('data')) {
      final status = t.str('status');
      final active = AppState.activeStatuses.contains(status);
      final scheduled = status == 'scheduled';
      final at = t.date(scheduled ? 'scheduled_at' : 'created_at') ?? now;
      items.add(
        _Booking(
          scheduled ? Icons.schedule_rounded : Icons.local_taxi_rounded,
          active || scheduled ? CaboColors.green : CaboColors.muted,
          'Ride to ${_short(t.str('dropoff_address'))}',
          [
            fmtDayTime(at),
            ?t.obj('ride_type')?.strOrNull('name'),
            naira(t.integer('fare_total')),
          ].join(' • '),
          active ? 'Live' : humanize(status),
          active
              ? CaboColors.red
              : status == 'cancelled'
              ? CaboColors.orange
              : CaboColors.muted,
          () {
            if (active) {
              state.trip = t;
              open(AppState.tripRoute(t) ?? '/past-trip');
            } else {
              state.select(pastTrip: t);
              open('/past-trip');
            }
          },
          active
              ? 0
              : scheduled
              ? 1
              : 2,
          at,
        ),
      );
    }
    for (final s in (res[1] as Json).list('data')) {
      final at = s.date('pickup_at') ?? now;
      final status = s.str('status');
      final done = const {'completed', 'cancelled', 'no_show'}.contains(status);
      final pickup = s.str('direction') == 'airport_pickup';
      items.add(
        _Booking(
          pickup ? Icons.flight_land_rounded : Icons.flight_takeoff_rounded,
          done ? CaboColors.muted : CaboColors.orange,
          pickup ? 'Airport pickup' : 'Ride to the airport',
          '${fmtDayTime(at)} • ${s.str('flight_number')}',
          humanize(status),
          done ? CaboColors.muted : CaboColors.green,
          () {
            state.select(shuttle: s);
            open('/shuttle-assigned');
          },
          done ? 2 : 1,
          at,
        ),
      );
    }
    for (final b in (res[2] as Json).list('data')) {
      final at = b.obj('slot')?.date('starts_at') ?? now;
      final status = b.str('status');
      final past =
          at.isBefore(now) ||
          const {
            'completed',
            'cancelled',
            'no_show',
            'refunded',
          }.contains(status);
      final canReview = status == 'completed' && b['review'] == null;
      items.add(
        _Booking(
          Icons.tour_rounded,
          past ? CaboColors.muted : CaboColors.blue,
          b.obj('tour')?.str('title') ?? 'Tour',
          '${fmtDayTime(at)} • ${plural(b.integer('guests'), 'guest')}',
          canReview
              ? 'Review'
              : past
              ? humanize(status)
              : 'Ticket',
          canReview
              ? CaboColors.orange
              : past
              ? CaboColors.muted
              : CaboColors.blue,
          () {
            state.select(tourBooking: b);
            open(canReview ? '/write-review' : '/ticket');
          },
          past ? 2 : 1,
          at,
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'My bookings',
      showBack: false,
      bottomNav: const RiderNav(1),
      children: [
        ChipPicker(
          options: const ['All', 'Upcoming', 'Past'],
          initial: {_filter},
          single: true,
          onChanged: (s) => setState(() => _filter = s.first),
        ),
        Loader<List<_Booking>>(
          load: _load,
          builder: (context, all, _) {
            List<_Booking> of(int group) {
              final list = all.where((b) => b.group == group).toList();
              list.sort(
                (a, b) =>
                    group == 2 ? b.at.compareTo(a.at) : a.at.compareTo(b.at),
              );
              return list;
            }

            final sections = [
              if (_filter != 2) ('Active', of(0)),
              if (_filter != 2) ('Upcoming', of(1)),
              if (_filter != 1) ('Past', of(2)),
            ].where((s) => s.$2.isNotEmpty).toList();
            if (sections.isEmpty) {
              return EmptyNotice(
                'Your rides, airport shuttles and tours appear here.',
                icon: Icons.event_available_rounded,
                action: 'Book a ride',
                onAction: () => go(context, '/where-to'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, list) in sections) ...[
                  SectionTitle(title),
                  for (final b in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CaboCard(
                        onTap: b.open,
                        child: Row(
                          children: [
                            IconBadge(b.icon, color: b.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    style: CaboText.h3.copyWith(fontSize: 15),
                                  ),
                                  Text(
                                    b.sub,
                                    style: CaboText.muted.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Pill(b.status, color: b.statusColor),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The trip chosen from a list, or the most recent one.
Future<Json?> _chosenTrip(AppState state) async {
  if (state.pastTrip != null) return state.pastTrip;
  final all = (await state.api.get('/rider/trips') as Json).list('data');
  return all.isEmpty ? null : all.first;
}

class PastTripScreen extends StatelessWidget {
  const PastTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _chosenTrip(state),
      builder: (context, t, reload) {
        if (t == null) {
          return CaboScaffold(
            title: 'Trip details',
            children: [
              EmptyNotice(
                'You have not taken a ride yet.',
                icon: Icons.local_taxi_rounded,
                action: 'Book a ride',
                onAction: () => go(context, '/where-to'),
              ),
            ],
          );
        }
        final status = t.str('status');
        final scheduled = status == 'scheduled';
        final rating = t['driver_rating'] as int?;
        return CaboScaffold(
          title: 'Trip details',
          bottom: Row(
            children: [
              Expanded(
                child: CaboButton(
                  'Get help',
                  style: CaboButtonStyle.secondary,
                  onPressed: () {
                    state.select(pastTrip: t);
                    go(context, '/report-issue');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: scheduled
                    ? CaboButton(
                        'Cancel ride',
                        style: CaboButtonStyle.danger,
                        onPressed: () async {
                          final ok = await runAction(
                            context,
                            () => state.api.post(
                              '/rider/trips/${t.integer('id')}/cancel',
                              {'reason': 'Plans changed'},
                            ),
                          );
                          if (ok && context.mounted) {
                            state.select(
                              pastTrip: await state.loadTrip(t.integer('id')),
                            );
                            await reload();
                          }
                        },
                      )
                    : CaboButton(
                        'Rebook',
                        onPressed: () {
                          state.resetRide();
                          state.setPickup({
                            'name': _short(t.str('pickup_address')),
                            'address': t.str('pickup_address'),
                            'lat': t.number('pickup_lat'),
                            'lng': t.number('pickup_lng'),
                          });
                          state.setDropoff({
                            'name': _short(t.str('dropoff_address')),
                            'address': t.str('dropoff_address'),
                            'lat': t.number('dropoff_lat'),
                            'lng': t.number('dropoff_lng'),
                          });
                          go(context, '/choose-ride');
                        },
                      ),
              ),
            ],
          ),
          children: [
            const SizedBox(
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: CaboMap(
                  labels: false,
                  route: [
                    Offset(0.5, 0.3),
                    Offset(0.4, 0.55),
                    Offset(0.36, 0.7),
                  ],
                  markers: [
                    MapMarker(Offset(0.5, 0.3), MarkerKind.pickup),
                    MapMarker(Offset(0.36, 0.7), MarkerKind.dropoff),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_short(t.str('pickup_address'))} → ${_short(t.str('dropoff_address'))}',
              style: CaboText.h2,
            ),
            Text(
              [
                fmtDayTime(t.date(scheduled ? 'scheduled_at' : 'created_at')),
                '${t.number('distance_km').toStringAsFixed(1)} km',
                ?t.obj('ride_type')?.strOrNull('name'),
                humanize(status),
              ].join(' • '),
              style: CaboText.muted,
            ),
            const SizedBox(height: 14),
            if (t.obj('driver') != null) ...[
              CaboCard(child: DriverCard(t, actions: false)),
              const SizedBox(height: 12),
            ],
            CaboCard(
              child: Column(
                children: [
                  InfoRow('Fare', naira(t.integer('fare_total'))),
                  if (t.integer('tip') > 0)
                    InfoRow('Tip', naira(t.integer('tip'))),
                  InfoRow(
                    'Payment',
                    paymentLabels[t.str('payment_method')] ??
                        humanize(t.str('payment_method')),
                  ),
                  if (rating != null) InfoRow('Your rating', '★' * rating),
                  if (t.strOrNull('cancellation_reason') != null)
                    InfoRow('Cancelled', t.str('cancellation_reason')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (status == 'completed')
              MenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'Receipt',
                subtitle: t.str('reference'),
                onTap: () {
                  state.select(pastTrip: t);
                  go(context, '/receipt');
                },
              ),
          ],
        );
      },
    );
  }
}

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const _kinds = [
    (
      'lost_item',
      'I lost an item',
      'We will contact the driver for you',
      Icons.backpack_rounded,
    ),
    ('overcharge', 'I was overcharged', null, Icons.payments_rounded),
    (
      'driver_behaviour',
      'Driver behaviour',
      null,
      Icons.sentiment_dissatisfied_rounded,
    ),
    ('refund', 'Request a refund', null, Icons.undo_rounded),
    ('other', 'Something else', null, Icons.help_outline_rounded),
  ];
  final _details = TextEditingController();
  int _kind = 0;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send(Json? trip) async {
    final text = _details.text.trim();
    if (text.length < 5) {
      setState(() => _error = 'Tell us what happened.');
      return;
    }
    setState(() => _error = null);
    final state = AppScope.read(context);
    final ticket = unwrap(
      await state.api.post('/rider/support/tickets', {
        'category': _kinds[_kind].$1,
        'subject': _kinds[_kind].$2,
        'message': text,
        'trip_id': ?trip?.integer('id'),
      }),
    ) as Json;
    state.select(ticket: ticket);
    if (mounted) replace(context, '/support-chat');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () => _chosenTrip(state),
      builder: (context, trip, _) => CaboScaffold(
        title: 'Report an issue',
        bottom: ActionButton('Send to support', onPressed: () => _send(trip)),
        children: [
          if (trip != null)
            Text(
              '${_short(trip.str('pickup_address'))} → ${_short(trip.str('dropoff_address'))} • ${fmtDay(trip.date('created_at'))}',
              style: CaboText.muted,
            ),
          const SectionTitle('What happened?'),
          SingleChoice(
            initial: _kind,
            icons: [for (final k in _kinds) k.$4],
            options: [for (final k in _kinds) (k.$2, k.$3)],
            onChanged: (i) => _kind = i,
          ),
          CaboField(
            'Details',
            controller: _details,
            hint: 'What happened, and when?',
            maxLines: 3,
            error: _error,
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final support = state.config.obj('support');
    final phone = support?.strOrNull('phone');
    final email = support?.strOrNull('email');
    final hours =
        state.config.obj('tours')?.integer('free_cancellation_hours', 24) ?? 24;
    final faqs = [
      (
        'Why do I pay in naira?',
        'All prices in Nigeria are charged in naira. We show an estimate in your home currency '
            'using the day\'s exchange rate. Your bank does the final conversion.',
      ),
      (
        'Can I pay with a foreign card?',
        'Yes. Cabo accepts Visa, Mastercard and Verve cards from Nigeria and abroad, '
            'plus wallet, bank transfer and, for rides, cash.',
      ),
      (
        'What if my flight is delayed?',
        'Give us your flight number when you book an airport pickup. Your driver follows the '
            'flight and waits for you at arrivals with a name board.',
      ),
      (
        'How do refunds for tours work?',
        'Cancel $hours hours or more before the tour starts for a full refund. '
            'Later cancellations are refunded in part, as shown when you cancel.',
      ),
    ];
    return CaboScaffold(
      title: 'Help centre',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            for (final (icon, label, route) in const [
              (
                Icons.local_taxi_rounded,
                'Problem with a ride',
                '/report-issue',
              ),
              (
                Icons.confirmation_number_rounded,
                'My support tickets',
                '/support-tickets',
              ),
              (Icons.shield_rounded, 'Safety centre', '/safety'),
              (Icons.event_available_rounded, 'My bookings', '/bookings'),
            ])
              CaboCard(
                color: CaboColors.surface,
                onTap: () => go(context, route),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: CaboColors.green),
                    Text(
                      label,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SectionTitle('Popular questions'),
        for (final (i, (q, a)) in faqs.indexed)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              tilePadding: EdgeInsets.zero,
              iconColor: CaboColors.green,
              title: Text(
                q,
                style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(a, style: CaboText.muted),
                ),
              ],
            ),
          ),
        if (phone != null)
          MenuTile(
            icon: Icons.call_rounded,
            title: 'Call support',
            subtitle: phone,
            onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
          ),
        if (email != null)
          MenuTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email support',
            subtitle: email,
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
          ),
        const SizedBox(height: 10),
        CaboButton(
          'Message support',
          icon: Icons.support_agent_rounded,
          onPressed: () {
            state.ticket = null;
            go(context, '/support-chat');
          },
        ),
      ],
    );
  }
}

/// A support conversation. Opens the selected ticket, or starts a new one
/// with the first message.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  Json? _ticket;
  List<Json> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _ticket = AppScope.read(context).ticket;
    if (_ticket != null) _refresh();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final state = AppScope.read(context);
    setState(() => _loading = _messages.isEmpty);
    try {
      final t = unwrap(
        await state.api.get('/rider/support/tickets/${_ticket!.integer('id')}'),
      ) as Json;
      if (mounted) {
        setState(() {
          _ticket = t;
          _messages = t.list('messages');
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || _sending) return;
    final state = AppScope.read(context);
    setState(() => _sending = true);
    try {
      if (_ticket == null) {
        final t = unwrap(
          await state.api.post('/rider/support/tickets', {
            'category': 'other',
            'subject': text.length > 60 ? '${text.substring(0, 60)}…' : text,
            'message': text,
          }),
        ) as Json;
        state.select(ticket: t);
        _ticket = t;
      } else {
        await state.api.post(
          '/rider/support/tickets/${_ticket!.integer('id')}/messages',
          {'message': text},
        );
      }
      _input.clear();
      await _refresh();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => back(context),
              )
            : null,
        titleSpacing: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Avatar('CS', size: 40, color: CaboColors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cabo Support', style: CaboText.h3),
                  Text(
                    t == null
                        ? 'New conversation'
                        : '${t.str('reference')} • ${humanize(t.str('status'))}',
                    style: CaboText.muted.copyWith(
                      fontSize: 12,
                      color: CaboColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (t != null)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorNotice(_error!, onRetry: _refresh)
                : _messages.isEmpty
                ? const EmptyNotice(
                    'Tell us how we can help. Our team replies here and you will get a notification.',
                    icon: Icons.support_agent_rounded,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final m in _messages)
                        ChatBubble(
                          m.str('body'),
                          mine: m.str('sender_role') == 'rider',
                          time: fmtTime(m.date('created_at')),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ChatInput(
                controller: _input,
                onSend: () => _send(_input.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () async =>
          (await state.api.get('/rider/support/tickets') as Json).list('data'),
      builder: (context, tickets, reload) => CaboScaffold(
        title: 'Support tickets',
        bottom: CaboButton(
          'New message to support',
          icon: Icons.add_comment_rounded,
          onPressed: () async {
            state.ticket = null;
            await Navigator.of(context).pushNamed('/support-chat');
            await reload();
          },
        ),
        children: [
          if (tickets.isEmpty)
            const EmptyNotice(
              'You have no support tickets.',
              icon: Icons.confirmation_number_rounded,
            ),
          for (final t in tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CaboCard(
                onTap: () async {
                  state.select(ticket: t);
                  await Navigator.of(context).pushNamed('/support-chat');
                  await reload();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t.str('reference'), style: CaboText.label),
                        const Spacer(),
                        Pill(
                          humanize(t.str('status')),
                          color: switch (t.str('status')) {
                            'resolved' || 'closed' => CaboColors.green,
                            'awaiting_user' => CaboColors.orange,
                            _ => CaboColors.blue,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(t.str('subject_line'), style: CaboText.h3),
                    Text(
                      'Updated ${timeAgo(t.date('updated_at'))} • ${plural(t.integer('messages_count'), 'message')}',
                      style: CaboText.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () async => unwrap(await state.api.get('/rider/wallet')) as Json,
      builder: (context, w, _) {
        final code = w.strOrNull('referral_code');
        return CaboScaffold(
          title: 'Rewards',
          bottom: code == null
              ? null
              : CaboButton(
                  'Copy my invite code',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted)
                      showMessage(
                        context,
                        'Copied $code. Share it with a friend.',
                      );
                  },
                ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CaboColors.yellowSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CaboColors.yellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cabo points', style: CaboText.label),
                  Text(
                    compact(w.integer('loyalty_points')),
                    style: CaboText.display,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You earn points on every ride and tour you pay for.',
                    style: CaboText.muted,
                  ),
                ],
              ),
            ),
            if (code != null) ...[
              const SectionTitle('Invite a friend'),
              CaboCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Share your code', style: CaboText.h3),
                          Text(
                            'Friends enter it when they join Cabo',
                            style: CaboText.muted,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CaboColors.greenSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        code,
                        style: CaboText.h3.copyWith(
                          color: CaboColors.green,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SectionTitle('Wallet'),
            MenuTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Wallet balance',
              subtitle: naira(w.integer('balance')),
              onTap: () => go(context, '/wallet'),
            ),
          ],
        );
      },
    );
  }
}
