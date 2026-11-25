import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/main.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:kapame/services/current_user.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('signed-out startup shows the landing page', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('restored startup opens Home with the saved user',
      (tester) async {
    const adsChannel = 'plugins.flutter.io/google_mobile_ads';
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      adsChannel,
      (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMessageHandler(adsChannel, null));
    final auth = AuthUserState(
        session: AuthResponse(
      'Restored',
      true,
      'test-token',
      null,
      AppUser(id: 'user-123', fullName: 'Test User'),
      DateTime.now().add(const Duration(hours: 2)),
    ));
    addTearDown(auth.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MyApp(initialRoute: '/home'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('HELLO, TEST'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
