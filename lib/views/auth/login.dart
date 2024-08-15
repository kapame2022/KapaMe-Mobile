import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:kapame/services/current_user.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<AuthResponse?> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails, return null without starting the loading process
      return null;
    }

    setState(() {
      isLoading = true;
    });
    try {
      final Dio dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      setState(() {
        isLoading = true;
      });

      var res = await dio
          .post('https://kapameapi.azurewebsites.net/api/auth/login', data: {
        "email": usernameController.text.trim(),
        "password": passwordController.text.trim()
      });

      if (res.statusCode == 200) {
        AuthResponse currentUser = AuthResponse(
            res.data['message'],
            res.data['isSuccess'],
            res.data['token'],
            res.data['errors'],
            AppUser.fromMap(res.data['user']),
            DateTime.parse(res.data['expireDate']));

        return currentUser;
      }
    } catch (e) {
      print("error: $e");
      setState(() {
        isLoading = false;
      });
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 255, 253, 248),
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/images/KapaMeLogo.png'),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 50),
                    width: screenWidth,
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextFormField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your email',
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(width: 1),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.lightBlue,
                                        width: 1), // Customize focused border
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    hintText: 'Password',
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(width: 1),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.lightBlue,
                                            width: 1))),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),
                              FilledButton(
                                onPressed: () async {
                                  AuthResponse? authRes = await loginUser();

                                  if (authRes?.isSuccess == true) {
                                    Provider.of<AuthUserState>(context,
                                            listen: false)
                                        .updateAuthUser(
                                            authRes!.message,
                                            authRes.isSuccess,
                                            authRes.token,
                                            authRes.errors,
                                            authRes.user,
                                            authRes.expireDate ??
                                                DateTime.now());
                                    Navigator.pushReplacementNamed(
                                        context, '/home');
                                  }
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
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      )
                                    : const Text("Login"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
          ),
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
