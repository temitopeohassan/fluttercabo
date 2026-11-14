import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 1. Onboarding and verification.

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

  /// Restores the session while the splash shows, then opens the right screen.
  Future<void> _open() async {
    final state = AppScope.read(context);
    final results = await Future.wait([state.start(), Future<void>.delayed(const Duration(milliseconds: 1200))]);
    // Only advance if the splash is still the visible screen.
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.of(context).pushNamedAndRemoveUntil(results.first as String, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E5233), CaboColors.deepGreen, Color(0xFF052617)],
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
              child: CustomPaint(painter: SkylinePainter(buildingColor: const Color(0xFF0F5434), water: true)),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const CaboLogo(size: 76),
                  const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  Text('EARN  •  GROW  •  BE INDEPENDENT', style: CaboText.label.copyWith(color: Colors.white, letterSpacing: 2.5)),
                  const Spacer(flex: 4),
                  Text(
                    'Drive Lagos.\nEarn on your terms.',
                    textAlign: TextAlign.center,
                    style: CaboText.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
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
      [Icons.flight_land_rounded, Icons.landscape_rounded, Icons.payments_rounded],
      'Earn with rides,\nshuttles and tours',
      'Pick up visitors across Lagos, run airport shuttles and, once certified, guide tours for extra income.',
    ),
    (
      Icons.schedule_rounded,
      [Icons.wb_sunny_rounded, Icons.nightlight_round, Icons.event_available_rounded],
      'Flexible hours\nthat fit your life',
      'Go online whenever you want. Accept scheduled airport and tour jobs days in advance.',
    ),
    (
      Icons.account_balance_wallet_rounded,
      [Icons.calendar_month_rounded, Icons.bolt_rounded, Icons.trending_up_rounded],
      'Weekly payouts,\nstraight to your bank',
      'Get paid every week, or cash out instantly whenever you need it.',
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
                  const CaboLogo(size: 30, hostLabel: false),
                  const Spacer(),
                  TextButton(
                    onPressed: () => go(context, '/sign-in'),
                    child: Text('Skip', style: CaboText.h3.copyWith(color: CaboColors.muted)),
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
                              HeroIllustration(icon, size: (c.maxHeight * 0.45).clamp(140, 240), badges: badges),
                              const SizedBox(height: 32),
                              Text(title, textAlign: TextAlign.center, style: CaboText.h1),
                              const SizedBox(height: 14),
                              Text(body, textAlign: TextAlign.center, style: CaboText.muted.copyWith(fontSize: 15)),
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
                        color: i == page ? CaboColors.yellow : CaboColors.outline,
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
                    : controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
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
                        style: CaboText.muted.copyWith(color: CaboColors.yellow, fontWeight: FontWeight.w700),
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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    var digits = _phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!digits.startsWith('+')) digits = '+234${digits.replaceFirst(RegExp(r'^0'), '')}';
    if (digits.length < 11) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    setState(() => _error = null);
    await AppScope.read(context).requestOtp(digits);
    if (mounted) go(context, '/otp');
  }

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
                        colors: [Color(0xFF2E6E8E), Color(0xFFF2A65A), Color(0xFF1C5A3A), CaboColors.deepGreen],
                        stops: [0, 0.45, 0.8, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    height: 220,
                    child: CustomPaint(painter: SkylinePainter(buildingColor: const Color(0xFF0C3B27), water: true)),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => back(context)),
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
                  Text('Welcome to', style: CaboText.h2.copyWith(fontWeight: FontWeight.w600)),
                  const CaboLogo(size: 48, hostLabel: false),
                  const SizedBox(height: 10),
                  Text('Sign up or log in with your phone number. We will text you a code.', style: CaboText.muted.copyWith(fontSize: 15)),
                  const SizedBox(height: 24),
                  Text('Phone number', style: CaboText.label),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text('+234', style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          style: CaboText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(hintText: '801 234 5678', errorText: _error),
                          onSubmitted: (_) => runAction(context, _continue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ActionButton('Continue', busyLabel: 'Sending code…', onPressed: _continue),
                  const SizedBox(height: 18),
                  Text(
                    "By continuing you agree to Cabo's Host Terms and Privacy Policy. "
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

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  String? _error;
  Timer? _timer;
  int _wait = 45;

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_wait > 0) setState(() => _wait--);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _key(String k) {
    setState(() {
      _error = null;
      if (k == '<') {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < 6) {
        _code += k;
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Enter all 6 digits.');
      return;
    }
    try {
      final route = await AppScope.read(context).verifyOtp(_code);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.fields['code'] ?? e.message;
          _code = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    final to = state.otpIdentifier;
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
                text: to == null ? 'Go back and enter your phone number.' : 'Sent to ',
                style: CaboText.muted.copyWith(fontSize: 15),
                children: [
                  if (to != null)
                    TextSpan(
                      text: to,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CodeBoxes(_code),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(_error!, style: CaboText.label.copyWith(color: CaboColors.red)),
                ),
              ),
            if (state.demoCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: Pill('Demo mode: your code is ${state.demoCode}', icon: Icons.info_outline_rounded)),
              ),
            const SizedBox(height: 12),
            Center(
              child: _wait > 0
                  ? Text.rich(
                      TextSpan(
                        text: 'Resend code in ',
                        style: CaboText.muted,
                        children: [
                          TextSpan(
                            text: '0:${_wait.toString().padLeft(2, '0')}',
                            style: CaboText.muted.copyWith(color: CaboColors.yellow, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : TextButton(
                      onPressed: to == null
                          ? null
                          : () => runAction(context, () async {
                              await state.requestOtp(to);
                              if (mounted) setState(() => _wait = 45);
                            }),
                      child: Text('Resend code', style: CaboText.h3.copyWith(color: CaboColors.yellow)),
                    ),
            ),
            const Spacer(),
            ActionButton('Verify', busyLabel: 'Checking…', onPressed: _verify),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.4,
              children: [
                for (final k in keys)
                  k.isEmpty
                      ? const SizedBox()
                      : InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _key(k),
                          child: Center(
                            child: k == '<'
                                ? const Icon(Icons.backspace_outlined, color: CaboColors.muted, semanticLabel: 'Delete')
                                : Text(k, style: CaboText.h1.copyWith(fontWeight: FontWeight.w600)),
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

const _languages = ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin', 'French'];

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _address = TextEditingController();
  DateTime? _dob;
  Set<int> _langs = {0};
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
    _address.text = d.str('address');
    _dob = d.date('date_of_birth');
    final saved = d.strings('languages');
    if (saved.isNotEmpty)
      _langs = {
        for (final (i, l) in _languages.indexed)
          if (saved.contains(l)) i,
      };
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 21, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final errors = <String, String>{
      if (_first.text.trim().isEmpty) 'first_name': 'Enter your first name.',
      if (_last.text.trim().isEmpty) 'last_name': 'Enter your last name.',
      if (_dob == null) 'date_of_birth': 'Choose your date of birth. Hosts must be 21 or older.',
      if (_address.text.trim().isEmpty) 'address': 'Enter your home address.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    final state = AppScope.read(context);
    try {
      await state.updateDriver({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'address': _address.text.trim(),
        // Approved hosts cannot change their date of birth.
        if (!state.approved) 'date_of_birth': _dob!.toIso8601String().substring(0, 10),
        'languages': [for (final i in _langs) _languages[i]],
      });
    } on ApiException catch (e) {
      if (e.fields.isEmpty) rethrow;
      if (mounted) setState(() => _errors = e.fields);
      return;
    }
    if (mounted) go(context, '/driver-type');
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      title: 'Tell us about you',
      subtitle: 'Riders see your first name when you accept a trip.',
      onNext: _save,
      children: [
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
        CaboField(
          'Date of birth',
          key: ValueKey(_dob),
          value: _dob == null ? null : fmtDate(_dob),
          hint: 'Choose a date',
          icon: Icons.cake_outlined,
          readOnly: true,
          onTap: _pickDob,
          error: _errors['date_of_birth'],
        ),
        CaboField('Home address', controller: _address, icon: Icons.home_outlined, error: _errors['address']),
        Text('Languages you speak', style: CaboText.label),
        const SizedBox(height: 10),
        ChipPicker(options: _languages, initial: _langs, onChanged: (s) => _langs = s),
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
  late int type = AppScope.read(context).driver?.str('driver_type') == 'fleet' ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final partner = state.driver?.obj('fleet_partner')?.strOrNull('name');
    return StepScaffold(
      step: 2,
      title: 'How will you drive?',
      subtitle: 'This decides who receives your payouts and owns the vehicle.',
      onNext: () async {
        if (!state.approved) await state.updateDriver({'driver_type': type == 1 ? 'fleet' : 'independent'});
        if (context.mounted) go(context, '/documents-upload');
      },
      children: [
        SelectTile(
          icon: Icons.person_pin_circle_rounded,
          title: 'Independent host',
          subtitle: 'I drive my own vehicle',
          selected: type == 0,
          onTap: () => setState(() => type = 0),
        ),
        SelectTile(
          icon: Icons.groups_rounded,
          title: 'Fleet host',
          subtitle: 'I drive a vehicle owned by a fleet partner',
          selected: type == 1,
          onTap: () => setState(() => type = 1),
        ),
        if (type == 1) ...[
          const SizedBox(height: 8),
          _Tip(
            partner == null
                ? 'Tell the Cabo team which fleet you drive for at your inspection and we will link your account to it.'
                : 'Your account is linked to $partner.',
          ),
        ],
      ],
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
      children: [DocumentTiles(personalDocuments), SizedBox(height: 8), _Tip('Documents are checked by the Cabo team within 48 hours.')],
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
        const Icon(Icons.info_outline_rounded, color: CaboColors.yellow, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: CaboText.muted)),
      ],
    );
  }
}

Future<List<Json>> _vehicles(AppState state) async => asJsonList(unwrap(await state.api.get('/driver/vehicles')));

/// Form for a new vehicle. Used during sign-up and from vehicle management.
class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key, required this.onSaved, this.buttonLabel = 'Save vehicle'});
  final void Function(Json vehicle) onSaved;
  final String buttonLabel;

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _colour = TextEditingController();
  final _plate = TextEditingController();
  int _seats = 0;
  bool _wheelchair = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_make, _model, _year, _colour, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final year = int.tryParse(_year.text.trim());
    final errors = <String, String>{
      if (_make.text.trim().isEmpty) 'make': 'Enter the make.',
      if (_model.text.trim().isEmpty) 'model': 'Enter the model.',
      if (year == null) 'year': 'Enter the year.',
      if (_colour.text.trim().isEmpty) 'colour': 'Enter the colour.',
      if (_plate.text.trim().length < 5) 'plate_number': 'Enter the plate number.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    try {
      final v = unwrap(
        await AppScope.read(context).api.post('/driver/vehicles', {
          'make': _make.text.trim(),
          'model': _model.text.trim(),
          'year': year,
          'colour': _colour.text.trim(),
          'plate_number': _plate.text.trim(),
          'seats': const [4, 6, 7][_seats],
          'wheelchair_accessible': _wheelchair,
        }),
      ) as Json;
      widget.onSaved(v);
    } on ApiException catch (e) {
      if (e.fields.isEmpty) rethrow;
      if (mounted) setState(() => _errors = e.fields);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField('Make', controller: _make, hint: 'Toyota', error: _errors['make']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField('Model', controller: _model, hint: 'Corolla', error: _errors['model']),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField('Year', controller: _year, hint: '2019', keyboardType: TextInputType.number, error: _errors['year']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField('Colour', controller: _colour, hint: 'Silver', error: _errors['colour']),
            ),
          ],
        ),
        CaboField('Plate number', controller: _plate, hint: 'LND 482 KJ', icon: Icons.pin_outlined, error: _errors['plate_number']),
        Text('Passenger seats', style: CaboText.label),
        const SizedBox(height: 8),
        ChipPicker(options: const ['4', '6', '7'], initial: {_seats}, single: true, onChanged: (s) => _seats = s.first),
        ToggleTile('Wheelchair accessible', initial: _wheelchair, icon: Icons.accessible_rounded, onChanged: (v) => _wheelchair = v),
        const SizedBox(height: 12),
        ActionButton(widget.buttonLabel, onPressed: _save),
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard(this.vehicle, {super.key, this.trailing});
  final Json vehicle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final status = v.str('status', 'pending');
    return CaboCard(
      borderColor: v.flag('is_active') ? CaboColors.yellow : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.directions_car_filled_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v.str('make')} ${v.str('model')}', style: CaboText.h3),
                    Text('${v.integer('year')} • ${v.str('colour')} • ${v.str('plate_number')}', style: CaboText.muted),
                  ],
                ),
              ),
              Pill(
                humanize(status),
                color: switch (status) {
                  'approved' => CaboColors.brightGreen,
                  'rejected' => CaboColors.red,
                  _ => CaboColors.yellow,
                },
              ),
            ],
          ),
          if (v.strings('ride_types').isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in v.strings('ride_types')) Pill(humanize(t), color: CaboColors.brightGreen)],
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 10), trailing!],
        ],
      ),
    );
  }
}

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      load: () => _vehicles(state),
      builder: (context, vehicles, reload) => StepScaffold(
        step: 4,
        title: 'Your vehicle',
        subtitle: 'Vehicles must be no more than 15 years old, with working air conditioning.',
        next: vehicles.isEmpty ? null : '/vehicle-documents',
        onNext: vehicles.isEmpty ? () async => showMessage(context, 'Add your vehicle to continue.', error: true) : null,
        children: [
          if (vehicles.isEmpty)
            VehicleForm(
              onSaved: (v) {
                state.newVehicle = v;
                reload();
              },
            )
          else ...[
            for (final v in vehicles) Padding(padding: const EdgeInsets.only(bottom: 10), child: VehicleCard(v)),
            const _Tip('Cabo sets which ride types your vehicle qualifies for when it is inspected.'),
          ],
        ],
      ),
    );
  }
}

