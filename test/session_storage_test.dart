import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late SessionStorage sessions;
  late AuthResponse session;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    sessions = SessionStorage();
    session = AuthResponse(
      'Signed in',
      true,
      'test-token',
      null,
      AppUser(id: 'user-123', fullName: 'Test User', email: 'test@example.com'),
      DateTime.now().toUtc().add(const Duration(hours: 2)),
    );
  });

  test('remembered login restores identity, token and original expiry',
      () async {
    await sessions.save(session, rememberMe: true);
    final restored = await SessionStorage().restore();
    expect(restored!.token, session.token);
    expect(restored.user.toMap(), session.user.toMap());
    expect(restored.expireDate, session.expireDate);
    final auth = AuthUserState(session: restored);
    addTearDown(auth.dispose);
    expect(auth.appUser!.id, 'user-123');
    expect(auth.isSuccess, isTrue);
    expect(auth.token, 'test-token');
  });

  test('unchecked remember me removes previous and legacy saved sessions',
      () async {
    FlutterSecureStorage.setMockInitialValues({'token': 'old', 'user': 'old'});
    await sessions.save(session, rememberMe: true);
    await sessions.save(session, rememberMe: false);
    expect(await SessionStorage().restore(), isNull);
    expect(await storage.readAll(), isEmpty);
  });

  test('expired session is removed instead of extending its expiry', () async {
    await sessions.save(session, rememberMe: true);
    final saved = jsonDecode((await storage.read(key: 'remembered_session'))!)
        as Map<String, dynamic>;
    saved['expireDate'] = DateTime.now()
        .subtract(const Duration(minutes: 1))
        .toUtc()
        .toIso8601String();
    await storage.write(key: 'remembered_session', value: jsonEncode(saved));
    expect(await sessions.restore(), isNull);
    expect(await storage.readAll(), isEmpty);
  });

  for (final saved in ['invalid json', '{}', '[]', '{"token":123}']) {
    test('malformed saved session is discarded: $saved', () async {
      FlutterSecureStorage.setMockInitialValues({'remembered_session': saved});
      expect(await sessions.restore(), isNull);
      expect(await storage.readAll(), isEmpty);
    });
  }

  test('sessions without an expiry or user identity are not remembered',
      () async {
    session.expireDate = null;
    await sessions.save(session, rememberMe: true);
    expect(await sessions.restore(), isNull);
    session.expireDate = DateTime.now().add(const Duration(hours: 1));
    session.user.id = null;
    await sessions.save(session, rememberMe: true);
    expect(await sessions.restore(), isNull);
  });

  test('legacy token alone never restores a signed-in user', () async {
    FlutterSecureStorage.setMockInitialValues({'token': 'old'});
    expect(await sessions.restore(), isNull);
  });

  test('profile updates preserve authentication and logout clears it',
      () async {
    final auth = AuthUserState(session: session);
    addTearDown(auth.dispose);
    await auth.updateAuthUser(
        inAppUser: AppUser(id: 'user-123', fullName: 'New Name'));
    expect(auth.token, session.token);
    expect(auth.expireDate, session.expireDate);
    auth.clear();
    expect(auth.token, isNull);
    expect(auth.appUser, isNull);
    expect(auth.expireDate, isNull);
    expect(auth.isSuccess, isFalse);
  });
}
