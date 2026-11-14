import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/widgets.dart';

// 10. Profile and settings.

const _travellerTypes = ['international', 'domestic', 'resident'];
const _travellerLabels = [
  'International visitor',
  'Domestic visitor',
  'Lagos resident',
];
const _languages = [
  ('en', 'English'),
  ('fr', 'Français'),
  ('yo', 'Yorùbá'),
  ('ig', 'Igbo'),
  ('ha', 'Hausa'),
  ('pcm', 'Naijá (Pidgin)'),
];
const _currencies = [
  ('GBP', 'British pound', '£'),
  ('USD', 'US dollar', r'$'),
  ('EUR', 'Euro', '€'),
  ('NGN', 'Naira only', '₦'),
];

void _toWelcome(BuildContext context) =>
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.read(context).refreshRider().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = state.rider ?? const {};
    Widget group(
      String title,
      List<(IconData, String, String?, String)> items,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        CaboCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (final (icon, label, sub, route) in items)
                MenuTile(
                  icon: icon,
                  title: label,
                  subtitle: sub,
                  onTap: () => go(context, route),
                ),
            ],
          ),
        ),
      ],
    );
    final type = _travellerTypes.indexOf(r.str('traveller_type'));
    final language =
        _languages
            .where((l) => l.$1 == r.str('language', 'en'))
            .firstOrNull
            ?.$2 ??
        'English';
    final contacts = r.list('emergency_contacts').length;
    final places = r.list('saved_places');
    return CaboScaffold(
      title: 'Profile',
      showBack: false,
      bottomNav: const RiderNav(3),
      children: [
        Row(
          children: [
            Avatar(initials(state.fullName), size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.fullName.isEmpty ? 'Your profile' : state.fullName,
                    style: CaboText.h2,
                  ),
                  Text(
                    r.strOrNull('phone') ?? r.strOrNull('email') ?? '',
                    style: CaboText.muted,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (type >= 0)
                        Pill(
                          _travellerLabels[type],
                          icon: Icons.flight_land_rounded,
                        ),
                      Pill(
                        '${compact(r.integer('loyalty_points'))} pts',
                        color: CaboColors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_rounded, color: CaboColors.green),
              onPressed: () => go(context, '/edit-profile'),
            ),
          ],
        ),
        group('Account', [
          (
            Icons.account_balance_wallet_rounded,
            'Wallet',
            naira(r.integer('wallet_balance')),
            '/wallet',
          ),
          (
            Icons.place_rounded,
            'Saved places',
            places.isEmpty
                ? 'Add your hotel or home'
                : places.map((p) => p.str('label')).join(', '),
            '/saved-places',
          ),
          (
            Icons.favorite_rounded,
            'Wishlist',
            plural(state.wishlist.length, 'saved item'),
            '/wishlist',
          ),
          (
            Icons.event_note_rounded,
            'My Lagos plan',
            'Your bookings day by day',
            '/itinerary',
          ),
          (
            Icons.card_giftcard_rounded,
            'Rewards and referrals',
            null,
            '/rewards',
          ),
        ]),
        group('Preferences', [
          (Icons.translate_rounded, 'Language', language, '/language'),
          (
            Icons.currency_exchange_rounded,
            'Home currency',
            state.homeCurrency,
            '/currency',
          ),
          (
            Icons.notifications_rounded,
            'Notifications',
            null,
            '/notification-settings',
          ),
          (
            Icons.accessible_forward_rounded,
            'Accessibility',
            (r['accessibility'] as Map?)?.isNotEmpty == true
                ? 'Set'
                : 'Not set',
            '/accessibility',
          ),
        ]),
        group('Safety and help', [
          (Icons.shield_rounded, 'Safety centre', null, '/safety'),
          (
            Icons.contacts_rounded,
            'Trusted contacts',
            contacts == 0 ? 'None yet' : plural(contacts, 'contact'),
            '/trusted-contacts',
          ),
          (Icons.help_rounded, 'Help centre', null, '/help'),
          (
            Icons.confirmation_number_rounded,
            'Support tickets',
            null,
            '/support-tickets',
          ),
        ]),
        group('More', [
          (Icons.event_rounded, 'Events', 'Coming soon', '/events'),
          (Icons.gavel_rounded, 'Legal and privacy', null, '/legal'),
          (
            Icons.delete_outline_rounded,
            'Delete account',
            null,
            '/delete-account',
          ),
        ]),
        const SizedBox(height: 16),
        ActionButton(
          'Log out',
          style: CaboButtonStyle.secondary,
          icon: Icons.logout_rounded,
          onPressed: () async {
            await state.signOut();
            if (context.mounted) _toWelcome(context);
          },
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _nationality = TextEditingController();
  int _type = 0;
  Map<String, String> _errors = {};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final r = AppScope.read(context).rider ?? const {};
    _first.text = r.str('first_name');
    _last.text = r.str('last_name');
    _phone.text = r.str('phone');
    _email.text = r.str('email');
    _nationality.text = r.str('nationality');
    _type = _travellerTypes.indexOf(r.str('traveller_type')).clamp(0, 2);
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _nationality]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{
      if (_first.text.trim().isEmpty) 'first_name': 'Enter your first name.',
      if (_last.text.trim().isEmpty) 'last_name': 'Enter your last name.',
      if (_phone.text.trim().isEmpty && _email.text.trim().isEmpty)
        'phone': 'Enter a phone number or an email.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await AppScope.read(context).updateRider({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'phone': orNull(_phone),
        'email': orNull(_email),
        'nationality': orNull(_nationality),
        'traveller_type': _travellerTypes[_type],
      });
    } on ApiException catch (e) {
      if (e.fields.isEmpty) rethrow;
      if (mounted) setState(() => _errors = e.fields);
      return;
    }
    if (!mounted) return;
    showMessage(context, 'Profile saved.');
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Edit profile',
      bottom: ActionButton('Save', onPressed: _save),
      children: [
        Center(
          child: Avatar(initials('${_first.text} ${_last.text}'), size: 96),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField(
                'First name',
                controller: _first,
                error: _errors['first_name'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField(
                'Last name',
                controller: _last,
                error: _errors['last_name'],
              ),
            ),
          ],
        ),
        CaboField(
          'Phone',
          controller: _phone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          error: _errors['phone'],
        ),
        CaboField(
          'Email',
          controller: _email,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          error: _errors['email'],
        ),
        CaboField(
          'Nationality',
          controller: _nationality,
          icon: Icons.flag_outlined,
          error: _errors['nationality'],
        ),
        Text('I am a', style: CaboText.label),
        const SizedBox(height: 8),
        ChipPicker(
          options: _travellerLabels,
          initial: {_type},
          single: true,
          onChanged: (s) => _type = s.first,
        ),
      ],
    );
  }
}

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  Future<void> _add(
    BuildContext context,
    Future<void> Function() reload,
  ) async {
    final state = AppScope.read(context);
    final place = await pickPlace(context, title: 'Add a saved place');
    if (place == null || !context.mounted) return;
    final label = TextEditingController(
      text: place.str('kind') == 'current' ? '' : place.str('name'),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Name this place'),
        content: TextField(
          controller: label,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Hotel'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(label.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await runAction(
      context,
      () => state.api.post('/rider/saved-places', {
        'label': name,
        'address': place.str('address'),
        'lat': place.number('lat'),
        'lng': place.number('lng'),
      }),
    );
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () async =>
          asJsonList(unwrap(await state.api.get('/rider/saved-places'))),
      builder: (context, places, reload) => CaboScaffold(
        title: 'Saved places',
        bottom: CaboButton(
          'Add a place',
          icon: Icons.add_rounded,
          onPressed: () => _add(context, reload),
        ),
        children: [
          Text(
            'Use these as quick pickup points, like your hotel.',
            style: CaboText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty)
            const EmptyNotice(
              'No saved places yet.',
              icon: Icons.place_rounded,
            ),
          for (final p in places)
            MenuTile(
              icon: p.str('label').toLowerCase().contains('hotel')
                  ? Icons.hotel_rounded
                  : Icons.place_rounded,
              title: p.str('label'),
              subtitle: p.str('address'),
              trailing: IconButton(
                tooltip: 'Remove ${p.str('label')}',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: CaboColors.muted,
                ),
                onPressed: () async {
                  await runAction(
                    context,
                    () => state.api.delete(
                      '/rider/saved-places/${p.integer('id')}',
                    ),
                  );
                  await reload();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final current = _languages.indexWhere(
      (l) => l.$1 == (state.rider?.str('language', 'en') ?? 'en'),
    );
    return CaboScaffold(
      title: 'Language',
      children: [
        SingleChoice(
          initial: current < 0 ? 0 : current,
          options: [
            for (final l in _languages)
              (
                l.$2,
                l.$1 == 'en'
                    ? null
                    : 'App text in this language is coming soon',
              ),
          ],
          onChanged: (i) => runAction(
            context,
            () => state.updateRider({'language': _languages[i].$1}),
          ),
        ),
        Text(
          'We save your choice so drivers and guides know which language you prefer.',
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final rates = state.config.obj('exchange_rates');
    final current = _currencies.indexWhere((c) => c.$1 == state.homeCurrency);
    return CaboScaffold(
      title: 'Home currency',
      children: [
        Text(
          'Shown as an estimate next to naira prices.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        SingleChoice(
          initial: current < 0 ? _currencies.length - 1 : current,
          options: [
            for (final (code, name, symbol) in _currencies)
              (
                code == 'NGN' ? name : '$code • $name',
                code == 'NGN'
                    ? 'Hide estimates'
                    : rates?.numberOrNull(code) == null
                    ? null
                    : '${symbol}1 ≈ ${naira(rates!.number(code))}',
              ),
          ],
          onChanged: (i) => runAction(
            context,
            () => state.updateRider({'home_currency': _currencies[i].$1}),
          ),
        ),
        Text(
          "Rates are set by Cabo. Your bank's rate may differ slightly.",
          style: CaboText.muted,
        ),
      ],
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Notifications',
      bottom: CaboButton(
        'Open my notifications',
        onPressed: () => go(context, '/notifications'),
      ),
      children: const [
        MenuTile(
          icon: Icons.local_taxi_rounded,
          title: 'Trips and bookings',
          subtitle: 'Driver updates, booking confirmations and refunds arrive in your in-app inbox.',
        ),
        MenuTile(
          icon: Icons.support_agent_rounded,
          title: 'Support',
          subtitle: 'Replies to your support tickets appear there too.',
        ),
        MenuTile(
          icon: Icons.notifications_paused_rounded,
          title: 'Push notifications',
          subtitle: 'Alerts on your lock screen, and choosing which ones you get, are coming soon.',
          color: CaboColors.muted,
        ),
      ],
    );
  }
}

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  static const _options = [
    ('wheelchair', 'Wheelchair-accessible vehicle', Icons.accessible_rounded),
    ('help_with_bags', 'Help with bags', Icons.luggage_rounded),
    (
      'visually_impaired',
      'I am visually impaired',
      Icons.visibility_off_rounded,
    ),
    (
      'hard_of_hearing',
      'I am deaf or hard of hearing',
      Icons.hearing_disabled_rounded,
    ),
    ('service_animal', 'Travelling with a service animal', Icons.pets_rounded),
  ];
  final _notes = TextEditingController();
  final _values = <String, bool>{};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final saved = AppScope.read(context).rider?['accessibility'];
    if (saved is Map) {
      for (final o in _options) {
        _values[o.$1] = saved[o.$1] == true;
      }
      _notes.text = '${saved['notes'] ?? ''}';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppScope.read(context).updateRider({
      'accessibility': {
        for (final o in _options)
          if (_values[o.$1] == true) o.$1: true,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      },
    });
    if (!mounted) return;
    showMessage(context, 'Accessibility needs saved.');
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Accessibility',
      bottom: ActionButton('Save', onPressed: _save),
      children: [
        Text(
          'Tell us what helps and we will share it with your drivers and guides.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        for (final (key, label, icon) in _options)
          ToggleTile(
            label,
            initial: _values[key] ?? false,
            icon: icon,
            onChanged: (v) => _values[key] = v,
          ),
        const SizedBox(height: 10),
        CaboField(
          'Notes for drivers and guides',
          controller: _notes,
          hint: 'e.g. I need extra time getting in',
          maxLines: 2,
        ),
      ],
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AppScope.read(context).config
        .obj('support')
        ?.strOrNull('email');
    return CaboScaffold(
      title: 'Legal and privacy',
      children: [
        MenuTile(
          icon: Icons.article_rounded,
          title: 'Terms and privacy policy',
          subtitle: 'caboapp.online',
          onTap: () => launchUrl(
            Uri.parse('https://caboapp.online'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        if (email != null)
          MenuTile(
            icon: Icons.download_rounded,
            title: 'Ask for a copy of my data',
            subtitle: email,
            onTap: () => launchUrl(
              Uri(scheme: 'mailto', path: email, query: 'subject=My Cabo data'),
            ),
          ),
        MenuTile(
          icon: Icons.delete_outline_rounded,
          title: 'Delete my account',
          onTap: () => go(context, '/delete-account'),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Cabo • Lagos, Nigeria\nVersion 1.0.0',
            textAlign: TextAlign.center,
            style: CaboText.muted.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  Future<void> _delete(BuildContext context) async {
    final state = AppScope.read(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep my account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: CaboColors.red),
            ),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await state.deleteAccount();
    if (context.mounted) _toWelcome(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final balance = state.rider?.integer('wallet_balance') ?? 0;
    return CaboScaffold(
      title: 'Delete account',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton(
            'Delete my account',
            style: CaboButtonStyle.danger,
            onPressed: () => _delete(context),
          ),
          const SizedBox(height: 10),
          ActionButton(
            'Log out instead',
            style: CaboButtonStyle.secondary,
            height: 48,
            onPressed: () async {
              await state.signOut();
              if (context.mounted) _toWelcome(context);
            },
          ),
        ],
      ),
      children: [
        const Center(
          child: HeroIllustration(
            Icons.delete_forever_rounded,
            size: 150,
            color: CaboColors.red,
          ),
        ),
        const SizedBox(height: 16),
        Text('We are sorry to see you go', style: CaboText.h2),
        const SizedBox(height: 10),
        const CheckRow(
          'Your profile, saved places, contacts and wishlist are deleted',
        ),
        const CheckRow('You are signed out on every device'),
        if (balance > 0)
          CheckRow(
            'Contact support first to get your wallet balance (${naira(balance)}) back',
            done: false,
          ),
        const CheckRow(
          'Cancel any upcoming bookings first so they can be refunded',
          done: false,
        ),
      ],
    );
  }
}
