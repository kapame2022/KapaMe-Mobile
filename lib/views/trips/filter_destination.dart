import 'package:flutter/material.dart';
import 'package:kapame/widgets/trip_place_picker.dart';

class FilterDestination extends StatelessWidget {
  const FilterDestination({super.key});

  @override
  Widget build(BuildContext context) =>
      const TripPlacePicker(destination: true, filter: true);
}
