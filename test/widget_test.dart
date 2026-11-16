import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/home/home.dart';

void main() {
  testWidgets('Find and Offer preserve all eight transport destinations',
      (tester) async {
    tester.view.physicalSize = const Size(396, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const destinations = {
      'Private ride': '/privatecommuter',
      'Public transport': '/publiccommuter',
      'Group trip': '/grouptransport',
      'Send an item': '/itemtransport',
      'Drive privately': '/privatedriver',
      'Public route': '/publicdriver',
      'Host a group': '/grouptransporter',
      'Deliver an item': '/itemtransporter',
    };
    await tester.pumpWidget(MaterialApp(
        theme: ClearBlue.theme,
        home: const HomeContent(name: 'Lerato Mokoena'),
        routes: {
          for (final route in destinations.values)
            route: (_) =>
                Scaffold(appBar: AppBar(), body: Text('Opened $route')),
        }));
    for (final entry in destinations.entries) {
      if (entry.key == 'Drive privately') {
        await tester.tap(find.text('Offer transport'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('Opened ${entry.value}'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(396, 900),
    const Size(800, 600)
  ]) {
    testWidgets('home remains usable at $size with large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: ClearBlue.theme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: const HomeContent(name: '')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send an item'));
      expect(tester.takeException(), isNull);
      expect(find.text('HELLO THERE'), findsOneWidget);
    });
  }
}
