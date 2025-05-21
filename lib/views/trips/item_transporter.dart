import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:location/location.dart';

class ItemTransporter extends StatefulWidget {
  const ItemTransporter({super.key});

  @override
  State<ItemTransporter> createState() => _ItemTransporterState();
}

class _ItemTransporterState extends State<ItemTransporter> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController pickUpController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  bool isLoading = false;

  DateTime? tripDateTime;
  TextEditingController tripDateTimeController = TextEditingController();

  List<Trip> allTrips = [];
  Set<Marker> markers = {};

  String? pickUpLat;
  String? pickUpLong;
  String? destLat;
  String? destLong;

  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.itemTransporterAd,
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
    tripDateTimeController.dispose();
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
            trips.where((trip) => trip.tripType == 'Item Transport').toList();

        _createMarkers(allTrips);
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      print('Error fetching trips: $e');
    }
  }

  void _applyFilters() {
    List<Trip> filteredTrips = _filterTrips(
      pickUp: pickUpController.text,
      destination: destinationController.text,
      date: tripDateTime,
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
    DateTime? date,
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

      bool matchesDate = date == null ||
          (trip.tripDateTime != null &&
              trip.tripDateTime!.isAtSameMomentAs(date));

      return matchesPickUp && matchesDestination && matchesDate;
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
                    'Requester Contact Info: ${trip.contactDetailsPhoneNumber}'),
          ),
        );
      }
    });
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tripDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != tripDateTime) {
      setState(() {
        tripDateTime = picked;
        tripDateTimeController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 0, vertical: 25), // Margin around the map
                  height: MediaQuery.of(context).size.height *
                      0.85, // 80% of the screen height
                  decoration: BoxDecoration(
                    color: Colors.white, // Optional: Set a background color
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Optional: Add rounded corners
                  ),
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
                Positioned(
                  bottom: 45,
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
                                  vertical: 40, horizontal: 25),
                              child: Column(
                                children: [
                                  const Text(
                                    'Item Transporter Filters',
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
                                                pickUpLat =
                                                    result.pickUpLatitude;
                                                pickUpLong =
                                                    result.pickUpLongitude;
                                              });
                                            }
                                          },
                                          style: const ButtonStyle(
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
                                            child: Text(pickUpController.text),
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
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: tripDateTimeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Select a date',
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(width: 1),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.lightBlue,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          readOnly: true,
                                          onTap: () => selectDate(context),
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Please select a date'
                                                  : null,
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
                                                Size(double.infinity, 60)),
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
                                              : const Text("Update Filter"),
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
