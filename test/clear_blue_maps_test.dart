import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/trips/private_commuter.dart';
import 'package:kapame/views/trips/public_commuter.dart';
import 'package:kapame/views/trips/group_transport.dart';
import 'package:kapame/views/trips/item_transport.dart';
import 'package:kapame/views/trips/private_driver.dart';
import 'package:kapame/views/trips/public_driver.dart';
import 'package:kapame/views/trips/group_transporter.dart';
import 'package:kapame/views/trips/item_transporter.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('lyokone/location'),
        (call) async => call.method == 'getLocation'
            ? await Completer<Map<String, dynamic>>().future
            : 0);
    messenger.setMockMessageHandler('plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
  });
  for (final scale in [1.0, 2.0]) {
    for (final entry in <(String, Widget, bool)>[
      ('/privatecommuter', const PrivateCommuter(), false),
      ('/publiccommuter', const PublicCommuter(), false),
      ('/grouptransport', const GroupTransport(), false),
      ('/itemtransport', const ItemTransport(), false),
      ('/privatedriver', const PrivateDriver(), true),
      ('/publicdriver', const PublicDriver(), true),
      ('/grouptransporter', const GroupTransporter(), true),
      ('/itemtransporter', const ItemTransporter(), true),
    ]) {
      testWidgets(
          '${entry.$1} opens its form with keyboard at text scale $scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(MaterialApp(
            theme: ClearBlue.theme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            initialRoute: entry.$1,
            routes: {entry.$1: (_) => entry.$2}));
        await tester.pumpAndSettle();
        expect(find.byType(MapActionPanel), findsOneWidget);
        await tester.ensureVisible(
            find.text(entry.$3 ? 'Filter requests' : 'Plan your journey'));
        await tester
            .tap(find.text(entry.$3 ? 'Filter requests' : 'Plan your journey'));
        await tester.pumpAndSettle();
        expect(find.byType(Form), findsOneWidget);
        tester.view.viewInsets = FakeViewPadding(bottom: 220);
        await tester.pumpAndSettle();
        await tester.drag(
            find.byType(SingleChildScrollView).last, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
