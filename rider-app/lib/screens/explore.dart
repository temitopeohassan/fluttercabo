import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 6. Cabo Explore.

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Explore Lagos',
      actions: [
        IconButton(
          icon: const Icon(Icons.map_rounded, color: CaboColors.green),
          onPressed: () => go(context, '/explore-map'),
        ),
      ],
      children: [
        const ChipPicker(
          options: ['All', 'Nature', 'Art', 'Beaches', 'History', 'Markets'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 16),
        for (final p in places)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => go(context, '/attraction'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Scene(p.scene, height: 150),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: CaboText.h3),
                            Text(
                              '${p.category} • ${p.area} • ${p.hours}',
                              style: CaboText.muted,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: CaboColors.yellow,
                        size: 18,
                      ),
                      Text(
                        '${p.rating}',
                        style: CaboText.label.copyWith(color: CaboColors.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ExploreMapScreen extends StatelessWidget {
  const ExploreMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MapLayout(
      map: const CaboMap(
        markers: [
          MapMarker(
            Offset(0.82, 0.78),
            MarkerKind.pickup,
            label: 'Lekki Conservation',
          ),
          MapMarker(
            Offset(0.62, 0.66),
            MarkerKind.pickup,
            label: 'Nike Art Gallery',
          ),
          MapMarker(Offset(0.3, 0.88), MarkerKind.pickup, label: 'Tarkwa Bay'),
          MapMarker(
            Offset(0.2, 0.36),
            MarkerKind.pickup,
            label: 'Freedom Park',
          ),
          MapMarker(Offset(0.5, 0.5), MarkerKind.stop),
        ],
      ),
      top: Row(
        children: [
          RoundAction(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 44,
            onTap: () => back(context),
          ),
          const SizedBox(width: 10),
          const Expanded(child: SearchBox(hint: 'Search attractions')),
        ],
      ),
      panel: Row(
        children: [
          const SizedBox(
            width: 84,
            height: 84,
            child: Scene(SceneKind.art, height: 84, radius: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nike Art Gallery', style: CaboText.h3),
                Text('Art • 4.2 km • Open until 18:00', style: CaboText.muted),
                const SizedBox(height: 8),
                CaboButton(
                  'Ride there',
                  height: 40,
                  expand: false,
                  onPressed: () => go(context, '/choose-ride'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttractionScreen extends StatelessWidget {
  const AttractionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(
        context,
        'Nike Art Gallery',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: CaboColors.red,
            ),
            onPressed: () => go(context, '/wishlist'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Scene(SceneKind.art, height: 200),
          const SizedBox(height: 14),
          Text('Nike Art Gallery', style: CaboText.h1),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: CaboColors.yellow,
                size: 18,
              ),
              Text(' 4.7 (1.8k) • Art • Lekki', style: CaboText.muted),
            ],
          ),
          const SizedBox(height: 14),
          const FactRow([
            (Icons.schedule_rounded, 'Open', '10:00 – 18:00'),
            (Icons.confirmation_number_rounded, 'Entry', 'Free'),
            (Icons.timer_rounded, 'Visit', '1 – 2 hours'),
          ]),
          const SectionTitle('About'),
          Text(
            'One of the largest galleries in West Africa, with over 8,000 works across five floors, '
            'founded by artist Nike Davies-Okundaye.',
            style: CaboText.body,
          ),
          const SectionTitle('Visitor tips'),
          const CheckRow('Prices on art are negotiable; ask staff for help'),
          const CheckRow('Photography is allowed on most floors'),
          const CheckRow('Weekday mornings are quietest'),
          const SectionTitle('Safety notes'),
          CaboCard(
            color: CaboColors.yellowSoft,
            child: Text(
              'Use the official car park. After dark, book your ride from the gallery entrance.',
              style: CaboText.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(
          'Ride There',
          icon: Icons.local_taxi_rounded,
          onPressed: () => go(context, '/choose-ride'),
        ),
      ),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Wishlist',
      bottom: CaboButton(
        'Plan my days',
        onPressed: () => go(context, '/itinerary'),
      ),
      children: [
        const ChipPicker(
          options: ['All (5)', 'Tours (2)', 'Places (3)'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 14),
        TourTile(
          tours[1],
          saved: true,
          onTap: () => go(context, '/tour-detail'),
        ),
        TourTile(
          tours[3],
          saved: true,
          onTap: () => go(context, '/tour-detail'),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
          children: [
            for (final p in places.take(3))
              DestinationCard(
                p,
                width: 110,
                onTap: () => go(context, '/attraction'),
              ),
          ],
        ),
      ],
    );
  }
}

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(
      String time,
      String title,
      String sub,
      IconData icon, {
      bool ride = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 48, child: Text(time, style: CaboText.label)),
          Expanded(
            child: CaboCard(
              color: ride ? CaboColors.greenSoft : Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, color: CaboColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: CaboText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(sub, style: CaboText.muted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return CaboScaffold(
      title: 'My Lagos plan',
      children: [
        const ChipPicker(
          options: ['Sat 17', 'Sun 18', 'Mon 19', 'Tue 20'],
          initial: {1},
          single: true,
        ),
        const SizedBox(height: 16),
        item(
          '08:20',
          'Cabo ride to Lekki',
          'Booked • Comfort',
          Icons.local_taxi_rounded,
          ride: true,
        ),
        item(
          '09:00',
          'Lekki Conservation Centre',
          'Tour • 4 hours • ticket ready',
          Icons.forest_rounded,
        ),
        item(
          '13:15',
          'Ride to Nike Art Gallery',
          'Tap to book • about ${naira(2500)}',
          Icons.add_road_rounded,
          ride: true,
        ),
        item(
          '13:30',
          'Nike Art Gallery',
          'Saved place • open until 18:00',
          Icons.palette_rounded,
        ),
        item(
          '19:00',
          'Dinner at Terra Kulture',
          'Saved place',
          Icons.restaurant_rounded,
        ),
        const SizedBox(height: 8),
        CaboButton(
          'Add a stop',
          style: CaboButtonStyle.secondary,
          icon: Icons.add_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      (
        'SAT 24 OCT',
        'Afrobeats Live at Eko Convention Centre',
        '₦20,000',
        SceneKind.nightlife,
      ),
      (
        'SUN 25 OCT',
        'Lagos Food Festival, Muri Okunola Park',
        '₦5,000',
        SceneKind.food,
      ),
      ('FRI 30 OCT', 'Art X Lagos opening night', '₦15,000', SceneKind.art),
    ];
    return CaboScaffold(
      title: 'Events',
      children: [
        CaboCard(
          color: CaboColors.yellowSoft,
          child: Row(
            children: [
              const Icon(Icons.new_releases_rounded, color: CaboColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ticketing is coming soon. For now, save events and book a ride there.',
                  style: CaboText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final (date, name, price, scene) in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CaboCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Scene(scene, height: 110, radius: 0),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: CaboText.label.copyWith(
                                  color: CaboColors.green,
                                ),
                              ),
                              Text(name, style: CaboText.h3),
                              Text('From $price', style: CaboText.muted),
                            ],
                          ),
                        ),
                        CaboButton(
                          'Ride there',
                          height: 40,
                          expand: false,
                          onPressed: () => go(context, '/choose-ride'),
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
