import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../widgets/widgets.dart';

// 5. Cabo Tours.

IconData _categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('island')) return Icons.sailing_rounded;
  if (n.contains('cultur')) return Icons.account_balance_rounded;
  if (n.contains('city')) return Icons.location_city_rounded;
  if (n.contains('night')) return Icons.nightlife_rounded;
  if (n.contains('nature')) return Icons.forest_rounded;
  if (n.contains('food')) return Icons.restaurant_rounded;
  return Icons.tour_rounded;
}

SceneKind _tourScene(Json tour) =>
    sceneFor('${tour.obj('category')?.str('name')} ${tour.str('title')}');

String _ratingLine(Json tour) => tour.numberOrNull('rating') == null
    ? 'New'
    : '★ ${tour.number('rating').toStringAsFixed(1)}';

/// What a booking ticket's QR code contains. The partner portal and the Host
/// app read the same format at check-in.
String ticketQr(Json booking) => 'cabo:ticket:${booking.str('qr_token')}';

void _openTour(BuildContext context, Json tour) {
  AppScope.read(context).select(tour: tour);
  go(context, '/tour-detail');
}

Future<void> _toggleSaved(BuildContext context, Json tour) => runAction(
  context,
  () => AppScope.read(context).toggleSaved('tour', tour.integer('id')),
);

class _ToursHome {
  _ToursHome(this.categories, this.featured, this.popular);
  final List<Json> categories;
  final List<Json> featured;
  final List<Json> popular;
}

