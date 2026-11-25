import 'package:flutter/material.dart';
import 'package:kapame/widgets/auth_screen.dart';

class VerifyEmail extends StatelessWidget {
  const VerifyEmail({super.key});

  @override
  Widget build(BuildContext context) => AuthScreen(
        title: 'Email verification',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHighlight(
              icon: Icons.mark_email_read_outlined,
              title: 'Check your inbox',
              description:
                  'Follow the verification link sent to your email address.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      );
}
