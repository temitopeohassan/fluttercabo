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
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, value: kScreenshotMode ? 0.7 : null)),
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
          const Positioned.fill(child: CaboMap(dimmed: true, markers: [MapMarker(Offset(0.45, 0.4), MarkerKind.driver)])),
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
                        const IconBadge(Icons.gps_off_rounded, color: CaboColors.orange, size: 64),
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
    final state = AppScope.of(context);
    final reason = state.driver?.strOrNull('status_reason');
    return StateScreen(
      icon: Icons.pause_circle_filled_rounded,
      color: CaboColors.orange,
      title: 'Your account is on hold',
      message: reason ?? 'You cannot go online while the Cabo team reviews your account. Contact support to find out more.',
      primary: 'Contact support',
      onPrimary: () => go(context, '/support-chat'),
      secondary: 'Log out',
      onSecondary: () async {
        await state.signOut();
        if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
      },
      extra: CaboCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What happens next', style: CaboText.h3),
            const SizedBox(height: 8),
            for (final t in const [
              'Cabo reviews your account, usually within 48 hours',
              'Support may ask you for a statement or documents',
              'You get the decision in your notifications',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_unchecked, size: 20, color: CaboColors.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: CaboText.body.copyWith(fontSize: 13))),
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
    final state = AppScope.of(context);
    final expired = state.driver?.obj('documents_summary')?.list('expired') ?? const <Json>[];
    final v = state.vehicle;
    return StateScreen(
      icon: Icons.event_busy_rounded,
      color: CaboColors.orange,
      title: expired.isEmpty ? 'Your documents are in date' : '${expired.first.str('label')} expired',
      message: expired.isEmpty
          ? 'None of your documents has expired. You will see a warning here when one does.'
          : 'You cannot go online until you upload a valid one. The Cabo team reviews new documents within 48 hours.',
      primary: expired.isEmpty ? 'See my documents' : 'Upload a new document',
      onPrimary: () => go(context, '/documents'),
      extra: expired.isEmpty
          ? null
          : CaboCard(
              child: Column(
                children: [
                  for (final doc in expired) ...[
                    InfoRow('Document', doc.str('label')),
                    InfoRow('Expired', fmtDate(doc.date('expires_at')), valueColor: CaboColors.red),
                  ],
                  if (v != null) InfoRow('Vehicle', '${v.str('make')} ${v.str('model')} • ${v.str('plate_number')}'),
                ],
              ),
            ),
    );
  }
}

class OutsideServiceAreaScreen extends StatelessWidget {
  const OutsideServiceAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = AppScope.of(context).config.list('service_areas');
    return MapLayout(
      map: const CaboMap(serviceArea: true, markers: [MapMarker(Offset(0.88, 0.86), MarkerKind.driver)]),
      top: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: CaboColors.orange, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.wrong_location_rounded, color: CaboColors.onYellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are outside the Cabo service area',
                style: CaboText.body.copyWith(color: CaboColors.onYellow, fontWeight: FontWeight.w700),
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
            areas.isEmpty
                ? 'Requests only reach you inside the areas Cabo serves.'
                : 'Cabo runs in ${[for (final a in areas) a.str('name')].join(', ')}.',
            style: CaboText.muted,
          ),
          const SizedBox(height: 16),
          if (areas.isNotEmpty)
            CaboButton(
              'Navigate to ${areas.first.str('name')}',
              icon: Icons.navigation_rounded,
              onPressed: () => openNavigation(context, areas.first.number('center_lat'), areas.first.number('center_lng')),
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
          'This version of Cabo Host is no longer supported. '
          'Update to keep receiving trips.',
      primary: 'Update now',
      top: const Padding(padding: EdgeInsets.only(top: 12), child: CaboLogo(size: 30, hostLabel: false)),
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
                    const Icon(Icons.check_rounded, size: 18, color: CaboColors.brightGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: CaboText.body.copyWith(fontSize: 13))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
