import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset('assets/images/KapaMeLogo.jpeg'),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 40),
                  width: screenWidth,
                  child: Column(
                    children: [
                      FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(double.infinity, 60),
                            ),
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue),
                          ),
                          child: const Text('Log in')),
                      const SizedBox(height: 10),
                      FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(double.infinity, 60),
                            ),
                            backgroundColor: WidgetStatePropertyAll(
                              Color.fromARGB(255, 72, 72, 72),
                            ),
                          ),
                          child: const Text('Register')),
                    ],
                  ),
                ),
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.question_mark),
      ),
    );
  }
}
