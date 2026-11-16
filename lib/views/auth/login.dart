import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:kapame/services/current_user.dart';
import 'package:provider/provider.dart';
import 'package:kapame/services/session_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key, this.dio});

  final Dio? dio;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isSuccess = false;
  bool isComplete = false;
  bool obscureText = true;

  bool rememberMe = false;
  final SessionStorage _sessionStorage = SessionStorage();

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
    final shouldRemember = rememberMe;
    try {
      final Dio dio = widget.dio ?? Dio();

      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

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
          DateTime.parse(res.data['expireDate']),
        );

        if (!currentUser.isSuccess || currentUser.token.isEmpty) return null;
        await _sessionStorage.save(currentUser, rememberMe: shouldRemember);
        if (!mounted) return null;

        setState(() {
          isSuccess = true;
        });

        return currentUser;
      }
    } catch (e) {
      if (!mounted) return null;
      final data = e is DioException ? e.response?.data : null;
      Fluttertoast.showToast(
        msg: data is Map && data['message'] is String
            ? data['message'] as String
            : 'Unable to sign in. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    return null;
  }

  //Function that checks what the status of an input
  //for username and password
  bool formComplete(String value) {
    //Validate the status of the required inputs
    // Check if both username and password fields are not empty
    if (usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      setState(() {
        isComplete = true;
      });
    } else {
      setState(() {
        isComplete = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Container(
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
                                onChanged: formComplete,
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
                                onChanged: formComplete,
                                obscureText: obscureText,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(width: 1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.lightBlue,
                                      width: 1,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureText = !obscureText;
                                      });
                                    },
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Remember me'),
                                value: rememberMe,
                                onChanged: isLoading
                                    ? null
                                    : (value) => setState(() {
                                          rememberMe = value ?? false;
                                        }),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        AuthResponse? authRes =
                                            await loginUser();
                                        if (!context.mounted) return;

                                        if (authRes?.isSuccess == true) {
                                          Provider.of<AuthUserState>(context,
                                                  listen: false)
                                              .updateAuthUser(
                                                  inMessage: authRes!.message,
                                                  inIsSuccess:
                                                      authRes.isSuccess,
                                                  inToken: authRes.token,
                                                  inErrors: authRes.errors,
                                                  inAppUser: authRes.user,
                                                  inExpireDate:
                                                      authRes.expireDate ??
                                                          DateTime.now());
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              '/home',
                                              (route) => false);
                                        }
                                      },
                                style: ButtonStyle(
                                  shape: const WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                  minimumSize: const WidgetStatePropertyAll(
                                    Size(double.infinity, 60),
                                  ),
                                  backgroundColor: WidgetStatePropertyAll(
                                    isComplete
                                        ? Colors.green
                                        : const Color.fromARGB(255, 72, 72, 72),
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
    );
  }
}
