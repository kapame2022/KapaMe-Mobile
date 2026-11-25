import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:kapame/services/trip_services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/theme/clear_blue.dart';

LatLng? tripCoordinates(String? latitude, String? longitude) {
  final lat = double.tryParse(latitude ?? '');
  final lng = double.tryParse(longitude ?? '');
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat.abs() > 90 ||
      lng.abs() > 180) {
    return null;
  }
  return LatLng(lat, lng);
}

class TripRouteMap extends StatefulWidget {
  const TripRouteMap({super.key, required this.location});

  final TripLocationInfo? location;

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  final _services = TripServices();
  List<LatLng> _route = const [];
  int _request = 0;

  LatLng? get _pickup => tripCoordinates(
      widget.location?.pickUpLatitude, widget.location?.pickUpLongitude);
  LatLng? get _destination => tripCoordinates(
      widget.location?.destinationLatitude,
      widget.location?.destinationLongitude);

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  @override
  void didUpdateWidget(TripRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _loadDirections();
  }

  Future<void> _loadDirections() async {
    final request = ++_request;
    final pickup = _pickup;
    final destination = _destination;
    _route = const [];
    if (pickup == null || destination == null || pickup == destination) return;
    try {
      final response = await _services.dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${pickup.latitude},${pickup.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _services.directionsApiKey,
        },
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      final routes = response.data?['routes'];
      if (routes is! List || routes.isEmpty) return;
      final points =
          (routes.first as Map)['overview_polyline']['points'] as String;
      if (!mounted || request != _request) return;
      final route = PolylinePoints()
          .decodePolyline(points)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      setState(() => _route = route);
    } catch (_) {
      // Location markers still show when directions are unavailable.
    }
  }

  @override
  void dispose() {
    _services.dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup;
    final destination = _destination;
    final start = pickup ?? destination;
    if (start == null) {
      return const ColoredBox(
        color: ClearBlue.soft,
        child: Center(child: Text('Map location unavailable')),
      );
    }
    return GoogleMap(
      key: ValueKey((pickup, destination)),
      initialCameraPosition: CameraPosition(target: start, zoom: 14),
      markers: {
        if (pickup != null)
          Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              infoWindow: const InfoWindow(title: 'Pick-up')),
        if (destination != null)
          Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              infoWindow: const InfoWindow(title: 'Destination')),
      },
      polylines: {
        if (_route.isNotEmpty)
          Polyline(
              polylineId: const PolylineId('route'),
              points: _route,
              color: ClearBlue.accent,
              width: 5),
      },
      onMapCreated: (controller) async {
        if (pickup == null || destination == null || pickup == destination) {
          return;
        }
        final south = pickup.latitude < destination.latitude
            ? pickup.latitude
            : destination.latitude;
        final north = pickup.latitude > destination.latitude
            ? pickup.latitude
            : destination.latitude;
        final west = pickup.longitude < destination.longitude
            ? pickup.longitude
            : destination.longitude;
        final east = pickup.longitude > destination.longitude
            ? pickup.longitude
            : destination.longitude;
        try {
          await controller.animateCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east)),
              32));
        } catch (_) {
          // Keep the initial camera if the native map is not ready or was closed.
        }
      },
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
