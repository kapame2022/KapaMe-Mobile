//import 'dart:js_interop';

//import 'dart:js_interop';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kapame/services/new_user.dart';
import 'package:kapame/views/auth/register/bio.dart';
import 'package:kapame/views/auth/register/contact_info.dart';
import 'package:kapame/views/auth/register/credentials.dart';
import 'package:provider/provider.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<Widget> stepList = [
    const Bio(),
    const ContactInfo(),
    const Credentials(),
  ];

  int _currentStep = 0;
  bool isLoading = false;

  //Stepper Navigation
  void goToNextStep() {
    final newUser = Provider.of<UserState>(context, listen: false);
    if (_currentStep == 0 && !validateBioStep(newUser)) return;
    if (_currentStep == 1 && !validateContactStep(newUser)) return;
    if (_currentStep == 2 && !validateCredentialsStep(newUser)) return;
    setState(() {
      if (_currentStep <= 2) {
        _currentStep += 1;
      }
    });
  }

  void goToPreviousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep -= 1;
      } else if (_currentStep == 0) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget currentButton() {
    if (_currentStep <= 1) {
      return FilledButton(
        onPressed: goToNextStep,
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
        child: const Text("Continue"),
      );
    } else {
      return FilledButton(
        onPressed: () async {
          await registerUser(context);
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text("Finish"),
      );
    }
  }

  //Form Handling
  bool validateBioStep(UserState user) {
    List<String> errors = [];
    if (user.gender.isEmpty || user.gender == 'Select gender') {
      errors.add("Gender is required");
    }
    if (errors.isNotEmpty) {
      Fluttertoast.showToast(
        msg: errors.join("\n"), /* ... */
      );
      return false;
    }
    return true;
  }

  bool validateContactStep(UserState user) {
    List<String> errors = [];

    // Validate Full Name
    if (user.fullName.isEmpty) {
      errors.add("Full Name is required");
    }

    // Validate Email
    if (user.email.isEmpty) {
      errors.add("Email is required");
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(user.email)) {
      errors.add("Invalid email format");
    }

    // Validate Phone Number
    if (user.phoneNumber.isEmpty) {
      errors.add("Phone Number is required");
    } else if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(user.phoneNumber)) {
      errors.add("Invalid phone number format");
    }

    if (errors.isNotEmpty) {
      String errorMessage = errors.join("\n");
      Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return false;
    }

    return true;
  }

  bool validateCredentialsStep(UserState user) {
    List<String> errors = [];

    if (user.password.isEmpty) {
      errors.add("Password is required");
    } else if (user.password.length < 8) {
      errors.add("Password must be at least 8 characters long");
    }
    if (user.confirmPassword.isEmpty) {
      errors.add("Confirm Password is required");
    } else if (user.password != user.confirmPassword) {
      errors.add("Passwords do not match");
    }

    if (user.termsAccepted == false) {
      errors.add("Terms and Conditions not accepted");
    }

    if (errors.isNotEmpty) {
      Fluttertoast.showToast(
          msg: errors.join("\n"),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return false;
    }

    return true;
  }

  bool validateUser(UserState user) {
    List<String> errors = [];

    // Validate Full Name
    if (user.fullName.isEmpty) {
      errors.add("Full Name is required");
    }

    // Validate Email
    if (user.email.isEmpty) {
      errors.add("Email is required");
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(user.email)) {
      errors.add("Invalid email format");
    }

    // Validate Phone Number
    if (user.phoneNumber.isEmpty) {
      errors.add("Phone Number is required");
    } else if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(user.phoneNumber)) {
      errors.add("Invalid phone number format");
    }

    if (errors.isNotEmpty) {
      String errorMessage = errors.join("\n");
      Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return false;
    }

    return true;
  }

  Future registerUser(BuildContext context) async {
    final newUser = Provider.of<UserState>(context, listen: false);
    try {
      if (validateUser(newUser)) {
        final Dio dio = Dio();

        dio.options.headers['content-Type'] = 'application/json';

        setState(() {
          isLoading = true;
        });

        var res = await dio.post(
            'https://kapameapi.azurewebsites.net/api/auth/register',
            data: {
              'dateOfBirth': newUser.dateOfBirth.toIso8601String(),
              'gender': newUser.gender,
              'userType': "Transporter",
              'subscription': null,
              'transporter': null,
              //id: "",
              'fullName': newUser.fullName,
              'userName': newUser.fullName.replaceAll(' ', ''),
              'email': newUser.email,
              'phoneNumber': newUser.phoneNumber,
              'password': newUser.password,
              'confirmPassword': newUser.confirmPassword,
              'referral': null
            });

        if (res.statusCode == 200) {
          // AuthResponse currentUser = AuthResponse(
          //   res.data['message'],
          //   res.data['isSuccess'],
          //   res.data['token'],
          //   res.data['errors'],
          //   AppUser.fromMap(res.data['user']),
          //   DateTime.parse(
          //     res.data['expireDate'],
          //   ),
          // );
          print(res.data);
          Fluttertoast.showToast(
            msg: "Trip Requested successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          await Navigator.pushReplacementNamed(context, '/verifyemail');
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (e is DioException) {
        print(e.response?.data);
        setState(() {
          Fluttertoast.showToast(
            msg: "Error submitting request. Please try again.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          isLoading = false;
        });
      }
      print('e: $e');
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
        appBar: AppBar(
          // Set the title of the appbar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Add a back button icon
            onPressed: goToPreviousStep,
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              child: Column(
                children: [
                  Image.asset('assets/images/KapaMeLogo.png'),
                  Center(
                    child: stepList[_currentStep],
                  ),
                  currentButton()
                ],
              ),
            ),
          ),
        ));
  }
}
