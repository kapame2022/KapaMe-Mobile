import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/views/trips/chat.dart';

void main() {
  testWidgets('preview composer rejects blank messages and appends text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Chat()));
    await tester.pumpAndSettle();
    expect(find.byType(Chat), findsOneWidget);
    expect(find.text('Chat preview · Messages are not sent'), findsOneWidget);

    final send = find.widgetWithIcon(IconButton, Icons.send_rounded);
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNull);

    await tester.enterText(
        find.byType(TextField), 'I am at the main entrance.');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('I am at the main entrance.'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('failed send preserves the draft and allows retry',
      (tester) async {
    var attempts = 0;
    final pending = Completer<TripMessage>();
    await tester.pumpWidget(MaterialApp(
      home: Chat(onSend: (text) {
        attempts++;
        if (attempts == 1) return pending.future;
        return Future.value(TripMessage(
          sender: 'me',
          message: text,
          timestamp: DateTime.now(),
        ));
      }),
    ));
    await tester.enterText(find.byType(TextField), 'Please meet me outside.');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Send message'))
            .onPressed,
        isNull);
    pending.completeError(Exception('Unavailable'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Message could not be sent. Your text is saved here. Try again.'),
        findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Please meet me outside.');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Please meet me outside.'), findsOneWidget);
  });

  testWidgets('composer fits a phone viewport with the keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MaterialApp(home: Chat()));
    await tester.enterText(
        find.byType(TextField), 'Line one\nLine two\nLine three\nLine four');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(544));
  });
}
