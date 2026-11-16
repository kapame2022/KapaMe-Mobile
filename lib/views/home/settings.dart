import 'package:flutter/material.dart';
import 'package:kapame/services/auth.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthUserState>().appUser;
    final name = (user?.fullName ?? '').trim();
    return JourneyPage(
        selected: 3,
        eyebrow: 'YOUR ACCOUNT',
        title:
            name.isEmpty ? 'Your profile.' : 'Hello, ${name.split(' ').first}.',
        children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 26,
                        backgroundColor: ClearBlue.soft,
                        child: Text(userInitials(name))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name.isEmpty ? 'KapaMe member' : name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (user?.email?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(user!.email!,
                                style: const TextStyle(color: ClearBlue.muted))
                          ]
                        ])),
                  ]))),
          const SizedBox(height: 20),
          Card(
              child: Column(children: [
            for (final item in [
              ('Account details', '/editprofile', Icons.person_outline),
              ('About KapaMe', '/aboutus', Icons.info_outline),
              (
                'POPIA agreement',
                '/popiaagreement',
                Icons.verified_user_outlined
              ),
              ('Privacy policy', '/privacypolicy', Icons.lock_outline),
              (
                'Terms and conditions',
                '/termsandconditions',
                Icons.description_outlined
              ),
              ('Disclaimer', '/disclaimer', Icons.article_outlined),
            ])
              ListTile(
                  leading: Icon(item.$3, color: ClearBlue.accent),
                  title: Text(item.$1),
                  trailing:
                      const Icon(Icons.chevron_right, color: ClearBlue.muted),
                  onTap: () => Navigator.pushNamed(context, item.$2)),
          ])),
          const SizedBox(height: 24),
          OutlinedButton(
              onPressed: () async {
                try {
                  await AuthService().logout();
                  if (!context.mounted) return;
                  await context.read<AuthUserState>().updateAuthUser();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Unable to sign out. Please try again.')));
                  }
                }
              },
              child: const Text('Sign out')),
        ]);
  }
}
