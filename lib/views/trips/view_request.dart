import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/services/trip_services.dart';

class ViewRequest extends StatefulWidget {
  const ViewRequest({super.key});

  @override
  State<ViewRequest> createState() => _ViewRequestState();
}

class _ViewRequestState extends State<ViewRequest> {
  GoogleMapController? mapController;
  BannerAd? _bannerAd;
  bool isAdLoaded = false;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  Trip? currentTrip;

  Future<void> getRoutePolyline(
      double startLat, double startLng, double endLat, double endLng) async {
    TripServices tripServices = TripServices();
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=${tripServices.directionsApiKey}';

    final response = await Dio().get(url);
    print(response.data);
    final points = response.data['routes'][0]['overview_polyline']['points'];
    final polylinePoints = PolylinePoints().decodePolyline(points);

    setState(() {
      polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylinePoints
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList(),
        ),
      };
    });
  }

  @override
  void initState() {
    super.initState();
    loadAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (currentTrip == null) {
      currentTrip = ModalRoute.of(context)!.settings.arguments as Trip?;
      // Now you can safely use currentTrip and call getRoutePolyline here
      if (currentTrip != null) {
        final pickUpLat = double.tryParse(
            currentTrip!.tripLocationInfo?.pickUpLatitude ?? '');
        final pickUpLng = double.tryParse(
            currentTrip!.tripLocationInfo?.pickUpLongitude ?? '');
        final destLat = double.tryParse(
            currentTrip!.tripLocationInfo?.destinationLatitude ?? '');
        final destLng = double.tryParse(
            currentTrip!.tripLocationInfo?.destinationLongitude ?? '');
        if (pickUpLat != null &&
            pickUpLng != null &&
            destLat != null &&
            destLng != null) {
          getRoutePolyline(pickUpLat, pickUpLng, destLat, destLng);
        }
      }
    }
  }

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.groupTransporterAd,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          setState(() {
            isAdLoaded = false;
          });
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickUpLat =
        double.tryParse(currentTrip?.tripLocationInfo?.pickUpLatitude ?? '');
    final pickUpLng =
        double.tryParse(currentTrip?.tripLocationInfo?.pickUpLongitude ?? '');
    final destLat = double.tryParse(
        currentTrip?.tripLocationInfo?.destinationLatitude ?? '');
    final destLng = double.tryParse(
        currentTrip?.tripLocationInfo?.destinationLongitude ?? '');

    final List<Marker> tripMarkers = [];
    if (pickUpLat != null && pickUpLng != null) {
      tripMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickUpLat, pickUpLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    if (destLat != null && destLng != null) {
      tripMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destLat, destLng),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    }

    return Scaffold(
      body: currentTrip == null
          ? const Center(child: Text('No trip data'))
          : Stack(
              fit: StackFit.expand,
              children: [
                if (pickUpLat != null && pickUpLng != null)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(pickUpLat, pickUpLng),
                      zoom: 10,
                    ),
                    markers: Set<Marker>.of(tripMarkers),
                    polylines: polylines,
                    padding: const EdgeInsets.only(bottom: 92),
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    myLocationButtonEnabled: false,
                  )
                else
                  const Center(child: Text('No map location available.')),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: currentTrip,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 19, 161, 232),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Chat with requester'),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isAdLoaded && _bannerAd != null
          ? SafeArea(
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 10),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
