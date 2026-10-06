import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/widgets.dart';

/// Lists every screen so reviewers can jump straight to any of them.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'All screens',
      children: [
        Text(
          'Every screen in this build, numbered as in the Cabo Driver spec.',
          style: CaboText.muted,
        ),
        for (final section in sectionNames.entries) ...[
          SectionTitle('${section.key}. ${section.value}'),
          for (final s in screens.where((s) => s.section == section.key))
            MenuTile(
              icon: Icons.phone_android_rounded,
              title: s.title,
              subtitle: '${s.id} • ${s.route}',
              onTap: () => go(context, s.route),
            ),
        ],
      ],
    );
  }
}