/// The vehicle documents belong to: the active one, or the first on file.
Future<int?> _vehicleId(AppState state) async {
  final vehicles = await _vehicles(state);
  if (vehicles.isEmpty) return null;
  return (vehicles.where((v) => v.flag('is_active')).firstOrNull ?? vehicles.first).integer('id');
}

class VehicleDocumentsScreen extends StatelessWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<int?>(
      load: () => _vehicleId(state),
      builder: (context, vehicleId, _) => StepScaffold(
        step: 5,
        title: 'Vehicle documents',
        subtitle: 'All documents must be valid for at least 30 more days.',
        next: '/vehicle-photos',
        children: [DocumentTiles(vehicleDocuments, vehicleId: vehicleId)],
      ),
    );
  }
}

class VehiclePhotosScreen extends StatelessWidget {
  const VehiclePhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<int?>(
      load: () => _vehicleId(state),
      builder: (context, vehicleId, _) => StepScaffold(
        step: 6,
        title: 'Photograph your vehicle',
        subtitle: 'Park somewhere bright and take the photo from the front, with the plate number visible.',
        next: '/face-verification',
        children: [
          DocumentTiles(const ['vehicle_photo'], vehicleId: vehicleId),
          const SizedBox(height: 8),
          const _Tip('The other angles and the interior are checked at your vehicle inspection.'),
        ],
      ),
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
      children: [
        Center(
          child: Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(120),
              border: Border.all(color: CaboColors.yellow, width: 3),
            ),
            child: const Icon(Icons.face_retouching_natural_rounded, size: 110, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 20),
        const DocumentTiles(['selfie']),
        for (final t in const ['Remove sunglasses and caps', 'Face the light, avoid shadows', 'Keep your face inside the frame'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: CaboColors.brightGreen, size: 20),
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
  late bool agreed = AppScope.read(context).driver?.flag('background_check_consent') ?? false;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 8,
      title: 'Background check',
      subtitle: 'Cabo serves visitors to Lagos, so every host passes a background check before going online.',
      buttonLabel: 'I consent',
      onNext: () async {
        if (!agreed) {
          showMessage(context, 'Tick the box to give your consent.', error: true);
          return;
        }
        await AppScope.read(context).updateDriver({'background_check_consent': true});
        if (context.mounted) go(context, '/payout-details');
      },
      children: [
        const Center(child: HeroIllustration(Icons.verified_user_rounded, size: 150)),
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
                      const Icon(Icons.circle, size: 7, color: CaboColors.yellow),
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
            Checkbox(value: agreed, onChanged: (v) => setState(() => agreed = v!)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'I authorise Cabo and its verification partner to run these checks, '
                  'as described in the Host Privacy Notice.',
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

const nigerianBanks = [
  'Access Bank',
  'Ecobank',
  'FCMB',
  'Fidelity Bank',
  'First Bank',
  'GTBank',
  'Kuda',
  'Moniepoint',
  'OPay',
  'PalmPay',
  'Polaris Bank',
  'Stanbic IBTC',
  'Sterling Bank',
  'UBA',
  'Union Bank',
  'Wema Bank',
  'Zenith Bank',
];

/// Bank account form. Used during sign-up and from the account screen.
class BankForm extends StatefulWidget {
  const BankForm({super.key, required this.buttonLabel, required this.onSaved});
  final String buttonLabel;
  final Future<void> Function() onSaved;

  @override
  State<BankForm> createState() => _BankFormState();
}

class _BankFormState extends State<BankForm> {
  final _number = TextEditingController();
  final _name = TextEditingController();
  String? _bank;
  Map<String, String> _errors = {};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final d = AppScope.read(context).driver ?? const {};
    _bank = d.strOrNull('bank_name');
    _number.text = d.str('bank_account_number');
    _name.text = d.str('bank_account_name', AppScope.read(context).fullName);
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [for (final b in nigerianBanks) ListTile(title: Text(b), onTap: () => Navigator.of(sheet).pop(b))],
        ),
      ),
    );
    if (chosen != null) setState(() => _bank = chosen);
  }

  Future<void> _save() async {
    final errors = <String, String>{
      if (_bank == null) 'bank_name': 'Choose your bank.',
      if (!RegExp(r'^\d{10}$').hasMatch(_number.text.trim())) 'bank_account_number': 'Enter your 10-digit account number.',
      if (_name.text.trim().isEmpty) 'bank_account_name': 'Enter the name on the account.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    try {
      await AppScope.read(context)
          .updateDriver({'bank_name': _bank, 'bank_account_number': _number.text.trim(), 'bank_account_name': _name.text.trim()});
    } on ApiException catch (e) {
      if (e.fields.isEmpty) rethrow;
      if (mounted) setState(() => _errors = e.fields);
      return;
    }
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaboField(
          'Bank',
          key: ValueKey(_bank),
          value: _bank,
          hint: 'Choose your bank',
          icon: Icons.account_balance_outlined,
          suffix: const Icon(Icons.expand_more, color: CaboColors.muted),
          readOnly: true,
          onTap: _pickBank,
          error: _errors['bank_name'],
        ),
        CaboField(
          'Account number',
          controller: _number,
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          error: _errors['bank_account_number'],
        ),
        CaboField('Account name', controller: _name, icon: Icons.person_outline, error: _errors['bank_account_name']),
        const _Tip('The account name must match the name on your ID.'),
        const SizedBox(height: 16),
        ActionButton(widget.buttonLabel, onPressed: _save),
      ],
    );
  }
}

