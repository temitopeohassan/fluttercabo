import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/widgets.dart';
import 'onboarding.dart' show relationships;

// 8. Safety.

Future<List<Json>> _contacts(AppState state) async =>
    asJsonList(unwrap(await state.api.get('/rider/emergency-contacts')));

Future<void> _call(BuildContext context, String number) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted)
    showMessage(
      context,
      'Could not open the phone app. Dial $number.',
      error: true,
    );
}

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final emergency =
        state.config.obj('support')?.str('emergency_number', '112') ?? '112';
    return CaboScaffold(
      title: 'Safety centre',
      children: [
        CaboCard(
          color: CaboColors.red.withValues(alpha: 0.08),
          onTap: () => go(context, '/sos'),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: CaboColors.red,
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency SOS', style: CaboText.h3),
                    Text(
                      'Alerts Cabo\'s safety team with your location and trip, and lets you call $emergency.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('How we keep you safe'),
        for (final (icon, title, body) in const [
          (
            Icons.verified_user_rounded,
            'Vetted drivers',
            'ID and document checks, vehicle inspection and hospitality training.',
          ),
          (
            Icons.pin_rounded,
            'Trip PIN',
            'Your trip only starts when the driver enters your 4-digit PIN.',
          ),
          (
            Icons.share_location_rounded,
            'Trip sharing',
            'Send a link anyone can open, no app needed.',
          ),
          (
            Icons.support_agent_rounded,
            'Safety team',
            'SOS alerts go straight to the top of our team\'s screen.',
          ),
        ])
          MenuTile(icon: icon, title: title, subtitle: body),
        const SectionTitle('Tips for visitors'),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (icon, tip) in const [
                (
                  Icons.directions_car_rounded,
                  'Check the plate number before you get in',
                ),
                (
                  Icons.nightlight_round,
                  'At night, wait inside the venue until your driver arrives',
                ),
                (
                  Icons.payments_rounded,
                  'Pay in the app rather than with cash where you can',
                ),
              ])
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 10),
                  child: CaboCard(
                    color: CaboColors.greenSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: CaboColors.green),
                        const SizedBox(height: 8),
                        Text(tip, style: CaboText.body.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Loader<List<Json>>(
          padding: const EdgeInsets.all(8),
          load: () => _contacts(state),
          builder: (context, contacts, _) => MenuTile(
            icon: Icons.contacts_rounded,
            title: 'Trusted contacts',
            subtitle: contacts.isEmpty
                ? 'Add someone we can reach for you'
                : plural(contacts.length, 'contact'),
            onTap: () => go(context, '/trusted-contacts'),
          ),
        ),
      ],
    );
  }
}

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Json? _place;
  List<Json> _contactList = [];
  bool _sending = false;
  Json? _alert;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final state = AppScope.read(context);
    state.currentPlace().then((p) {
      if (mounted) setState(() => _place = p);
    }, onError: (_) {});
    _contacts(state).then((c) {
      if (mounted) setState(() => _contactList = c);
    }, onError: (_) {});
  }

  Future<void> _raise() async {
    if (_sending || _alert != null) return;
    final state = AppScope.read(context);
    setState(() => _sending = true);
    try {
      final res = await state.api.post('/rider/sos', {
        if (state.trip != null &&
            AppState.activeStatuses.contains(state.trip!.str('status')))
          'trip_id': state.trip!.integer('id'),
        if (_place != null) ...{
          'lat': _place!.number('lat'),
          'lng': _place!.number('lng'),
          'address': _place!.str('address'),
        },
      }) as Json;
      if (mounted) setState(() => _alert = res);
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          '${errorText(e)} Call the emergency number now.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final emergency =
        state.config.obj('support')?.str('emergency_number', '112') ?? '112';
    final trip = state.trip;
    final onTrip =
        trip != null && AppState.activeStatuses.contains(trip.str('status'));
    final sent = _alert != null;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F1),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => back(context),
        ),
        title: const Text('Emergency'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Semantics(
              button: true,
              label: sent ? 'SOS sent' : 'Send SOS alert to Cabo',
              child: GestureDetector(
                onTap: _raise,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CaboColors.red.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sent ? CaboColors.green : CaboColors.red,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sent)
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 48,
                            )
                          else
                            Text(
                              'SOS',
                              style: CaboText.display.copyWith(
                                color: Colors.white,
                                fontSize: 38,
                              ),
                            ),
                          Text(
                            sent
                                ? 'Alert sent'
                                : _sending
                                ? 'Sending…'
                                : 'Tap to alert Cabo',
                            style: CaboText.label.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (sent)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CaboCard(
                color: CaboColors.greenSoft,
                child: Text(
                  'Cabo\'s safety team has your alert${_place == null ? '' : ' and location'}. '
                  'If you are in danger, call $emergency now.',
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          CaboButton(
            'Call $emergency',
            icon: Icons.call_rounded,
            style: CaboButtonStyle.danger,
            height: 60,
            onPressed: () => _call(context, emergency),
          ),
          const SizedBox(height: 16),
          CaboCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  'Your location',
                  _place?.str('address') ?? 'Not available',
                ),
                if (onTrip)
                  InfoRow(
                    'Trip',
                    [
                      trip.obj('driver')?.str('first_name'),
                      trip.obj('vehicle')?.str('plate_number'),
                    ].whereType<String>().join(' • '),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CaboCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('When you press SOS', style: CaboText.label),
                const SizedBox(height: 6),
                const CheckRow('Cabo\'s safety team is alerted straight away'),
                for (final c in _contactList)
                  CheckRow(
                    'They can reach ${c.str('name')}${c.strOrNull('relationship') == null ? '' : ' (${c.str('relationship').toLowerCase()})'}',
                  ),
                if (_contactList.isEmpty)
                  const CheckRow(
                    'Add a trusted contact so we can reach someone for you',
                    done: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AreYouOkScreen extends StatelessWidget {
  const AreYouOkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        route: [Offset(0.62, 0.52), Offset(0.7, 0.4), Offset(0.85, 0.35)],
        routeColor: CaboColors.orange,
        markers: [MapMarker(Offset(0.85, 0.35), MarkerKind.driver)],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconBadge(
            Icons.help_rounded,
            color: CaboColors.orange,
            size: 60,
          ),
          const SizedBox(height: 10),
          Text('Is everything OK?', style: CaboText.h1),
          const SizedBox(height: 6),
          Text(
            'If something does not feel right on your trip, tell us and Cabo\'s safety team will step in.',
            textAlign: TextAlign.center,
            style: CaboText.muted.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
          CaboButton("I'm OK", onPressed: () => back(context)),
          const SizedBox(height: 10),
          CaboButton(
            'I need help',
            style: CaboButtonStyle.danger,
            onPressed: () => go(context, '/sos'),
          ),
        ],
      ),
    );
  }
}

class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  Future<void> _add(
    BuildContext context,
    Future<void> Function() reload,
  ) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactForm(state: AppScope.read(context)),
    );
    if (added == true) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () => _contacts(state),
      builder: (context, contacts, reload) => CaboScaffold(
        title: 'Trusted contacts',
        bottom: CaboButton(
          'Add a contact',
          icon: Icons.person_add_rounded,
          onPressed: contacts.length >= 5 ? null : () => _add(context, reload),
        ),
        children: [
          Text(
            'Cabo\'s safety team can reach them if you press SOS. Turn on trip sharing to share every trip with them.',
            style: CaboText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 14),
          if (contacts.isEmpty)
            const EmptyNotice(
              'No trusted contacts yet.',
              icon: Icons.group_add_rounded,
            ),
          for (final c in contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CaboCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Avatar(
                          initials(c.str('name')),
                          size: 44,
                          color: CaboColors.greenSoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.str('name'), style: CaboText.h3),
                              Text(
                                [
                                  ?c.strOrNull('relationship'),
                                  c.str('phone'),
                                ].join(' • '),
                                style: CaboText.muted,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${c.str('name')}',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: CaboColors.muted,
                          ),
                          onPressed: () async {
                            await runAction(
                              context,
                              () => state.api.delete(
                                '/rider/emergency-contacts/${c.integer('id')}',
                              ),
                            );
                            await reload();
                          },
                        ),
                      ],
                    ),
                    ToggleTile(
                      'Share every trip automatically',
                      key: ValueKey('share-${c.integer('id')}'),
                      initial: c.flag('share_trips_automatically'),
                      onChanged: (v) => runAction(
                        context,
                        () => state.api.put(
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
            ),
          if (contacts.length >= 5)
            Text('You can have up to five contacts.', style: CaboText.muted),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.state});
  final AppState state;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _relationship = 3;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{
      if (_name.text.trim().isEmpty) 'name': 'Enter their name.',
      if (_phone.text.replaceAll(RegExp(r'[^0-9]'), '').length < 7)
        'phone': 'Enter their phone number with the country code.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    await widget.state.api.post('/rider/emergency-contacts', {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'relationship': relationships[_relationship],
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a trusted contact', style: CaboText.h2),
            const SizedBox(height: 14),
            CaboField(
              'Name',
              controller: _name,
              icon: Icons.person_outline,
              error: _errors['name'],
            ),
            CaboField(
              'Phone',
              controller: _phone,
              hint: '+44 7700 900 118',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              error: _errors['phone'],
            ),
            Text('Relationship', style: CaboText.label),
            const SizedBox(height: 8),
            ChipPicker(
              options: relationships,
              initial: {_relationship},
              single: true,
              onChanged: (s) => _relationship = s.first,
            ),
            const SizedBox(height: 18),
            ActionButton('Save contact', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
