import 'package:flutter/material.dart';
import 'package:kapame/services/session_storage.dart';
import 'package:kapame/services/current_user.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_outlined),
                ),
                const Text("Home"),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
              child: const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/aboutus');
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll<Color>(Colors.blue),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(60),
                        ),
                      ),
                      child: const Text("About Us"),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/popiaagreement');
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll<Color>(Colors.blue),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(60),
                        ),
                      ),
                      child: const Text("Popia Agreement"),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/privacypolicy');
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll<Color>(Colors.blue),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(60),
                        ),
                      ),
                      child: const Text("Privacy Policy"),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/disclaimer');
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll<Color>(Colors.blue),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(60),
                        ),
                      ),
                      child: const Text("Disclaimer"),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    child: FilledButton(
                      onPressed: () async {
                        final auth = context.read<AuthUserState>();
                        try {
                          await SessionStorage().clear();
                          auth.clear();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (route) => false);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Unable to log out. Please try again.'),
                            ),
                          );
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll<Color>(Colors.blue),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(60),
                        ),
                      ),
                      child: const Text("Logout"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
