import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/trip_services.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/trip_route_map.dart';

class TripPlacePicker extends StatefulWidget {
  const TripPlacePicker(
      {super.key, required this.destination, this.filter = false});

  final bool destination;
  final bool filter;

  @override
  State<TripPlacePicker> createState() => _TripPlacePickerState();
}

class _TripPlacePickerState extends State<TripPlacePicker> {
  final _services = TripServices();
  final _query = TextEditingController();
  Timer? _debounce;
  Future<List<dynamic>>? _suggestions;
  TripLocationInfo? _selected;
  bool _loadingPlace = false;
  String? _error;

  String get _label => widget.destination ? 'destination' : 'pick-up';

  @override
  void dispose() {
    _debounce?.cancel();
    _services.dio.close(force: true);
    _query.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    setState(() {
      _selected = null;
      _error = null;
      _suggestions = null;
    });
    if (value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _suggestions = _services.getSuggestions(value));
    });
  }

  Future<void> _choose(String id, String address) async {
    if (_loadingPlace) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingPlace = true;
      _error = null;
    });
    try {
      final location = await _services.getPlaceDetails(id);
      if (!mounted) return;
      _query.text = address;
      setState(() => _selected = widget.destination
          ? TripLocationInfo(
              destinationAddress: address,
              destinationLatitude: location.pickUpLatitude,
              destinationLongitude: location.pickUpLongitude)
          : TripLocationInfo(
              pickUpAddress: address,
              pickUpLatitude: location.pickUpLatitude,
              pickUpLongitude: location.pickUpLongitude));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t open this place. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loadingPlace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.filter ? 'Filter by $_label' : 'Choose $_label')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _query,
                enabled: !_loadingPlace,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search for a $_label',
                  hintText: 'Address, suburb or landmark',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _search,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_loadingPlace) const LinearProgressIndicator(),
            Expanded(
              child: selected != null
                  ? TripRouteMap(location: selected)
                  : FutureBuilder<List<dynamic>>(
                      future: _suggestions,
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (results.isEmpty ||
                            snapshot.hasError ||
                            _suggestions == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                  snapshot.hasError
                                      ? 'Couldn’t search places. Check your connection and try again.'
                                      : _suggestions == null
                                          ? 'Search for an address, suburb or landmark.'
                                          : 'No places found. Try another search.',
                                  textAlign: TextAlign.center),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final result = results[i] as Map;
                            final address = result['description'] as String;
                            return ListTile(
                              leading: const Icon(Icons.place_outlined,
                                  color: ClearBlue.accent),
                              title: Text(address),
                              onTap: _loadingPlace
                                  ? null
                                  : () => _choose(
                                      result['place_id'] as String, address),
                            );
                          },
                        );
                      },
                    ),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(
                      widget.filter ? 'Use this area' : 'Use this $_label'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
