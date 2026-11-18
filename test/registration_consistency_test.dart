import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/services/new_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/auth/register.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'registration validates bio and preserves details when going back',
      (tester) async {
    final user = UserState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: user,
        child: MaterialApp(theme: ClearBlue.theme, home: const Register())));
    await tester.enterText(find.byType(TextFormField).at(0), 'Lerato Mokoena');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'lerato@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '0825550142');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('ABOUT YOU · STEP 2 OF 3'), findsOneWidget);
    expect(user.hasSelectedDateOfBirth, isFalse);
    final dateHeight = tester.getSize(find.byType(TextFormField)).height;
    final genderHeight =
        tester.getSize(find.byType(DropdownButtonFormField<String>)).height;
    expect((dateHeight - genderHeight).abs(), lessThanOrEqualTo(1));
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Select your gender'), findsOneWidget);
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.lastDate, DateUtils.dateOnly(DateTime.now()));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('SECURITY · STEP 3 OF 3'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'test-password');
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Female'), findsOneWidget);
    expect(user.hasSelectedDateOfBirth, isTrue);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Lerato Mokoena'), findsOneWidget);
    expect(find.text('lerato@example.com'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .initialValue,
        'test-password');
    expect(tester.takeException(), isNull);
  });
  testWidgets('registration fits a small phone with large text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => UserState(),
        child: MaterialApp(
            theme: ClearBlue.theme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const Register())));
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
