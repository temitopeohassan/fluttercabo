import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/widgets.dart';
import 'earnings.dart' show bankLabel;
import 'onboarding.dart' show BankForm, VehicleCard, VehicleForm;

// 8. Account and settings.

void _toWelcome(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);

class AccountOverviewScreen extends StatefulWidget {
  const AccountOverviewScreen({super.key});

  @override
  State<AccountOverviewScreen> createState() => _AccountOverviewScreenState();
}

class _AccountOverviewScreenState extends State<AccountOverviewScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.read(context).refreshDriver().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = state.driver ?? const {};
    final v = state.vehicle;
    final docs = d.obj('documents_summary');
    final attention = (docs?.integer('rejected') ?? 0) + (docs?.list('expired').length ?? 0) + (docs?.list('expiring_soon').length ?? 0);
    Widget group(String title, List<(IconData, String, String?, String)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        CaboCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (final (icon, label, sub, route) in items)
                MenuTile(icon: icon, title: label, subtitle: sub, onTap: () => go(context, route)),
            ],
          ),
        ),
      ],
    );
    return CaboScaffold(
      title: 'Account',
      showBack: false,
      bottomNav: const DriverNav(3),
      children: [
        Row(
          children: [
            Avatar(initials(state.fullName), size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.fullName.isEmpty ? 'Your account' : state.fullName, style: CaboText.h2),
                  Text(d.str('phone'), style: CaboText.muted),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(d.number('rating').toStringAsFixed(2), icon: Icons.star_rounded),
                      Pill(humanize(d.str('tier', 'standard')), color: CaboColors.blue),
                      Pill(humanize(state.status), color: state.approved ? CaboColors.brightGreen : CaboColors.orange, icon: Icons.circle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CaboCard(
          onTap: () => go(context, '/vehicles'),
          child: Row(
            children: [
              const IconBadge(Icons.directions_car_filled_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v == null ? 'No active vehicle' : '${v.str('make')} ${v.str('model')} ${v.integer('year')}', style: CaboText.h3),
                    Text(
                      v == null
                          ? 'Add a vehicle to start driving'
                          : [v.str('colour'), v.str('plate_number'), ...v.strings('ride_types').map(humanize)].join(' • '),
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CaboColors.muted),
            ],
          ),
        ),
        group('Profile', [
          (Icons.person_rounded, 'Edit profile', null, '/edit-profile'),
          (
            Icons.description_rounded,
            'Documents',
            attention > 0 ? '${plural(attention, 'document')} need attention' : 'All in order',
            '/documents',
          ),
          (Icons.account_balance_rounded, 'Bank details', bankLabel(d), '/bank-details'),
          (Icons.fact_check_rounded, 'Application status', humanize(state.status), '/application-status'),
          (Icons.insights_rounded, 'Performance', null, '/performance'),
        ]),
        group('Settings', [
          (Icons.tune_rounded, 'Ride preferences', null, '/ride-preferences'),
          (Icons.navigation_rounded, 'Navigation', null, '/navigation-settings'),
          (Icons.translate_rounded, 'Language', null, '/language'),
          (Icons.notifications_rounded, 'Notifications', null, '/notification-settings'),
        ]),
        group('Support', [
          (Icons.shield_rounded, 'Safety toolkit', null, '/safety'),
          (Icons.help_rounded, 'Help centre', null, '/help'),
          (Icons.school_rounded, 'Learning centre', null, '/learning-centre'),
          (Icons.card_giftcard_rounded, 'Refer a host', d.strOrNull('referral_code'), '/refer'),
          (Icons.gavel_rounded, 'Legal', null, '/legal'),
          (Icons.logout_rounded, 'Log out or delete account', null, '/logout-delete'),
        ]),
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
  static const _languages = ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin', 'French'];
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  Set<int> _langs = {};
  Map<String, String> _errors = {};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final d = AppScope.read(context).driver ?? const {};
    _first.text = d.str('first_name');
    _last.text = d.str('last_name');
    _email.text = d.str('email');
    _address.text = d.str('address');
    final saved = d.strings('languages');
    _langs = {
      for (final (i, l) in _languages.indexed)
        if (saved.contains(l)) i,
    };
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{
      if (_first.text.trim().isEmpty) 'first_name': 'Enter your first name.',
      if (_last.text.trim().isEmpty) 'last_name': 'Enter your last name.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    try {
      await AppScope.read(context).updateDriver({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
        'languages': [for (final i in _langs) _languages[i]],
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
    final d = AppScope.read(context).driver ?? const {};
    return CaboScaffold(
      title: 'Edit profile',
      bottom: ActionButton('Save changes', onPressed: _save),
      children: [
        Center(child: Avatar(initials('${_first.text} ${_last.text}'), size: 100)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField('First name', controller: _first, icon: Icons.person_outline, error: _errors['first_name']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField('Last name', controller: _last, error: _errors['last_name']),
            ),
          ],
        ),
        CaboField('Phone', value: d.str('phone'), icon: Icons.phone_outlined, readOnly: true),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Your phone number is how you sign in. Contact support to change it.', style: CaboText.muted.copyWith(fontSize: 12)),
        ),
        CaboField('Email', controller: _email, icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, error: _errors['email']),
        CaboField('Home address', controller: _address, icon: Icons.home_outlined, error: _errors['address']),
        Text('Languages', style: CaboText.label),
        const SizedBox(height: 10),
        ChipPicker(options: _languages, initial: _langs, onChanged: (s) => _langs = s),
      ],
    );
  }
}

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () async => asJsonList(unwrap(await state.api.get('/driver/vehicles'))),
      builder: (context, vehicles, reload) => CaboScaffold(
        title: 'Vehicles',
        bottom: _adding
            ? CaboButton('Cancel', style: CaboButtonStyle.secondary, onPressed: () => setState(() => _adding = false))
            : CaboButton('Add a vehicle', icon: Icons.add_rounded, onPressed: () => setState(() => _adding = true)),
        children: [
          if (_adding) ...[
            Text('New vehicle', style: CaboText.h2),
            const SizedBox(height: 12),
            VehicleForm(
              onSaved: (v) async {
                setState(() => _adding = false);
                showMessage(context, 'Vehicle added. Upload its documents so we can approve it.');
                await reload();
              },
            ),
          ] else ...[
            Text('Choose the vehicle you are driving today. Go offline before switching.', style: CaboText.muted),
            const SizedBox(height: 14),
            if (vehicles.isEmpty) const EmptyNotice('You have not added a vehicle yet.', icon: Icons.directions_car_rounded),
            for (final v in vehicles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VehicleCard(
                  v,
                  trailing: v.flag('is_active')
                      ? const Pill('Driving this today', icon: Icons.check)
                      : v.str('status') == 'approved'
                      ? ActionButton(
                          'Drive this vehicle',
                          height: 40,
                          style: CaboButtonStyle.secondary,
                          onPressed: () async {
                            await state.api.post('/driver/vehicles/${v.integer('id')}/activate');
                            await state.refreshDriver();
                            await reload();
                          },
                        )
                      : Text('You can drive it once Cabo approves it.', style: CaboText.muted),
                ),
              ),
            MenuTile(
              icon: Icons.description_rounded,
              title: 'Vehicle documents',
              subtitle: 'Licence, roadworthiness and insurance',
              onTap: () => go(context, '/documents'),
            ),
          ],
        ],
      ),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final summary = state.driver?.obj('documents_summary');
    final expired = summary?.list('expired') ?? const <Json>[];
    final expiring = summary?.list('expiring_soon') ?? const <Json>[];
    final vehicleId = state.vehicle?['id'] as int?;
    return CaboScaffold(
      title: 'Documents',
      children: [
        for (final (docs, colour, text) in [
          (expired, CaboColors.red, 'has expired. Upload a new one to go online.'),
          (expiring, CaboColors.orange, 'expires soon. Renew it to keep driving.'),
        ])
          for (final doc in docs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CaboCard(
                color: colour.withValues(alpha: 0.14),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colour),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Your ${doc.str('label').toLowerCase()} $text', style: CaboText.body.copyWith(fontSize: 13))),
                  ],
                ),
              ),
            ),
        const SectionTitle('Host'),
        DocumentTiles(const [...personalDocuments, 'selfie'], onChanged: state.refreshDriver),
        const SectionTitle('Vehicle'),
        DocumentTiles(const [...vehicleDocuments, 'vehicle_photo'], vehicleId: vehicleId, onChanged: state.refreshDriver),
      ],
    );
  }
}

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context).driver ?? const {};
    final number = d.strOrNull('bank_account_number');
    return CaboScaffold(
      title: 'Bank details',
      children: [
        if (number != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [CaboColors.green, CaboColors.surfaceHigh]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payout account', style: CaboText.label.copyWith(color: Colors.white70)),
                const SizedBox(height: 10),
                Text(d.str('bank_name'), style: CaboText.h2),
                Text('•••• •• ${number.substring(number.length - 4)}', style: CaboText.h1.copyWith(letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(d.str('bank_account_name').toUpperCase(), style: CaboText.label.copyWith(color: Colors.white)),
              ],
            ),
          ),
        SectionTitle(number == null ? 'Add your account' : 'Change account'),
        BankForm(
          buttonLabel: number == null ? 'Save bank account' : 'Update bank account',
          onSaved: () async {
            showMessage(context, 'Bank details saved.');
            back(context);
          },
        ),
      ],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return CaboCard(
      child: Row(
        children: [
          IconBadge(icon, color: CaboColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: CaboText.muted)),
        ],
      ),
    );
  }
}

