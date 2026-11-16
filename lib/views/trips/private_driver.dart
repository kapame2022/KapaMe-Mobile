import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:kapame/widgets/location_address_text.dart';
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
    pickUpController.text = 'Pick Up';
    destinationController.text = 'Destination';
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
        allTrips =
            trips.where((trip) => trip.tripType == 'Private Commute').toList();

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

  void _createMarkers(List<Trip> trips) {
    setState(() {
      markers.clear();
      for (final trip in trips) {
        markers.add(
          Marker(
            markerId: MarkerId(trip.tripId.toString()),
            position: LatLng(
              double.parse(trip.tripLocationInfo!.pickUpLatitude!),
              double.parse(trip.tripLocationInfo!.pickUpLongitude!),
            ),
            infoWindow: InfoWindow(
              title: trip.tripLocationInfo?.destinationAddress.toString() ??
                  'Unknown Location',
              snippet:
                  'Requester Contact Info: ${trip.contactDetailsPhoneNumber}',
              onTap: () =>
                  Navigator.pushNamed(context, '/chat', arguments: trip),
            ),
          ),
        );
      }
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
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ])),
            MapActionPanel(
              offering: true,
              title: 'Nearby requests',
              subtitle: 'Explore requests on the map and filter your route.',
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
                                  'Private Commuter Filter',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      OutlinedButton(
                                        onPressed: () async {
                                          final result =
                                              await Navigator.pushNamed(
                                                      context, '/pickup')
                                                  as TripLocationInfo?;
                                          if (result != null) {
                                            setState(() {
                                              pickUpController.text =
                                                  result.pickUpAddress ?? '';
                                              pickUpLat = result.pickUpLatitude;
                                              pickUpLong =
                                                  result.pickUpLongitude;
                                            });
                                          }
                                        },
                                        style: const ButtonStyle(
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                            ClearBlue.ink,
                                          ),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20),
                                              ),
                                            ),
                                          ),
                                          minimumSize: WidgetStatePropertyAll(
                                            Size(double.infinity, 60),
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: LocationAddressText(
                                            controller: pickUpController,
                                            style: TextStyle(
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Destination button
                                      OutlinedButton(
                                        onPressed: () async {
                                          final result =
                                              await Navigator.pushNamed(
                                                      context, '/destination')
                                                  as TripLocationInfo?;
                                          if (result != null) {
                                            setState(() {
                                              destinationController.text =
                                                  result.destinationAddress ??
                                                      '';
                                              destLat =
                                                  result.destinationLatitude;
                                              destLong =
                                                  result.destinationLongitude;
                                            });
                                          }
                                        },
                                        style: const ButtonStyle(
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                            ClearBlue.ink,
                                          ),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20),
                                              ),
                                            ),
                                          ),
                                          minimumSize: WidgetStatePropertyAll(
                                            Size(double.infinity, 60),
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: LocationAddressText(
                                            controller: destinationController,
                                            style: TextStyle(
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ),
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
                                            : const Text("Update Filters"),
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
