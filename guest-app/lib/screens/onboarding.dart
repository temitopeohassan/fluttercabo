import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 1. Onboarding and account.

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
      backgroundColor: CaboColors.deepGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F5B36),
                  CaboColors.deepGreen,
                  Color(0xFF06301D),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            height: 240,
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
                const Icon(
                  Icons.location_on_rounded,
                  size: 56,
                  color: CaboColors.yellow,
                ),
                const SizedBox(height: 8),
                const CaboLogo(size: 78, tagline: true, color: Colors.white),
                const Spacer(flex: 4),
                Text(
                  'Explore Lagos.\nDiscover Nigeria.',
                  textAlign: TextAlign.center,
                  style: CaboText.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CaboColors.yellow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Scene(SceneKind.skyline, radius: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x00000000),
                  Color(0xCC062B1A),
                ],
                stops: [0, 0.4, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                children: [
                  const CaboLogo(size: 80, tagline: true, color: Colors.white),
                  const Spacer(),
                  Text(
                    "More than a ride.\nIt's your Lagos experience.",
                    textAlign: TextAlign.center,
                    style: CaboText.h2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  CaboButton(
                    'Get Started',
                    style: CaboButtonStyle.accent,
                    onPressed: () => go(context, '/sign-in'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Discover Lagos.\nOne Ride at a Time.',
                    textAlign: TextAlign.center,
                    style: CaboText.h3.copyWith(color: Colors.white),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton(this.label, this.icon, this.onTap);
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(label, style: CaboText.h3.copyWith(color: CaboColors.green)),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Scene(SceneKind.skyline, radius: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0xE6083A24),
                  CaboColors.deepGreen,
                ],
                stops: [0.15, 0.5, 1],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => back(context),
                    ),
                  ),
                  const SizedBox(height: 200),
                  Text(
                    'Welcome to',
                    style: CaboText.h1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const CaboLogo(size: 56, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Your all-in-one ride, tour and travel platform in Nigeria.',
                    style: CaboText.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),
                  CaboButton(
                    'Continue with Phone Number',
                    style: CaboButtonStyle.accent,
                    icon: Icons.phone_iphone_rounded,
                    onPressed: () => go(context, '/phone'),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    'Continue with Google',
                    Text(
                      'G',
                      style: CaboText.h2.copyWith(color: CaboColors.blue),
                    ),
                    () => go(context, '/profile-setup'),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    'Continue with Apple',
                    const Icon(Icons.apple, color: Colors.black, size: 26),
                    () => go(context, '/profile-setup'),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () => go(context, '/email'),
                      child: Text(
                        'Continue with email',
                        style: CaboText.h3.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: CaboText.body.copyWith(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: CaboText.body.copyWith(
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
        ],
      ),
    );
  }
}

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Your phone number',
      bottom: CaboButton('Send code', onPressed: () => go(context, '/otp')),
      children: [
        Text(
          'Use any number. We will text you a 6-digit code.',
          style: CaboText.muted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: CaboColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CaboColors.line),
              ),
              child: Row(
                children: [
                  Text(
                    'GB',
                    style: CaboText.h3.copyWith(color: CaboColors.blue),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+44',
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.expand_more, color: CaboColors.muted),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: '7700 900 412',
                keyboardType: TextInputType.phone,
                style: CaboText.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SectionTitle('Popular countries'),
        for (final (code, name, dial) in const [
          ('NG', 'Nigeria', '+234'),
          ('GB', 'United Kingdom', '+44'),
          ('US', 'United States', '+1'),
          ('KE', 'Kenya', '+254'),
          ('GH', 'Ghana', '+233'),
          ('FR', 'France', '+33'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    code,
                    style: CaboText.h3.copyWith(color: CaboColors.green),
                  ),
                ),
                Expanded(child: Text(name, style: CaboText.body)),
                Text(dial, style: CaboText.muted),
                if (code == 'GB') ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, color: CaboColors.green),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Verify your number',
      bottom: CaboButton(
        'Verify',
        onPressed: () => go(context, '/profile-setup'),
      ),
      children: [
        Text('Enter the 6-digit code', style: CaboText.h1),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Sent by SMS to ',
            style: CaboText.muted.copyWith(fontSize: 15),
            children: const [
              TextSpan(
                text: '+44 7700 900 412',
                style: TextStyle(
                  color: CaboColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const CodeBoxes('3917'),
        const SizedBox(height: 18),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'Resend code in ',
              style: CaboText.muted,
              children: [
                TextSpan(
                  text: '0:38',
                  style: CaboText.muted.copyWith(
                    color: CaboColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        CaboCard(
          color: CaboColors.yellowSoft,
          onTap: () => go(context, '/email'),
          child: Row(
            children: [
              const IconBadge(
                Icons.mark_email_unread_rounded,
                color: CaboColors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS not arriving?', style: CaboText.h3),
                    Text(
                      'Foreign numbers can be slow. Get your code by email instead.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmailScreen extends StatelessWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Continue with email',
      bottom: CaboButton(
        'Email me a code',
        onPressed: () => go(context, '/otp'),
      ),
      children: [
        const SizedBox(height: 10),
        const Center(
          child: HeroIllustration(Icons.alternate_email_rounded, size: 150),
        ),
        const SizedBox(height: 20),
        Text('What is your email?', style: CaboText.h1),
        const SizedBox(height: 6),
        Text(
          'We will send a 6-digit code to sign you in. No password needed.',
          style: CaboText.muted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 20),
        const CaboField(
          'Email',
          value: 'tunde.bakare@gmail.com',
          icon: Icons.mail_outline,
        ),
      ],
    );
  }
}

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      totalSteps: 3,
      title: 'Set up your profile',
      subtitle: 'Your driver sees your first name and photo.',
      next: '/traveller-type',
      children: [
        Center(
          child: Stack(
            children: [
              const Avatar('TB', size: 96),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: CaboColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: CaboField('First name', value: 'Tunde')),
            SizedBox(width: 12),
            Expanded(child: CaboField('Last name', value: 'Bakare')),
          ],
        ),
        const CaboField(
          'Nationality',
          value: 'British',
          icon: Icons.flag_outlined,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        const CaboField(
          'Home currency',
          value: 'GBP • British pound (£)',
          icon: Icons.currency_exchange_rounded,
          suffix: Icon(Icons.expand_more, color: CaboColors.muted),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: CaboColors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You always pay in naira. We show an estimate in your home currency.',
                style: CaboText.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TravellerTypeScreen extends StatelessWidget {
  const TravellerTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StepScaffold(
      step: 2,
      totalSteps: 3,
      title: 'How are you visiting Lagos?',
      subtitle: 'We use this to personalise your home screen.',
      next: '/emergency-contact',
      children: [
        SingleChoice(
          icons: [
            Icons.flight_land_rounded,
            Icons.luggage_rounded,
            Icons.home_rounded,
          ],
          options: [
            ('International visitor', 'Visiting Nigeria from abroad'),
            ('Domestic visitor', 'Visiting Lagos from another state'),
            ('Lagos resident', 'I live here'),
          ],
        ),
      ],
    );
  }
}

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(
        context,
        'Step 3 of 3',
        actions: [
          TextButton(
            onPressed: () => go(context, '/permissions'),
            child: Text(
              'Skip',
              style: CaboText.h3.copyWith(color: CaboColors.muted),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Bar(1, height: 6),
          const SizedBox(height: 22),
          Text('Add an emergency contact', style: CaboText.h1),
          const SizedBox(height: 6),
          Text(
            'If you press SOS, we alert this person with your live location.',
            style: CaboText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 22),
          const CaboField(
            'Name',
            value: 'Bisi Bakare',
            icon: Icons.person_outline,
          ),
          const CaboField(
            'Phone',
            value: '+44 7700 900 118',
            icon: Icons.phone_outlined,
          ),
          Text('Relationship', style: CaboText.label),
          const SizedBox(height: 8),
          const ChipPicker(
            options: ['Partner', 'Parent', 'Sibling', 'Friend', 'Colleague'],
            initial: {1},
            single: true,
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Save contact',
          onPressed: () => go(context, '/permissions'),
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
        'Find you at pickup and suggest nearby landmarks.',
        true,
      ),
      (
        Icons.notifications_active_rounded,
        'Notifications',
        'Know when your driver arrives and when tours are about to start.',
        false,
      ),
    ];
    return CaboScaffold(
      title: 'Permissions',
      bottom: CaboButton('Continue', onPressed: () => go(context, '/all-set')),
      children: [
        Text(
          'Two quick permissions make Cabo work better.',
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
                            ? const Pill('Allowed', icon: Icons.check)
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

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.celebration_rounded,
      title: "You're all set, Tunde!",
      message: 'Book a ride, plan a tour or explore Lagos.',
      primary: 'Start exploring',
      onPrimary: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false),
      extra: Column(
        children: [
          for (final (icon, text) in const [
            (Icons.local_taxi_rounded, 'Vetted drivers, fixed upfront fares'),
            (Icons.flight_land_rounded, 'Airport pickups that wait for you'),
            (Icons.tour_rounded, 'Curated tours from trusted guides'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  IconBadge(icon, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: CaboText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
