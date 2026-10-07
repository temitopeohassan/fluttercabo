import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 9. System and edge-case screens.

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.wifi_off_rounded,
      color: CaboColors.orange,
      title: 'No internet connection',
      message:
          'You will not receive new requests until you reconnect. '
          'Your current trip is saved.',
      primary: 'Try again',
      extra: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: kScreenshotMode ? 0.7 : null,
            ),
          ),
          const SizedBox(width: 10),
          Text('Reconnecting…', style: CaboText.muted),
        ],
      ),
    );
  }
}

class GpsLostScreen extends StatelessWidget {
  const GpsLostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CaboMap(
              dimmed: true,
              markers: [MapMarker(Offset(0.45, 0.4), MarkerKind.driver)],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CaboCard(
                    color: CaboColors.deepGreen,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const IconBadge(
                          Icons.gps_off_rounded,
                          color: CaboColors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 14),
                        Text('GPS signal lost', style: CaboText.h1),
                        const SizedBox(height: 6),
                        Text(
                          'We cannot find your location. Move away from tall buildings or '
                          'tunnels, and check location is set to "Always".',
                          textAlign: TextAlign.center,
                          style: CaboText.muted,
                        ),
                        const SizedBox(height: 18),
                        CaboButton('Open location settings', onPressed: () {}),
                      ],
                    ),
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

class AccountOnHoldScreen extends StatelessWidget {
  const AccountOnHoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.pause_circle_filled_rounded,
      color: CaboColors.red,
      title: 'Your account is on hold',
      message:
          'We received a safety report about a trip on 3 October. '
          'You cannot go online while we review it.',
      primary: 'Contact support',
      onPrimary: () => go(context, '/support-chat'),
      secondary: 'Read community guidelines',
      onSecondary: () => go(context, '/legal'),
      extra: CaboCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Steps to resolve', style: CaboText.h3),
            const SizedBox(height: 8),
            for (final (done, t) in const [
              (true, 'Report received • 4 Oct'),
              (true, 'Your statement submitted • 5 Oct'),
              (false, 'Review by Cabo Safety (usually 48 h)'),
              (false, 'Decision sent to you by SMS and email'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: done ? CaboColors.brightGreen : CaboColors.muted,
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
          ],
        ),
      ),
    );
  }
}

class DocumentExpiredScreen extends StatelessWidget {
  const DocumentExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.event_busy_rounded,
      color: CaboColors.orange,
      title: 'Insurance certificate expired',
      message:
          'You cannot go online until you upload a valid certificate. '
          'Most renewals are approved within 2 hours.',
      primary: 'Upload new certificate',
      onPrimary: () => go(context, '/vehicle-documents'),
      extra: Column(
        children: [
          const CaboCard(
            child: Column(
              children: [
                InfoRow('Document', 'Insurance certificate'),
                InfoRow('Vehicle', 'Toyota Corolla • LND 482 KJ'),
                InfoRow('Expired', '18 Oct 2026', valueColor: CaboColors.red),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CaboButton(
            'Go online',
            icon: Icons.lock_rounded,
            style: CaboButtonStyle.secondary,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class OutsideServiceAreaScreen extends StatelessWidget {
  const OutsideServiceAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        serviceArea: true,
        markers: [MapMarker(Offset(0.88, 0.86), MarkerKind.driver)],
      ),
      top: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CaboColors.orange,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wrong_location_rounded,
              color: CaboColors.onYellow,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are outside the Cabo service area',
                style: CaboText.body.copyWith(
                  color: CaboColors.onYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      panel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Head back to receive trips', style: CaboText.h2),
          const SizedBox(height: 6),
          Text(
            'During the pilot, Cabo runs in Victoria Island, Ikoyi, Lekki, Yaba and Surulere. '
            'You are 7 km from the nearest zone.',
            style: CaboText.muted,
          ),
          const SizedBox(height: 16),
          CaboButton(
            'Navigate to Lekki Phase 1',
            icon: Icons.navigation_rounded,
            onPressed: () => go(context, '/home'),
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
    return StateScreen(
      icon: Icons.system_update_rounded,
      title: 'Update required',
      message:
          'This version of Cabo Driver is no longer supported. '
          'Update to keep receiving trips.',
      primary: 'Update now',
      top: const Padding(
        padding: EdgeInsets.only(top: 12),
        child: CaboLogo(size: 30, driverLabel: false),
      ),
      extra: CaboCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What's new in 1.1", style: CaboText.h3),
            const SizedBox(height: 8),
            for (final t in const [
              'Faster airport pickup check-in',
              'Instant cash-out to any Nigerian bank',
              'Better navigation around Lekki toll gates',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: CaboColors.brightGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: CaboText.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
