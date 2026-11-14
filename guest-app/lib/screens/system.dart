import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/widgets.dart';

// 11. System and edge cases, plus the screen gallery.

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.wifi_off_rounded,
      color: CaboColors.orange,
      title: 'No internet connection',
      message: 'Check your data or Wi-Fi. Your bookings and tickets are saved on this phone.',
      primary: 'Try again',
      secondary: 'View my ticket offline',
      onSecondary: () => go(context, '/ticket'),
    );
  }
}

class LocationOffScreen extends StatelessWidget {
  const LocationOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.location_off_rounded,
      title: 'Turn on location',
      message: 'We use it to find you at pickup and suggest landmarks nearby. You can also type your pickup.',
      primary: 'Open settings',
      secondary: 'Enter pickup manually',
      onSecondary: () => go(context, '/where-to'),
    );
  }
}

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.credit_card_off_rounded,
      color: CaboColors.red,
      title: 'Payment did not go through',
      message: 'Your bank declined Visa •• 4242. Foreign cards sometimes need approval in your banking app.',
      primary: 'Try another method',
      onPrimary: () => go(context, '/payment-method'),
      secondary: 'Pay by bank transfer',
      onSecondary: () => go(context, '/bank-transfer'),
    );
  }
}

class NoDriversScreen extends StatelessWidget {
  const NoDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.car_crash_rounded,
      color: CaboColors.orange,
      title: 'No drivers nearby right now',
      message: 'It is a busy evening in Victoria Island. Try again in a few minutes or choose another ride type.',
      primary: 'Try again',
      onPrimary: () => go(context, '/finding-driver'),
      secondary: 'Schedule for later',
      onSecondary: () => go(context, '/schedule-ride'),
    );
  }
}

class OutsideAreaScreen extends StatelessWidget {
  const OutsideAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        serviceArea: true,
        markers: [
          MapMarker(Offset(0.88, 0.86), MarkerKind.dropoff, label: 'Epe'),
        ],
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("We don't go there yet", style: CaboText.h2),
          const SizedBox(height: 6),
          Text(
            'Cabo currently runs in Victoria Island, Ikoyi, Lekki, Yaba and Surulere. '
            'Epe is outside the pilot area.',
            style: CaboText.muted,
          ),
          const SizedBox(height: 16),
          CaboButton(
            'Choose another destination',
            onPressed: () => go(context, '/where-to'),
          ),
        ],
      ),
    );
  }
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StateScreen(
      icon: Icons.system_update_rounded,
      title: 'Update required',
      message: 'This version of Cabo is no longer supported. Update to keep booking rides and tours.',
      primary: 'Update now',
      top: Padding(
        padding: EdgeInsets.only(top: 12),
        child: CaboLogo(size: 32),
      ),
    );
  }
}

/// Lists every screen so reviewers can jump straight to any of them.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'All screens',
      children: [
        Text(
          'Every screen in this build, grouped by section.',
          style: CaboText.muted,
        ),
        for (final section in sectionNames.entries) ...[
          SectionTitle('${section.key}. ${section.value}'),
          for (final s in screens.where((s) => s.section == section.key))
            MenuTile(
              icon: Icons.phone_android_rounded,
              title: s.title,
              subtitle: '${s.id} • ${s.route}',
              onTap: () => go(context, s.route),
            ),
        ],
      ],
    );
  }
}
