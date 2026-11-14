import 'dart:convert';
import 'dart:io';

import 'package:cabo_guest/api/api_client.dart';
import 'package:cabo_guest/api/location.dart';
import 'package:cabo_guest/api/token_store.dart';
import 'package:cabo_guest/state/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Serves responses recorded from the Cabo backend (test/fixtures/api.json),
/// so screens can be tested against realistic data without a network.
class FakeApi {
  FakeApi({this.tripStatus, this.signedIn = true})
    : fixtures = jsonDecode(
        File('test/fixtures/api.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  final Map<String, dynamic> fixtures;

  /// When set, the guest's latest trip is reported with this status.
  final String? tripStatus;
  final bool signedIn;

  /// Every request made, as "METHOD /path".
  final calls = <String>[];

  /// Request bodies by "METHOD /path".
  final bodies = <String, dynamic>{};

  /// Extra or replacement responses by "METHOD /path": a body, or (status, body).
  final overrides = <String, Object?>{};

  dynamic _find(String method, Uri uri) {
    final parts = uri.path.replaceFirst('/api/v1', '').split('/');
    final path = parts.join('/');
    final candidates = [
      if (uri.hasQuery) '$path?${uri.query}',
      path,
      for (var i = parts.length - 1; i >= 2; i--)
        ([...parts]..[i] = '*').join('/'),
    ];
    for (final c in candidates) {
      final key = '$method $c';
      if (overrides.containsKey(key)) return overrides[key];
      if (fixtures.containsKey(key)) return fixtures[key];
    }
    return null;
  }

  dynamic _withTrip(String path, dynamic body) {
    if (tripStatus == null || body is! Map) return body;
    Map<String, dynamic> live(Map trip) => {
      ...trip.cast<String, dynamic>(),
      'status': tripStatus,
      'pin': '4821',
      if (tripStatus == 'requested') ...{
        'driver': null,
        'vehicle': null,
        'driver_id': null,
      },
    };
    final data = body['data'];
    if (path == '/rider/trips' && data is List && data.isNotEmpty) {
      return {
        ...body,
        'data': [live(data.first as Map), ...data.skip(1)],
      };
    }
    if (RegExp(r'^/rider/trips/\d+$').hasMatch(path) && data is Map)
      return {...body, 'data': live(data)};
    return body;
  }

  late final http.Client client = MockClient((request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    final key = '${request.method} $path';
    calls.add(key);
    if (request.body.isNotEmpty) bodies[key] = jsonDecode(request.body);
    var found = _find(request.method, request.url);
    var status = 200;
    if (found is (int, Object?)) {
      status = found.$1;
      found = found.$2;
    }
    found ??= request.method == 'GET'
        ? {'data': []}
        : {'data': <String, dynamic>{}};
    return http.Response(
      jsonEncode(_withTrip(path, found)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  /// App state wired to this fake API, signed in unless [signedIn] is false.
  AppState state() {
    final api = ApiClient(
      httpClient: client,
      baseUrl: 'https://cabo.test/api/v1',
    );
    final state = AppState(
      api: api,
      tokens: MemoryTokenStore(signedIn ? 'test-token' : null),
      location: const FixedLocationService(),
    );
    if (signedIn) {
      api.token = 'test-token';
      state.rider = (fixtures['GET /rider/me'] as Map)['data'] as Json;
    }
    state.config = (fixtures['GET /config'] as Map)['data'] as Json;
    return state;
  }
}
