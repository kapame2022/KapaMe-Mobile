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

class PublicCommuter extends StatefulWidget {
  const PublicCommuter({super.key});

  @override
  State<PublicCommuter> createState() => _PublicCommuterState();
}

class _PublicCommuterState extends State<PublicCommuter> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController destinationController = TextEditingController();
  String? destLat;
  String? destLong;

  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.publicCommuterAd,
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
    loadAd();
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
    if (!mounted) return;
    setState(() {
      currentLocation = locationData;
    });
  }

  bool _reviewOpen = false;

  Future<void> _reviewRequest() async {
    if (_reviewOpen || _formKey.currentState?.validate() != true) return;
    if (destinationController.text.isEmpty) {
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
      'tripType': 'Public Commute',
      'tripStatus': 'Requested',
      'tripLocationInfo': {
        'pickUpAddress': '',
        'pickUpLatitude': '',
        'pickUpLongitude': '',
        'destinationAddress': destinationController.text,
        'destinationLatitude': destLat,
        'destinationLongitude': destLong
      },
      'contactDetailsPhoneNumber': '',
      'contactDetailsEmail': '',
      'tripPriority': '',
      'tripScheduling': '',
      'tripLastingTime': null,
      'tripDateTime': null,
      'groupTransport': null,
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
    final destination = tripCoordinates(destLat, destLong);
    return {
      if (destination != null)
        Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: const InfoWindow(title: 'Destination')),
    };
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
      appBar: AppBar(title: const Text('Public transport')),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: currentLocation == null
                    ? const Center(child: Text('Waiting for your location…'))
                    : Stack(fit: StackFit.expand, children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              currentLocation!.latitude!,
                              currentLocation!.longitude!,
                            ),
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
                            child: Column(
                              children: [
                                const Text(
                                  'Trip details',
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
                                          label: 'Destination',
                                          address: destinationController,
                                          onPressed: _chooseDestination),
                                      const SizedBox(height: 40),
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
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                            ClearBlue.accent,
                                          ),
                                        ),
                                        child: const Text('Review request'),
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
