import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/widgets/custom_info_window.dart';
import 'package:location/location.dart';

class PublicDriver extends StatefulWidget {
  const PublicDriver({super.key});

  @override
  State<PublicDriver> createState() => _PublicDriverState();
}

class _PublicDriverState extends State<PublicDriver> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
      adUnitId: AdUnitIds.publicDriverAd,
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
    destinationController.text = 'Destination';
  }

  @override
  void dispose() {
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
            trips.where((trip) => trip.tripType == 'Public Commute').toList();

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

    List<Trip> filteredTrips =
        _filterTrips(destination: destinationController.text);

    _createMarkers(filteredTrips);

    setState(() {
      isLoading = false;
    });
    Navigator.pop(context); // Close the bottom sheet
  }

  List<Trip> _filterTrips({String? destination}) {
    return allTrips.where((trip) {
      bool matchesDestination = destination == null ||
          destination.isEmpty ||
          trip.tripLocationInfo?.destinationAddress
                  ?.toLowerCase()
                  .contains(destination.toLowerCase()) ==
              true;

      return matchesDestination;
    }).toList();
  }

  bool _showCustomWindow = false;
  Trip? _selectedTrip;

  void _createMarkers(List<Trip> trips) {
    setState(() {
      markers.clear();
      for (final trip in trips) {
        markers.add(
          Marker(
            markerId: MarkerId(trip.tripId.toString()),
            onTap: () {
              setState(() {
                _showCustomWindow = true;
                _selectedTrip = trip;
              });
            },
            position: LatLng(
              double.parse(trip.tripLocationInfo!.pickUpLatitude!),
              double.parse(trip.tripLocationInfo!.pickUpLongitude!),
            ),
            infoWindow: const InfoWindow(title: '', snippet: ''),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(top: 24), // Margin around the map
                  height: MediaQuery.of(context).size.height *
                      0.95, // 80% of the screen height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GoogleMap(
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
                  ),
                ),
                if (_showCustomWindow && _selectedTrip != null)
                  Positioned(
                    bottom: 100, // Adjust as needed
                    left: 20,
                    right: 20,
                    child: CustomInfoWindow(
                      title:
                          "Pickup Address: ${_selectedTrip!.tripLocationInfo!.pickUpAddress != null ? _selectedTrip!.tripLocationInfo!.pickUpAddress : 'No address'}",
                      snippet:
                          "Destination Address: ${_selectedTrip!.tripLocationInfo!.destinationAddress != null ? _selectedTrip!.tripLocationInfo!.destinationAddress : 'No address'}",
                      onClick: () => Navigator.pushNamed(
                        context,
                        '/viewrequest',
                        arguments: _selectedTrip,
                      ),
                      onClose: () {
                        setState(() {
                          _showCustomWindow = false;
                        });
                      },
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.white,
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 25,
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Public Commuter Filters',
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
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 15,
                                              ),
                                            ),
                                            foregroundColor:
                                                WidgetStatePropertyAll(
                                              Color.fromARGB(255, 82, 82, 82),
                                            ),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(double.infinity, 60),
                                            ),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              destinationController.text,
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
                                                  Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(double.infinity, 60),
                                            ),
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                              Color.fromARGB(255, 241, 144, 47),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                )
                                              : const Text("Apply Filters"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Icon(Icons.filter_alt),
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
