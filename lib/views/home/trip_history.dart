import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';

class TripHistory extends StatefulWidget {
  const TripHistory({super.key});

  @override
  State<TripHistory> createState() => _TripHistoryState();
}

class _TripHistoryState extends State<TripHistory> {
  Future<List<Trip>> getTrips() async {
    final Dio dio = Dio();
    var res = await dio.get('https://kapameapi.azurewebsites.net/api/trips');

    List<Trip> allTrips = [];

    for (Map<String, dynamic> trip in res.data) {
      print(trip);
      Trip? deserializedTrip = Trip.fromMap(trip);
      // deserializedTrip.tripLocationInfo =
      //     TripLocationInfo.fromMap(trip['tripLocationInfo']);
      // deserializedTrip.itemTransport =
      //     ItemTransportDetails.fromMap(trip['itemTransport']);
      // deserializedTrip.groupTransport =
      //     GroupTransportDetails.fromMap(trip['groupTransport']);
      allTrips.add(deserializedTrip);
    }

    return allTrips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_outlined),
                ),
                const Text("Home"),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 0),
              child: const Text(
                "Trip History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder<List<Trip>>(
              future: getTrips(),
              builder: ((context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            snapshot.data![index].tripDateTime.toString(),
                          ),
                          subtitle: Text(
                              'Trip Type: ${snapshot.data![index].tripType}'),
                          onTap: () {
                            // Handle tapping on trip item
                          },
                        );
                      },
                    ),
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
