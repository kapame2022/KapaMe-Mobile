import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:provider/provider.dart';
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

  testWidgets('Home opens the next scheduled trip for the signed-in user',
      (tester) async {
    final auth = AuthUserState();
    await auth.updateAuthUser(inAppUser: AppUser(id: 'me'));
    addTearDown(auth.dispose);
    final messenger = tester.binding.defaultBinaryMessenger;
    const ads = 'plugins.flutter.io/google_mobile_ads';
    messenger.setMockMessageHandler(ads,
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    addTearDown(() => messenger.setMockMessageHandler(ads, null));
    final now = DateTime.now();
    final next = Trip(
      requester: 'ME',
      tripType: 'Next private ride',
      tripDateTime: now.add(const Duration(days: 1)),
    );
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        theme: ClearBlue.theme,
        home: Home(
            loadTrips: () async => [
                  Trip(
                      requester: 'other',
                      tripType: 'Other rider',
                      tripDateTime: now.add(const Duration(hours: 1))),
                  Trip(
                      requester: 'me',
                      tripType: 'Cancelled ride',
                      tripStatus: 'Cancelled',
                      tripDateTime: now.add(const Duration(hours: 2))),
                  Trip(
                      requester: 'me',
                      tripType: 'Later ride',
                      tripDateTime: now.add(const Duration(days: 2))),
                  next,
                ]),
        routes: {
          '/viewrequest': (context) => Scaffold(
                body: Text((ModalRoute.of(context)!.settings.arguments as Trip)
                    .tripType!),
              ),
        },
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Next private ride'), 120);
    expect(find.text('Next trip'), findsOneWidget);
    expect(find.text('Other rider'), findsNothing);
    await tester.tap(find.text('Next private ride'));
    await tester.pumpAndSettle();
    expect(find.text('Next private ride'), findsOneWidget);
    expect(find.text('Next trip'), findsNothing);
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
      await tester.scrollUntilVisible(find.text('Send an item'), 100);
      expect(tester.takeException(), isNull);
      expect(find.text('Find transport'), findsWidgets);
    });
  }
}
