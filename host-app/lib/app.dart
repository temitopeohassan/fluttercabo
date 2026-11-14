import 'package:flutter/material.dart';

import 'routes.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/live.dart';

/// Tab roots switch instantly instead of sliding in.
const _tabRoutes = {'/home', '/jobs', '/earnings', '/account'};

class CaboHostApp extends StatefulWidget {
  const CaboHostApp({super.key, this.initialRoute = '/', this.state});

  final String initialRoute;

  /// Supplied by tests; the app creates its own otherwise.
  final AppState? state;

  @override
  State<CaboHostApp> createState() => _CaboHostAppState();
}

class _CaboHostAppState extends State<CaboHostApp> {
  late final AppState _state = widget.state ?? AppState();

  static final _byRoute = {for (final s in screens) s.route: s.builder};

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        navigatorKey: _state.navigatorKey,
        title: 'Cabo Host',
        debugShowCheckedModeBanner: false,
        theme: buildCaboTheme(),
        initialRoute: widget.initialRoute,
        onGenerateRoute: (settings) {
          final builder = _byRoute[settings.name];
          if (builder == null) return null;
          if (_tabRoutes.contains(settings.name)) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            );
          }
          return MaterialPageRoute(settings: settings, builder: builder);
        },
        onUnknownRoute: (settings) => MaterialPageRoute(settings: settings, builder: screens.first.builder),
      ),
    );
  }
}
