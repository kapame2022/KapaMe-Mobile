import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Credentials extends StatefulWidget {
  const Credentials({Key? key}) : super(key: key);

  @override
  State<Credentials> createState() => _CredentialsState();
}

class _CredentialsState extends State<Credentials> {
  bool obscureText = true;
  bool obscureText2 = true;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newUser = Provider.of<UserState>(context, listen: false);

    void showTermsAndConditions() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Usage Policy'),
            content: SfPdfViewer.asset("assets/Usage_Policy.pdf"),
            actions: <Widget>[
              TextButton(
                child: const Text('Decline'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Update user data in your state management solution
                  // For example, using Provider:
                  setState(() {
                    Provider.of<UserState>(context, listen: false)
                        .updateTermsAccepted(false);
                  });
                },
              ),
              TextButton(
                child: const Text('Accept'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Update user data in your state management solution
                  // For example, using Provider:
                  setState(() {
                    Provider.of<UserState>(context, listen: false)
                        .updateTermsAccepted(true);
                  });
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
          onChanged: (value) {
            newUser.updatePassword(value);
          },
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Password',
            border: const OutlineInputBorder(
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 1),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
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
        const SizedBox(height: 10),
        TextFormField(
          controller: confirmPasswordController,
          onChanged: (value) {
            newUser.updateConfirmPassword(value);
          },
          obscureText: obscureText2,
          decoration: InputDecoration(
            hintText: 'Re-enter Password',
            border: const OutlineInputBorder(
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 1),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText2 ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  obscureText2 = !obscureText2;
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
            backgroundColor: WidgetStatePropertyAll(
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
              value: newUser.termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  Provider.of<UserState>(context, listen: false)
                      .updateTermsAccepted(value);
                });
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
