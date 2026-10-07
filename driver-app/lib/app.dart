import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

/// Tab roots switch instantly instead of sliding in.
const _tabRoutes = {'/home', '/jobs', '/earnings', '/account'};

class CaboDriverApp extends StatelessWidget {
  const CaboDriverApp({super.key, this.initialRoute = '/'});

  final String initialRoute;

  static final _byRoute = {for (final s in screens) s.route: s.builder};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabo Driver',
      debugShowCheckedModeBanner: false,
      theme: buildCaboTheme(),
      initialRoute: initialRoute,
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
      onUnknownRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: screens.first.builder),
    );
  }
}
