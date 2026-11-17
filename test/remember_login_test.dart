import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/session_storage.dart';
import 'package:kapame/views/auth/login.dart';
import 'package:kapame/views/home/settings.dart';
import 'package:provider/provider.dart';

void main() {
  for (final remember in [false, true]) {
    testWidgets('login with remember me $remember and logout', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = AuthUserState();
      final dio = Dio();
      addTearDown(auth.dispose);
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'message': 'Signed in',
          'isSuccess': true,
          'token': 'test-token',
          'errors': null,
          'user': {'id': 'user-123', 'fullName': 'Test User'},
          'expireDate':
              DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        }));
      }));
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          initialRoute: '/login',
          routes: {
            '/': (_) => const Scaffold(body: Text('Signed out')),
            '/login': (_) => Login(dio: dio),
            '/home': (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('Open settings'),
                )),
            '/settings': (_) => const Settings(),
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isFalse);
      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'test-password');
      if (remember) {
        await tester.ensureVisible(find.text('Remember me'));
        await tester.tap(find.text('Remember me'));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Login'));
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsOneWidget);
      expect(auth.appUser!.id, 'user-123');
      expect(auth.token, 'test-token');
      final restored = await SessionStorage().restore();
      expect(restored?.user.id, remember ? 'user-123' : null);
      expect((await const FlutterSecureStorage().readAll()).toString(),
          isNot(contains('test-password')));
      expect(Navigator.of(tester.element(find.text('Open settings'))).canPop(),
          isFalse);

      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sign out'), 200);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Signed out'), findsOneWidget);
      expect(auth.token, isNull);
      expect(auth.appUser, isNull);
      expect(await SessionStorage().restore(), isNull);
      expect(Navigator.of(tester.element(find.text('Signed out'))).canPop(),
          isFalse);
    });
  }
}
