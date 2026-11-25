import 'package:flutter/material.dart';
import 'package:kapame/theme/clear_blue.dart';

class JourneyPlaceButton extends StatelessWidget {
  const JourneyPlaceButton({
    super.key,
    required this.label,
    required this.address,
    required this.onPressed,
  });

  final String label;
  final TextEditingController address;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
          onPressed: onPressed,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: address,
            builder: (context, value, _) => Row(
              children: [
                const Icon(Icons.place_outlined, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: ClearBlue.label),
                      if (value.text.isNotEmpty) Text(value.text),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ),
      );
}
