import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 10. Profile and settings.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
      title: 'Profile',
      showBack: false,
      bottomNav: const RiderNav(3),
      children: [
        Row(
          children: [
            const Avatar('TB', size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tunde Bakare', style: CaboText.h2),
                  Text('+44 7700 900 412', style: CaboText.muted),
                  const SizedBox(height: 4),
                  const Wrap(
                    spacing: 6,
                    children: [
                      Pill(
                        'International visitor',
                        icon: Icons.flight_land_rounded,
                      ),
                      Pill('1,240 pts', color: CaboColors.orange),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: CaboColors.green),
              onPressed: () => go(context, '/edit-profile'),
            ),
          ],
        ),
        group('Account', [
          (
            Icons.account_balance_wallet_rounded,
            'Wallet',
            '₦12,400',
            '/wallet',
          ),
          (Icons.place_rounded, 'Saved places', 'Hotel, Work', '/saved-places'),
          (Icons.favorite_rounded, 'Wishlist', '5 saved', '/wishlist'),
          (
            Icons.event_note_rounded,
            'My Lagos plan',
            'Itinerary',
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
          (Icons.translate_rounded, 'Language', 'English', '/language'),
          (
            Icons.currency_exchange_rounded,
            'Home currency',
            'GBP (£)',
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
            'Not set',
            '/accessibility',
          ),
        ]),
        group('Safety and help', [
          (Icons.shield_rounded, 'Safety centre', null, '/safety'),
          (
            Icons.contacts_rounded,
            'Trusted contacts',
            '2 contacts',
            '/trusted-contacts',
          ),
          (Icons.help_rounded, 'Help centre', null, '/help'),
          (
            Icons.confirmation_number_rounded,
            'Support tickets',
            '1 open',
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
      bottom: CaboButton('Save', onPressed: () => back(context)),
      children: [
        const Center(child: Avatar('TB', size: 96)),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: CaboField('First name', value: 'Tunde')),
            SizedBox(width: 12),
            Expanded(child: CaboField('Last name', value: 'Bakare')),
          ],
        ),
        const CaboField(
          'Phone',
          value: '+44 7700 900 412',
          icon: Icons.phone_outlined,
        ),
        const CaboField(
          'Email',
          value: 'tunde.bakare@gmail.com',
          icon: Icons.mail_outline,
        ),
        const CaboField(
          'Nationality',
          value: 'British',
          icon: Icons.flag_outlined,
        ),
        Text('I am a', style: CaboText.label),
        const SizedBox(height: 8),
        const ChipPicker(
          options: [
            'International visitor',
            'Domestic visitor',
            'Lagos resident',
          ],
          initial: {0},
          single: true,
        ),
      ],
    );
  }
}

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Saved places',
      bottom: CaboButton(
        'Add a place',
        icon: Icons.add_rounded,
        onPressed: () {},
      ),
      children: [
        for (final (icon, name, address) in const [
          (Icons.hotel_rounded, 'Hotel', 'Eko Hotel & Suites, Victoria Island'),
          (Icons.work_rounded, 'Work', 'Civic Towers, Ozumba Mbadiwe Ave'),
          (
            Icons.family_restroom_rounded,
            'Aunty Funmi',
            '14 Bourdillon Rd, Ikoyi',
          ),
        ])
          MenuTile(
            icon: icon,
            title: name,
            subtitle: address,
            trailing: const Icon(
              Icons.more_vert_rounded,
              color: CaboColors.muted,
            ),
          ),
      ],
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Language',
      children: [
        const SingleChoice(
          options: [
            ('English', null),
            ('Français', 'Coming soon'),
            ('Yorùbá', 'Coming soon'),
            ('Igbo', 'Coming soon'),
            ('Hausa', 'Coming soon'),
          ],
        ),
        Text(
          'Chats with drivers are translated automatically where possible.',
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
    return CaboScaffold(
      title: 'Home currency',
      children: [
        Text(
          'Shown as an estimate next to naira prices.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        const SingleChoice(
          initial: 0,
          options: [
            ('GBP • British pound', '£1 ≈ ₦2,000'),
            ('USD • US dollar', '\$1 ≈ ₦1,550'),
            ('EUR • Euro', '€1 ≈ ₦1,700'),
            ('KES • Kenyan shilling', 'KSh1 ≈ ₦12'),
            ('NGN only', 'Hide estimates'),
          ],
        ),
        Text(
          "Rates update daily. Your bank's rate may differ slightly.",
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
    return const CaboScaffold(
      title: 'Notifications',
      children: [
        SectionTitle('Trips and bookings'),
        ToggleTile(
          'Driver updates',
          subtitle: 'Arrival, delays and trip status',
        ),
        ToggleTile('Booking reminders', subtitle: 'Tours and airport pickups'),
        ToggleTile('Receipts by email'),
        SectionTitle('From Cabo'),
        ToggleTile('Offers and promo codes', initial: false),
        ToggleTile('Things to do this weekend'),
      ],
    );
  }
}

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Accessibility',
      bottom: CaboButton('Save', onPressed: () => back(context)),
      children: [
        Text(
          'Tell us what helps and we will match you with suitable vehicles, drivers and tours.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        const ToggleTile(
          'Wheelchair-accessible vehicle',
          initial: false,
          icon: Icons.accessible_rounded,
        ),
        const ToggleTile('Help with bags', icon: Icons.luggage_rounded),
        const ToggleTile(
          'I am visually impaired',
          initial: false,
          icon: Icons.visibility_off_rounded,
        ),
        const ToggleTile(
          'I am deaf or hard of hearing',
          initial: false,
          icon: Icons.hearing_disabled_rounded,
        ),
        const ToggleTile(
          'Travelling with a service animal',
          initial: false,
          icon: Icons.pets_rounded,
        ),
        const SizedBox(height: 10),
        const CaboField(
          'Notes for drivers and guides',
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
    return CaboScaffold(
      title: 'Legal and privacy',
      children: [
        for (final t in const [
          'Terms of service',
          'Privacy policy',
          'Tour booking terms',
          'Cookie settings',
          'Download my data',
        ])
          MenuTile(icon: Icons.article_rounded, title: t, onTap: () {}),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Cabo Mobility Ltd • Lagos, Nigeria\nVersion 1.0.0',
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

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Delete account',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CaboButton(
            'Delete my account',
            style: CaboButtonStyle.danger,
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          CaboButton(
            'Log out instead',
            style: CaboButtonStyle.secondary,
            height: 48,
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/sign-in', (_) => false),
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
          'Your profile, saved places and wishlist are deleted within 30 days',
        ),
        const CheckRow(
          'Your wallet balance (₦12,400) is refunded to Visa •• 4242',
        ),
        const CheckRow(
          'Upcoming bookings are cancelled under each partner policy',
          done: false,
        ),
        const CheckRow(
          'Receipts are kept for 6 years as the law requires',
          done: false,
        ),
      ],
    );
  }
}
