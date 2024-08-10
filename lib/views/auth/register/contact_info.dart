import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';

class ContactInfo extends StatefulWidget {
  const ContactInfo({super.key});

  @override
  State<ContactInfo> createState() => _ContactInfoState();
}

class _ContactInfoState extends State<ContactInfo> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        TextField(
          controller: fullNameController,
          onChanged:
              Provider.of<UserState>(context, listen: false).updateFullName,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            border: OutlineInputBorder(
                borderSide: BorderSide(width: 1),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Colors.lightBlue,
                  width: 1), // Customize focused border
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: emailController,
          onChanged: Provider.of<UserState>(context, listen: false).updateEmail,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            border: OutlineInputBorder(
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Colors.lightBlue,
                  width: 1), // Customize focused border
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: phoneNumberController,
          onChanged:
              Provider.of<UserState>(context, listen: false).updatePhoneNumber,
          obscureText: false,
          decoration: const InputDecoration(
            hintText: 'Phone Number',
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
        const SizedBox(height: 30)
      ],
    );
  }
}
