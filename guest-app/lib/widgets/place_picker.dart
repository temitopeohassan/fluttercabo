import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import 'common.dart';
import 'live.dart';
import '../state/app_state.dart';

/// Opens a searchable sheet of places and returns the one chosen.
Future<Json?> pickPlace(
  BuildContext context, {
  required String title,
  bool allowCurrent = true,
}) {
  return showModalBottomSheet<Json>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PlaceSheet(
      title: title,
      allowCurrent: allowCurrent,
      state: AppScope.read(context),
    ),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({
    required this.title,
    required this.allowCurrent,
    required this.state,
  });
  final String title;
  final bool allowCurrent;
  final AppState state;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Json> _results = [];
  String? _error;
  int _search = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final run = ++_search;
    try {
      final list = await widget.state.searchPlaces(_query.text.trim());
      if (mounted && run == _search) {
        setState(() {
          _results = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && run == _search) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text(widget.title, style: CaboText.h2),
              const SizedBox(height: 10),
              TextField(
                controller: _query,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), _run);
                },
                decoration: const InputDecoration(
                  hintText: 'Search hotels, landmarks and areas',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: CaboColors.muted,
                  ),
                ),
              ),
              if (widget.allowCurrent)
                MenuTile(
                  icon: Icons.my_location_rounded,
                  title: 'Use my current location',
                  onTap: () async {
                    try {
                      final place = await widget.state.currentPlace();
                      if (context.mounted) Navigator.of(context).pop(place);
                    } catch (e) {
                      if (context.mounted)
                        showMessage(context, errorText(e), error: true);
                    }
                  },
                ),
              if (_error != null)
                ErrorNotice(
                  _error!,
                  onRetry: _run,
                  padding: const EdgeInsets.all(12),
                ),
              if (_error == null && _results.isEmpty)
                const EmptyNotice(
                  'No places match. Try a landmark or an area.',
                  icon: Icons.search_off_rounded,
                ),
              for (final p in _results.take(15))
                MenuTile(
                  icon: p.str('kind') == 'airport'
                      ? Icons.flight_rounded
                      : Icons.place_rounded,
                  title: p.str('name'),
                  subtitle: p.str('address'),
                  onTap: () => Navigator.of(context).pop(p),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
