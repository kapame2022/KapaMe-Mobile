import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';

class ContactInfo extends StatelessWidget {
  const ContactInfo({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.read<UserState>();
    return AutofillGroup(
        child: Column(children: [
      TextFormField(
          initialValue: user.fullName,
          onChanged: user.updateFullName,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              constraints: BoxConstraints(minHeight: 72),
              labelText: 'Full name',
              floatingLabelStyle: TextStyle(fontSize: 16),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter your full name' : null),
      const SizedBox(height: 16),
      TextFormField(
          initialValue: user.email,
          onChanged: user.updateEmail,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              constraints: BoxConstraints(minHeight: 72),
              labelText: 'Email address',
              floatingLabelStyle: TextStyle(fontSize: 16),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          validator: (value) =>
              RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter a valid email address'),
      const SizedBox(height: 16),
      TextFormField(
          initialValue: user.phoneNumber,
          onChanged: user.updatePhoneNumber,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
              constraints: BoxConstraints(minHeight: 72),
              labelText: 'Phone number',
              floatingLabelStyle: TextStyle(fontSize: 16),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          validator: (value) =>
              RegExp(r'^\+?[0-9]{10,14}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter a valid phone number'),
    ]));
  }
}
