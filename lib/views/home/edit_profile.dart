import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key, this.dio});
  final Dio? dio;
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _phone;
  late final Dio _dio;
  late List<String> _saved;
  bool _saving = false, _allowLeave = false, _askingToLeave = false;
  String? _error, _notice;
  List<String> get _values =>
      [_name.text.trim(), _email.text.trim(), _phone.text.trim()];
  bool get _dirty {
    final values = _values;
    return List.generate(3, (i) => values[i] != _saved[i])
        .any((changed) => changed);
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthUserState>().appUser;
    _name = TextEditingController(text: user?.fullName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
    _saved = _values;
    _dio = widget.dio ??
        Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30)));
    for (final controller in [_name, _email, _phone]) {
      controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {
        _error = null;
        _notice = null;
      });
  @override
  void dispose() {
    for (final controller in [_name, _email, _phone]) {
      controller.dispose();
    }
    if (widget.dio == null) _dio.close();
    super.dispose();
  }

  void _cancel() {
    _form.currentState?.reset();
    _name.text = _saved[0];
    _email.text = _saved[1];
    _phone.text = _saved[2];
    setState(() {
      _error = null;
      _notice = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _leave() async {
    if (_saving || _askingToLeave) return;
    if (!_dirty) {
      Navigator.maybePop(context);
      return;
    }
    _askingToLeave = true;
    final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Discard your changes?'),
              content: const Text('Your account details haven’t been saved.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Keep editing')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Discard changes'))
              ],
            ));
    _askingToLeave = false;
    if (discard != true || !mounted) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_saving || !_dirty || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final auth = context.read<AuthUserState>();
    final user = auth.appUser;
    final token = auth.token;
    if (user?.id?.isNotEmpty != true) {
      setState(() => _error = 'Sign in again to update your profile.');
      return;
    }
    final values = _values;
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      final response = await _dio.put(
          'https://kapameapi.azurewebsites.net/api/auth/${user!.id}',
          data: {
            'userId': user.id,
            'fullName': values[0],
            'email': values[1],
            'phoneNumber': values[2]
          },
          options: Options(headers: {
            if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token'
          }));
      if (!mounted) return;
      if (response.statusCode != 200 || response.data is! Map) {
        throw const FormatException('Invalid profile response');
      }
      if (auth.appUser?.id != user.id || auth.token != token) {
        setState(() =>
            _error = 'Your session changed. Sign in again before saving.');
        return;
      }
      final updated = AppUser.fromMap({
        ...user.toMap(),
        'fullName': values[0],
        'email': values[1],
        'phoneNumber': values[2],
        ...Map<String, dynamic>.from(response.data as Map)
      });
      await auth.updateAuthUser(inAppUser: updated);
      if (!mounted) return;
      _name.text = updated.fullName ?? values[0];
      _email.text = updated.email ?? values[1];
      _phone.text = updated.phoneNumber ?? values[2];
      setState(() {
        _saved = _values;
        _notice = 'Your account details have been saved.';
      });
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t save your changes. Your edits are still here. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthUserState>().appUser;
    return PopScope(
        canPop: _allowLeave || (!_dirty && !_saving),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
              title: const Text('Account details'),
              leading: IconButton(
                  tooltip: 'Back to profile',
                  onPressed: _saving ? null : _leave,
                  icon: const Icon(Icons.arrow_back))),
          body: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                      key: _form,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const PageHeading(
                                eyebrow: 'YOUR ACCOUNT',
                                title: 'Account details.',
                                subtitle:
                                    'Keep your contact information up to date.'),
                            const SizedBox(height: 24),
                            Row(children: [
                              CircleAvatar(
                                  radius: 26,
                                  backgroundColor: ClearBlue.soft,
                                  foregroundColor: ClearBlue.accent,
                                  child: Text(userInitials(user?.fullName))),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(user?.fullName ?? 'KapaMe member',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const Text('KapaMe member',
                                        style:
                                            TextStyle(color: ClearBlue.muted))
                                  ]))
                            ]),
                            const SizedBox(height: 28),
                            TextFormField(
                                controller: _name,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    constraints: BoxConstraints(minHeight: 72),
                                    floatingLabelStyle: TextStyle(fontSize: 16),
                                    labelText: 'Full name',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always),
                                validator: (value) =>
                                    (value ?? '').trim().isEmpty
                                        ? 'Enter your full name'
                                        : null),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _email,
                                enabled: !_saving,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    constraints: BoxConstraints(minHeight: 72),
                                    floatingLabelStyle: TextStyle(fontSize: 16),
                                    labelText: 'Email address',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always),
                                validator: (value) =>
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch((value ?? '').trim())
                                        ? null
                                        : 'Enter a valid email address'),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _phone,
                                enabled: !_saving,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                    constraints: BoxConstraints(minHeight: 72),
                                    floatingLabelStyle: TextStyle(fontSize: 16),
                                    labelText: 'Phone number',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always),
                                validator: (value) =>
                                    RegExp(r'^\+?[0-9]{10,14}$').hasMatch(
                                            (value ?? '').replaceAll(
                                                RegExp(r'[\s()-]'), ''))
                                        ? null
                                        : 'Enter a valid phone number'),
                            if (_error != null || _notice != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Semantics(
                                      liveRegion: true,
                                      child: Text(_error ?? _notice!,
                                          style: TextStyle(
                                              color: _error != null
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                  : ClearBlue.accent)))),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: _dirty && !_saving ? _save : null,
                                child: _saving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Save changes')),
                            TextButton(
                                onPressed: _dirty && !_saving ? _cancel : null,
                                child: const Text('Cancel')),
                          ])))),
        ));
  }
}
