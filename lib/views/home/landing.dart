import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 255, 253, 248),
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset('assets/images/kapamelogo.png'),
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
                              shape: MaterialStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              minimumSize: MaterialStatePropertyAll(
                                  Size(double.infinity, 60)),
                              backgroundColor:
                                  MaterialStatePropertyAll(Colors.blue)),
                          child: const Text('Log in')),
                      const SizedBox(height: 10),
                      FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: const ButtonStyle(
                              shape: MaterialStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              minimumSize: MaterialStatePropertyAll(
                                  Size(double.infinity, 60)),
                              backgroundColor: MaterialStatePropertyAll(
                                  Color.fromARGB(255, 72, 72, 72))),
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
