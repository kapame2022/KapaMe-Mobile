import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/trip_services.dart';

class Destination extends StatefulWidget {
  const Destination({super.key});

  @override
  State<Destination> createState() => _DestinationState();
}

class _DestinationState extends State<Destination> {
  TextEditingController destinationAddress = TextEditingController();
  Future<List<dynamic>>? suggestions;

  TripServices tripServices = TripServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
        child: Column(
          children: [
            TextField(
              controller: destinationAddress,
              decoration: const InputDecoration(
                hintText: 'Enter some text',
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
              onChanged: (value) {
                setState(() {
                  suggestions = tripServices.getSuggestions(value);
                });
                print(suggestions!.asStream().length);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: suggestions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No suggestions'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(snapshot.data![index]['description']),
                          onTap: () async {
                            // Get place details for the selected suggestion
                            final coord = await tripServices.getPlaceDetails(
                                snapshot.data![index]['place_id']);

                            // Create a TripLocationInfo object
                            final tripLocationInfo = TripLocationInfo(
                              // pickUpAddress: '',
                              // pickUpLatitude: coord.pickUpLatitude,
                              // pickUpLongitude: coord.pickUpLongitude,
                              destinationAddress: snapshot.data![index][
                                  'description'], // You might want to set this if applicable
                              destinationLatitude: coord.pickUpLatitude
                                  .toString(), // You might want to set this if applicable
                              destinationLongitude: coord.pickUpLongitude
                                  .toString(), // You might want to set this if applicable
                            );

                            // Optionally, update the text field with the selected suggestion
                            destinationAddress.text =
                                snapshot.data![index]['description'];

                            print(
                                "Latitude: ${tripLocationInfo.destinationLatitude}");
                            print(
                                "Longitude: ${tripLocationInfo.destinationLongitude}");
                            // Clear the suggestions list
                            setState(() {
                              suggestions = Future.value([]);
                            });

                            Navigator.pop(context, tripLocationInfo);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
