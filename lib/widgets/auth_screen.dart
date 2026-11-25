import 'package:flutter/material.dart';
import 'package:kapame/theme/clear_blue.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: title == null ? null : AppBar(title: Text(title!)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('kapame.',
                      style: TextStyle(
                        color: ClearBlue.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      )),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}

class AuthHighlight extends StatelessWidget {
  const AuthHighlight({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
        color: ClearBlue.soft,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ClearBlue.accent),
              const SizedBox(height: 10),
              Text(title, style: ClearBlue.heading),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      );
}
