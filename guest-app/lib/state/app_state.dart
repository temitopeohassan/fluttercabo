import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../api/location.dart';
import '../api/token_store.dart';

/// Signed-in guest, app configuration and the bookings being made.
///
/// Screens read it with `AppScope.of(context)` and call its methods; it
/// talks to the Cabo API and notifies listeners when something changes.
class AppState extends ChangeNotifier {
  AppState({ApiClient? api, TokenStore? tokens, LocationService? location})
    : api = api ?? ApiClient(),
      tokens = tokens ?? const SecureTokenStore('cabo_guest_token'),
      location = location ?? const DeviceLocationService() {
    this.api.onUnauthorized = _sessionEnded;
  }

  final ApiClient api;
  final TokenStore tokens;
  final LocationService location;
  final navigatorKey = GlobalKey<NavigatorState>();

  Json? rider;
  Json config = {};

  bool get signedIn => api.token != null;
  String get firstName => rider?.strOrNull('first_name') ?? 'there';
  String get fullName => rider?.str('name') ?? '';

  // ------------------------------------------------------------ Start-up

  /// Restores the session and returns the route to open first.
  Future<String> start() async {
    api.token = await tokens.read();
    unawaited(loadConfig());
    if (api.token == null) return '/welcome';
    try {
      await refreshRider();
    } on ApiException catch (e) {
      // Offline with a saved session: go in and let screens show their own errors.
      if (e.isUnauthorized) return '/welcome';
    }
    return rider != null && rider!.strOrNull('first_name') == null
        ? '/profile-setup'
        : '/home';
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
    if (api.token == null) return;
    _clearSession();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/welcome',
      (_) => false,
    );
  }

  void _clearSession() {
    api.token = null;
    rider = null;
    trip = null;
    wishlist = {};
    _wishlistLoaded = false;
    resetRide();
    unawaited(tokens.clear());
    notifyListeners();
  }

  // ------------------------------------------------------------ Sign-in

  String? otpIdentifier;
  String otpChannel = 'sms';

  /// Set by the server only while it runs in demo mode.
  String? demoCode;

  Future<void> requestOtp(String identifier) async {
    final res =
        await api.post('/rider/auth/otp', {'identifier': identifier}) as Json;
    otpIdentifier = res.str('identifier', identifier);
    otpChannel = res.str('channel', 'sms');
    demoCode = res.strOrNull('debug_code');
    notifyListeners();
  }

  /// Returns true when this is a new account that still needs a profile.
  Future<bool> verifyOtp(String code) async {
    final res = await api.post('/rider/auth/verify', {
      'identifier': otpIdentifier,
      'code': code,
      'device_name': 'Cabo Guest app',
    }) as Json;
    api.token = res.str('token');
    await tokens.write(api.token!);
    rider = res.obj('rider');
    notifyListeners();
    return res.flag('is_new') || rider?.strOrNull('first_name') == null;
  }

  Future<void> signOut() async {
    try {
      await api.post('/rider/auth/logout');
    } on ApiException {
      // Signing out locally is enough if the server cannot be reached.
    }
    _clearSession();
  }

  Future<void> deleteAccount() async {
    await api.delete('/rider/me');
    _clearSession();
  }

  Future<void> refreshRider() async {
    rider = unwrap(await api.get('/rider/me')) as Json;
    notifyListeners();
  }

  Future<void> updateRider(Json changes) async {
    final updated = unwrap(await api.patch('/rider/me', changes)) as Json;
    rider = {...?rider, ...updated};
    notifyListeners();
  }

  // ------------------------------------------------------------ Money

  static const _symbols = {'GBP': '£', 'USD': r'$', 'EUR': '€'};

  String get homeCurrency => rider?.str('home_currency', 'NGN') ?? 'NGN';

  /// "≈ £1.75" in the guest's home currency, or '' for naira.
  String homePrice(num ngn) {
    final rate = config.obj('exchange_rates')?.numberOrNull(homeCurrency);
    if (homeCurrency == 'NGN' || rate == null || rate <= 0) return '';
    return '≈ ${_symbols[homeCurrency] ?? '$homeCurrency '}${(ngn / rate).toStringAsFixed(2)}';
  }

  /// Absolute URL for an image path returned by the API.
  String? imageUrl(Json? item) {
    final url = item?.strOrNull('image') ?? item?.strOrNull('image_url');
    if (url == null) return null;
    return url.startsWith('http') ? url : '${api.origin}$url';
  }

  // ------------------------------------------------------------ Places

  List<Json> _places = [];

  Future<List<Json>> searchPlaces([String q = '']) async {
    final list = asJsonList(unwrap(await api.get('/places', query: {'q': q})));
    if (q.isEmpty) _places = list;
    return list;
  }

  /// Where a ride can go: only the tourism locations the API lists.
  Future<List<Json>> destinations([String q = '']) async {
    final list = asJsonList(
      unwrap(await api.get('/places', query: {'q': q, 'kind': 'attraction'})),
    );
    return [
      for (final p in list)
        if (p.str('kind') == 'attraction') p,
    ];
  }

  /// The tourism location at this point, if there is one.
  static Json? destinationAt(List<Json> destinations, double lat, double lng) {
    for (final d in destinations) {
      if (distanceKm(lat, lng, d.number('lat'), d.number('lng')) <= 0.3)
        return d;
    }
    return null;
  }

  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    double rad(double d) => d * pi / 180;
    final a =
        pow(sin(rad(lat2 - lat1) / 2), 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(rad(lng2 - lng1) / 2), 2);
    return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// A place record for the phone's position, named after the nearest known place.
  Future<Json> currentPlace() async {
    final here = await location.current();
    if (_places.isEmpty) {
      try {
        await searchPlaces();
      } on ApiException {
        // Naming the spot is optional.
      }
    }
    Json? nearest;
    var best = double.infinity;
    for (final p in _places) {
      final d = distanceKm(
        here.lat,
        here.lng,
        p.number('lat'),
        p.number('lng'),
      );
      if (d < best) {
        best = d;
        nearest = p;
      }
    }
    final label = nearest == null
        ? 'My location'
        : best < 0.15
        ? nearest.str('name')
        : 'Near ${nearest.str('name')}';
    return {
      'name': label,
      'address': label,
      'lat': here.lat,
      'lng': here.lng,
      'kind': 'current',
    };
  }

  // ------------------------------------------------------------ Rides

  Json? pickup;
  Json? dropoff;
  List<Json> stops = [];
  List<Json> estimates = [];
  String rideType = 'comfort';
  String paymentMethod = 'card';
  String? promoCode;
  DateTime? scheduledAt;

  /// The ride being requested, in progress or just finished.
  Json? trip;

  void resetRide() {
    dropoff = null;
    stops = [];
    estimates = [];
    promoCode = null;
    scheduledAt = null;
  }

  void setPickup(Json place) {
    pickup = place;
    estimates = [];
    notifyListeners();
  }

  void setDropoff(Json place) {
    dropoff = place;
    estimates = [];
    notifyListeners();
  }

  void chooseRide(String code) {
    rideType = code;
    notifyListeners();
  }

  void choosePayment(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setSchedule(DateTime? when) {
    scheduledAt = when;
    notifyListeners();
  }

  Json get _route => {
    'pickup_lat': pickup!.number('lat'),
    'pickup_lng': pickup!.number('lng'),
    'dropoff_lat': dropoff!.number('lat'),
    'dropoff_lng': dropoff!.number('lng'),
    if (stops.isNotEmpty)
      'stops': [
        for (final s in stops)
          {
            'address': s.str('address'),
            'lat': s.number('lat'),
            'lng': s.number('lng'),
          },
      ],
    if (promoCode != null) 'promo_code': promoCode,
  };

  Json? get estimate {
    for (final e in estimates) {
      if (e.str('ride_type') == rideType) return e;
    }
    return estimates.isEmpty ? null : estimates.first;
  }

  Future<void> loadEstimates() async {
    if (pickup == null || dropoff == null)
      throw ApiException('Choose where you are going first.');
    estimates = asJsonList(
      unwrap(await api.post('/rider/fare-estimates', _route)),
    );
    if (estimates.isNotEmpty &&
        !estimates.any((e) => e.str('ride_type') == rideType)) {
      rideType = estimates.first.str('ride_type');
    }
    notifyListeners();
  }

  Future<Json> requestRide() async {
    trip = unwrap(
      await api.post('/rider/trips', {
        ..._route,
        'ride_type': rideType,
        'pickup_address': pickup!.str('address'),
        'dropoff_address': dropoff!.str('address'),
        'payment_method': paymentMethod,
        if (scheduledAt != null)
          'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
      }),
    ) as Json;
    resetRide();
    notifyListeners();
    return trip!;
  }

  static const activeStatuses = {
    'requested',
    'accepted',
    'arrived',
    'in_progress',
  };

  /// Loads the guest's ride in progress, if there is one.
  Future<Json?> findActiveTrip() async {
    final res = await api.get('/rider/trips') as Json;
    for (final t in res.list('data')) {
      if (activeStatuses.contains(t.str('status'))) {
        trip = await loadTrip(t.integer('id'));
        notifyListeners();
        return trip;
      }
    }
    return null;
  }

  Future<Json> loadTrip(int id) async =>
      unwrap(await api.get('/rider/trips/$id')) as Json;

  Future<void> refreshTrip() async {
    final id = trip?.integer('id');
    if (id == null || id == 0) return;
    trip = await loadTrip(id);
    notifyListeners();
  }

  Timer? _tripTimer;
  int _tripWatchers = 0;

  /// Polls the active ride every few seconds while a ride screen is open.
  void watchTrip() {
    _tripWatchers++;
    _tripTimer ??= Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        await refreshTrip();
      } on ApiException {
        // Keep the last known state; the next poll retries.
      }
    });
  }

  void unwatchTrip() {
    if (--_tripWatchers <= 0) {
      _tripWatchers = 0;
      _tripTimer?.cancel();
      _tripTimer = null;
    }
  }

  /// The screen that matches a ride's status.
  static String? tripRoute(Json? trip) => switch (trip?.str('status')) {
    'requested' => '/finding-driver',
    'accepted' || 'arrived' => '/driver-on-way',
    'in_progress' => '/trip-in-progress',
    'completed' => '/trip-complete',
    _ => null,
  };

  Future<Json> cancelTrip(String reason) async {
    final res = await api.post('/rider/trips/${trip!.integer('id')}/cancel', {
      'reason': reason,
    }) as Json;
    trip = res.obj('data');
    notifyListeners();
    return res;
  }

  // ------------------------------------------------------------ Selections

  /// The item a detail screen shows, set by the list that opened it.
  Json? tour;
  Json? tourSlot;
  int guests = 1;
  Set<String> addons = {};
  bool includeRide = false;
  String? tourPromo;
  Json? tourBooking;
  Json? attraction;
  Json? shuttle;
  Json shuttleDraft = {};
  Json? ticket;
  Json? pastTrip;

  void select({
    Json? tour,
    Json? attraction,
    Json? tourBooking,
    Json? shuttle,
    Json? ticket,
    Json? pastTrip,
  }) {
    if (tour != null) {
      if (tour.str('slug') != this.tour?.str('slug')) {
        tourSlot = null;
        guests = max(1, tour.integer('min_group_size', 1));
        addons = {};
        includeRide = false;
        tourPromo = null;
      }
      this.tour = tour;
    }
    if (attraction != null) this.attraction = attraction;
    if (tourBooking != null) this.tourBooking = tourBooking;
    if (shuttle != null) this.shuttle = shuttle;
    if (ticket != null) this.ticket = ticket;
    if (pastTrip != null) this.pastTrip = pastTrip;
    notifyListeners();
  }

  void changed() => notifyListeners();

  /// Filters for the tour list: category, max_price, date, wheelchair, sort.
  Json tourFilters = {};

  void setTourFilters(Json filters) {
    tourFilters = filters;
    notifyListeners();
  }

  // ------------------------------------------------------------ Wishlist

  /// Saved tours and attractions: "tour:12" → wishlist item id.
  Map<String, int> wishlist = {};
  bool _wishlistLoaded = false;

  Future<void> loadWishlist({bool force = false}) async {
    if (_wishlistLoaded && !force) return;
    final items = asJsonList(unwrap(await api.get('/rider/wishlist')));
    wishlist = {
      for (final i in items)
        '${i.str('item_type')}:${i.integer('item_id')}': i.integer('id'),
    };
    _wishlistLoaded = true;
    notifyListeners();
  }

  bool isSaved(String type, int id) => wishlist.containsKey('$type:$id');

  Future<void> toggleSaved(String type, int id) async {
    final key = '$type:$id';
    final existing = wishlist[key];
    if (existing != null) {
      await api.delete('/rider/wishlist/$existing');
      wishlist.remove(key);
    } else {
      final item = unwrap(
        await api.post('/rider/wishlist', {'type': type, 'id': id}),
      ) as Json;
      wishlist[key] = item.integer('id');
    }
    notifyListeners();
  }

  /// Price of the tour booking being built, before any promo discount.
  int get tourTotal {
    final t = tour;
    if (t == null) return 0;
    var total = t.integer('price') * guests;
    for (final a in t.list('addons')) {
      if (addons.contains(a.str('code'))) total += a.integer('price');
    }
    if (includeRide)
      total += config.obj('tours')?.integer('ride_addon_price', 4000) ?? 4000;
    return total;
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }
}
