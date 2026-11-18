import 'package:kapame/theme/clear_blue.dart';
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
    const ContactInfo(),
    const Bio(),
    const Credentials(),
  ];

  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _resetScroll() {
    FocusScope.of(context).unfocus();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  int _currentStep = 0;
  bool isLoading = false;
  bool isComplete = false;

  //Stepper Navigation
  void goToNextStep() {
    if (isLoading || !(formKey.currentState?.validate() ?? false)) return;
    final newUser = Provider.of<UserState>(context, listen: false);
    if (_currentStep == 0 && !validateContactStep(newUser)) return;
    if (_currentStep == 1 && !validateBioStep(newUser)) return;
    if (_currentStep == 2 && !validateCredentialsStep(newUser)) return;
    _resetScroll();
    setState(() {
      if (_currentStep <= 2) {
        _currentStep += 1;
      }
    });
  }

  void goToPreviousStep() {
    _resetScroll();
    setState(() {
      if (_currentStep > 0) {
        _currentStep -= 1;
      } else if (_currentStep == 0) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget currentButton() => FilledButton(
        onPressed: isLoading
            ? null
            : _currentStep < 2
                ? goToNextStep
                : () {
                    if (formKey.currentState?.validate() ?? false) {
                      registerUser(context);
                    }
                  },
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_currentStep < 2 ? 'Continue' : 'Create account'),
      );

  //Form Handling
  bool validateBioStep(UserState user) {
    List<String> errors = [];
    if (!user.hasSelectedDateOfBirth) errors.add("Date of birth is required");
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

    setState(() {
      isComplete = true;
    });

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

  void checkFormCompletion() {
    final newUser = Provider.of<UserState>(context, listen: false);
    bool complete = false;

    if (_currentStep == 2) {
      complete =
          newUser.password.isNotEmpty && newUser.confirmPassword.isNotEmpty;
    }

    setState(() {
      isComplete = complete;
    });
  }

  Future registerUser(BuildContext context) async {
    final newUser = Provider.of<UserState>(context, listen: false);
    if (isLoading ||
        !validateBioStep(newUser) ||
        !validateCredentialsStep(newUser)) {
      return;
    }
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

        if (!context.mounted) return;
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
          Fluttertoast.showToast(
            msg: "Account created. Please verify your email.",
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
      if (!mounted) return;
      if (e is DioException) {
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const headings = [
      'Let’s get acquainted.',
      'A little about you.',
      'Keep your account safe.'
    ];
    const labels = ['CONTACT DETAILS', 'ABOUT YOU', 'SECURITY'];
    const descriptions = [
      'Your contact details, all in one place.',
      'Add your personal details to continue.',
      'Choose a password to finish signing up.'
    ];
    return PopScope(
      canPop: _currentStep == 0 && !isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isLoading && _currentStep > 0) goToPreviousStep();
      },
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Create account'),
            leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: isLoading ? null : goToPreviousStep)),
        body: SafeArea(
            child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(24),
                child: Form(
                    key: formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('kapame.',
                              style: TextStyle(
                                  color: ClearBlue.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 24),
                          Text(
                              '${labels[_currentStep]} · STEP ${_currentStep + 1} OF 3',
                              style: ClearBlue.label),
                          const SizedBox(height: 16),
                          Row(
                              children: List.generate(
                                  3,
                                  (i) => Expanded(
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              right: i == 2 ? 0 : 8),
                                          child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                  color: i <= _currentStep
                                                      ? ClearBlue.accent
                                                      : ClearBlue.line,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4))))))),
                          const SizedBox(height: 24),
                          Text(headings[_currentStep],
                              style: ClearBlue.heading),
                          const SizedBox(height: 12),
                          Text(descriptions[_currentStep],
                              style: const TextStyle(color: ClearBlue.muted)),
                          const SizedBox(height: 28),
                          AbsorbPointer(
                              absorbing: isLoading,
                              child: stepList[_currentStep]),
                          const SizedBox(height: 24),
                          currentButton(),
                        ])))),
      ),
    );
  }
}