class ToursHomeScreen extends StatelessWidget {
  const ToursHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final api = state.api;
    return Scaffold(
      body: SafeArea(
        child: Loader<_ToursHome>(
          load: () async {
            final results = await Future.wait([
              api.get('/tour-categories'),
              api.get('/tours', query: {'featured': 1}),
              api.get('/tours'),
            ]);
            state.loadWishlist().catchError((_) {});
            return _ToursHome(
              asJsonList(unwrap(results[0])),
              (results[1] as Json).list('data'),
              (results[2] as Json).list('data'),
            );
          },
          builder: (context, data, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text('Tours & Experiences', style: CaboText.h1),
                Text(
                  'Curated by trusted local guides',
                  style: CaboText.muted.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 14),
                SearchBox(
                  hint: 'Search tours',
                  onTap: () {
                    state.setTourFilters({});
                    go(context, '/tour-list');
                  },
                ),
                const SectionTitle('Categories'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    for (final c in data.categories)
                      CaboCard(
                        color: CaboColors.surface,
                        onTap: () {
                          state.setTourFilters({
                            'category': c.str('slug'),
                            'category_name': c.str('name'),
                          });
                          go(context, '/tour-list');
                        },
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _categoryIcon(c.str('name')),
                              color: CaboColors.green,
                              size: 30,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.str('name'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CaboText.label.copyWith(
                                color: CaboColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SectionTitle(
                  'Featured',
                  action: 'See all',
                  onAction: () {
                    state.setTourFilters({});
                    go(context, '/tour-list');
                  },
                ),
                if (data.featured.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openTour(context, data.featured.first),
                    child: Stack(
                      children: [
                        NetPhoto(
                          state.imageUrl(data.featured.first),
                          fallback: _tourScene(data.featured.first),
                          height: 180,
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.featured.first.str('title'),
                                        style: CaboText.h3,
                                      ),
                                      Text(
                                        '${fmtDuration(data.featured.first.integer('duration_minutes'))} • '
                                        '${_ratingLine(data.featured.first)} • from ${naira(data.featured.first.integer('price'))}',
                                        style: CaboText.muted,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: CaboColors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SectionTitle('Popular this week'),
                if (data.popular.isEmpty)
                  const EmptyNotice(
                    'No tours are available yet.',
                    icon: Icons.tour_rounded,
                  ),
                for (final t in data.popular.take(3))
                  TourTile(
                    t,
                    saved: state.isSaved('tour', t.integer('id')),
                    onSave: () => _toggleSaved(context, t),
                    onTap: () => _openTour(context, t),
                  ),
                CaboCard(
                  color: CaboColors.surface,
                  onTap: () => go(context, '/private-tour'),
                  child: Row(
                    children: [
                      const IconBadge(Icons.lock_person_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Want a private tour?', style: CaboText.h3),
                            Text(
                              'Tell us what you would like and get a quote.',
                              style: CaboText.muted,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: CaboColors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const RiderNav(2),
    );
  }
}

/// The coming Saturday (or today, on a Saturday), as YYYY-MM-DD.
String _thisSaturday() {
  final now = DateTime.now();
  final d = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
  return _ymd(d);
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TourListScreen extends StatelessWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final f = state.tourFilters;
    final quick = f['quick'] as int? ?? 0;
    final query = {
      'category': f['category'],
      'max_price': f['max_price'],
      'date': f['date'],
      'sort': f['sort'],
      'q': f['q'],
      if (f['wheelchair'] == true) 'wheelchair': 1,
    };
    return CaboScaffold(
      title: f.strOrNull('category_name') ?? 'All tours',
      actions: [
        IconButton(
          tooltip: 'Filters',
          icon: const Icon(Icons.tune_rounded, color: CaboColors.green),
          onPressed: () => go(context, '/tour-filters'),
        ),
      ],
      children: [
        TextField(
          onSubmitted: (q) => state.setTourFilters({
            ...f,
            'q': q.trim().isEmpty ? null : q.trim(),
          }),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search tours',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: CaboColors.muted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ChipPicker(
          key: ValueKey('quick-$quick'),
          options: [
            'All',
            'Under ${naira(20000)}',
            'This weekend',
            'Accessible',
          ],
          initial: {quick},
          single: true,
          onChanged: (s) {
            final keep = {
              'category': f['category'],
              'category_name': f['category_name'],
              'q': f['q'],
            };
            state.setTourFilters({
              ...keep,
              'quick': s.first,
              if (s.first == 1) 'max_price': 20000,
              if (s.first == 2) 'date': _thisSaturday(),
              if (s.first == 3) 'wheelchair': true,
            });
          },
        ),
        const SizedBox(height: 14),
        Loader<List<Json>>(
          key: ValueKey('$query'),
          load: () async {
            state.loadWishlist().catchError((_) {});
            return (await state.api.get('/tours', query: query) as Json).list(
              'data',
            );
          },
          builder: (context, tours, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${plural(tours.length, 'tour')} in Lagos',
                style: CaboText.label,
              ),
              const SizedBox(height: 10),
              if (tours.isEmpty)
                EmptyNotice(
                  'No tours match these filters.',
                  icon: Icons.search_off_rounded,
                  action: 'Clear filters',
                  onAction: () => state.setTourFilters({}),
                ),
              for (final t in tours)
                TourTile(
                  t,
                  saved: state.isSaved('tour', t.integer('id')),
                  onSave: () => _toggleSaved(context, t),
                  onTap: () => _openTour(context, t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class TourFiltersScreen extends StatefulWidget {
  const TourFiltersScreen({super.key});

  @override
  State<TourFiltersScreen> createState() => _TourFiltersScreenState();
}

class _TourFiltersScreenState extends State<TourFiltersScreen> {
  static const _sorts = [
    ('popular', 'Most popular'),
    ('rating', 'Top rated'),
    ('price_low', 'Lowest price'),
    ('price_high', 'Highest price'),
  ];
  double _maxPrice = 60000;
  int _date = 0;
  int _sort = 0;
  bool _wheelchair = false;
  String? _category;
  String? _categoryName;
  bool _started = false;
  int _reset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final f = AppScope.read(context).tourFilters;
    _maxPrice = (f['max_price'] as num?)?.toDouble() ?? 60000;
    _wheelchair = f['wheelchair'] == true;
    _category = f.strOrNull('category');
    _categoryName = f.strOrNull('category_name');
    _sort = _sorts.indexWhere((s) => s.$1 == f['sort']).clamp(0, 3);
    _date = f['date_choice'] as int? ?? 0;
  }

  void _apply() {
    final now = DateTime.now();
    AppScope.read(context).setTourFilters({
      if (_category != null) 'category': _category,
      if (_categoryName != null) 'category_name': _categoryName,
      if (_maxPrice < 60000) 'max_price': _maxPrice.round(),
      if (_date == 1) 'date': _ymd(now),
      if (_date == 2) 'date': _ymd(now.add(const Duration(days: 1))),
      if (_date == 3) 'date': _thisSaturday(),
      'date_choice': _date,
      if (_sort > 0) 'sort': _sorts[_sort].$1,
      if (_wheelchair) 'wheelchair': true,
    });
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.read(context).api;
    return CaboScaffold(
      title: 'Filters',
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _maxPrice = 60000;
            _date = 0;
            _sort = 0;
            _wheelchair = false;
            _category = null;
            _categoryName = null;
            _reset++;
          }),
          child: Text(
            'Reset',
            style: CaboText.label.copyWith(color: CaboColors.green),
          ),
        ),
      ],
      bottom: CaboButton('Show tours', onPressed: _apply),
      children: [
        const SectionTitle('Price per person'),
        Text(
          _maxPrice >= 60000
              ? 'Any price'
              : 'Up to ${naira(_maxPrice.round())}',
          style: CaboText.h3,
        ),
        Slider(
          value: _maxPrice,
          min: 5000,
          max: 60000,
          divisions: 11,
          label: naira(_maxPrice.round()),
          onChanged: (v) => setState(() => _maxPrice = v),
        ),
        const SectionTitle('Category'),
        Loader<List<Json>>(
          padding: const EdgeInsets.all(8),
          load: () async =>
              asJsonList(unwrap(await api.get('/tour-categories'))),
          builder: (context, categories, _) => ChipPicker(
            key: ValueKey('cat-$_reset'),
            single: true,
            options: ['Any', for (final c in categories) c.str('name')],
            initial: {
              categories.indexWhere((c) => c.str('slug') == _category) + 1,
            },
            onChanged: (s) {
              final c = s.first == 0 ? null : categories[s.first - 1];
              _category = c?.str('slug');
              _categoryName = c?.str('name');
            },
          ),
        ),
        const SectionTitle('Date'),
        ChipPicker(
          key: ValueKey('date-$_reset'),
          options: const ['Any day', 'Today', 'Tomorrow', 'This weekend'],
          initial: {_date},
          single: true,
          onChanged: (s) => _date = s.first,
        ),
        const SectionTitle('Sort by'),
        ChipPicker(
          key: ValueKey('sort-$_reset'),
          options: [for (final s in _sorts) s.$2],
          initial: {_sort},
          single: true,
          onChanged: (s) => _sort = s.first,
        ),
        const SizedBox(height: 10),
        ToggleTile(
          'Wheelchair accessible',
          key: ValueKey('wc-$_reset'),
          subtitle: 'Only show tours marked as accessible',
          initial: _wheelchair,
          onChanged: (v) => _wheelchair = v,
        ),
      ],
    );
  }
}

/// Loads the full tour (with reviews) for the selected tour, or the first
/// tour when a screen is opened without a selection.
Future<Json> _loadTour(AppState state) async {
  var slug = state.tour?.strOrNull('slug');
  if (slug == null) {
    final tours = (await state.api.get('/tours') as Json).list('data');
    if (tours.isEmpty) throw ApiException('No tours are available yet.');
    slug = tours.first.str('slug');
  }
  if (state.tour != null &&
      state.tour!.containsKey('reviews') &&
      state.tour!.str('slug') == slug)
    return state.tour!;
  final tour = unwrap(await state.api.get('/tours/$slug')) as Json;
  state.select(tour: tour);
  return tour;
}

/// Wraps a tour screen: loads the tour, then builds with it.
class _TourLoader extends StatelessWidget {
  const _TourLoader({required this.title, required this.builder});
  final String title;
  final Widget Function(BuildContext context, Json tour) builder;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ready = state.tour != null && state.tour!.containsKey('reviews');
    if (ready) return builder(context, state.tour!);
    return Scaffold(
      appBar: caboAppBar(context, title),
      body: Loader<Json>(
        load: () => _loadTour(state),
        builder: (context, tour, _) => builder(context, tour),
      ),
    );
  }
}

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Book a Tour',
      builder: (context, tour) {
        final state = AppScope.of(context);
        final saved = state.isSaved('tour', tour.integer('id'));
        final reviews = tour.list('reviews');
        final price = tour.integer('price');
        final home = state.homePrice(price);
        return Scaffold(
          appBar: caboAppBar(context, 'Book a Tour'),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Stack(
                children: [
                  NetPhoto(
                    state.imageUrl(tour),
                    fallback: _tourScene(tour),
                    height: 200,
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        tooltip: saved
                            ? 'Remove from wishlist'
                            : 'Save to wishlist',
                        icon: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: CaboColors.red,
                          size: 20,
                        ),
                        onPressed: () => _toggleSaved(context, tour),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tour.str('title'), style: CaboText.h1),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => go(context, '/tour-reviews'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: CaboColors.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tour.numberOrNull('rating') == null
                          ? 'New'
                          : tour.number('rating').toStringAsFixed(1),
                      style: CaboText.h3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${compact(tour.integer('reviews_count'))} reviews)',
                      style: CaboText.muted,
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        'by ${tour.obj('partner')?.str('name') ?? 'Cabo'}',
                        overflow: TextOverflow.ellipsis,
                        style: CaboText.label,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FactRow([
                (
                  Icons.schedule_rounded,
                  'Duration',
                  fmtDuration(tour.integer('duration_minutes')),
                ),
                (Icons.place_rounded, 'Location', tour.str('area')),
                (
                  Icons.groups_rounded,
                  'Group Size',
                  '${tour.integer('min_group_size', 1)} – ${tour.integer('max_group_size')}',
                ),
              ]),
              const SectionTitle('Description'),
              Text(tour.str('description'), style: CaboText.body),
              const SizedBox(height: 14),
              MenuTile(
                icon: Icons.route_rounded,
                title: 'Itinerary and what is included',
                subtitle:
                    '${plural(tour.strings('itinerary').length, 'stop')} • ${tour.strings('inclusions').take(2).join(', ')}',
                onTap: () => go(context, '/tour-itinerary'),
              ),
              MenuTile(
                icon: Icons.reviews_rounded,
                title: 'Reviews',
                subtitle:
                    reviews.isEmpty ||
                        reviews.first.strOrNull('comment') == null
                    ? 'See what other guests said'
                    : '"${reviews.first.str('comment')}"',
                onTap: () => go(context, '/tour-reviews'),
              ),
              MenuTile(
                icon: Icons.event_busy_rounded,
                title: 'Cancellation',
                subtitle: tour.str(
                  'cancellation_policy',
                  'Free cancellation up to 24 hours before the start.',
                ),
              ),
              if (tour.flag('wheelchair_accessible'))
                const MenuTile(
                  icon: Icons.accessible_rounded,
                  title: 'Wheelchair accessible',
                ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      naira(price),
                      style: CaboText.h2.copyWith(color: CaboColors.green),
                    ),
                    Text(
                      home.isEmpty ? 'per person' : 'per person • $home',
                      style: CaboText.label,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CaboButton(
                    'Book Now',
                    onPressed: () => go(context, '/tour-date'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TourItineraryScreen extends StatelessWidget {
  const TourItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Itinerary',
      builder: (context, tour) {
        final stops = tour.strings('itinerary');
        return CaboScaffold(
          title: 'Itinerary',
          children: [
            Text(
              'Meet at ${tour.str('meeting_point')}',
              style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            for (final (i, stop) in stops.indexed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${i + 1}', style: CaboText.label),
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 14,
                        color: CaboColors.green,
                      ),
                      if (i < stops.length - 1)
                        Container(width: 2, height: 34, color: CaboColors.line),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stop,
                      style: CaboText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            const SectionTitle('Included'),
            for (final item in tour.strings('inclusions')) CheckRow(item),
            if (tour.strings('exclusions').isNotEmpty) ...[
              const SectionTitle('Not included'),
              for (final item in tour.strings('exclusions'))
                CheckRow(item, done: false),
            ],
            const SectionTitle('Run by'),
            CaboCard(
              child: Row(
                children: [
                  Avatar(
                    initials(tour.obj('partner')?.str('name')),
                    size: 52,
                    color: CaboColors.greenSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour.obj('partner')?.str('name') ?? 'Cabo',
                          style: CaboText.h3,
                        ),
                        Text(
                          'Vetted Cabo partner${tour.strings('languages').isEmpty ? '' : ' • ${tour.strings('languages').join(', ')}'}',
                          style: CaboText.muted,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: CaboColors.green),
                ],
              ),
            ),
            const SectionTitle('Cancellation policy'),
            Text(
              tour.str(
                'cancellation_policy',
                'Free cancellation up to 24 hours before the start.',
              ),
              style: CaboText.body,
            ),
          ],
        );
      },
    );
  }
}

class TourReviewsScreen extends StatelessWidget {
  const TourReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Reviews',
      builder: (context, tour) {
        final reviews = tour.list('reviews');
        final rating = tour.numberOrNull('rating');
        return CaboScaffold(
          title: 'Reviews',
          children: [
            CaboCard(
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        rating?.toStringAsFixed(1) ?? '–',
                        style: CaboText.display,
                      ),
                      if (rating != null) Stars(rating),
                      Text(
                        plural(tour.integer('reviews_count'), 'review'),
                        style: CaboText.label,
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        for (var s = 5; s >= 1; s--)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  child: Text('$s', style: CaboText.label),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Bar(
                                    reviews.isEmpty
                                        ? 0
                                        : reviews
                                                  .where(
                                                    (r) =>
                                                        r.integer('rating') ==
                                                        s,
                                                  )
                                                  .length /
                                              reviews.length,
                                    color: CaboColors.yellow,
                                    height: 7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (reviews.isEmpty)
              const EmptyNotice(
                'No written reviews yet. Guests can review after they check in.',
                icon: Icons.reviews_rounded,
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Latest ${plural(reviews.length, 'review')}',
                  style: CaboText.label,
                ),
              ),
            for (final r in reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CaboCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Avatar(
                            initials(r.obj('rider')?.str('first_name')),
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.obj('rider')?.str('first_name', 'Guest') ??
                                      'Guest',
                                  style: CaboText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [
                                    ?r.obj('rider')?.strOrNull('nationality'),
                                    timeAgo(r.date('created_at')),
                                  ].join(' • '),
                                  style: CaboText.label,
                                ),
                              ],
                            ),
                          ),
                          Stars(r.number('rating'), size: 15),
                        ],
                      ),
                      if (r.strOrNull('comment') != null) ...[
                        const SizedBox(height: 8),
                        Text(r.str('comment'), style: CaboText.body),
                      ],
                      const SizedBox(height: 4),
                      const Pill(
                        'Verified booking',
                        icon: Icons.verified_rounded,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TourDateScreen extends StatefulWidget {
  const TourDateScreen({super.key});

  @override
  State<TourDateScreen> createState() => _TourDateScreenState();
}

class _TourDateScreenState extends State<TourDateScreen> {
  String? _day;

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Date and guests',
      builder: (context, tour) {
        final state = AppScope.of(context);
        return Loader<List<Json>>(
          load: () async => asJsonList(
            unwrap(await state.api.get('/tours/${tour.str('slug')}/slots')),
          ),
          builder: (context, slots, _) {
            // Group the next 30 days of slots by local date.
            final byDay = <String, List<Json>>{};
            for (final s in slots) {
              byDay.putIfAbsent(_ymd(s.date('starts_at')!), () => []).add(s);
            }
            final days = byDay.keys.toList();
            final day = byDay.containsKey(_day)
                ? _day!
                : days.firstWhere(
                    (d) => byDay[d]!.any((s) => s.integer('remaining') > 0),
                    orElse: () => days.isEmpty ? '' : days.first,
                  );
            final slot = state.tourSlot;
            final remaining =
                slot?.integer('remaining') ??
                tour.integer('max_group_size', 10);
            final minGuests = tour.integer('min_group_size', 1);
            final total = tour.integer('price') * state.guests;
            return CaboScaffold(
              title: 'Date and guests',
              bottom: CaboButton(
                slot == null ? 'Choose a time' : 'Continue • ${naira(total)}',
                onPressed: slot == null
                    ? null
                    : () => go(context, '/tour-addons'),
              ),
              children: [
                Text(tour.str('title'), style: CaboText.h3),
                if (days.isEmpty)
                  const EmptyNotice(
                    'No dates are open for booking in the next 30 days.',
                    icon: Icons.event_busy_rounded,
                  ),
                if (days.isNotEmpty) ...[
                  const SectionTitle('Date'),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final left = byDay[days[i]]!.fold(
                          0,
                          (n, s) => n + s.integer('remaining'),
                        );
                        final date = byDay[days[i]]!.first.date('starts_at')!;
                        final soldOut = left == 0;
                        final sel = days[i] == day;
                        return GestureDetector(
                          onTap: soldOut
                              ? null
                              : () {
                                  setState(() => _day = days[i]);
                                  state.tourSlot = null;
                                  state.changed();
                                },
                          child: Opacity(
                            opacity: soldOut ? 0.4 : 1,
                            child: Container(
                              width: 62,
                              decoration: BoxDecoration(
                                color: sel
                                    ? CaboColors.green
                                    : CaboColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekdayShort(date),
                                    style: CaboText.label.copyWith(
                                      color: sel
                                          ? Colors.white70
                                          : CaboColors.muted,
                                    ),
                                  ),
                                  Text(
                                    '${date.day}',
                                    style: CaboText.h2.copyWith(
                                      color: sel
                                          ? Colors.white
                                          : CaboColors.ink,
                                    ),
                                  ),
                                  Text(
                                    soldOut ? 'Full' : '$left left',
                                    style: CaboText.label.copyWith(
                                      fontSize: 10,
                                      color: sel
                                          ? Colors.white70
                                          : CaboColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SectionTitle(
                    'Time on ${fmtDay(byDay[day]!.first.date('starts_at'))}',
                  ),
                  for (final s in byDay[day]!)
                    Opacity(
                      opacity: s.integer('remaining') == 0 ? 0.45 : 1,
                      child: SelectTile(
                        icon: Icons.schedule_rounded,
                        title: fmtTime(s.date('starts_at')),
                        subtitle: s.integer('remaining') == 0
                            ? 'Sold out'
                            : '${plural(s.integer('remaining'), 'spot')} left',
                        selected: slot?.integer('id') == s.integer('id'),
                        onTap: s.integer('remaining') == 0
                            ? () {}
                            : () {
                                state.tourSlot = s;
                                state.guests = state.guests
                                    .clamp(minGuests, s.integer('remaining'))
                                    .toInt();
                                state.changed();
                              },
                      ),
                    ),
                  const SectionTitle('Guests'),
                  CaboCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plural(state.guests, 'guest'),
                                style: CaboText.h3,
                              ),
                              Text(
                                '${naira(tour.integer('price'))} each',
                                style: CaboText.muted,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fewer guests',
                          onPressed: state.guests > minGuests
                              ? () {
                                  state.guests--;
                                  state.changed();
                                }
                              : null,
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: CaboColors.green,
                          ),
                        ),
                        Text('${state.guests}', style: CaboText.h2),
                        IconButton(
                          tooltip: 'More guests',
                          onPressed: state.guests < remaining
                              ? () {
                                  state.guests++;
                                  state.changed();
                                }
                              : null,
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: CaboColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (minGuests > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'This tour needs at least $minGuests guests.',
                        style: CaboText.muted,
                      ),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class TourAddonsScreen extends StatelessWidget {
  const TourAddonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Add-ons',
      builder: (context, tour) {
        final state = AppScope.of(context);
        final ridePrice =
            state.config.obj('tours')?.integer('ride_addon_price', 4000) ??
            4000;
        Widget box(bool on) => Icon(
          on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
          color: on ? CaboColors.green : CaboColors.muted,
        );
        return CaboScaffold(
          title: 'Add-ons',
          bottom: CaboButton(
            'Continue to payment • ${naira(state.tourTotal)}',
            onPressed: () => go(context, '/tour-checkout'),
          ),
          children: [
            CaboCard(
              color: state.includeRide ? CaboColors.greenSoft : Colors.white,
              borderColor: state.includeRide ? CaboColors.green : null,
              onTap: () {
                state.includeRide = !state.includeRide;
                state.changed();
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(Icons.local_taxi_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cabo ride to the meeting point',
                          style: CaboText.h3,
                        ),
                        Text(
                          'Cabo arranges a ride to ${tour.str('meeting_point')} in time for your tour.',
                          style: CaboText.muted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+ ${naira(ridePrice)}',
                          style: CaboText.h3.copyWith(color: CaboColors.green),
                        ),
                      ],
                    ),
                  ),
                  box(state.includeRide),
                ],
              ),
            ),
            if (tour.list('addons').isNotEmpty)
              SectionTitle(
                'From ${tour.obj('partner')?.str('name') ?? 'the guide'}',
              ),
            for (final a in tour.list('addons'))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CaboCard(
                  borderColor: state.addons.contains(a.str('code'))
                      ? CaboColors.green
                      : null,
                  onTap: () {
                    if (!state.addons.remove(a.str('code')))
                      state.addons.add(a.str('code'));
                    state.changed();
                  },
                  child: Row(
                    children: [
                      const IconBadge(
                        Icons.add_circle_rounded,
                        color: CaboColors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.str('name'), style: CaboText.h3),
                            Text(
                              '+ ${naira(a.integer('price'))}',
                              style: CaboText.label.copyWith(
                                color: CaboColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      box(state.addons.contains(a.str('code'))),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TourCheckoutScreen extends StatefulWidget {
  const TourCheckoutScreen({super.key});

  @override
  State<TourCheckoutScreen> createState() => _TourCheckoutScreenState();
}

class _TourCheckoutScreenState extends State<TourCheckoutScreen> {
  static const _methods = ['card', 'bank_transfer', 'wallet'];
  final _promo = TextEditingController();
  final _company = TextEditingController();
  int _method = 0;
  int _discount = 0;
  String? _promoMessage;
  bool _promoOk = false;

  @override
  void dispose() {
    _promo.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final state = AppScope.read(context);
    final code = _promo.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _discount = 0;
        _promoMessage = null;
        _promoOk = false;
        state.tourPromo = null;
      });
      return;
    }
    try {
      final res = await state.api.post('/rider/promo-codes/validate', {
        'code': code,
        'service': 'tour',
        'amount': state.tourTotal,
      }) as Json;
      setState(() {
        _discount = res.integer('discount');
        _promoMessage = res.str('description');
        _promoOk = true;
        state.tourPromo = code;
      });
    } on ApiException catch (e) {
      setState(() {
        _discount = 0;
        _promoMessage = e.data?.str('message') ?? e.message;
        _promoOk = false;
        state.tourPromo = null;
      });
    }
  }

  Future<void> _pay() async {
    final state = AppScope.read(context);
    final booking = unwrap(
      await state.api.post('/rider/tour-bookings', {
        'tour_id': state.tour!.integer('id'),
        'tour_slot_id': state.tourSlot!.integer('id'),
        'guests': state.guests,
        'addons': state.addons.toList(),
        'include_ride': state.includeRide,
        if (state.tourPromo != null) 'promo_code': state.tourPromo,
        'payment_method': _methods[_method],
        if (_company.text.trim().isNotEmpty)
          'company_name': _company.text.trim(),
      }),
    ) as Json;
    final method = _methods[_method];
    state.tourSlot = null;
    state.addons = {};
    state.includeRide = false;
    state.tourPromo = null;
    state.select(tourBooking: booking);
    state.refreshRider().catchError((_) {});
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      method == 'bank_transfer' ? '/bank-transfer' : '/tour-confirmed',
      (r) => r.settings.name == '/tours' || r.settings.name == '/home',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TourLoader(
      title: 'Checkout',
      builder: (context, tour) {
        final state = AppScope.of(context);
        final slot = state.tourSlot;
        if (slot == null) {
          return CaboScaffold(
            title: 'Checkout',
            children: [
              EmptyNotice(
                'Choose a date and time first.',
                icon: Icons.event_rounded,
                action: 'Choose a date',
                onAction: () => replace(context, '/tour-date'),
              ),
            ],
          );
        }
        final ridePrice =
            state.config.obj('tours')?.integer('ride_addon_price', 4000) ??
            4000;
        final total = state.tourTotal - _discount;
        final balance = state.rider?.integer('wallet_balance') ?? 0;
        return CaboScaffold(
          title: 'Checkout',
          bottom: ActionButton(
            'Pay ${naira(total)}',
            busyLabel: 'Booking…',
            onPressed: _pay,
          ),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: NetPhoto(
                    state.imageUrl(tour),
                    fallback: _tourScene(tour),
                    height: 72,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tour.str('title'), style: CaboText.h3),
                      Text(
                        '${fmtDayTime(slot.date('starts_at'))} • ${plural(state.guests, 'guest')}',
                        style: CaboText.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CaboCard(
              child: Column(
                children: [
                  InfoRow(
                    'Tour × ${state.guests}',
                    naira(tour.integer('price') * state.guests),
                  ),
                  for (final a in tour.list('addons'))
                    if (state.addons.contains(a.str('code')))
                      InfoRow(a.str('name'), naira(a.integer('price'))),
                  if (state.includeRide)
                    InfoRow('Cabo ride to meeting point', naira(ridePrice)),
                  if (_discount > 0)
                    InfoRow(
                      'Promo ${state.tourPromo}',
                      '− ${naira(_discount)}',
                      valueColor: CaboColors.green,
                    ),
                  const Divider(height: 20),
                  InfoRow('Total', naira(total), bold: true),
                  if (state.homePrice(total).isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        state.homePrice(total),
                        style: CaboText.label,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CaboField(
                    'Promo code',
                    controller: _promo,
                    hint: 'e.g. EKOTOURS',
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ActionButton(
                    'Apply',
                    height: 48,
                    expand: false,
                    style: CaboButtonStyle.secondary,
                    busyLabel: '…',
                    onPressed: _applyPromo,
                  ),
                ),
              ],
            ),
            if (_promoMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _promoMessage!,
                  style: CaboText.muted.copyWith(
                    color: _promoOk ? CaboColors.green : CaboColors.red,
                  ),
                ),
              ),
            const SectionTitle('Pay with'),
            SingleChoice(
              initial: _method,
              onChanged: (i) => _method = i,
              icons: const [
                Icons.credit_card_rounded,
                Icons.account_balance_rounded,
                Icons.account_balance_wallet_rounded,
              ],
              options: [
                ('Card', null),
                ('Bank transfer', 'Pay to a virtual account'),
                (
                  'Cabo Wallet',
                  'Balance ${naira(balance)}${balance < total ? ' • not enough' : ''}',
                ),
              ],
            ),
            CaboField(
              'Company name for invoice (optional)',
              controller: _company,
              hint: 'e.g. Bakare Consulting Ltd',
            ),
          ],
        );
      },
    );
  }
}

/// Loads the selected tour booking in full, or the next upcoming one when a
/// screen is opened without a selection.
Future<Json> _loadBooking(AppState state) async {
  var id = state.tourBooking?.integer('id');
  if (id == null || id == 0) {
    final list = (await state.api.get('/rider/tour-bookings') as Json).list(
      'data',
    );
    if (list.isEmpty) throw ApiException('You have no tour bookings yet.');
    final upcoming = list.where((b) => b.str('status') == 'confirmed');
    id = (upcoming.isEmpty ? list.first : upcoming.last).integer('id');
  }
  final booking =
      unwrap(await state.api.get('/rider/tour-bookings/$id')) as Json;
  state.tourBooking = booking;
  return booking;
}

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _loadBooking(state),
      builder: (context, b, _) => CaboScaffold(
        title: 'Bank transfer',
        bottom: CaboButton(
          'View booking',
          onPressed: () => replace(context, '/tour-confirmed'),
        ),
        children: [
          Text(
            'Amount for this booking',
            style: CaboText.muted.copyWith(fontSize: 15),
          ),
          Text(
            naira(b.integer('total')),
            style: CaboText.display.copyWith(color: CaboColors.green),
          ),
          const SizedBox(height: 18),
          CaboCard(
            child: Column(
              children: [
                InfoRow('Booking', b.str('reference')),
                InfoRow('Tour', b.obj('tour')?.str('title') ?? ''),
                InfoRow('When', fmtDayTime(b.obj('slot')?.date('starts_at'))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CaboCard(
            color: CaboColors.yellowSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: CaboColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your place is held under booking ${b.str('reference')}. Cabo\'s team will send you the '
                    'account details for your transfer. Quote the booking reference when you pay.',
                    style: CaboText.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TourConfirmedScreen extends StatelessWidget {
  const TourConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _loadBooking(state),
      builder: (context, b, _) => StateScreen(
        icon: Icons.confirmation_number_rounded,
        title: "You're going!",
        message:
            '${b.obj('tour')?.str('title')}, ${fmtDayTime(b.obj('slot')?.date('starts_at'))}.'
            '${b.integer('ride_addon_price') > 0 ? ' Your ride to the meeting point is included.' : ''}',
        primary: 'View ticket',
        onPrimary: () => replace(context, '/ticket'),
        secondary: 'Back to home',
        onSecondary: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (_) => false),
        extra: CaboCard(
          color: CaboColors.surface,
          child: Column(
            children: [
              InfoRow('Booking', b.str('reference')),
              InfoRow('Guests', '${b.integer('guests')}'),
              InfoRow(
                'Paid',
                '${naira(b.integer('total'))} • ${paymentLabels[b.str('payment_method')] ?? ''}',
              ),
              InfoRow(
                'Meeting point',
                b.obj('tour')?.str('meeting_point') ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Scaffold(
      backgroundColor: CaboColors.green,
      appBar: AppBar(
        backgroundColor: CaboColors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => back(context),
        ),
        title: Text(
          'Your ticket',
          style: CaboText.h3.copyWith(color: Colors.white),
        ),
      ),
      body: Loader<Json>(
        load: () => _loadBooking(state),
        builder: (context, b, _) {
          final status = b.str('status');
          final usable = status == 'confirmed';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      b.obj('tour')?.str('title') ?? '',
                      style: CaboText.h2,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      fmtDayTime(b.obj('slot')?.date('starts_at')),
                      style: CaboText.muted,
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: usable ? 1 : 0.25,
                      child: Semantics(
                        label: 'QR code for booking ${b.str('reference')}',
                        child: QrImageView(
                          data: ticketQr(b),
                          size: 210,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: CaboColors.ink,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: CaboColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      b.str('reference'),
                      style: CaboText.h3.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(switch (status) {
                      'confirmed' => 'Show this to your guide at check-in',
                      'checked_in' => 'Checked in. Enjoy your tour!',
                      'completed' => 'This tour is complete',
                      _ => 'This booking was cancelled',
                    }, style: CaboText.muted),
                    const Divider(height: 32),
                    InfoRow(
                      'Guests',
                      '${state.fullName.isEmpty ? 'You' : state.fullName}${b.integer('guests') > 1 ? ' + ${b.integer('guests') - 1}' : ''}',
                    ),
                    InfoRow(
                      'Meeting point',
                      b.obj('tour')?.str('meeting_point') ?? '',
                    ),
                    InfoRow('Paid', naira(b.integer('total'))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (usable)
                CaboButton(
                  'Cancel booking',
                  style: CaboButtonStyle.light,
                  onPressed: () => go(context, '/tour-cancel'),
                ),
              if ((status == 'checked_in' || status == 'completed') &&
                  b['review'] == null)
                CaboButton(
                  'Write a review',
                  style: CaboButtonStyle.light,
                  onPressed: () => go(context, '/write-review'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const _tags = [
    'Great guide',
    'Good value',
    'Well organised',
    'Safe',
    'Fun for groups',
  ];
  final _comment = TextEditingController();
  int stars = 5;
  Set<int> _picked = {};

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _loadBooking(state),
      builder: (context, b, _) {
        final checkedIn = b.date('checked_in_at');
        return CaboScaffold(
          title: 'Review your tour',
          bottom: ActionButton(
            'Post review',
            busyLabel: 'Posting…',
            enabled: checkedIn != null && b['review'] == null,
            onPressed: () async {
              await state.api.post(
                '/rider/tour-bookings/${b.integer('id')}/review',
                {
                  'rating': stars,
                  if (_comment.text.trim().isNotEmpty)
                    'comment': _comment.text.trim(),
                  'highlights': [
                    for (final i in _picked.toList()..sort()) _tags[i],
                  ],
                },
              );
              state.tourBooking = null;
              if (!context.mounted) return;
              showMessage(context, 'Thanks! Your review is posted.');
              back(context);
            },
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: checkedIn != null
                  ? Pill(
                      'Checked in ${fmtDay(checkedIn)}',
                      icon: Icons.verified_rounded,
                    )
                  : const Pill(
                      'Not checked in yet',
                      icon: Icons.schedule_rounded,
                      color: CaboColors.orange,
                    ),
            ),
            const SizedBox(height: 10),
            Text(b.obj('tour')?.str('title') ?? '', style: CaboText.h2),
            if (checkedIn == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You can review this tour after your guide checks you in.',
                  style: CaboText.muted,
                ),
              ),
            if (b['review'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You have already reviewed this tour.',
                  style: CaboText.muted,
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 42,
                    tooltip: '$i ${i == 1 ? 'star' : 'stars'}',
                    onPressed: () => setState(() => stars = i),
                    icon: Icon(
                      i <= stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: CaboColors.yellow,
                    ),
                  ),
              ],
            ),
            const SectionTitle('Highlights'),
            ChipPicker(options: _tags, onChanged: (s) => _picked = s),
            const SizedBox(height: 18),
            CaboField(
              'Your review',
              controller: _comment,
              hint: 'What should other guests know?',
              maxLines: 4,
            ),
          ],
        );
      },
    );
  }
}

class TourCancelScreen extends StatelessWidget {
  const TourCancelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final freeHours =
        state.config.obj('cancellation')?.integer('tour_free_hours', 24) ?? 24;
    return Loader<Json>(
      load: () => _loadBooking(state),
      builder: (context, b, reload) {
        final starts = b.obj('slot')?.date('starts_at') ?? DateTime.now();
        final hours = starts.difference(DateTime.now()).inMinutes / 60;
        final tier = hours >= freeHours
            ? 0
            : hours > 0
            ? 1
            : 2;
        final total = b.integer('total');
        final refund = [total, (total / 2).round(), 0][tier];
        final open = b.str('status') == 'confirmed';
        return CaboScaffold(
          title: 'Cancel booking',
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                refund > 0
                    ? 'Cancel and refund ${naira(refund)}'
                    : 'Cancel booking',
                style: CaboButtonStyle.danger,
                busyLabel: 'Cancelling…',
                enabled: open,
                onPressed: () async {
                  final res = await state.api.post(
                    '/rider/tour-bookings/${b.integer('id')}/cancel',
                  ) as Json;
                  state.refreshRider().catchError((_) {});
                  if (!context.mounted) return;
                  showMessage(
                    context,
                    res.integer('refund') > 0
                        ? 'Booking cancelled. ${naira(res.integer('refund'))} is being refunded.'
                        : 'Booking cancelled.',
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/bookings',
                    (r) => r.settings.name == '/home',
                  );
                },
              ),
              const SizedBox(height: 10),
              CaboButton(
                'Keep my booking',
                style: CaboButtonStyle.secondary,
                height: 48,
                onPressed: () => back(context),
              ),
            ],
          ),
          children: [
            CaboCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: NetPhoto(
                      state.imageUrl(b.obj('tour')),
                      fallback: sceneFor(b.obj('tour')?.str('title')),
                      height: 64,
                      radius: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.obj('tour')?.str('title') ?? '',
                          style: CaboText.h3,
                        ),
                        Text(
                          '${fmtDayTime(starts)} • ${plural(b.integer('guests'), 'guest')}',
                          style: CaboText.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!open)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'This booking is ${humanize(b.str('status')).toLowerCase()} and can no longer be cancelled.',
                  style: CaboText.muted,
                ),
              ),
            const SectionTitle('Refund policy'),
            for (final (i, (period, text)) in [
              ('More than $freeHours hours before', 'Full refund'),
              ('Less than $freeHours hours before', '50% refund'),
              ('After the start', 'No refund'),
            ].indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      i == tier
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: i == tier ? CaboColors.green : CaboColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(period, style: CaboText.body)),
                    Text(
                      text,
                      style: CaboText.label.copyWith(
                        color: i == tier ? CaboColors.green : CaboColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            CaboCard(
              color: CaboColors.greenSoft,
              child: Text(
                'Wallet payments are refunded to your wallet straight away. Card refunds take 3 – 5 working days. '
                'To change the date, cancel and book the new date.',
                style: CaboText.body.copyWith(fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PrivateTourScreen extends StatefulWidget {
  const PrivateTourScreen({super.key});

  @override
  State<PrivateTourScreen> createState() => _PrivateTourScreenState();
}

class _PrivateTourScreenState extends State<PrivateTourScreen> {
  static const _interests = [
    'History',
    'Art',
    'Food',
    'Beaches',
    'Nightlife',
    'Shopping',
    'Nature',
  ];
  final _guests = TextEditingController(text: '2');
  final _budget = TextEditingController();
  final _notes = TextEditingController();
  Set<int> _picked = {};
  DateTime? _date;
  String? _error;

  @override
  void dispose() {
    _guests.dispose();
    _budget.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_date == null || (int.tryParse(_guests.text.trim()) ?? 0) < 1) {
      setState(() => _error = 'Choose a date and the number of guests.');
      return;
    }
    setState(() => _error = null);
    final interests = [for (final i in _picked.toList()..sort()) _interests[i]];
    await AppScope.read(context).api.post('/rider/support/tickets', {
      'category': 'other',
      'subject': 'Private tour request for ${fmtDate(_date)}',
      'message': [
        'Private tour request',
        'Date: ${fmtDate(_date)}',
        'Guests: ${_guests.text.trim()}',
        if (interests.isNotEmpty) 'Interests: ${interests.join(', ')}',
        if (_budget.text.trim().isNotEmpty)
          'Budget per person: ${_budget.text.trim()}',
        if (_notes.text.trim().isNotEmpty) 'Notes: ${_notes.text.trim()}',
      ].join('\n'),
    });
    if (!mounted) return;
    showMessage(
      context,
      'Request sent. We will reply under Support tickets, usually within 24 hours.',
    );
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Request a private tour',
      bottom: ActionButton(
        'Send request',
        busyLabel: 'Sending…',
        onPressed: _send,
      ),
      children: [
        Text(
          'Tell us what you would like. Cabo\'s team asks local partners and replies with a quote, usually within 24 hours.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SectionTitle('Interests'),
        ChipPicker(options: _interests, onChanged: (s) => _picked = s),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CaboField(
                'Date',
                key: ValueKey(_date),
                value: _date == null ? null : fmtDay(_date),
                hint: 'Choose',
                icon: Icons.event_rounded,
                readOnly: true,
                error: _error,
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date ?? now.add(const Duration(days: 2)),
                    firstDate: now.add(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 180)),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CaboField(
                'Guests',
                controller: _guests,
                icon: Icons.groups_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        CaboField(
          'Budget per person (optional)',
          controller: _budget,
          hint: 'e.g. ₦40,000 – ₦60,000',
          icon: Icons.payments_outlined,
        ),
        CaboField(
          'Anything else? (optional)',
          controller: _notes,
          hint: 'Occasion, accessibility needs, places you want to see',
          maxLines: 3,
        ),
      ],
    );
  }
}
