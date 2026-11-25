import 'package:kapame/widgets/trip_route_map.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_request_filter.dart';
import 'package:provider/provider.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:kapame/widgets/journey_place_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:location/location.dart';

class PrivateDriver extends StatefulWidget {
  const PrivateDriver({super.key});

  @override
  State<PrivateDriver> createState() => _PrivateDriverState();
}

class _PrivateDriverState extends State<PrivateDriver> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController pickUpController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  bool isLoading = false;
  Set<Marker> markers = {};
  List<Trip> allTrips = [];

  String? pickUpLat;
  String? pickUpLong;
  String? destLat;
  String? destLong;

  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.privateDriverAd,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
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
  void initState() {
    super.initState();
    _getLocation();
    _getTrips();
    loadAd();
  }

  @override
  void dispose() {
    pickUpController.dispose();
    destinationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    if (!mounted) return;
    setState(() {
      currentLocation = locationData;
    });
  }

  Future<void> _getTrips() async {
    try {
      Dio dio = Dio();
      final res =
          await dio.get('https://kapameapi.azurewebsites.net/api/trips');
      print('Response Status Code: ${res.statusCode}');
      if (res.statusCode == 200) {
        final List<dynamic> tripsJson = res.data;
        final trips = tripsJson.map((json) => Trip.fromMap(json)).toList();
        if (!mounted) return;
        allTrips = filterTripRequests(
          trips,
          tripType: 'Private Commute',
          auth: context.read<AuthUserState>(),
        );

        _createMarkers(allTrips);
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      print('Error fetching trips: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      isLoading = true;
    });

    List<Trip> filteredTrips = _filterTrips(
      pickUp: pickUpController.text,
      destination: destinationController.text,
    );

    _createMarkers(filteredTrips);

    setState(() {
      isLoading = false;
    });
    Navigator.pop(context); // Close the bottom sheet
  }

  List<Trip> _filterTrips({
    String? pickUp,
    String? destination,
  }) {
    return allTrips.where((trip) {
      bool matchesPickUp = pickUp == null ||
          pickUp.isEmpty ||
          trip.tripLocationInfo?.pickUpAddress
                  ?.toLowerCase()
                  .contains(pickUp.toLowerCase()) ==
              true;

      bool matchesDestination = destination == null ||
          destination.isEmpty ||
          trip.tripLocationInfo?.destinationAddress
                  ?.toLowerCase()
                  .contains(destination.toLowerCase()) ==
              true;

      return matchesPickUp && matchesDestination;
    }).toList();
  }

  double _getTripPriority(String? tripPriority) {
    if (tripPriority == "Low") {
      return BitmapDescriptor.hueGreen;
    } else if (tripPriority == "Important") {
      return BitmapDescriptor.hueOrange;
    } else {
      return BitmapDescriptor.hueRed;
    }
  }

  Trip? _selectedTrip;

  void _createMarkers(List<Trip> trips) {
    setState(() {
      _selectedTrip = null;
      markers.clear();
      for (final trip in trips) {
        final location = trip.tripLocationInfo;
        final position = tripCoordinates(
                location?.pickUpLatitude, location?.pickUpLongitude) ??
            tripCoordinates(
                location?.destinationLatitude, location?.destinationLongitude);
        final id = trip.tripId;
        if (position == null || id == null || id.isEmpty) continue;
        markers.add(Marker(
          markerId: MarkerId(id),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              _getTripPriority(trip.tripPriority)),
          position: position,
          consumeTapEvents: true,
          onTap: () => setState(() => _selectedTrip = trip),
        ));
      }
    });
  }

  Future<void> _choosePickup() async {
    final result =
        await Navigator.pushNamed<TripLocationInfo>(context, '/filterpickup');
    if (!mounted || result == null) return;
    setState(() {
      pickUpController.text = result.pickUpAddress ?? '';
      pickUpLat = result.pickUpLatitude;
      pickUpLong = result.pickUpLongitude;
    });
  }

  Future<void> _chooseDestination() async {
    final result = await Navigator.pushNamed<TripLocationInfo>(
        context, '/filterdestination');
    if (!mounted || result == null) return;
    setState(() {
      destinationController.text = result.destinationAddress ?? '';
      destLat = result.destinationLatitude;
      destLong = result.destinationLongitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Private driver')),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: currentLocation == null
                    ? const Center(child: Text('Waiting for your location…'))
                    : Stack(fit: StackFit.expand, children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(currentLocation!.latitude!,
                                currentLocation!.longitude!),
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            mapController = controller;
                          },
                          markers: markers,
                          onTap: (_) => setState(() => _selectedTrip = null),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ])),
            MapActionPanel(
              title: 'Nearby requests',
              subtitle: _selectedTrip == null
                  ? 'Select a map pin to view a request.'
                  : null,
              locations: [
                if (_selectedTrip case final trip?) ...[
                  if (trip.requesterName?.trim().isNotEmpty == true)
                    Text(trip.requesterName!, style: ClearBlue.label),
                  RouteSummary(location: trip.tripLocationInfo),
                  if (trip.contactDetailsPhoneNumber?.trim().isNotEmpty == true)
                    Text('Requester phone: ${trip.contactDetailsPhoneNumber}'),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/viewrequest',
                        arguments: trip),
                    child: const Text('View request'),
                  ),
                ],
              ],
              action: 'Filter requests',
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (BuildContext context) {
                    return FractionallySizedBox(
                        heightFactor: 0.85,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.viewInsetsOf(context).bottom),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            child: Column(
                              children: [
                                const Text(
                                  'Filter by route',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      JourneyPlaceButton(
                                          label: 'Pick-up area',
                                          address: pickUpController,
                                          onPressed: _choosePickup),
                                      const SizedBox(height: 10),
                                      // Destination button
                                      JourneyPlaceButton(
                                          label: 'Destination area',
                                          address: destinationController,
                                          onPressed: _chooseDestination),
                                      const SizedBox(height: 40),
                                      FilledButton(
                                        onPressed: _applyFilters,
                                        style: const ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                            ),
                                          ),
                                          minimumSize: WidgetStatePropertyAll(
                                              Size(double.infinity, 60)),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  ClearBlue.accent),
                                        ),
                                        child: isLoading
                                            ? const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              )
                                            : const Text("Update filters"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                );
              },
            ),
          ])),
      bottomNavigationBar: isAdLoaded && _bannerAd != null
          ? SafeArea(
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