class PayoutDetailsScreen extends StatelessWidget {
  const PayoutDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, 'Step 9 of 9'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Bar(1, height: 6),
          const SizedBox(height: 20),
          Text('Where should we pay you?', style: CaboText.h1),
          const SizedBox(height: 6),
          Text('Your earnings are paid to this account every week.', style: CaboText.muted.copyWith(fontSize: 15)),
          const SizedBox(height: 20),
          BankForm(buttonLabel: 'Save and review application', onSaved: () async => go(context, '/application-status')),
        ],
      ),
    );
  }
}

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<(List<Json>, List<Json>)>(
      load: () async {
        final res = await Future.wait<dynamic>([
          state.api.get('/driver/documents'),
          state.api.get('/driver/vehicles'),
          state.refreshDriver(),
        ]);
        return (asJsonList(unwrap(res[0])), asJsonList(unwrap(res[1])));
      },
      builder: (context, data, reload) {
        final (docs, vehicles) = data;
        final d = state.driver ?? const {};
        final status = state.status;
        DocStatus done(bool ok) => ok ? DocStatus.approved : DocStatus.needed;
        final items = <(String, DocStatus, String)>[
          ('Personal details', done(d.strOrNull('first_name') != null && d.strOrNull('address') != null), '/personal-details'),
          for (final type in requiredDocuments)
            (
              documentTypes[type]!.$1,
              docStatus(docs.where((x) => x.str('type') == type).firstOrNull),
              vehicleDocuments.contains(type) ? '/vehicle-documents' : '/documents-upload',
            ),
          (
            'Vehicle details',
            vehicles.isEmpty
                ? DocStatus.needed
                : vehicles.any((v) => v.str('status') == 'approved')
                ? DocStatus.approved
                : DocStatus.review,
            '/vehicle-details',
          ),
          ('Background check consent', done(d.flag('background_check_consent')), '/background-check'),
          ('Payout details', done(d.strOrNull('bank_account_number') != null), '/payout-details'),
        ];
        final complete = items.where((i) => i.$2 == DocStatus.approved || i.$2 == DocStatus.review).length;
        final rejected = docs.where((x) => x.str('status') == 'rejected').toList();
        final inspection = d.date('inspection_at');
        final (headline, message) = switch (status) {
          'approved' => ('You are approved, ${state.firstName}', 'Your account is active. You can go online.'),
          'pending_review' => ('In review, ${state.firstName}', 'We are checking your application. This usually takes up to 48 hours.'),
          'rejected' => ('Application not approved', d.str('status_reason', 'Contact support to find out more.')),
          'suspended' => ('Account on hold', d.str('status_reason', 'Contact support to find out more.')),
          _ => (
            complete == items.length ? 'Ready to submit, ${state.firstName}' : 'Almost there, ${state.firstName}',
            complete == items.length
                ? 'Everything is in. Submit your application for review.'
                : '${plural(items.length - complete, 'item')} still to do before you can submit.',
          ),
        };
        return CaboScaffold(
          title: 'Application status',
          showBack: Navigator.of(context).canPop(),
          actions: [
            IconButton(tooltip: 'Help', icon: const Icon(Icons.help_outline_rounded), onPressed: () => go(context, '/help')),
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await state.signOut();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
              },
            ),
          ],
          bottom: switch (status) {
            'applicant' => ActionButton(
              'Submit application',
              icon: Icons.send_rounded,
              onPressed: () async {
                final res = await state.api.post('/driver/application/submit') as Json;
                await reload();
                if (context.mounted) showMessage(context, res.str('message', 'Application submitted.'));
              },
            ),
            'approved' => CaboButton('Continue', onPressed: () => go(context, '/approved')),
            _ => CaboButton('Refresh', style: CaboButtonStyle.secondary, icon: Icons.refresh_rounded, onPressed: reload),
          },
          children: [
            CaboCard(
              child: Row(
                children: [
                  Ring(
                    value: complete / items.length,
                    size: 96,
                    child: Text('$complete/${items.length}', style: CaboText.h2),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline, style: CaboText.h3),
                        const SizedBox(height: 4),
                        Text(message, style: CaboText.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (inspection != null || status == 'pending_review') ...[
              const SizedBox(height: 10),
              MenuTile(
                icon: Icons.event_available_rounded,
                title: 'Vehicle inspection',
                subtitle: inspection == null
                    ? 'We will contact you to book it'
                    : '${fmtDayTime(inspection)} • ${d.str('inspection_location', 'Cabo hub')}',
                onTap: () => go(context, '/inspection-booking'),
              ),
            ],
            const SectionTitle('Checklist'),
            for (final (name, itemStatus, route) in items)
              InkWell(
                onTap: () => go(context, route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        switch (itemStatus) {
                          DocStatus.approved => Icons.check_circle,
                          DocStatus.review => Icons.schedule_rounded,
                          DocStatus.rejected => Icons.error_rounded,
                          DocStatus.expiring => Icons.update_rounded,
                          DocStatus.needed => Icons.radio_button_unchecked,
                        },
                        color: switch (itemStatus) {
                          DocStatus.approved => CaboColors.brightGreen,
                          DocStatus.rejected => CaboColors.red,
                          _ => CaboColors.yellow,
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: CaboText.body)),
                      Text(
                        switch (itemStatus) {
                          DocStatus.approved => 'Done',
                          DocStatus.review => 'In review',
                          DocStatus.rejected => 'Resubmit',
                          DocStatus.expiring => 'Renew',
                          DocStatus.needed => 'To do',
                        },
                        style: CaboText.label.copyWith(
                          color: switch (itemStatus) {
                            DocStatus.approved => CaboColors.brightGreen,
                            DocStatus.rejected => CaboColors.red,
                            _ => CaboColors.yellow,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final r in rejected)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CaboCard(
                  color: CaboColors.red.withValues(alpha: 0.12),
                  child: Text(
                    '${r.str('label')}: ${r.str('rejection_reason', 'Please upload it again.')}',
                    style: CaboText.body.copyWith(fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class InspectionBookingScreen extends StatelessWidget {
  const InspectionBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = state.driver ?? const {};
    final at = d.date('inspection_at');
    final phone = state.config.obj('support')?.strOrNull('phone');
    return CaboScaffold(
      title: 'Vehicle inspection',
      bottom: CaboButton('Message support', style: CaboButtonStyle.secondary, onPressed: () => go(context, '/support-chat')),
      children: [
        Text(
          'A 20-minute check of your vehicle at a Cabo hub. Bring your original documents.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 16),
        CaboCard(
          borderColor: at == null ? null : CaboColors.yellow,
          child: Row(
            children: [
              IconBadge(at == null ? Icons.hourglass_top_rounded : Icons.event_available_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(at == null ? 'Not booked yet' : fmtDayTime(at), style: CaboText.h3),
                    Text(
                      at == null
                          ? 'The Cabo team will contact you with a date once your documents are in review.'
                          : d.str('inspection_location', 'Cabo hub'),
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('What to bring'),
        for (final t in const [
          'Your original driver\'s licence and ID',
          'The vehicle, clean inside and out',
          'Original vehicle licence, roadworthiness and insurance',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: CaboColors.brightGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: CaboText.body)),
              ],
            ),
          ),
        if (phone != null) ...[const SizedBox(height: 10), _Tip('Need to change the date? Call $phone or message support.')],
      ],
    );
  }
}

const trainingLessons = [
  ('Welcoming visitors to Lagos', '6 min', Icons.waving_hand_rounded),
  ('Safety on every trip', '8 min', Icons.health_and_safety_rounded),
  ('Lagos landmarks riders ask about', '10 min', Icons.location_city_rounded),
  ('Airport pickups at MMIA', '7 min', Icons.flight_land_rounded),
  ('Using the Cabo Host app', '5 min', Icons.phone_android_rounded),
];

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final done = AppScope.of(context).driver?.flag('training_completed') ?? false;
    return CaboScaffold(
      title: 'Host training',
      bottom: CaboButton('Try a practice question', onPressed: () => go(context, '/training-quiz')),
      children: [
        CaboCard(
          borderColor: done ? CaboColors.brightGreen : null,
          child: Row(
            children: [
              IconBadge(done ? Icons.verified_rounded : Icons.school_rounded, color: done ? CaboColors.brightGreen : CaboColors.yellow),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(done ? 'Training completed' : 'Training not completed yet', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      done
                          ? 'Cabo has recorded your hospitality training.'
                          : 'The Cabo team runs this training with you at your vehicle inspection and records it on your account.',
                      style: CaboText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('What it covers'),
        for (final (i, (title, time, icon)) in trainingLessons.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconBadge(icon, color: done ? CaboColors.brightGreen : CaboColors.yellow),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lesson ${i + 1}', style: CaboText.label),
                        Text(title, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                        Text(time, style: CaboText.muted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (done) const Icon(Icons.check_circle, color: CaboColors.brightGreen, size: 26),
                ],
              ),
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
  static const _correct = 1;
  int? answer;
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Drop them at the main gate and drive off',
      'Wait until they are inside the hotel lobby',
      'Ask them to pay extra for waiting',
      'End the trip before arriving',
    ];
    final right = answer == _correct;
    return CaboScaffold(
      title: 'Practice question',
      bottom: CaboButton(
        checked ? 'Done' : 'Check answer',
        onPressed: answer == null
            ? null
            : () {
                if (checked) {
                  back(context);
                } else {
                  setState(() => checked = true);
                }
              },
      ),
      children: [
        Text('Not scored. Your training is recorded by the Cabo team.', style: CaboText.label),
        const SizedBox(height: 22),
        Text('A first-time visitor arrives at their Ikoyi hotel at 11 pm. What should you do?', style: CaboText.h2),
        const SizedBox(height: 24),
        for (var i = 0; i < options.length; i++)
          SelectTile(
            title: options[i],
            selected: answer == i,
            onTap: () => setState(() {
              answer = i;
              checked = false;
            }),
          ),
        if (checked)
          CaboCard(
            color: (right ? CaboColors.brightGreen : CaboColors.red).withValues(alpha: 0.12),
            child: Text(
              right
                  ? 'Correct. Visitors should always be seen safely inside, especially at night.'
                  : 'Not quite. Wait until your rider is safely inside the hotel lobby.',
              style: CaboText.body,
            ),
          ),
      ],
    );
  }
}

class ApprovedScreen extends StatelessWidget {
  const ApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return StateScreen(
      icon: Icons.verified_rounded,
      color: CaboColors.brightGreen,
      title: "You're approved, ${state.firstName}!",
      message: 'Your Cabo Host account is active. Welcome to the team.',
      primary: 'Set up permissions',
      onPrimary: () => go(context, '/permissions'),
      extra: CaboCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your first steps', style: CaboText.h3),
            const SizedBox(height: 8),
            for (final (i, t) in const [
              'Allow location so nearby requests reach you',
              'Go online in a busy zone like Victoria Island',
              'Turn on airport shuttles in your ride preferences',
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CaboColors.onYellow),
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

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _location = false;

  Future<void> _allowLocation() async {
    await AppScope.read(context).location.current();
    if (mounted) setState(() => _location = true);
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Permissions',
      bottom: CaboButton('Start driving', onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false)),
      children: [
        Text('Cabo needs your location to work while you drive.', style: CaboText.muted.copyWith(fontSize: 15)),
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
                      'Used while you are online so nearby ride requests reach you and riders can see you arrive.',
                      style: CaboText.muted,
                    ),
                    const SizedBox(height: 12),
                    _location
                        ? const Pill('Allowed', color: CaboColors.brightGreen, icon: Icons.check)
                        : ActionButton('Allow', height: 40, expand: false, onPressed: _allowLocation),
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
              const IconBadge(Icons.notifications_active_rounded, color: CaboColors.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: CaboText.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Push alerts are coming soon. For now, keep the app open while you are online to see new requests.',
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
