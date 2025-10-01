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

  bool isLoading = false;
  bool isComplete = false;

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

  Future<void> handleSubmit() async {
    try {
      AppUser? authUser =
          Provider.of<AuthUserState>(context, listen: false).appUser;
      if (destinationController.text == '') {
        print(destinationController.text);
        setState(() {
          isComplete = true;
        });
      } else {
        final Dio dio = Dio();

        dio.options.connectTimeout = const Duration(seconds: 30);
        dio.options.receiveTimeout = const Duration(seconds: 30);

        setState(() {
          isLoading = true;
        });

        final newTrip = {
          'requester': authUser?.id,
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

        await dio.post('https://kapameapi.azurewebsites.net/api/trips',
            data: newTrip);
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(
            msg: "Trip Requested successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error submitting request. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
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
                        target: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
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
                                    'Public Commuter Request',
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
                                            // Navigate to the second page
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
                                                    Radius.circular(10)),
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                                Size(double.infinity, 60)),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                                destinationController.text),
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                        FilledButton(
                                          onPressed: handleSubmit,
                                          style: const ButtonStyle(
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                                Size(double.infinity, 60)),
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Color.fromARGB(
                                                        255, 241, 144, 47)),
                                          ),
                                          child: isLoading
                                              ? const CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                )
                                              : const Text("Finish"),
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
                    child: const Icon(Icons.add),
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
