import 'package:flutter/material.dart';
import 'package:kapame/widgets/trip_place_picker.dart';

class Destination extends StatelessWidget {
  const Destination({super.key});

  @override
  Widget build(BuildContext context) =>
      const TripPlacePicker(destination: true);
}
