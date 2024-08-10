import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';

class Credentials extends StatefulWidget {
  const Credentials({super.key});

  @override
  State<Credentials> createState() => _CredentialsState();
}

class _CredentialsState extends State<Credentials> {
  @override
  Widget build(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    bool termsAccepted = false;

    void showTermsAndConditions() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Usage Policy'),
            content: const SingleChildScrollView(
              child: Text(''),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Decline'),
                onPressed: () {
                  setState(() {
                    termsAccepted = false;
                  });
                  Navigator.of(context).pop();
                  // Update user data in your state management solution
                  // For example, using Provider:
                  // Provider.of<UserDataProvider>(context, listen: false).updateTermsStatus(false);
                },
              ),
              TextButton(
                child: const Text('Accept'),
                onPressed: () {
                  setState(() {
                    termsAccepted = true;
                  });
                  Navigator.of(context).pop();
                  // Update user data in your state management solution
                  // For example, using Provider:
                  // Provider.of<UserDataProvider>(context, listen: false).updateTermsStatus(true);
                },
              ),
            ],
          );
        },
      );
    }

    return Column(
      children: [
        const SizedBox(height: 30),
        TextFormField(
          controller: passwordController,
          onChanged:
              Provider.of<UserState>(context, listen: false).updatePassword,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 1),
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
          controller: confirmPasswordController,
          onChanged: Provider.of<UserState>(context, listen: false)
              .updateConfirmPassword,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Re-enter Password',
            border: OutlineInputBorder(
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.all(
                Radius.circular(
                  10,
                ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 1),
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
        FilledButton(
          style: const ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
            minimumSize: WidgetStatePropertyAll(
              Size(60, 60),
            ),
            backgroundColor: const WidgetStatePropertyAll(
              Color.fromARGB(255, 19, 161, 232),
            ),
          ),
          onPressed: showTermsAndConditions,
          child: const Text('Read Terms and Conditions'),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Checkbox(
              value: termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  termsAccepted = value ?? false;
                });
                // Update user data in your state management solution
                // For example, using Provider:
                // Provider.of<UserDataProvider>(context, listen: false).updateTermsStatus(_termsAccepted);
              },
            ),
            const Text('I Accept the Terms and Conditions'),
          ],
        ),
        const SizedBox(height: 10)
      ],
    );
  }
}
