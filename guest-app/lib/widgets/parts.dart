import 'dart:math';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../format.dart';
import 'live.dart';
import '../theme.dart';
import 'common.dart';

/// Rounded search field like the one on the home screen.
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, this.hint = 'Where to?', this.onTap, this.value});
  final String hint;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CaboColors.surface,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: CaboColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value ?? hint,
                  overflow: TextOverflow.ellipsis,
                  style: value == null
                      ? CaboText.muted.copyWith(fontSize: 14)
                      : CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo card with a title underneath, as in "Popular Destinations".
class DestinationCard extends StatelessWidget {
  const DestinationCard(this.place, {super.key, this.width = 130, this.onTap});

  /// An attraction from the API.
  final Json place;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetPhoto(
              AppScope.read(context).imageUrl(place),
              fallback: sceneFor(
                '${place.str('category')} ${place.str('name')}',
              ),
              height: width * 0.85,
              radius: 16,
            ),
            const SizedBox(height: 8),
            Text(
              place.str('name'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CaboText.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List row for a tour: thumbnail, name, rating and price.
class TourTile extends StatelessWidget {
  const TourTile(
    this.tour, {
    super.key,
    this.onTap,
    this.saved = false,
    this.onSave,
  });

  /// A tour from the API.
  final Json tour;
  final VoidCallback? onSave;
  final VoidCallback? onTap;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CaboCard(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: NetPhoto(
                AppScope.read(context).imageUrl(tour),
                fallback: sceneFor(
                  '${tour.obj('category')?.str('name')} ${tour.str('title')}',
                ),
                radius: 14,
                height: 96,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (tour.obj('category')?.str('name') ?? tour.str('area'))
                        .toUpperCase(),
                    style: CaboText.label.copyWith(
                      color: CaboColors.green,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    tour.str('title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CaboText.h3.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: CaboColors.yellow,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        tour.numberOrNull('rating') == null
                            ? 'New'
                            : '${tour.number('rating').toStringAsFixed(1)} (${compact(tour.integer('reviews_count'))})',
                        style: CaboText.label,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: CaboColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          fmtDuration(tour.integer('duration_minutes')),
                          overflow: TextOverflow.ellipsis,
                          style: CaboText.label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: naira(tour.integer('price')),
                      style: CaboText.h3.copyWith(color: CaboColors.green),
                      children: [
                        TextSpan(text: ' / person', style: CaboText.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
              onPressed: onSave,
              icon: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? CaboColors.red : CaboColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three icon facts in a row (duration, location, group size).
class FactRow extends StatelessWidget {
  const FactRow(this.facts, {super.key});
  final List<(IconData, String, String)> facts;

  @override
  Widget build(BuildContext context) {
    return CaboCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Icon(facts[i].$1, color: CaboColors.green),
                    const SizedBox(height: 6),
                    Text(facts[i].$2, style: CaboText.label),
                    Text(
                      facts[i].$3,
                      textAlign: TextAlign.center,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckRow extends StatelessWidget {
  const CheckRow(this.text, {super.key, this.done = true});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: done ? CaboColors.green : CaboColors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: CaboText.body)),
        ],
      ),
    );
  }
}

/// A ride tier row with ETA, distance, capacity and upfront fare.
class RideOption extends StatelessWidget {
  const RideOption({
    super.key,
    required this.name,
    required this.icon,
    required this.eta,
    required this.fare,
    required this.selected,
    required this.onTap,
    this.seats = 4,
    this.surge,
    this.homeFare = '',
  });

  final String name;
  final IconData icon;
  final String eta;
  final int fare;
  final int seats;
  final bool selected;
  final VoidCallback onTap;
  final String? surge;

  /// The fare in the guest's home currency, e.g. "≈ £1.75".
  final String homeFare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? CaboColors.greenSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? CaboColors.green : CaboColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 34, color: CaboColors.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: CaboText.h3),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: CaboColors.muted,
                          ),
                          Text('$seats', style: CaboText.label),
                          if (surge != null) ...[
                            const SizedBox(width: 6),
                            Pill(surge!, color: CaboColors.orange),
                          ],
                        ],
                      ),
                      Text(eta, style: CaboText.muted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(naira(fare), style: CaboText.h3),
                    if (homeFare.isNotEmpty)
                      Text(homeFare, style: CaboText.label),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A QR-code-like pattern, used only as a placeholder in design previews.
class FakeQr extends StatelessWidget {
  const FakeQr({super.key, this.size = 200, this.seed = 42});
  final double size;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _QrPainter(seed)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final cell = size.width / n;
    final rnd = Random(seed);
    final ink = Paint()..color = CaboColors.ink;
    bool finder(int x, int y) =>
        (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!finder(x, y) && rnd.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), ink);
        }
      }
    }
    for (final (fx, fy) in [(0, 0), (n - 7, 0), (0, n - 7)]) {
      final o = Offset(fx * cell, fy * cell);
      canvas.drawRect(o & Size(cell * 7, cell * 7), ink);
      canvas.drawRect(
        (o + Offset(cell, cell)) & Size(cell * 5, cell * 5),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        (o + Offset(cell * 2, cell * 2)) & Size(cell * 3, cell * 3),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

/// Driver summary used on the match and trip screens.
class DriverCard extends StatelessWidget {
  const DriverCard(this.trip, {super.key, this.actions = true});

  /// A trip from the API, with its `driver` and `vehicle`.
  final Json trip;
  final bool actions;

  @override
  Widget build(BuildContext context) {
    final driver = trip.obj('driver') ?? const {};
    final vehicle = trip.obj('vehicle') ?? const {};
    final name = driver.str('first_name', 'Your driver');
    final last = driver.str('last_name');
    final rating = driver.numberOrNull('rating');
    return Row(
      children: [
        Avatar(initials('$name $last'), size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      last.isEmpty ? name : '$name ${last[0]}.',
                      overflow: TextOverflow.ellipsis,
                      style: CaboText.h3,
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: CaboColors.yellow,
                    ),
                    Text(rating.toStringAsFixed(2), style: CaboText.label),
                  ],
                ],
              ),
              if (vehicle.isNotEmpty)
                Text(
                  '${vehicle.str('colour')} ${vehicle.str('make')} ${vehicle.str('model')}',
                  style: CaboText.muted,
                ),
              if (vehicle.strOrNull('plate_number') != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CaboColors.yellowSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CaboColors.yellow),
                  ),
                  child: Text(
                    vehicle.str('plate_number'),
                    style: CaboText.label.copyWith(
                      color: CaboColors.ink,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions)
          RoundAction(
            Icons.shield_rounded,
            color: CaboColors.greenSoft,
            iconColor: CaboColors.green,
            onTap: () => go(context, '/safety'),
          ),
      ],
    );
  }
}
