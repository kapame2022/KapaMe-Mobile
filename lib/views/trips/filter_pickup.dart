import 'package:flutter/material.dart';
import 'package:kapame/widgets/trip_place_picker.dart';

class FilterPickUp extends StatelessWidget {
  const FilterPickUp({super.key});

  @override
  Widget build(BuildContext context) =>
      const TripPlacePicker(destination: false, filter: true);
}
