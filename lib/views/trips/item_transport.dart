import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class ItemTransport extends StatefulWidget {
  const ItemTransport({super.key});

  @override
  State<ItemTransport> createState() => _ItemTransportState();
}

class _ItemTransportState extends State<ItemTransport> {
  GoogleMapController? mapController;
  LocationData? currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
    });
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
          // Your existing modal bottom sheet code here
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
