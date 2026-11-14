import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../api/location.dart';
import '../api/token_store.dart';

/// Everything the Host app knows about the signed-in host: their session,
/// profile, online status, ride requests and the trip in hand.
class AppState extends ChangeNotifier {
  AppState({ApiClient? api, TokenStore? tokens, LocationService? location})
    : api = api ?? ApiClient(),
      tokens = tokens ?? const SecureTokenStore('cabo_host_token'),
      location = location ?? const DeviceLocationService() {
    this.api.onUnauthorized = _sessionEnded;
  }

  final ApiClient api;
  final TokenStore tokens;
  final LocationService location;
  final navigatorKey = GlobalKey<NavigatorState>();

  Json? driver;
  Json config = {};

  bool get signedIn => api.token != null;
  String get firstName => driver?.strOrNull('first_name') ?? 'there';
  String get fullName => driver?.str('name').trim() ?? '';
  String get status => driver?.str('status', 'applicant') ?? 'applicant';
  bool get approved => status == 'approved';
  bool get isOnline => driver?.flag('is_online') ?? false;
  Json? get vehicle => driver?.obj('active_vehicle');
  List<String> get blockers => driver?.strings('online_blockers') ?? const [];
  Json get preferences => driver?.obj('preferences') ?? {};

  // ------------------------------------------------------------ Start-up

  /// Restores the session and returns the route to open first.
  Future<String> start() async {
    api.token = await tokens.read();
    unawaited(loadConfig());
    if (api.token == null) return '/welcome';
    try {
      await refreshDriver();
    } on ApiException catch (e) {
      if (e.isUnauthorized) return '/welcome';
      // Offline with a saved session: go in and let screens show their own errors.
      return '/home';
    }
    return homeRoute;
  }

  /// Where a signed-in host belongs, given how far their application has got.
  String get homeRoute {
    final d = driver;
    if (d == null) return '/welcome';
    if (d.strOrNull('first_name') == null) return '/personal-details';
    return switch (status) {
      'approved' => '/home',
      'suspended' || 'deactivated' => '/account-on-hold',
      _ => '/application-status',
    };
  }

  Future<void> loadConfig() async {
    try {
      config = unwrap(await api.get('/config')) as Json;
      notifyListeners();
    } on ApiException {
      // Screens fall back to sensible defaults without it.
    }
  }

  void _sessionEnded() {
    if (!signedIn) return;
    _clearSession();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/welcome', (_) => false);
  }