class NavigationSettingsScreen extends StatelessWidget {
  const NavigationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Navigation',
      children: [
        const MenuTile(
          icon: Icons.map_rounded,
          title: 'Your phone\'s maps app',
          subtitle: 'The Navigate button on each trip opens directions in Google Maps or your default maps app.',
        ),
        const SizedBox(height: 10),
        const _ComingSoon(Icons.navigation_rounded, 'Built-in turn-by-turn navigation and route options are coming soon.'),
        const SizedBox(height: 16),
        CaboButton(
          'Test navigation',
          style: CaboButtonStyle.secondary,
          icon: Icons.navigation_rounded,
          // Tafawa Balewa Square, a central landmark.
          onPressed: () => openNavigation(context, 6.4474, 3.3950),
        ),
      ],
    );
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spoken = AppScope.of(context).driver?.strings('languages') ?? const <String>[];
    return CaboScaffold(
      title: 'Language',
      children: [
        const SectionTitle('App language'),
        const MenuTile(
          icon: Icons.language_rounded,
          title: 'English',
          trailing: Pill('In use', icon: Icons.check),
        ),
        const SizedBox(height: 8),
        const _ComingSoon(Icons.translate_rounded, 'Pidgin, Yorùbá, Igbo, Hausa and French are coming soon.'),
        const SectionTitle('Languages you speak'),
        MenuTile(
          icon: Icons.record_voice_over_rounded,
          title: spoken.isEmpty ? 'None added' : spoken.join(', '),
          subtitle: 'Shown to Cabo so visitors can be matched with hosts who speak their language',
          onTap: () => go(context, '/edit-profile'),
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
      title: 'Notifications and sounds',
      bottom: CaboButton('Open my notifications', onPressed: () => go(context, '/notifications')),
      children: const [
        MenuTile(
          icon: Icons.notifications_active_rounded,
          title: 'Ride requests',
          subtitle: 'New requests appear on your home screen while you are online. Keep the app open.',
        ),
        MenuTile(
          icon: Icons.inbox_rounded,
          title: 'In-app inbox',
          subtitle: 'Document reviews, payouts and support replies arrive in your notifications.',
        ),
        SizedBox(height: 10),
        _ComingSoon(Icons.volume_up_rounded, 'Push alerts, request sounds and vibration settings are coming soon.'),
      ],
    );
  }
}

