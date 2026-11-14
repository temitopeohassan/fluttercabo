import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/widgets.dart';

// 7. Safety and support.

String _emergency(AppState state) => state.config.obj('support')?.str('emergency_number', '112') ?? '112';
String _short(String address) => address.split(',').first;

class SafetyToolkitScreen extends StatelessWidget {
  const SafetyToolkitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return CaboScaffold(
      title: 'Safety toolkit',
      children: [
        const SizedBox(height: 8),
        Center(
          child: Semantics(
            button: true,
            label: 'Emergency SOS',
            child: GestureDetector(
              onTap: () => go(context, '/emergency'),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: CaboColors.red.withValues(alpha: 0.2)),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: CaboColors.red),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SOS', style: CaboText.display.copyWith(fontSize: 36)),
                        Text('Tap for help', style: CaboText.label.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Alerts Cabo\'s safety team with your location, and lets you call ${_emergency(state)}',
            style: CaboText.muted,
            textAlign: TextAlign.center,
          ),
        ),
        const SectionTitle('Tools'),
        MenuTile(
          icon: Icons.report_rounded,
          title: 'Report an incident',
          subtitle: 'Rider misconduct, accident or damage',
          color: CaboColors.orange,
          onTap: () => go(context, '/report-incident'),
        ),
        MenuTile(
          icon: Icons.backpack_rounded,
          title: 'Found an item',
          subtitle: 'Tell us about something a rider left behind',
          color: CaboColors.blue,
          onTap: () => go(context, '/lost-item'),
        ),
        MenuTile(icon: Icons.support_agent_rounded, title: 'Help centre', onTap: () => go(context, '/help')),
        const SectionTitle('Safety tips'),
        for (final (icon, tip) in const [
          (Icons.pin_rounded, 'Only start a trip once the rider gives you their 4-digit PIN'),
          (Icons.groups_rounded, 'Do not carry more passengers than your vehicle has seats'),
          (Icons.nightlight_round, 'At night, wait until your rider is safely inside before leaving'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, color: CaboColors.yellow),
                const SizedBox(width: 12),
                Expanded(child: Text(tip, style: CaboText.body)),
              ],
            ),
          ),
      ],
    );
  }
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  LatLng? _here;
  Json? _alert;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.read(context).location.current().then((p) {
      if (mounted) setState(() => _here = p);
    }, onError: (_) {});
  }

  Future<void> _raise() async {
    final state = AppScope.read(context);
    final res = await state.api.post('/driver/sos', {
      if (state.onTrip) 'trip_id': state.trip!.integer('id'),
      if (_here != null) ...{'lat': _here!.lat, 'lng': _here!.lng},
    });
    if (mounted) setState(() => _alert = (unwrap(res) as Json?) ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final number = _emergency(state);
    final trip = state.onTrip ? state.trip : null;
    final v = state.vehicle;
    final sent = _alert != null;
    return Scaffold(
      backgroundColor: const Color(0xFF3A0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A0D12),
        automaticallyImplyLeading: false,
        leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => back(context)),
        title: const Text('Emergency'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(sent ? 'Cabo\'s safety team has your alert.' : 'Stay calm. Get help now.', style: CaboText.h1, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          CaboButton(
            'Call $number',
            icon: Icons.call_rounded,
            style: CaboButtonStyle.danger,
            height: 72,
            onPressed: () => callNumber(context, number),
          ),
          const SizedBox(height: 12),
          if (sent)
            const Center(
              child: Pill('Alert sent to Cabo Safety', color: CaboColors.brightGreen, icon: Icons.check),
            )
          else
            ActionButton(
              'Alert Cabo Safety',
              icon: Icons.shield_rounded,
              style: CaboButtonStyle.light,
              busyLabel: 'Sending…',
              onPressed: _raise,
            ),
          const SizedBox(height: 20),
          CaboCard(
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your location', style: CaboText.label.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  _here == null ? 'Finding your position…' : '${_here!.lat.toStringAsFixed(4)}° N, ${_here!.lng.toStringAsFixed(4)}° E',
                  style: CaboText.h3,
                ),
                Text(
                  sent && _here != null ? 'Sent with your alert' : 'Sent with your alert when you press the button',
                  style: CaboText.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (trip != null || v != null)
            CaboCard(
              color: Colors.black26,
              child: Column(
                children: [
                  if (trip != null)
                    InfoRow('Current trip', '${_short(trip.str('pickup_address'))} → ${_short(trip.str('dropoff_address'))}'),
                  if (v != null) InfoRow('Vehicle', '${v.str('colour')} ${v.str('make')} ${v.str('model')} • ${v.str('plate_number')}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A form that opens a support ticket about a trip.
class _TicketForm extends StatefulWidget {
  const _TicketForm({required this.title, required this.heading, required this.kinds, required this.hint, this.intro});
  final String title;
  final String heading;
  final String? intro;
  final String hint;

  /// Category code, label and optional note for each choice.
  final List<(String, String, String?)> kinds;

  @override
  State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
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
      await state.api.post('/driver/support/tickets', {
        'category': widget.kinds[_kind].$1,
        'subject': widget.kinds[_kind].$2,
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
      load: () async {
        if (state.pastTrip != null) return state.pastTrip;
        if (state.trip != null) return state.trip;
        return (await state.api.get('/driver/trips') as Json).list('data').firstOrNull;
      },
      builder: (context, trip, _) => CaboScaffold(
        title: widget.title,
        bottom: ActionButton('Send to support', onPressed: () => _send(trip)),
        children: [
          Text(widget.heading, style: CaboText.h2),
          if (widget.intro != null) ...[const SizedBox(height: 6), Text(widget.intro!, style: CaboText.muted)],
          const SizedBox(height: 16),
          if (widget.kinds.length > 1)
            SingleChoice(initial: _kind, options: [for (final k in widget.kinds) (k.$2, k.$3)], onChanged: (i) => _kind = i),
          if (trip != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CaboCard(
                child: Row(
                  children: [
                    const IconBadge(Icons.directions_car_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About this trip', style: CaboText.label),
                          Text(
                            '${_short(trip.str('pickup_address'))} → ${_short(trip.str('dropoff_address'))}',
                            style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            fmtDayTime(trip.date('completed_at') ?? trip.date('created_at')),
                            style: CaboText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          CaboField('Details', controller: _details, hint: widget.hint, maxLines: 4, error: _error),
        ],
      ),
    );
  }
}

class ReportIncidentScreen extends StatelessWidget {
  const ReportIncidentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TicketForm(
      title: 'Report an incident',
      heading: 'What happened?',
      hint: 'Describe what happened, and when',
      kinds: [
        ('rider_behaviour', 'Rider misconduct', 'Abuse, threats or harassment'),
        ('accident', 'Accident', 'A collision during a trip'),
        ('vehicle_damage', 'Vehicle damage', 'Damage caused by a rider'),
        ('fare_dispute', 'Fare problem', 'The fare or my earnings look wrong'),
        ('other', 'Something else', null),
      ],
    );
  }
}

class LostItemScreen extends StatelessWidget {
  const LostItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TicketForm(
      title: 'Found an item',
      heading: 'Found something in your car?',
      intro: 'Tell us what it is and where you found it. Cabo support contacts the rider and arranges the return with you.',
      hint: 'e.g. Black phone in a green case, on the back seat',
      kinds: [('lost_item', 'Item found in my vehicle', null)],
    );
  }
}

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final support = state.config.obj('support');
    final phone = support?.strOrNull('phone');
    final email = support?.strOrNull('email');
    final drivers = state.config.obj('drivers');
    final faqs = [
      (
        'When do I get paid?',
        'Your earnings balance is paid to your bank account every week. You can also cash out instantly from '
            '${naira(drivers?.integer('minimum_cashout', 5000) ?? 5000)} for a '
            '${(drivers?.number('instant_cashout_fee_percent', 1.5) ?? 1.5).toStringAsFixed(1)}% fee.',
      ),
      (
        'How much commission does Cabo take?',
        'Cabo keeps ${(drivers?.number('commission_rate', 20) ?? 20).round()}% of each fare. Tips are all yours.',
      ),
      (
        'How do cash trips work?',
        'You keep the cash the rider pays. Cabo\'s commission on those trips is added to your cash balance and '
            'taken from your earnings at your next payout. Above '
            '${naira(drivers?.integer('cash_debt_limit', 20000) ?? 20000)} owed you cannot go online until it is settled.',
      ),
      (
        'Why can I not go online?',
        'Your account, required documents and active vehicle must all be approved, and your documents in date. '
            'Check your application status to see what is missing.',
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
              (Icons.report_rounded, 'Report an incident', '/report-incident'),
              (Icons.confirmation_number_rounded, 'My support tickets', '/support-tickets'),
              (Icons.shield_rounded, 'Safety toolkit', '/safety'),
              (Icons.fact_check_rounded, 'Application status', '/application-status'),
            ])
              CaboCard(
                onTap: () => go(context, route),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: CaboColors.yellow),
                    Text(label, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
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
              iconColor: CaboColors.yellow,
              collapsedIconColor: CaboColors.muted,
              title: Text(q, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(a, style: CaboText.muted),
                ),
              ],
            ),
          ),
        if (phone != null)
          MenuTile(icon: Icons.call_rounded, title: 'Call support', subtitle: phone, onTap: () => callNumber(context, phone)),
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
      final t = unwrap(await state.api.get('/driver/support/tickets/${_ticket!.integer('id')}')) as Json;
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

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final state = AppScope.read(context);
    setState(() => _sending = true);
    try {
      if (_ticket == null) {
        final t = unwrap(
          await state.api.post('/driver/support/tickets', {
            'category': 'other',
            'subject': text.length > 60 ? '${text.substring(0, 60)}…' : text,
            'message': text,
          }),
        ) as Json;
        state.select(ticket: t);
        _ticket = t;
      } else {
        await state.api.post('/driver/support/tickets/${_ticket!.integer('id')}/messages', {'message': text});
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
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => back(context))
            : null,
        titleSpacing: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Avatar('CS', size: 40, color: CaboColors.brightGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cabo Support', style: CaboText.h3),
                  Text(
                    t == null ? 'New conversation' : '${t.str('reference')} • ${humanize(t.str('status'))}',
                    style: CaboText.muted.copyWith(fontSize: 12, color: CaboColors.brightGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [if (t != null) IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded), onPressed: _refresh)],
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
                        ChatBubble(m.str('body'), mine: m.str('sender_role') == 'driver', time: fmtTime(m.date('created_at'))),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ChatInput(controller: _input, onSend: _send),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () async => (await state.api.get('/driver/support/tickets') as Json).list('data'),
      builder: (context, tickets, reload) {
        bool closed(Json t) => const {'resolved', 'closed'}.contains(t.str('status'));
        final open = tickets.where((t) => !closed(t)).toList();
        final resolved = tickets.where(closed).toList();
        final shown = [tickets, open, resolved][_filter];
        Future<void> openChat(Json? ticket) async {
          if (ticket == null) {
            state.ticket = null;
          } else {
            state.select(ticket: ticket);
          }
          await Navigator.of(context).pushNamed('/support-chat');
          await reload();
        }

        return CaboScaffold(
          title: 'Support tickets',
          bottom: CaboButton('New request', icon: Icons.add_rounded, onPressed: () => openChat(null)),
          children: [
            ChipPicker(
              key: ValueKey('${open.length}-${resolved.length}'),
              options: ['All (${tickets.length})', 'Open (${open.length})', 'Resolved (${resolved.length})'],
              initial: {_filter},
              single: true,
              onChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: 14),
            if (shown.isEmpty) const EmptyNotice('No support tickets here.', icon: Icons.confirmation_number_rounded),
            for (final t in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CaboCard(
                  onTap: () => openChat(t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.str('reference'), style: CaboText.label),
                          const Spacer(),
                          Pill(
                            humanize(t.str('status')),
                            color: closed(t)
                                ? CaboColors.brightGreen
                                : t.str('status') == 'awaiting_user'
                                ? CaboColors.orange
                                : CaboColors.yellow,
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
        );
      },
    );
  }
}
