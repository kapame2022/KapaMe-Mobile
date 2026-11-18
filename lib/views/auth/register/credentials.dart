import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Credentials extends StatefulWidget {
  const Credentials({super.key});
  @override
  State<Credentials> createState() => _CredentialsState();
}

class _CredentialsState extends State<Credentials> {
  bool _hidePassword = true, _hideConfirmation = true;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
          initialValue: user.password,
          onChanged: user.updatePassword,
          obscureText: _hidePassword,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
              labelText: 'Password',
              floatingLabelStyle: const TextStyle(fontSize: 16),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              helperText: 'Use at least 8 characters.',
              suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined))),
          validator: (value) =>
              (value ?? '').length < 8 ? 'Use at least 8 characters' : null),
      const SizedBox(height: 16),
      TextFormField(
          initialValue: user.confirmPassword,
          onChanged: user.updateConfirmPassword,
          obscureText: _hideConfirmation,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
              labelText: 'Confirm password',
              floatingLabelStyle: const TextStyle(fontSize: 16),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixIcon: IconButton(
                  tooltip: _hideConfirmation
                      ? 'Show confirmation'
                      : 'Hide confirmation',
                  onPressed: () =>
                      setState(() => _hideConfirmation = !_hideConfirmation),
                  icon: Icon(_hideConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined))),
          validator: (value) => value != user.password || (value ?? '').isEmpty
              ? 'Passwords must match'
              : null),
      const SizedBox(height: 16),
      TextButton(
          onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                    title: const Text('Terms and conditions'),
                    content: SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.sizeOf(context).height * .5,
                        child: SfPdfViewer.asset('assets/Usage_Policy.pdf')),
                    actions: [
                      TextButton(
                          onPressed: () {
                            user.updateTermsAccepted(false);
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Decline')),
                      FilledButton(
                          onPressed: () {
                            user.updateTermsAccepted(true);
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Accept'))
                    ],
                  )),
          child: const Text('Read terms and conditions')),
      FormField<bool>(
          validator: (_) => user.termsAccepted == true
              ? null
              : 'Accept the terms to create your account',
          builder: (field) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I accept the terms and conditions.'),
                    value: user.termsAccepted ?? false,
                    onChanged: (value) {
                      user.updateTermsAccepted(value);
                      field.didChange(value);
                    }),
                if (field.hasError)
                  Text(field.errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
              ])),
    ]);
  }
}
