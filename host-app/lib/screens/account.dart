import 'package:flutter/material.dart';

import '../widgets/widgets.dart';
import 'onboarding.dart' show DocStatus, DocTile;

// 8. Account and settings.

class AccountOverviewScreen extends StatelessWidget {
  const AccountOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
    return CaboScaffold(
      title: 'Account',
      showBack: false,
      bottomNav: const DriverNav(3),
      children: [
        Row(
          children: [
            const Avatar('EN', size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emeka Nwosu', style: CaboText.h2),
                  const SizedBox(height: 4),
                  const Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill('4.92', icon: Icons.star_rounded),
                      Pill('Standard', color: CaboColors.blue),
                      Pill(
                        'Active',
                        color: CaboColors.brightGreen,
                        icon: Icons.circle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: CaboColors.yellow),
              onPressed: () => go(context, '/edit-profile'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CaboCard(
          onTap: () => go(context, '/vehicles'),
          child: Row(
            children: [
              const IconBadge(Icons.directions_car_filled_rounded, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toyota Corolla 2019', style: CaboText.h3),
                    Text(
                      'Silver • LND 482 KJ • Comfort',
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
          (
            Icons.description_rounded,
            'Documents',
            '1 expiring soon',
            '/documents',
          ),
          (
            Icons.account_balance_rounded,
            'Bank details',
            'GTBank ••6789',
            '/bank-details',
          ),
          (Icons.bar_chart_rounded, 'Ratings', null, '/ratings'),
          (Icons.insights_rounded, 'Performance', null, '/performance'),
          (Icons.workspace_premium_rounded, 'Tiers and badges', null, '/tiers'),
          (Icons.school_rounded, 'Learning centre', null, '/learning-centre'),
        ]),
        group('Settings', [
          (
            Icons.navigation_rounded,
            'Navigation',
            'Cabo Navigation',
            '/navigation-settings',
          ),
          (Icons.translate_rounded, 'Language', 'English', '/language'),
          (
            Icons.notifications_rounded,
            'Notifications and sounds',
            null,
            '/notification-settings',
          ),
        ]),
        group('Support', [
          (Icons.shield_rounded, 'Safety toolkit', null, '/safety'),
          (Icons.help_rounded, 'Help centre', null, '/help'),
          (
            Icons.confirmation_number_rounded,
            'Support tickets',
            '2 open',
            '/support-tickets',
          ),
          (
            Icons.card_giftcard_rounded,
            'Refer a driver',
            'Earn ₦15,000',
            '/refer',
          ),
          (Icons.gavel_rounded, 'Legal', null, '/legal'),
          (
            Icons.logout_rounded,
            'Log out or delete account',
            null,
            '/logout-delete',
          ),
        ]),
        group('Preview', [
          (
            Icons.grid_view_rounded,
            'All screens',
            'Browse every screen in this build',
            '/gallery',
          ),
        ]),
      ],
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Edit profile',
      bottom: CaboButton('Save changes', onPressed: () => back(context)),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              const Avatar('EN', size: 100),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CaboColors.brightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: CaboColors.onYellow,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Photo changes are reviewed before riders see them',
            style: CaboText.muted.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        const CaboField(
          'Full name',
          value: 'Emeka Nwosu',
          icon: Icons.person_outline,
        ),
        const CaboField(
          'Phone',
          value: '+234 803 412 7765',
          icon: Icons.phone_outlined,
        ),
        const CaboField(
          'Email',
          value: 'emeka.nwosu@gmail.com',
          icon: Icons.mail_outline,
        ),
        const CaboField(
          'Home address',
          value: '12 Adeniran Ogunsanya St, Surulere',
          icon: Icons.home_outlined,
        ),
        Text('Languages', style: CaboText.label),
        const SizedBox(height: 8),
        const ChipPicker(
          options: ['English', 'Igbo', 'Pidgin', 'Yoruba', 'Hausa', 'French'],
          initial: {0, 1, 2},
        ),
        const SizedBox(height: 16),
        const CaboField(
          'About me (shown to tour guests)',
          value: 'Born in Enugu, driving in Lagos for 12 years. Ask me about the best suya spots!',
          maxLines: 3,
        ),
      ],
    );
  }
}

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  int active = 0;

  @override
  Widget build(BuildContext context) {
    const vehicles = [
      ('Toyota Corolla 2019', 'Silver • LND 482 KJ', 'Standard, Comfort', true),
      (
        'Toyota Sienna 2018',
        'Black • KJA 911 AB • Fleet: Eko Mobility',
        'Standard, XL',
        true,
      ),
      ('Honda Accord 2021', 'White • EKY 220 LG', 'Inspection pending', false),
    ];
    return CaboScaffold(
      title: 'Vehicles',
      bottom: CaboButton(
        'Add a vehicle',
        icon: Icons.add_rounded,
        onPressed: () => go(context, '/vehicle-details'),
      ),
      children: [
        Text(
          'Choose the vehicle you are driving today.',
          style: CaboText.muted,
        ),
        const SizedBox(height: 14),
        for (final (i, (name, info, tiers, ready)) in vehicles.indexed)
          SelectTile(
            icon: Icons.directions_car_filled_rounded,
            title: name,
            subtitle: '$info\n$tiers',
            selected: active == i,
            onTap: ready ? () => setState(() => active = i) : () {},
            trailing: ready
                ? null
                : const Pill('Pending', color: CaboColors.orange),
          ),
        const SizedBox(height: 6),
        MenuTile(
          icon: Icons.edit_note_rounded,
          title: 'Update vehicle details',
          subtitle: 'Colour, plate or documents',
          onTap: () => go(context, '/vehicle-documents'),
        ),
      ],
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Documents',
      children: [
        CaboCard(
          color: CaboColors.orange.withValues(alpha: 0.14),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: CaboColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your insurance expires in 12 days. Renew it to keep driving.',
                  style: CaboText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Driver'),
        const DocTile(
          "Driver's licence",
          'Expires 14 Mar 2029',
          DocStatus.approved,
          icon: Icons.badge_outlined,
        ),
        const DocTile(
          'National ID (NIN)',
          'No expiry',
          DocStatus.approved,
          icon: Icons.perm_identity_rounded,
        ),
        const DocTile(
          'LASDRI card',
          'Expires 30 Jun 2027',
          DocStatus.approved,
          icon: Icons.credit_card_rounded,
        ),
        const SectionTitle('Vehicle'),
        DocTile(
          'Insurance certificate',
          'Expires 18 Oct 2026 • 12 days',
          DocStatus.expiring,
          icon: Icons.shield_outlined,
          onTap: () => go(context, '/document-expired'),
        ),
        const DocTile(
          'Roadworthiness certificate',
          'Expires 18 Jan 2027',
          DocStatus.approved,
          icon: Icons.build_circle_outlined,
        ),
        const DocTile(
          'Vehicle licence',
          'Expires 02 Mar 2027',
          DocStatus.approved,
          icon: Icons.directions_car_outlined,
        ),
      ],
    );
  }
}

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Bank details',
      bottom: CaboButton('Update bank account', onPressed: () => back(context)),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CaboColors.green, CaboColors.surfaceHigh],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: CaboColors.yellow,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Payout account',
                    style: CaboText.label.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                  const Pill(
                    'Verified',
                    color: CaboColors.brightGreen,
                    icon: Icons.check,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('GTBank', style: CaboText.h2),
              Text(
                '•••• •••• 6789',
                style: CaboText.h1.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'EMEKA CHUKWUDI NWOSU',
                style: CaboText.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SectionTitle('Change account'),
        const CaboField(
          'Bank',
          hint: 'Select bank',
          icon: Icons.account_balance_outlined,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        const CaboField(
          'Account number',
          hint: '10-digit NUBAN',
          icon: Icons.numbers_rounded,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: CaboColors.yellow),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'For your security, payouts pause for 24 hours after a bank change.',
                style: CaboText.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NavigationSettingsScreen extends StatelessWidget {
  const NavigationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaboScaffold(
      title: 'Navigation',
      children: [
        SectionTitle('Navigation app'),
        SingleChoice(
          icons: [
            Icons.navigation_rounded,
            Icons.map_rounded,
            Icons.alt_route_rounded,
          ],
          options: [
            ('Cabo Navigation', 'Built in, with pickup tips for tourists'),
            ('Google Maps', 'Opens Google Maps for each trip'),
            ('Waze', 'Opens Waze for each trip'),
          ],
        ),
        SectionTitle('Route options'),
        ToggleTile('Voice guidance', icon: Icons.record_voice_over_rounded),
        ToggleTile(
          'Avoid toll roads',
          subtitle: 'Lekki toll gates',
          initial: false,
          icon: Icons.toll_rounded,
        ),
        ToggleTile('Night mode after sunset', icon: Icons.dark_mode_rounded),
      ],
    );
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaboScaffold(
      title: 'Language',
      children: [
        SectionTitle('App language'),
        SingleChoice(
          options: [
            ('English', null),
            ('Nigerian Pidgin', null),
            ('Yorùbá', null),
            ('Igbo', null),
            ('Hausa', null),
            ('Français', null),
          ],
        ),
        SectionTitle('Rider messages'),
        ToggleTile(
          'Translate rider messages',
          subtitle: 'Show messages from riders in English',
          icon: Icons.translate_rounded,
        ),
      ],
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  double volume = 0.8;

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Notifications and sounds',
      children: [
        const SectionTitle('Trip requests'),
        const MenuTile(
          icon: Icons.music_note_rounded,
          title: 'Request sound',
          subtitle: 'Talking drum',
          trailing: Icon(Icons.chevron_right, color: CaboColors.muted),
        ),
        Row(
          children: [
            const Icon(Icons.volume_down_rounded, color: CaboColors.muted),
            Expanded(
              child: Slider(
                value: volume,
                onChanged: (v) => setState(() => volume = v),
              ),
            ),
            const Icon(Icons.volume_up_rounded, color: CaboColors.muted),
          ],
        ),
        const ToggleTile(
          'Vibrate on new request',
          icon: Icons.vibration_rounded,
        ),
        const ToggleTile(
          'Sound for approaching stops',
          icon: Icons.campaign_rounded,
        ),
        const SectionTitle('Notifications'),
        const ToggleTile(
          'Scheduled jobs',
          subtitle: 'New airport and tour jobs',
        ),
        const ToggleTile('Earnings and payouts'),
        const ToggleTile('Document reminders'),
        const ToggleTile('Promotions and tips', initial: false),
      ],
    );
  }
}

class ReferScreen extends StatelessWidget {
  const ReferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Refer a driver',
      bottom: CaboButton(
        'Share invite',
        icon: Icons.share_rounded,
        onPressed: () {},
      ),
      children: [
        const Center(
          child: HeroIllustration(
            Icons.card_giftcard_rounded,
            size: 170,
            badges: [Icons.person_add_rounded, Icons.payments_rounded],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Earn ₦15,000 for every driver you refer',
            style: CaboText.h2,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Paid when they complete 50 trips in their first 30 days.',
            style: CaboText.muted,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        CaboCard(
          borderColor: CaboColors.yellow,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your code', style: CaboText.label),
                    Text(
                      'EMEKA250',
                      style: CaboText.h1.copyWith(
                        color: CaboColors.yellow,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_rounded, color: CaboColors.yellow),
            ],
          ),
        ),
        const SectionTitle('Your referrals'),
        for (final (name, progress, status) in const [
          ('Tunde A.', 1.0, 'Paid ₦15,000'),
          ('Chioma E.', 0.64, '32 of 50 trips'),
          ('Musa B.', 0.0, 'Documents pending'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      status,
                      style: CaboText.label.copyWith(
                        color: progress == 1
                            ? CaboColors.brightGreen
                            : CaboColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Bar(
                  progress,
                  color: progress == 1
                      ? CaboColors.brightGreen
                      : CaboColors.yellow,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Legal',
      children: [
        for (final (title, updated) in const [
          ('Driver terms of service', 'Updated 1 Sep 2026'),
          ('Privacy policy', 'Updated 1 Sep 2026'),
          ('Driver privacy notice (background checks)', 'Updated 15 Aug 2026'),
          ('Community guidelines', 'Updated 1 Jul 2026'),
          ('Open-source licences', 'Software used in this app'),
        ])
          MenuTile(
            icon: Icons.article_rounded,
            title: title,
            subtitle: updated,
            onTap: () {},
          ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Cabo Mobility Ltd • RC 1234567 • Lagos, Nigeria\nApp version 1.0.0',
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

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Log out or delete',
      children: [
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out', style: CaboText.h3),
              const SizedBox(height: 4),
              Text(
                'You will go offline and need your phone number to log back in.',
                style: CaboText.muted,
              ),
              const SizedBox(height: 14),
              CaboButton(
                'Log out',
                style: CaboButtonStyle.secondary,
                icon: Icons.logout_rounded,
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/sign-in', (_) => false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CaboCard(
          color: CaboColors.red.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete account',
                style: CaboText.h3.copyWith(color: CaboColors.red),
              ),
              const SizedBox(height: 8),
              for (final t in const [
                'Your profile, ratings and documents are deleted after 30 days',
                'Any balance (₦96,400) is paid out first',
                'Trip records are kept for 6 years as required by law',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: CaboColors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t,
                          style: CaboText.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              CaboButton(
                'Delete my account',
                style: CaboButtonStyle.danger,
                icon: Icons.delete_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
