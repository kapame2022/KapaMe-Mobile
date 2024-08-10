import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
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

  @override
  void dispose() {
    pickUpController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    MobileAds.instance.initialize();
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
      //print('Response Data: ${res.data}');
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
    // if (_formKey.currentState!.validate()) {
    //   setState(() {
    //     isLoading = true;
    //   });

    List<Trip> filteredTrips = _filterTrips(
        pickUp: pickUpController.text, destination: destinationController.text);

    _createMarkers(filteredTrips);

    setState(() {
      isLoading = false;
    });
    Navigator.pop(context); // Close the bottom sheet
    // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!),
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
                child: Column(children: [
                  const Text(
                    'Private Commuter Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: pickUpController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your pick up location',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(width: 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.lightBlue,
                                  width: 1), // Customize focused border
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: destinationController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              hintText: 'Destination',
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(width: 1),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.lightBlue, width: 1))),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        FilledButton(
                          onPressed: _applyFilters,
                          style: const ButtonStyle(
                            shape: MaterialStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            minimumSize: MaterialStatePropertyAll(
                              Size(double.infinity, 60),
                            ),
                            backgroundColor: MaterialStatePropertyAll(
                              Color.fromARGB(255, 241, 144, 47),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text("Update Filters"),
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            },
          );
        },
        child: const Icon(Icons.filter_alt),
      ),
    );
  }
}
