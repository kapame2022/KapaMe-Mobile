import 'package:flutter/material.dart';

/// Keeps a location label current even inside a separately built bottom sheet.
class LocationAddressText extends StatelessWidget {
  const LocationAddressText({
    super.key,
    required this.controller,
    this.style,
  });

  final TextEditingController controller;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) => Text(value.text, style: style),
    );
  }
}
