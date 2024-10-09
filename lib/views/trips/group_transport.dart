import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/services/current_user.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class GroupTransport extends StatefulWidget {
  const GroupTransport({super.key});

  @override
  State<GroupTransport> createState() => _GroupTransportState();
}

class _GroupTransportState extends State<GroupTransport> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController pickUpController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController numberOfPeopleController = TextEditingController();
  TextEditingController tripPriorityController = TextEditingController();
  String? selectedPriority;
  final List<String> priorityItems = ['Low', 'Important', 'Urgent'];
  TextEditingController tripScheduleController = TextEditingController();
  String? selectedSchedule;
  final List<String> scheduleItems = [
    'No Repeat',
    'Daily',
    'Weekly',
    'Monthly'
  ];
  String? pickUpLat;
  String? pickUpLong;
  String? destLat;
  String? destLong;

  bool isLoading = false;
  bool isComplete = false;

  DateTime? tripDateTime;
  final TextEditingController _dateController = TextEditingController();

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
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  void dispose() {
    pickUpController.dispose();
    destinationController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    numberOfPeopleController.dispose();
    tripPriorityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    MobileAds.instance.initialize();
    pickUpController.text = 'Pick Up';
    destinationController.text = 'Destination';
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

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      // Form is not valid, show an error message
      Fluttertoast.showToast(
        msg: "Please fill in all required fields correctly.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      AppUser? authUser =
          Provider.of<AuthUserState>(context, listen: false).appUser;

      if (authUser == null) {
        throw Exception("User not authenticated");
      }

      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final newTrip = {
        'requester': authUser.id,
        'transporter': null,
        'tripType': 'Group Transport',
        'tripStatus': 'Requested',
        'tripLocationInfo': {
          'pickUpAddress': pickUpController.text,
          'pickUpLatitude': pickUpLat,
          'pickUpLongitude': pickUpLong,
          'destinationAddress': destinationController.text,
          'destinationLatitude': destLat,
          'destinationLongitude': destLong
        },
        'contactDetailsPhoneNumber': phoneNumberController.text,
        'contactDetailsEmail': emailController.text,
        'tripPriority': tripPriorityController.text,
        'tripScheduling': tripScheduleController.text,
        'tripLastingTime': _dateController.text,
        'tripDateTime': tripDateTime?.toLocal().toIso8601String(),
        'groupTransport': {
          'numberOfPeople': numberOfPeopleController.text,
        },
        'itemTransport': null
      };

      final response = await dio.post(
        'https://kapameapi.azurewebsites.net/api/trips',
        data: newTrip,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            // Add any necessary authentication headers here
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "Trip Requested successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        throw Exception("Failed to create trip: ${response.statusCode}");
      }
    } catch (e) {
      print("Error submitting request: $e");
      Fluttertoast.showToast(
        msg: "Error submitting request. Please try again.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
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
                // Container with margin and padding
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 40), // Margin around the map
                  height: MediaQuery.of(context).size.height *
                      0.8, // 80% of the screen height
                  decoration: BoxDecoration(
                    color: Colors.white, // Optional: Set a background color
                    borderRadius: BorderRadius.circular(
                        10), // Optional: Add rounded corners
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        10), // Optional: Clip map to match border radius
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
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[200],
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
                  child: Column(children: [
                    const Text(
                      'Group Transporter Request',
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Your form widgets go here
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
