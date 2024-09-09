import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';

class ViewRequest extends StatelessWidget {
  const ViewRequest({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final currentTrip = args['trip'] as Trip?;
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('Trip Information'),
          ),
          Expanded(
            child: Column(
              children: [
                Column(
                  children: [
                    const Text('Trip Type'),
                    Text(
                      currentTrip!.tripType.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
