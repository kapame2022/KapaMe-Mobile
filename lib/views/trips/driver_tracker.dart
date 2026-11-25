import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/widgets/trip_route_map.dart';

class DriverTracker extends StatelessWidget {
  const DriverTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final trip = args is Trip ? args : null;
    final location = trip?.tripLocationInfo;
    return Scaffold(
      appBar: AppBar(title: const Text('Pick-up location')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TripRouteMap(
                location: location == null
                    ? null
                    : TripLocationInfo(
                        pickUpLatitude: location.pickUpLatitude,
                        pickUpLongitude: location.pickUpLongitude,
                      ),
              ),
            ),
            if (location?.pickUpAddress?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(location!.pickUpAddress!),
              ),
          ],
        ),
      ),
    );
  }
}
