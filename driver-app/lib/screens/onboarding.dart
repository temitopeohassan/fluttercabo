import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 1. Onboarding and verification.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      _timer = Timer(const Duration(milliseconds: 2500), () {
        // Only advance if the splash is still the visible screen.
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          replace(context, '/welcome');
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E5233),
              CaboColors.deepGreen,
              Color(0xFF052617),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              height: 260,
              child: CustomPaint(
                painter: SkylinePainter(
                  buildingColor: const Color(0xFF0F5434),
                  water: true,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const CaboLogo(size: 76),
                  const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  Text(
                    'EARN  •  GROW  •  BE INDEPENDENT',
                    style: CaboText.label.copyWith(
                      color: Colors.white,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  Text(
                    'Drive Lagos.\nEarn on your terms.',
                    textAlign: TextAlign.center,
                    style: CaboText.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final controller = PageController();
  int page = 0;

  static const pages = [
    (
      Icons.directions_car_filled_rounded,
      [
        Icons.flight_land_rounded,
        Icons.landscape_rounded,
        Icons.payments_rounded,
      ],
      'Earn with rides,\nshuttles and tours',
      'Pick up visitors across Lagos, run airport shuttles and, once certified, guide tours for extra income.',
    ),
    (
      Icons.schedule_rounded,
      [
        Icons.wb_sunny_rounded,
        Icons.nightlight_round,
        Icons.event_available_rounded,
      ],
      'Flexible hours\nthat fit your life',
      'Go online whenever you want. Accept scheduled airport and tour jobs days in advance.',
    ),
    (
      Icons.account_balance_wallet_rounded,
      [
        Icons.calendar_month_rounded,
        Icons.bolt_rounded,
        Icons.trending_up_rounded,
      ],
      'Weekly payouts,\nstraight to your bank',
      'Get paid every Monday, or cash out instantly whenever you need it.',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const CaboLogo(size: 30, driverLabel: false),
                  const Spacer(),
                  TextButton(
                    onPressed: () => go(context, '/sign-in'),
                    child: Text(
                      'Skip',
                      style: CaboText.h3.copyWith(color: CaboColors.muted),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (p) => setState(() => page = p),
                  itemBuilder: (context, i) {
                    final (icon, badges, title, body) = pages[i];
                    return LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeroIllustration(
                                icon,
                                size: (c.maxHeight * 0.45).clamp(140, 240),
                                badges: badges,
                              ),
                              const SizedBox(height: 32),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: CaboText.h1,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: CaboText.muted.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == page ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == page
                            ? CaboColors.yellow
                            : CaboColors.outline,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              CaboButton(
                page == pages.length - 1 ? 'Get started' : 'Next',
                onPressed: () => page == pages.length - 1
                    ? go(context, '/sign-in')
                    : controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => go(context, '/sign-in'),
                child: Text.rich(
                  TextSpan(
                    text: 'Already driving with Cabo? ',
                    style: CaboText.muted,
                    children: [
                      TextSpan(
                        text: 'Log in',
                        style: CaboText.muted.copyWith(
                          color: CaboColors.yellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2E6E8E),
                          Color(0xFFF2A65A),
                          Color(0xFF1C5A3A),
                          CaboColors.deepGreen,
                        ],
                        stops: [0, 0.45, 0.8, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    height: 220,
                    child: CustomPaint(
                      painter: SkylinePainter(
                        buildingColor: const Color(0xFF0C3B27),
                        water: true,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => back(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: CaboText.h2.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const CaboLogo(size: 48, driverLabel: false),
                  const SizedBox(height: 10),
                  Text(
                    'Sign up or log in with your phone number. We will text you a code.',
                    style: CaboText.muted.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  Text('Phone number', style: CaboText.label),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: CaboColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CaboColors.outline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 15,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF008751),
                                    Color(0xFF008751),
                                    Colors.white,
                                    Colors.white,
                                    Color(0xFF008751),
                                    Color(0xFF008751),
                                  ],
                                  stops: [0, 0.33, 0.33, 0.67, 0.67, 1],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+234',
                              style: CaboText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                              color: CaboColors.muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: '803 412 7765',
                          keyboardType: TextInputType.phone,
                          style: CaboText.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CaboButton('Continue', onPressed: () => go(context, '/otp')),
                  const SizedBox(height: 18),
                  Text(
                    "By continuing you agree to Cabo's Driver Terms and Privacy Policy. "
                    'Standard SMS rates may apply.',
                    textAlign: TextAlign.center,
                    style: CaboText.muted.copyWith(fontSize: 12),
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

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return Scaffold(
      appBar: caboAppBar(context, 'Verify phone'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code', style: CaboText.h1),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: 'Sent by SMS to ',
                style: CaboText.muted.copyWith(fontSize: 15),
                children: const [
                  TextSpan(
                    text: '+234 803 412 7765',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const CodeBoxes('4827'),
            const SizedBox(height: 18),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Resend code in ',
                  style: CaboText.muted,
                  children: [
                    TextSpan(
                      text: '0:42',
                      style: CaboText.muted.copyWith(
                        color: CaboColors.yellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            CaboButton(
              'Verify',
              onPressed: () => go(context, '/personal-details'),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.4,
              children: [
                for (final k in keys)
                  Center(
                    child: k == '<'
                        ? const Icon(
                            Icons.backspace_outlined,
                            color: CaboColors.muted,
                          )
                        : Text(
                            k,
                            style: CaboText.h1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      title: 'Tell us about you',
      subtitle: 'Riders see your first name and photo when you accept a trip.',
      next: '/driver-type',
      children: [
        Center(
          child: Stack(
            children: [
              const Avatar('EN', size: 96),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
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
        const SizedBox(height: 6),
        Center(
          child: Text('Add a clear photo of your face', style: CaboText.muted),
        ),
        const SizedBox(height: 20),
        const CaboField(
          'Full name',
          value: 'Emeka Nwosu',
          icon: Icons.person_outline,
        ),
        const CaboField(
          'Date of birth',
          value: '14 / 03 / 1988',
          icon: Icons.cake_outlined,
        ),
        const CaboField(
          'Home address',
          value: '12 Adeniran Ogunsanya St, Surulere, Lagos',
          icon: Icons.home_outlined,
        ),
        Text('Languages you speak', style: CaboText.label),
        const SizedBox(height: 10),
        const ChipPicker(
          options: ['English', 'Igbo', 'Pidgin', 'Yoruba', 'Hausa', 'French'],
          initial: {0, 1, 2},
        ),
      ],
    );
  }
}

class DriverTypeScreen extends StatefulWidget {
  const DriverTypeScreen({super.key});

  @override
  State<DriverTypeScreen> createState() => _DriverTypeScreenState();
}

class _DriverTypeScreenState extends State<DriverTypeScreen> {
  int type = 1;
  int partner = 0;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 2,
      title: 'How will you drive?',
      subtitle: 'This decides who receives your payouts and owns the vehicle.',
      next: '/documents-upload',
      children: [
        SelectTile(
          icon: Icons.person_pin_circle_rounded,
          title: 'Independent driver',
          subtitle: 'I drive my own vehicle',
          selected: type == 0,
          onTap: () => setState(() => type = 0),
        ),
        SelectTile(
          icon: Icons.groups_rounded,
          title: 'Fleet driver',
          subtitle: 'I drive a vehicle owned by a fleet partner',
          selected: type == 1,
          onTap: () => setState(() => type = 1),
        ),
        if (type == 1) ...[
          const SectionTitle('Select your fleet partner'),
          TextFormField(
            style: CaboText.body,
            decoration: const InputDecoration(
              hintText: 'Search fleet partners',
              prefixIcon: Icon(Icons.search, color: CaboColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, (name, info)) in const [
            ('Eko Mobility Fleet', 'Lekki • 48 vehicles'),
            ('Island Rides Ltd', 'Victoria Island • 22 vehicles'),
            ('Mainland Motors', 'Yaba • 35 vehicles'),
          ].indexed)
            SelectTile(
              title: name,
              subtitle: info,
              selected: partner == i,
              onTap: () => setState(() => partner = i),
            ),
        ],
      ],
    );
  }
}

enum DocStatus { approved, review, needed, rejected, expiring }

class DocTile extends StatelessWidget {
  const DocTile(
    this.title,
    this.subtitle,
    this.status, {
    super.key,
    this.icon = Icons.description_outlined,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final DocStatus status;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, pillIcon) = switch (status) {
      DocStatus.approved => (
        'Approved',
        CaboColors.brightGreen,
        Icons.check_circle,
      ),
      DocStatus.review => (
        'In review',
        CaboColors.yellow,
        Icons.hourglass_top_rounded,
      ),
      DocStatus.needed => ('Upload', CaboColors.yellow, Icons.upload_rounded),
      DocStatus.rejected => ('Resubmit', CaboColors.red, Icons.error_rounded),
      DocStatus.expiring => ('Renew', CaboColors.orange, Icons.update_rounded),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: onTap ?? () {},
        padding: const EdgeInsets.all(14),
        borderColor: status == DocStatus.needed ? CaboColors.surfaceHigh : null,
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(subtitle, style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(
              label,
              color: color,
              icon: pillIcon,
              solid: status == DocStatus.needed,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StepScaffold(
      step: 3,
      title: 'Upload your documents',
      subtitle: 'Take a clear photo of each document. Make sure all four corners are visible.',
      next: '/vehicle-details',
      children: [
        DocTile(
          "Driver's licence",
          'Front and back • Uploaded',
          DocStatus.approved,
          icon: Icons.badge_outlined,
        ),
        DocTile(
          'National ID (NIN)',
          'NIN slip or card • Uploaded',
          DocStatus.review,
          icon: Icons.perm_identity_rounded,
        ),
        DocTile(
          'Proof of address',
          'Utility bill from the last 3 months',
          DocStatus.needed,
          icon: Icons.home_work_outlined,
        ),
        DocTile(
          'LASDRI card',
          'Lagos State Drivers Institute',
          DocStatus.needed,
          icon: Icons.credit_card_rounded,
        ),
        DocTile(
          'Other Lagos State permits',
          'Optional • e.g. hackney permit',
          DocStatus.needed,
          icon: Icons.verified_outlined,
        ),
        SizedBox(height: 8),
        _Tip('Documents are checked by the Cabo team within 48 hours.'),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: CaboColors.yellow,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: CaboText.muted)),
      ],
    );
  }
}

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 4,
      title: 'Your vehicle',
      subtitle:
          'Vehicles must be 2012 or newer, with working air conditioning.',
      next: '/vehicle-documents',
      children: [
        const Row(
          children: [
            Expanded(child: CaboField('Make', value: 'Toyota')),
            SizedBox(width: 12),
            Expanded(child: CaboField('Model', value: 'Corolla')),
          ],
        ),
        const Row(
          children: [
            Expanded(child: CaboField('Year', value: '2019')),
            SizedBox(width: 12),
            Expanded(child: CaboField('Colour', value: 'Silver')),
          ],
        ),
        const CaboField(
          'Plate number',
          value: 'LND 482 KJ',
          icon: Icons.pin_outlined,
        ),
        const SizedBox(height: 4),
        CaboCard(
          color: CaboColors.brightGreen.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: CaboColors.brightGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Your vehicle qualifies for',
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill('Standard', color: CaboColors.brightGreen),
                  Pill('Comfort', color: CaboColors.brightGreen),
                  Pill('Premium • needs 2020+', color: CaboColors.muted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VehicleDocumentsScreen extends StatelessWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StepScaffold(
      step: 5,
      title: 'Vehicle documents',
      subtitle: 'All documents must be valid for at least 30 more days.',
      next: '/vehicle-photos',
      children: [
        DocTile(
          'Vehicle licence',
          'Expires 02 Mar 2027',
          DocStatus.approved,
          icon: Icons.directions_car_outlined,
        ),
        DocTile(
          'Roadworthiness certificate',
          'Expires 18 Jan 2027',
          DocStatus.review,
          icon: Icons.build_circle_outlined,
        ),
        DocTile(
          'Insurance certificate',
          'Third party or comprehensive',
          DocStatus.needed,
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}

class VehiclePhotosScreen extends StatelessWidget {
  const VehiclePhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const shots = [
      ('Front', Icons.directions_car_filled_rounded, true),
      ('Back', Icons.directions_car_filled_rounded, true),
      ('Left side', Icons.airport_shuttle_rounded, true),
      ('Right side', Icons.airport_shuttle_rounded, false),
      ('Front seats', Icons.event_seat_rounded, false),
      ('Back seats', Icons.airline_seat_recline_normal_rounded, false),
    ];
    return StepScaffold(
      step: 6,
      title: 'Photograph your vehicle',
      subtitle: 'We guide you through each angle. Park somewhere bright.',
      next: '/face-verification',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (final (label, icon, done) in shots)
              Container(
                decoration: BoxDecoration(
                  color: done ? CaboColors.surfaceHigh : CaboColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: done ? CaboColors.brightGreen : CaboColors.outline,
                    width: done ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        done ? icon : Icons.add_a_photo_outlined,
                        size: done ? 56 : 34,
                        color: done ? Colors.white70 : CaboColors.yellow,
                      ),
                    ),
                    if (done)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.check_circle,
                          color: CaboColors.brightGreen,
                          size: 22,
                        ),
                      ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Text(
                        label,
                        style: CaboText.label.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _Tip('3 of 6 photos taken. Tap a tile to open the camera guide.'),
      ],
    );
  }
}

class FaceVerificationScreen extends StatelessWidget {
  const FaceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 7,
      title: 'Verify it is you',
      subtitle: "Take a selfie. We'll match it against the photo on your ID.",
      next: '/background-check',
      buttonLabel: 'Take selfie',
      children: [
        Center(
          child: Container(
            width: 240,
            height: 290,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(140),
              border: Border.all(color: CaboColors.yellow, width: 3),
            ),
            child: const Icon(
              Icons.face_retouching_natural_rounded,
              size: 120,
              color: Colors.white38,
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final t in const [
          'Remove sunglasses and caps',
          'Face the light, avoid shadows',
          'Keep your face inside the frame',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: CaboColors.brightGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(t, style: CaboText.body),
              ],
            ),
          ),
      ],
    );
  }
}

class BackgroundCheckScreen extends StatefulWidget {
  const BackgroundCheckScreen({super.key});

  @override
  State<BackgroundCheckScreen> createState() => _BackgroundCheckScreenState();
}

class _BackgroundCheckScreenState extends State<BackgroundCheckScreen> {
  bool agreed = true;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 8,
      title: 'Background check',
      subtitle: 'Cabo serves visitors to Lagos, so every driver passes a background check before going online.',
      next: '/payout-details',
      buttonLabel: 'I consent',
      children: [
        const Center(
          child: HeroIllustration(Icons.verified_user_rounded, size: 150),
        ),
        const SizedBox(height: 16),
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We will check', style: CaboText.h3),
              const SizedBox(height: 8),
              for (final t in const [
                'Identity, using your NIN',
                'Criminal record with the Nigeria Police Force',
                'Driving record with the FRSC',
                'Past platform deactivations',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 7,
                        color: CaboColors.yellow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t, style: CaboText.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: agreed,
              onChanged: (v) => setState(() => agreed = v!),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'I authorise Cabo and its verification partner to run these checks, '
                  'as described in the Driver Privacy Notice.',
                  style: CaboText.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PayoutDetailsScreen extends StatelessWidget {
  const PayoutDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 9,
      title: 'Where should we pay you?',
      subtitle: 'Earnings are paid every Monday to this account.',
      next: '/application-status',
      buttonLabel: 'Submit application',
      children: [
        const CaboField(
          'Bank',
          value: 'GTBank (Guaranty Trust Bank)',
          icon: Icons.account_balance_outlined,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        const CaboField(
          'Account number',
          value: '0123456789',
          icon: Icons.numbers_rounded,
        ),
        CaboCard(
          color: CaboColors.brightGreen.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: CaboColors.brightGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account name', style: CaboText.label),
                    Text(
                      'EMEKA CHUKWUDI NWOSU',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Tip('The account name must match the name on your ID.'),
      ],
    );
  }
}

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Personal details', DocStatus.approved),
      ("Driver's licence", DocStatus.approved),
      ('National ID (NIN)', DocStatus.approved),
      ('Proof of address', DocStatus.rejected),
      ('LASDRI card', DocStatus.review),
      ('Vehicle documents', DocStatus.approved),
      ('Vehicle photos', DocStatus.approved),
      ('Face verification', DocStatus.approved),
      ('Background check', DocStatus.review),
      ('Vehicle inspection', DocStatus.needed),
    ];
    return CaboScaffold(
      title: 'Application status',
      bottom: CaboButton(
        'Book vehicle inspection',
        icon: Icons.event_available_rounded,
        onPressed: () => go(context, '/inspection-booking'),
      ),
      children: [
        CaboCard(
          child: Row(
            children: [
              Ring(
                value: 0.6,
                size: 96,
                child: Text('6/10', style: CaboText.h2),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Almost there, Emeka', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      '1 item needs resubmitting and your vehicle inspection is still to book.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Checklist'),
        for (final (name, status) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  switch (status) {
                    DocStatus.approved => Icons.check_circle,
                    DocStatus.review => Icons.schedule_rounded,
                    DocStatus.rejected => Icons.error_rounded,
                    _ => Icons.radio_button_unchecked,
                  },
                  color: switch (status) {
                    DocStatus.approved => CaboColors.brightGreen,
                    DocStatus.rejected => CaboColors.red,
                    _ => CaboColors.yellow,
                  },
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: CaboText.body)),
                Text(
                  switch (status) {
                    DocStatus.approved => 'Approved',
                    DocStatus.review => 'Pending',
                    DocStatus.rejected => 'Resubmit',
                    _ => 'To do',
                  },
                  style: CaboText.label.copyWith(
                    color: switch (status) {
                      DocStatus.approved => CaboColors.brightGreen,
                      DocStatus.rejected => CaboColors.red,
                      _ => CaboColors.yellow,
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        CaboCard(
          color: CaboColors.red.withValues(alpha: 0.12),
          child: Text(
            'Proof of address: the photo was blurry. Please upload a clear utility bill dated within 3 months.',
            style: CaboText.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class InspectionBookingScreen extends StatefulWidget {
  const InspectionBookingScreen({super.key});

  @override
  State<InspectionBookingScreen> createState() =>
      _InspectionBookingScreenState();
}

class _InspectionBookingScreenState extends State<InspectionBookingScreen> {
  int day = 1;
  int slot = 2;

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Wed', '7'),
      ('Thu', '8'),
      ('Fri', '9'),
      ('Sat', '10'),
      ('Mon', '12'),
      ('Tue', '13'),
    ];
    const slots = ['09:00', '10:00', '11:30', '13:00', '14:30', '16:00'];
    return CaboScaffold(
      title: 'Book inspection',
      bottom: CaboButton(
        'Confirm Thu 8 Oct, 11:30',
        onPressed: () => go(context, '/training'),
      ),
      children: [
        Text(
          'A 20-minute check of your vehicle at a Cabo hub. Bring your original documents.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SectionTitle('October 2026'),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => setState(() => day = i),
              child: Container(
                width: 62,
                decoration: BoxDecoration(
                  color: i == day ? CaboColors.yellow : CaboColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[i].$1,
                      style: CaboText.label.copyWith(
                        color: i == day
                            ? CaboColors.onYellow
                            : CaboColors.muted,
                      ),
                    ),
                    Text(
                      days[i].$2,
                      style: CaboText.h2.copyWith(
                        color: i == day ? CaboColors.onYellow : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('Time'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < slots.length; i++)
              GestureDetector(
                onTap: () => setState(() => slot = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == slot ? CaboColors.yellow : CaboColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    slots[i],
                    style: CaboText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: i == slot ? CaboColors.onYellow : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SectionTitle('Location'),
        const SingleChoice(
          icons: [Icons.location_on, Icons.location_on, Icons.location_on],
          options: [
            ('Cabo Hub Lekki', 'Admiralty Way, Lekki Phase 1 • 6.2 km'),
            ('Cabo Hub Yaba', 'Herbert Macaulay Way • 9.8 km'),
            ('Cabo Hub Ikeja', 'Obafemi Awolowo Way • 18 km'),
          ],
        ),
      ],
    );
  }
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const lessons = [
      ('Welcoming visitors to Lagos', '6 min', true, Icons.waving_hand_rounded),
      ('Safety on every trip', '8 min', true, Icons.health_and_safety_rounded),
      (
        'Lagos landmarks riders ask about',
        '10 min',
        false,
        Icons.location_city_rounded,
      ),
      ('Airport pickups at MMIA', '7 min', false, Icons.flight_land_rounded),
      (
        'Using the Cabo Driver app',
        '5 min',
        false,
        Icons.phone_android_rounded,
      ),
    ];
    return CaboScaffold(
      title: 'Driver training',
      bottom: CaboButton(
        'Continue lesson 3',
        onPressed: () => go(context, '/training-quiz'),
      ),
      children: [
        CaboCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('2 of 5 lessons done', style: CaboText.h3),
              const SizedBox(height: 4),
              Text(
                'About 22 minutes left, then a 10-question quiz.',
                style: CaboText.muted,
              ),
              const SizedBox(height: 12),
              const Bar(0.4),
            ],
          ),
        ),
        const SectionTitle('Lessons'),
        for (final (i, (title, time, done, icon)) in lessons.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              padding: const EdgeInsets.all(14),
              borderColor: i == 2 ? CaboColors.yellow : null,
              onTap: () {},
              child: Row(
                children: [
                  IconBadge(
                    icon,
                    color: done ? CaboColors.brightGreen : CaboColors.yellow,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lesson ${i + 1}', style: CaboText.label),
                        Text(
                          title,
                          style: CaboText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          time,
                          style: CaboText.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    done ? Icons.check_circle : Icons.play_circle_fill_rounded,
                    color: done ? CaboColors.brightGreen : CaboColors.yellow,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        CaboCard(
          color: CaboColors.surfaceHigh,
          child: Row(
            children: [
              const IconBadge(Icons.quiz_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final quiz',
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pass mark 8/10 • Unlocks after all lessons',
                      style: CaboText.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.lock_rounded, color: CaboColors.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class TrainingQuizScreen extends StatefulWidget {
  const TrainingQuizScreen({super.key});

  @override
  State<TrainingQuizScreen> createState() => _TrainingQuizScreenState();
}

class _TrainingQuizScreenState extends State<TrainingQuizScreen> {
  int answer = 1;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Drop them at the main gate and drive off',
      'Wait until they are inside the hotel lobby',
      'Ask them to pay extra for waiting',
      'End the trip before arriving',
    ];
    return CaboScaffold(
      title: 'Quiz',
      bottom: CaboButton(
        'Submit answer',
        onPressed: () => go(context, '/approved'),
      ),
      children: [
        Row(
          children: [
            Text('Question 4 of 10', style: CaboText.label),
            const Spacer(),
            const Pill('03:12', icon: Icons.timer_outlined),
          ],
        ),
        const SizedBox(height: 10),
        const Bar(0.4, height: 6),
        const SizedBox(height: 26),
        Text(
          'A first-time visitor arrives at their Ikoyi hotel at 11 pm. What should you do?',
          style: CaboText.h2,
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < options.length; i++)
          SelectTile(
            title: options[i],
            selected: answer == i,
            onTap: () => setState(() => answer = i),
          ),
      ],
    );
  }
}

class ApprovedScreen extends StatelessWidget {
  const ApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.verified_rounded,
      color: CaboColors.brightGreen,
      title: "You're approved, Emeka!",
      message: 'Your Cabo Driver account is active. Welcome to the team.',
      primary: 'Set up permissions',
      onPrimary: () => go(context, '/permissions'),
      extra: CaboCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your first steps', style: CaboText.h3),
            const SizedBox(height: 8),
            for (final (i, t) in const [
              'Allow location and notifications',
              'Go online in a busy zone like Victoria Island',
              'Complete 20 trips to unlock airport shuttles',
            ].indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: CaboColors.yellow,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CaboColors.onYellow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t, style: CaboText.body)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const perms = [
      (
        Icons.my_location_rounded,
        'Location',
        'Set to "Always" so riders can find you while you are online, even with the app in the background.',
        true,
      ),
      (
        Icons.notifications_active_rounded,
        'Notifications',
        'Hear new trip requests, scheduled jobs and payout alerts.',
        true,
      ),
      (
        Icons.mic_rounded,
        'Microphone',
        'Used for in-app calls with riders and Cabo support.',
        false,
      ),
    ];
    return CaboScaffold(
      title: 'Permissions',
      bottom: CaboButton(
        'Start driving',
        onPressed: () => go(context, '/home'),
      ),
      children: [
        Text(
          'Cabo needs a few permissions to work while you drive.',
          style: CaboText.muted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 18),
        for (final (icon, title, body, granted) in perms)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CaboCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: CaboText.h3),
                        const SizedBox(height: 4),
                        Text(body, style: CaboText.muted),
                        const SizedBox(height: 12),
                        granted
                            ? const Pill(
                                'Allowed',
                                color: CaboColors.brightGreen,
                                icon: Icons.check,
                              )
                            : CaboButton(
                                'Allow',
                                height: 40,
                                expand: false,
                                onPressed: () {},
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
