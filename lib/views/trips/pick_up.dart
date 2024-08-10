import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/trip_services.dart';

class PickUp extends StatefulWidget {
  const PickUp({super.key});

  @override
  State<PickUp> createState() => _PickUpState();
}

class _PickUpState extends State<PickUp> {
  TextEditingController pickUpAddress = TextEditingController();
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
              controller: pickUpAddress,
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
                              pickUpAddress: snapshot.data![index]
                                  ['description'],
                              pickUpLatitude: coord.pickUpLatitude,
                              pickUpLongitude: coord.pickUpLongitude,
                              destinationAddress:
                                  '', // You might want to set this if applicable
                              destinationLatitude:
                                  '', // You might want to set this if applicable
                              destinationLongitude:
                                  '', // You might want to set this if applicable
                            );

                            // Optionally, update the text field with the selected suggestion
                            pickUpAddress.text =
                                snapshot.data![index]['description'];

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
