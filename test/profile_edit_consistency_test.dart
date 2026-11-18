import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/home/edit_profile.dart';
import 'package:provider/provider.dart';

void main() {
  late AuthUserState auth;
  late Dio dio;
  setUp(() async {
    auth = AuthUserState(inToken: 'token');
    await auth.updateAuthUser(
        inAppUser: AppUser(
            id: 'me',
            fullName: 'Lerato Mokoena',
            email: 'lerato@example.com',
            phoneNumber: '0825550142'),
        inExpireDate: DateTime(2030));
    dio = Dio();
  });
  Future<void> mount(WidgetTester tester) =>
      tester.pumpWidget(ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
              theme: ClearBlue.theme,
              home: const Scaffold(body: Text('Profile home')),
              routes: {'/edit': (_) => EditProfile(dio: dio)},
              initialRoute: '/edit')));
  testWidgets(
      'save preserves auth, handles failures, and cancel restores saved values',
      (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      calls++;
      expect(options.data['userId'], 'me');
      expect(options.headers['Authorization'], 'Bearer token');
      if (calls == 1) {
        await pending.future;
        handler.reject(DioException(requestOptions: options));
      } else {
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'fullName': options.data['fullName']}));
      }
    }));
    await mount(tester);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save changes'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextFormField).first, 'Lerato Updated');
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Your edits are still here'), findsOneWidget);
    expect(find.text('Lerato Updated'), findsOneWidget);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(auth.appUser!.fullName, 'Lerato Updated');
    expect(auth.token, 'token');
    expect(auth.expireDate, DateTime(2030));
    expect(auth.appUser!.email, 'lerato@example.com');
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved change');
    await tester.pump();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Lerato Updated');
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save changes'))
            .onPressed,
        isNull);
  });
  testWidgets('Back protects unsaved edits and discard returns to profile',
      (tester) async {
    await mount(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Draft');
    await tester.pump();
    await tester.tap(find.byTooltip('Back to profile'));
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Profile home'), findsOneWidget);
    expect(auth.appUser!.fullName, 'Lerato Mokoena');
  });
  testWidgets(
      'profile fits large text and keyboard and validates before saving',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
            theme: ClearBlue.theme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: EditProfile(dio: dio))));
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid');
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