class ReferScreen extends StatelessWidget {
  const ReferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = AppScope.of(context).driver?.strOrNull('referral_code');
    return CaboScaffold(
      title: 'Refer a host',
      bottom: code == null
          ? null
          : CaboButton(
              'Copy my code',
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) showMessage(context, 'Copied $code. Share it with a driver you trust.');
              },
            ),
      children: [
        const Center(child: HeroIllustration(Icons.group_add_rounded, size: 150)),
        const SizedBox(height: 16),
        Center(
          child: Text('Invite a driver to host with Cabo', style: CaboText.h2, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('They give your code to the Cabo team when they apply.', style: CaboText.muted, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
        if (code != null)
          CaboCard(
            child: Column(
              children: [
                Text('Your code', style: CaboText.label),
                Text(code, style: CaboText.h1.copyWith(color: CaboColors.yellow, letterSpacing: 3)),
              ],
            ),
          )
        else
          const _ComingSoon(Icons.card_giftcard_rounded, 'Your referral code appears here once your account is approved.'),
        const SizedBox(height: 12),
        const _ComingSoon(Icons.payments_rounded, 'Referral rewards and tracking are coming soon.'),
      ],
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AppScope.read(context).config.obj('support')?.strOrNull('email');
    return CaboScaffold(
      title: 'Legal',
      children: [
        MenuTile(
          icon: Icons.article_rounded,
          title: 'Host terms and privacy policy',
          subtitle: 'caboapp.online',
          onTap: () => launchUrl(Uri.parse('https://caboapp.online'), mode: LaunchMode.externalApplication),
        ),
        if (email != null)
          MenuTile(
            icon: Icons.download_rounded,
            title: 'Ask for a copy of my data',
            subtitle: email,
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: email, query: 'subject=My Cabo Host data')),
          ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Cabo Host • Lagos, Nigeria\nVersion 1.0.0',
            textAlign: TextAlign.center,
            style: CaboText.muted.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class LogoutDeleteScreen extends StatelessWidget {
  const LogoutDeleteScreen({super.key});

  Future<void> _requestDeletion(BuildContext context) async {
    final state = AppScope.read(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Ask Cabo to delete your account?'),
        content: const Text('Support will confirm with you, settle any balance and then delete your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Keep my account')),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Send request', style: TextStyle(color: CaboColors.red)),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final ticket = unwrap(
      await state.api.post('/driver/support/tickets', {
        'category': 'account',
        'subject': 'Delete my account',
        'message': 'Please delete my Cabo Host account and pay out any remaining balance.',
      }),
    ) as Json;
    state.select(ticket: ticket);
    if (context.mounted) go(context, '/support-chat');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final d = state.driver ?? const {};
    return CaboScaffold(
      title: 'Log out or delete',
      children: [
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out', style: CaboText.h3),
              const SizedBox(height: 4),
              Text('You will go offline and need your phone number to log back in.', style: CaboText.muted),
              const SizedBox(height: 14),
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
          ),
        ),
        const SizedBox(height: 14),
        CaboCard(
          color: CaboColors.red.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete account', style: CaboText.h3.copyWith(color: CaboColors.red)),
              const SizedBox(height: 4),
              Text('Before your account can be deleted:', style: CaboText.muted),
              const SizedBox(height: 8),
              for (final t in [
                'Your earnings balance of ${naira(d.integer('earnings_balance'))} is paid out',
                'Cash commission of ${naira(d.integer('cash_commission_owed'))} is settled',
                'Any scheduled airport or tour jobs are handed back',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 7, color: CaboColors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: CaboText.body.copyWith(fontSize: 13))),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ActionButton(
                'Ask to delete my account',
                style: CaboButtonStyle.danger,
                icon: Icons.delete_rounded,
                onPressed: () => _requestDeletion(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
