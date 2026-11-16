import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'remembered_session';

  Future<void> save(AuthResponse session, {required bool rememberMe}) async {
    // Remove any previous account and the old token-only session first.
    await clear();
    if (!rememberMe || !_isValid(session)) return;

    await _storage.write(
      key: _key,
      value: jsonEncode({
        'token': session.token,
        'user': session.user.toMap(),
        'expireDate': session.expireDate!.toUtc().toIso8601String(),
      }),
    );
  }

  Future<AuthResponse?> restore() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;

    try {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final session = AuthResponse(
        'Session restored',
        true,
        data['token'] as String,
        null,
        AppUser.fromMap(data['user'] as Map<String, dynamic>),
        DateTime.parse(data['expireDate'] as String),
      );
      if (_isValid(session)) return session;
    } on FormatException {
      // Discard unreadable or incomplete sessions and require a new login.
    } on TypeError {
      // Stored data from an older or incomplete session may have missing fields.
    }

    await clear();
    return null;
  }

  bool _isValid(AuthResponse session) =>
      session.isSuccess &&
      session.token.isNotEmpty &&
      (session.user.id?.isNotEmpty ?? false) &&
      (session.expireDate?.isAfter(DateTime.now()) ?? false);

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }
}
