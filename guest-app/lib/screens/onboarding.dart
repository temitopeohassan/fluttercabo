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
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || kScreenshotMode) return;
    _started = true;
    _open();
  }

  /// Restores the session while the logo shows, then opens the right screen.
  Future<void> _open() async {
    final state = AppScope.read(context);
    final results = await Future.wait([
      state.start(),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);
    // Only advance if the splash is still the visible screen.
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      replace(context, results.first as String);
    }
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
                    () => showMessage(
                      context,
                      'Google sign-in is coming soon. Use your phone number or email for now.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    'Continue with Apple',
                    const Icon(Icons.apple, color: Colors.black, size: 26),
                    () => showMessage(
                      context,
                      'Apple sign-in is coming soon. Use your phone number or email for now.',
                    ),
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
                    child: GestureDetector(
                      onTap: () => go(context, '/phone'),
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

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  static const _countries = [
    ('NG', 'Nigeria', '+234'),
    ('GB', 'United Kingdom', '+44'),
    ('US', 'United States', '+1'),
    ('KE', 'Kenya', '+254'),
    ('GH', 'Ghana', '+233'),
    ('FR', 'France', '+33'),
  ];
  final _number = TextEditingController();
  int _country = 0;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    var digits = _number.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length < 7) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    setState(() => _error = null);
    await AppScope.read(context)
        .requestOtp('${_countries[_country].$3}$digits');
    if (mounted) go(context, '/otp');
  }

  @override
  Widget build(BuildContext context) {
    final (code, _, dial) = _countries[_country];
    return CaboScaffold(
      title: 'Your phone number',
      bottom: ActionButton(
        'Send code',
        busyLabel: 'Sending…',
        onPressed: _send,
      ),
      children: [
        Text(
          'Use any number. We will text you a 6-digit code.',
          style: CaboText.muted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    code,
                    style: CaboText.h3.copyWith(color: CaboColors.blue),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dial,
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _number,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                onSubmitted: (_) => runAction(context, _send),
                style: CaboText.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  errorText: _error,
                ),
              ),
            ),
          ],
        ),
        const SectionTitle('Country'),
        for (final (i, (c, name, d)) in _countries.indexed)
          InkWell(
            onTap: () => setState(() => _country = i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      c,
                      style: CaboText.h3.copyWith(color: CaboColors.green),
                    ),
                  ),
                  Expanded(child: Text(name, style: CaboText.body)),
                  Text(d, style: CaboText.muted),
                  SizedBox(
                    width: 32,
                    child: i == _country
                        ? const Icon(
                            Icons.check_rounded,
                            color: CaboColors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _wait = 30;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _wait = 30);
    if (kScreenshotMode) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_wait <= 1) t.cancel();
      if (mounted) setState(() => _wait--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final state = AppScope.read(context);
    final isNew = await state.verifyOtp(_code.text);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(isNew ? '/profile-setup' : '/home', (_) => false);
  }

  Future<void> _resend() async {
    final state = AppScope.read(context);
    await state.requestOtp(state.otpIdentifier!);
    _code.clear();
    _startTimer();
    if (mounted) showMessage(context, 'We sent a new code.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final email = state.otpChannel == 'email';
    final to = state.otpIdentifier;
    return CaboScaffold(
      title: email ? 'Check your email' : 'Verify your number',
      bottom: ActionButton(
        'Verify',
        busyLabel: 'Checking…',
        enabled: _code.text.length == 6 && to != null,
        onPressed: _verify,
      ),
      children: [
        Text('Enter the 6-digit code', style: CaboText.h1),
        const SizedBox(height: 6),
        if (to == null)
          Text(
            'Go back and enter your phone number or email first.',
            style: CaboText.muted.copyWith(fontSize: 15),
          )
        else
          Text.rich(
            TextSpan(
              text: email ? 'Sent by email to ' : 'Sent by SMS to ',
              style: CaboText.muted.copyWith(fontSize: 15),
              children: [
                TextSpan(
                  text: to,
                  style: const TextStyle(
                    color: CaboColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),
        // The boxes show what is typed into an invisible field on top of them.
        Stack(
          alignment: Alignment.center,
          children: [
            CodeBoxes(_code.text),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: !kScreenshotMode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: '6-digit code',
                  ),
                  onSubmitted: (_) {
                    if (_code.text.length == 6) runAction(context, _verify);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (state.demoCode != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CaboCard(
              color: CaboColors.greenSoft,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: CaboColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cabo is in test mode, so no message is sent. Your code is ${state.demoCode}.',
                      style: CaboText.body.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: _wait > 0
              ? Text.rich(
                  TextSpan(
                    text: 'Resend code in ',
                    style: CaboText.muted,
                    children: [
                      TextSpan(
                        text: '0:${_wait.toString().padLeft(2, '0')}',
                        style: CaboText.muted.copyWith(
                          color: CaboColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : TextButton(
                  onPressed: to == null
                      ? null
                      : () => runAction(context, _resend),
                  child: Text(
                    'Resend code',
                    style: CaboText.h3.copyWith(color: CaboColors.green),
                  ),
                ),
        ),
        const SizedBox(height: 28),
        if (!email)
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

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() => _error = null);
    await AppScope.read(context).requestOtp(email);
    if (mounted) go(context, '/otp');
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Continue with email',
      bottom: ActionButton(
        'Email me a code',
        busyLabel: 'Sending…',
        onPressed: _send,
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
        CaboField(
          'Email',
          controller: _email,
          hint: 'you@example.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          error: _error,
        ),
      ],
    );
  }
}

const _currencies = [
  ('NGN', 'Nigerian naira (₦)'),
  ('GBP', 'British pound (£)'),
  ('USD', r'US dollar ($)'),
  ('EUR', 'Euro (€)'),
];

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _nationality = TextEditingController();
  String _currency = 'NGN';
  Map<String, String> _errors = {};
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final rider = AppScope.read(context).rider;
    _first.text = rider?.str('first_name') ?? '';
    _last.text = rider?.str('last_name') ?? '';
    _nationality.text = rider?.str('nationality') ?? '';
    _currency = rider?.str('home_currency', 'NGN') ?? 'NGN';
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _nationality.dispose();
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
      await AppScope.read(context).updateRider({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'nationality': _nationality.text.trim().isEmpty
            ? null
            : _nationality.text.trim(),
        'home_currency': _currency,
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errors = e.fields);
      rethrow;
    }
    if (mounted) go(context, '/traveller-type');
  }

  @override
  Widget build(BuildContext context) {
    final name = '${_first.text} ${_last.text}'.trim();
    return StepScaffold(
      step: 1,
      totalSteps: 3,
      title: 'Set up your profile',
      subtitle: 'Your driver sees your first name.',
      onNext: _save,
      children: [
        Center(child: Avatar(name.isEmpty ? '?' : initials(name), size: 96)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField(
                'First name',
                controller: _first,
                error: _errors['first_name'],
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField(
                'Last name',
                controller: _last,
                error: _errors['last_name'],
                autofillHints: const [AutofillHints.familyName],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        CaboField(
          'Nationality',
          controller: _nationality,
          hint: 'e.g. British',
          icon: Icons.flag_outlined,
          error: _errors['nationality'],
        ),
        Text('Home currency', style: CaboText.label),
        const SizedBox(height: 8),
        ChipPicker(
          key: ValueKey(_currency),
          single: true,
          options: [for (final (code, _) in _currencies) code],
          initial: {_currencies.indexWhere((c) => c.$1 == _currency)},
          onChanged: (s) => setState(() => _currency = _currencies[s.first].$1),
        ),
        const SizedBox(height: 14),
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

class TravellerTypeScreen extends StatefulWidget {
  const TravellerTypeScreen({super.key});

  @override
  State<TravellerTypeScreen> createState() => _TravellerTypeScreenState();
}

class _TravellerTypeScreenState extends State<TravellerTypeScreen> {
  static const _types = ['international', 'domestic', 'resident'];
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final current = _types.indexOf(
      AppScope.read(context).rider?.str('traveller_type') ?? '',
    );
    final selected = _selected ?? (current < 0 ? 0 : current);
    return StepScaffold(
      step: 2,
      totalSteps: 3,
      title: 'How are you visiting Lagos?',
      subtitle: 'We use this to personalise your home screen.',
      onNext: () async {
        await AppScope.read(context)
            .updateRider({'traveller_type': _types[selected]});
        if (context.mounted) go(context, '/emergency-contact');
      },
      children: [
        SingleChoice(
          initial: selected,
          onChanged: (i) => setState(() => _selected = i),
          icons: const [
            Icons.flight_land_rounded,
            Icons.luggage_rounded,
            Icons.home_rounded,
          ],
          options: const [
            ('International visitor', 'Visiting Nigeria from abroad'),
            ('Domestic visitor', 'Visiting Lagos from another state'),
            ('Lagos resident', 'I live here'),
          ],
        ),
      ],
    );
  }
}

const relationships = ['Partner', 'Parent', 'Sibling', 'Friend', 'Colleague'];

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
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
    final state = AppScope.read(context);
    await state.api.post('/rider/emergency-contacts', {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'relationship': relationships[_relationship],
      'share_trips_automatically': false,
    });
    if (mounted) go(context, '/permissions');
  }

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
            'If you press SOS, Cabo\'s safety team sees this contact and can reach them.',
            style: CaboText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 22),
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
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: ActionButton('Save contact', onPressed: _save),
      ),
    );
  }
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationAllowed = false;

  Future<void> _allowLocation() async {
    await AppScope.read(context).location.current();
    if (mounted) setState(() => _locationAllowed = true);
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Permissions',
      bottom: CaboButton('Continue', onPressed: () => go(context, '/all-set')),
      children: [
        Text(
          'One quick permission makes Cabo work better.',
          style: CaboText.muted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 18),
        CaboCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.my_location_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Find you at pickup and suggest nearby landmarks.',
                      style: CaboText.muted,
                    ),
                    const SizedBox(height: 12),
                    _locationAllowed
                        ? const Pill('Allowed', icon: Icons.check)
                        : ActionButton(
                            'Allow',
                            height: 40,
                            expand: false,
                            onPressed: _allowLocation,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CaboCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.notifications_active_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Driver and booking updates appear in the app under the bell on your home screen.',
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

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.celebration_rounded,
      title: "You're all set, ${AppScope.of(context).firstName}!",
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
