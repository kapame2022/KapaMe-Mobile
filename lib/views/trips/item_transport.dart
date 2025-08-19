import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/services/current_user.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class ItemTransport extends StatefulWidget {
  const ItemTransport({super.key});

  @override
  State<ItemTransport> createState() => _ItemTransportState();
}

class _ItemTransportState extends State<ItemTransport> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController pickUpController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController itemDescriptionController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController tripPriorityController = TextEditingController();
  String? selectedPriority;
  final List<String> priorityItems = [
    'Low (Removed after 4 hours)',
    'Important (Removed after 2 hours)',
    'Urgent (Removed after 1 hour)'
  ];
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
  TextEditingController tripDateTimeController = TextEditingController();
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

  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.itemTransportAd,
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
  void dispose() {
    pickUpController.dispose();
    destinationController.dispose();
    itemDescriptionController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    tripPriorityController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    loadAd();
    pickUpController.text = 'Pick Up';
    destinationController.text = 'Destination';
  }

  Future<void> _getLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
    });
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
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
        'tripType': 'Item Transport',
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
        'contactDetailsEmail': '', // Consider adding an email field if needed
        'tripPriority': tripPriorityController.text,
        'tripScheduling': tripScheduleController.text,
        'tripLastingTime': tripDateTimeController.text,
        'tripDateTime': tripDateTime?.toLocal().toIso8601String(),
        'groupTransport': null,
        'itemTransport': {'description': itemDescriptionController.text}
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
      print('Response Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
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
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 25,
                  ), // Margin around the map
                  height: MediaQuery.of(context).size.height *
                      0.85, // 80% of the screen height
                  decoration: BoxDecoration(
                    color: Colors.white, // Optional: Set a background color
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Optional: Add rounded corners
                  ),
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
                // Positioning the button at the bottom left
                Positioned(
                  bottom: 45, // Adjust the distance from the bottom
                  left: 20, // Adjust the distance from the left
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
                              child: Column(children: [
                                const Text(
                                  'Item Transporter Request',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      // Pick-up Address Button
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
                                      // Destination Button
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
                                          child:
                                              Text(destinationController.text),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Phone Number Field
                                      TextFormField(
                                        controller: phoneNumberController,
                                        obscureText: false,
                                        decoration: const InputDecoration(
                                            hintText: 'Phone Number',
                                            border: OutlineInputBorder(
                                                borderSide:
                                                    BorderSide(width: 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10))),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.lightBlue,
                                                    width: 1))),
                                        validator: (String? value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter some text';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      // Item Description Field
                                      TextFormField(
                                        controller: itemDescriptionController,
                                        decoration: const InputDecoration(
                                          hintText: 'Item Description',
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.lightBlue,
                                                width: 1),
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
                                      // Trip Priority Dropdown
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Select a trip priority',
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
                                        value: selectedPriority,
                                        onChanged: (String? newValue) {
                                          tripPriorityController.text =
                                              newValue.toString();
                                        },
                                        validator: (value) => value == null
                                            ? 'Please select a priority level'
                                            : null,
                                        items: priorityItems.map((String item) {
                                          return DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(item),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 10),
                                      // Trip Schedule Dropdown
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Select a trip schedule',
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
                                        value: selectedSchedule,
                                        onChanged: (String? newValue) {
                                          tripScheduleController.text =
                                              newValue.toString();
                                        },
                                        validator: (value) => value == null
                                            ? 'Please select a trip schedule'
                                            : null,
                                        items: scheduleItems.map((String item) {
                                          return DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(item),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 10),
                                      // Trip Date Picker
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
                                      // Submit Button
                                      FilledButton(
                                        onPressed: handleSubmit,
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
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              )
                                            : const Text("Finish"),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                    child: const Icon(Icons.create),
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
