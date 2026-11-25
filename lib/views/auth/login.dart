import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/auth_screen.dart';
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
  String? errorMessage;
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
    if (isLoading || !_formKey.currentState!.validate()) {
      // If validation fails, return null without starting the loading process
      return null;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final shouldRemember = rememberMe;
    final dio = widget.dio ?? Dio();
    try {
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

        if (!currentUser.isSuccess || currentUser.token.isEmpty) {
          if (mounted) {
            setState(
                () => errorMessage = 'Unable to sign in. Please try again.');
          }
          return null;
        }
        await _sessionStorage.save(currentUser, rememberMe: shouldRemember);
        if (!mounted) return null;

        return currentUser;
      }
    } catch (e) {
      if (!mounted) return null;
      final data = e is DioException ? e.response?.data : null;
      setState(() => errorMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Unable to sign in. Please try again.');
      return null;
    } finally {
      if (widget.dio == null) dio.close();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    return null;
  }

  Future<void> _signIn() async {
    final response = await loginUser();
    if (!mounted || response == null) return;
    context.read<AuthUserState>().updateAuthUser(
          inMessage: response.message,
          inIsSuccess: response.isSuccess,
          inToken: response.token,
          inErrors: response.errors,
          inAppUser: response.user,
          inExpireDate: response.expireDate ?? DateTime.now(),
        );
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) => AuthScreen(
        title: 'Sign in',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Welcome back', style: ClearBlue.heading),
                const SizedBox(height: 20),
                TextFormField(
                  controller: usernameController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your email address'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: obscureText,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: obscureText ? 'Show password' : 'Hide password',
                      icon: Icon(obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => obscureText = !obscureText),
                    ),
                  ),
                  onFieldSubmitted: (_) => _signIn(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your password'
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Keep me signed in'),
                  value: rememberMe,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => rememberMe = value ?? false),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  ),
                FilledButton(
                  onPressed: isLoading ? null : _signIn,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      );
}
