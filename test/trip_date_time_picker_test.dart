import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/widgets/trip_date_time_picker.dart';

void main() {
  Future<void> openPicker(
    WidgetTester tester,
    ValueChanged<DateTime?> onPicked,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onPicked(await showTripDateTimePicker(
              context: context,
              initialDateTime: DateTime(2026, 10, 14, 15, 45),
            )),
            child: const Text('Select trip date and time'),
          ),
        ),
      ),
    ));
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);
    await tester.tap(find.text('Select trip date and time'));
    await tester.pumpAndSettle();
  }

  testWidgets('combines selected date and time and restores previous selection',
      (tester) async {
    DateTime? result;
    await openPicker(tester, (value) => result = value);
    expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .initialDate,
        DateTime(2026, 10, 14));
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<TimePickerDialog>(find.byType(TimePickerDialog));
    expect(picker.initialTime, const TimeOfDay(hour: 15, minute: 45));
    // Confirm a different time to verify the returned value uses the time picker.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '4');
    await tester.enterText(find.byType(TextField).last, '20');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 10, 15, 16, 20));
    expect(formatTripDateTime(result!), '2026-10-15 16:20');
    expect(result!.toIso8601String(), '2026-10-15T16:20:00.000');
  });

  testWidgets('cancelling the date does not open a time picker',
      (tester) async {
    DateTime? result;
    var completed = false;
    await openPicker(tester, (value) {
      result = value;
      completed = true;
    });
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('cancelling the time discards the partial selection',
      (tester) async {
    DateTime? result;
    var completed = false;
    await openPicker(tester, (value) {
      result = value;
      completed = true;
    });
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });
}
