import 'package:kapame/theme/clear_blue.dart';

import 'package:flutter/material.dart';

class CustomInfoWindow extends StatelessWidget {
  final String title;
  final String snippet;
  final VoidCallback onClick;
  final VoidCallback onClose;

  const CustomInfoWindow({
    super.key,
    required this.title,
    required this.snippet,
    required this.onClick,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              snippet,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    "Close",
                    style: TextStyle(color: ClearBlue.muted),
                  ),
                ),
                TextButton(
                  onPressed: onClick,
                  child: const Text(
                    "More Details",
                    style: TextStyle(color: ClearBlue.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
