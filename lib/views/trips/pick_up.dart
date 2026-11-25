import 'package:flutter/material.dart';
import 'package:kapame/widgets/trip_place_picker.dart';

class PickUp extends StatelessWidget {
  const PickUp({super.key});

  @override
  Widget build(BuildContext context) =>
      const TripPlacePicker(destination: false);
}