  void _clearSession() {
    api.token = null;
    unawaited(tokens.clear());
    _stopTimers();
    driver = null;
    trip = null;
    requests = [];
    offer = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ Sign-in

  String? otpIdentifier;

  /// The code to type, when the server is in demo mode and does not send one.
  String? demoCode;

  Future<void> requestOtp(String identifier) async {
    final res = await api.post('/driver/auth/otp', {'identifier': identifier}) as Json;
    otpIdentifier = identifier;
    demoCode = res.strOrNull('debug_code');
    notifyListeners();
  }

  /// Signs in and returns the route to open next.
  Future<String> verifyOtp(String code) async {
    final res = await api.post('/driver/auth/verify', {'identifier': otpIdentifier, 'code': code}) as Json;
    api.token = res.str('token');
    await tokens.write(api.token!);
    await refreshDriver();
    return homeRoute;
  }

  Future<void> signOut() async {
    try {
      if (isOnline) await api.post('/driver/status', {'online': false});
      await api.post('/driver/auth/logout');
    } on ApiException {
      // Signing out locally is enough.
    }
    _clearSession();
  }

  Future<void> refreshDriver() async {
    driver = unwrap(await api.get('/driver/me')) as Json;
    notifyListeners();
    if (isOnline) _startHeartbeat();
  }

  Future<void> updateDriver(Json changes) async {
    await api.patch('/driver/me', changes);
    await refreshDriver();
  }

  // ------------------------------------------------------------ Online status

  Timer? _heartbeat;
  Timer? _requestTimer;
  int _requestWatchers = 0;

  /// Goes online at the phone's position. Throws an [ApiException] carrying
  /// `blockers` when the account is not ready.
  Future<void> goOnline() async {
    final here = await location.current();
    await api.post('/driver/status', {'online': true, 'lat': here.lat, 'lng': here.lng});
    driver = {...?driver, 'is_online': true};
    notifyListeners();
    _startHeartbeat();
  }

  Future<void> goOffline() async {
    await api.post('/driver/status', {'online': false});
    driver = {...?driver, 'is_online': false};
    requests = [];
    _heartbeat?.cancel();
    _heartbeat = null;
    notifyListeners();
  }

  /// Sends the phone's position every 20 seconds while online, so nearby
  /// requests reach this host.
  void _startHeartbeat() {
    _heartbeat ??= Timer.periodic(const Duration(seconds: 20), (_) => sendLocation());
  }

  Future<void> sendLocation() async {
    if (!signedIn || !isOnline) return;
    try {
      final here = await location.current();
      await api.post('/driver/location', {'lat': here.lat, 'lng': here.lng});
    } catch (_) {
      // The next beat tries again.
    }
  }

  // ------------------------------------------------------------ Requests

  /// Open ride requests near this host, closest first.
  List<Json> requests = [];

  /// The request being looked at.
  Json? offer;

  Future<void> loadRequests() async {
    if (!isOnline) {
      // Never notify listeners in the same frame as the call: screens call this while building.
      await Future<void>.value();
      requests = [];
    } else {
      requests = asJsonList(unwrap(await api.get('/driver/trips/available')));
    }
    notifyListeners();
  }

  /// Polls for requests while a screen is showing them.
  void watchRequests() {
    _requestWatchers++;
    _requestTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await loadRequests();
      } on ApiException {
        // Keep the last list; the next poll tries again.
      }
    });
  }

  void unwatchRequests() {
    if (--_requestWatchers <= 0) {
      _requestWatchers = 0;
      _requestTimer?.cancel();
      _requestTimer = null;
    }
  }

  Future<void> accept(Json request) async {
    trip = unwrap(await api.post('/driver/trips/${request.integer('id')}/accept')) as Json;
    requests = [];
    offer = null;
    notifyListeners();
  }

  Future<void> decline(Json request) async {
    await api.post('/driver/trips/${request.integer('id')}/decline');
    requests = [
      for (final r in requests)
        if (r.integer('id') != request.integer('id')) r,
    ];
    offer = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ Current trip

  /// The trip in hand, or the one just finished.
  Json? trip;

  /// Cash to collect from the rider after the last completed trip.
  int cashToCollect = 0;

  static const activeStatuses = {'accepted', 'arrived', 'in_progress'};
  bool get onTrip => trip != null && activeStatuses.contains(trip!.str('status'));

  Future<Json?> loadCurrentTrip() async {
    final current = unwrap(await api.get('/driver/trips/current'));
    if (current is Map<String, dynamic>) {
      trip = current;
    } else if (onTrip) {
      // The trip ended elsewhere (cancelled by the rider or support): show how it ended.
      trip = unwrap(await api.get('/driver/trips/${trip!.integer('id')}')) as Json;
    }
    notifyListeners();
    return onTrip ? trip : null;
  }

  /// Runs a step of the trip: arrive, start, complete, collect-cash, cancel or rating.
  Future<Json> tripAction(String action, [Json? body]) async {
    final res = await api.post('/driver/trips/${trip!.integer('id')}/$action', body) as Json;
    // Keep the rider and ride type, which some responses leave out.
    trip = {...trip!, ...unwrap(res) as Json};
    if (action == 'complete') cashToCollect = res.integer('collect_cash');
    if (action == 'collect-cash') cashToCollect = 0;
    notifyListeners();
    return res;
  }

  /// The screen that goes with the trip's status.
  static String? tripRoute(Json? trip) => switch (trip?.str('status')) {
    'accepted' => '/navigate-pickup',
    'arrived' => '/arrived-pickup',
    'in_progress' => '/trip-in-progress',
    'completed' => '/trip-summary',
    _ => null,
  };

  // ------------------------------------------------------------ Selections

  /// Items picked on one screen and shown on the next.
  Json? shuttle;
  Json? tourSlot;
  Json? pastTrip;
  Json? ticket;

  /// The vehicle added during sign-up, so its documents attach to it.
  Json? newVehicle;

  void select({Json? shuttle, Json? tourSlot, Json? pastTrip, Json? ticket, Json? offer}) {
    this.shuttle = shuttle ?? this.shuttle;
    this.tourSlot = tourSlot ?? this.tourSlot;
    this.pastTrip = pastTrip ?? this.pastTrip;
    this.ticket = ticket ?? this.ticket;
    this.offer = offer ?? this.offer;
    notifyListeners();
  }

  void changed() => notifyListeners();

  void _stopTimers() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _requestTimer?.cancel();
    _requestTimer = null;
    _requestWatchers = 0;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
