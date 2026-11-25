import 'package:kapame/widgets/trip_date_time_picker.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:kapame/widgets/journey_place_button.dart';
import 'package:kapame/views/trips/review_trip_request.dart';
import 'package:kapame/widgets/trip_route_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
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

  DateTime? tripDateTime;
  final TextEditingController _dateController = TextEditingController();

  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.groupTransportAd,
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

  Future<void> selectDate(BuildContext context) async {
    final picked = await showTripDateTimePicker(
      context: context,
      initialDateTime: tripDateTime,
    );
    if (picked == null || !mounted || !context.mounted) return;

    setState(() {
      tripDateTime = picked;
      _dateController.text = formatTripDateTime(picked);
    });
  }

  @override
  void dispose() {
    pickUpController.dispose();
    destinationController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    numberOfPeopleController.dispose();
    tripPriorityController.dispose();
    tripScheduleController.dispose();
    _dateController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    loadAd();
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

  bool _reviewOpen = false;

  Future<void> _reviewRequest() async {
    if (_reviewOpen || _formKey.currentState?.validate() != true) return;
    if (destinationController.text.isEmpty || pickUpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choose the required locations before continuing.')),
      );
      return;
    }
    final auth = context.read<AuthUserState>();
    final userId = auth.appUser?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to request a trip.')),
      );
      return;
    }
    final newTrip = {
      'requester': userId,
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
    _reviewOpen = true;
    try {
      await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ReviewTripRequest(request: newTrip, token: auth.token),
          ));
    } finally {
      _reviewOpen = false;
    }
  }

  Future<void> _centerOnPlace(String? latitude, String? longitude) async {
    final position = tripCoordinates(latitude, longitude);
    if (position == null) return;
    try {
      await mapController?.animateCamera(CameraUpdate.newLatLng(position));
    } catch (_) {
      // A map can be disposed while a place is being selected.
    }
  }

  Set<Marker> get _routeMarkers {
    final pickup = tripCoordinates(pickUpLat, pickUpLong);
    final destination = tripCoordinates(destLat, destLong);
    return {
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
    };
  }

  Future<void> _choosePickup() async {
    final result =
        await Navigator.pushNamed<TripLocationInfo>(context, '/pickup');
    if (!mounted || result == null) return;
    setState(() {
      pickUpController.text = result.pickUpAddress ?? '';
      pickUpLat = result.pickUpLatitude;
      pickUpLong = result.pickUpLongitude;
    });
    _centerOnPlace(pickUpLat, pickUpLong);
  }

  Future<void> _chooseDestination() async {
    final result =
        await Navigator.pushNamed<TripLocationInfo>(context, '/destination');
    if (!mounted || result == null) return;
    setState(() {
      destinationController.text = result.destinationAddress ?? '';
      destLat = result.destinationLatitude;
      destLong = result.destinationLongitude;
    });
    _centerOnPlace(destLat, destLong);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Group trip')),
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
                          markers: _routeMarkers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ])),
            MapActionPanel(
              title: 'Set your route',
              action: 'Trip details',
              locations: [
                JourneyPlaceButton(
                    label: 'Pick-up',
                    address: pickUpController,
                    onPressed: _choosePickup),
                const SizedBox(height: 8),
                JourneyPlaceButton(
                    label: 'Destination',
                    address: destinationController,
                    onPressed: _chooseDestination)
              ],
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
                              vertical: 16,
                              horizontal: 24,
                            ),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // Pick-up address button
                                    JourneyPlaceButton(
                                        label: 'Pick-up',
                                        address: pickUpController,
                                        onPressed: _choosePickup),
                                    const SizedBox(height: 10),
                                    // Destination button
                                    JourneyPlaceButton(
                                        label: 'Destination',
                                        address: destinationController,
                                        onPressed: _chooseDestination),
                                    const SizedBox(height: 10),
                                    // Number of People
                                    TextFormField(
                                      controller: numberOfPeopleController,
                                      obscureText: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Passengers',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Enter the number of passengers'
                                              : null,
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: phoneNumberController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                          labelText: 'Phone number'),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Enter your phone number'
                                              : null,
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Priority'),
                                      initialValue: selectedPriority,
                                      onChanged: (String? newValue) {
                                        selectedPriority = newValue;
                                        tripPriorityController.text =
                                            newValue.toString();
                                      },
                                      validator: (value) => value == null
                                          ? 'Please select a priority level'
                                          : null,
                                      items: priorityItems.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item,
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                    // Trip Schedule Dropdown
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Schedule',
                                      ),
                                      initialValue: selectedSchedule,
                                      onChanged: (String? newValue) {
                                        selectedSchedule = newValue;
                                        tripScheduleController.text =
                                            newValue.toString();
                                      },
                                      validator: (value) => value == null
                                          ? 'Please select a trip schedule'
                                          : null,
                                      items: scheduleItems.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item,
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                    // Trip Date Picker
                                    TextFormField(
                                      controller: _dateController,
                                      decoration: const InputDecoration(
                                        labelText: 'Departure',
                                        suffixIcon:
                                            Icon(Icons.calendar_today_outlined),
                                      ),
                                      readOnly: true,
                                      onTap: () => selectDate(context),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Please select a date and time'
                                              : null,
                                    ),
                                    const SizedBox(height: 40),
                                    // Submit Button
                                    FilledButton(
                                      onPressed: _reviewRequest,
                                      style: const ButtonStyle(
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
                                        backgroundColor: WidgetStatePropertyAll(
                                          ClearBlue.accent,
                                        ),
                                      ),
                                      child: const Text('Review request'),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
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
