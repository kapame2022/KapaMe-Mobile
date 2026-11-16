// Generate review screenshots with CAPTURE_REVIEW=true (see docs/clear-blue.md).
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/home/home.dart';
import 'package:kapame/views/home/settings.dart';
import 'package:kapame/views/home/trip_history.dart';
import 'package:kapame/views/trips/chat.dart';
import 'package:provider/provider.dart';
import 'package:kapame/views/trips/private_commuter.dart';
import 'package:kapame/views/home/messages.dart';
import 'package:kapame/services/trip_chat_controller.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:dio/dio.dart';
import 'trip_chat_controller_test.dart' show FakeRealtime;

void main() {
  testWidgets('capture Clear Blue review screens', (tester) async {
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      final loader = FontLoader('Roboto');
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)));
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(File(
                '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await icons.load();
    });
    tester.view.physicalSize = const Size(396, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthUserState();
    await auth.updateAuthUser(
        inAppUser: AppUser(
            id: 'me', fullName: 'Lerato Mokoena', email: 'lerato@example.com'));
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/clear-blue/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> mount(Widget child) =>
        tester.pumpWidget(ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp(
                theme: ClearBlue.theme,
                builder: (context, navigator) =>
                    RepaintBoundary(key: boundary, child: navigator!),
                home: child)));
    Directory('docs/clear-blue').createSync(recursive: true);
    await mount(const HomeContent(name: 'Lerato Mokoena'));
    await capture('home-find');
    await tester.tap(find.text('Offer transport'));
    await capture('home-offer');
    await mount(TripHistory(
        loadTrips: () async => [
              Trip(
                  requester: 'me',
                  tripType: 'Private ride',
                  tripStatus: 'Requested',
                  tripDateTime: DateTime(2030, 11, 19, 8, 30),
                  tripLocationInfo: TripLocationInfo(
                      pickUpAddress: 'Hatfield, Pretoria',
                      destinationAddress: 'Menlyn Mall'))
            ]));
    await capture('trips');
    await mount(const Settings());
    await capture('profile');
    await mount(Chat(
        recipientName: 'Thabo M.',
        tripLabel: 'Hatfield to Menlyn Mall',
        onSend: (text) async => TripMessage(message: text),
        initialMessages: [
          TripMessage(
              sender: 'other',
              message: 'Hi Lerato, I’m at the main entrance.',
              timestamp: DateTime(2026, 11, 16, 9, 38)),
          TripMessage(
              sender: 'me',
              message: 'Perfect. I’ll meet you there shortly.',
              timestamp: DateTime(2026, 11, 16, 9, 39))
        ]));
    await capture('chat');
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: options.path.contains('/senders/')
                ? [
                    {
                      'tripMessageId': 'fixture',
                      'tripId': 'trip',
                      'sender': 'thabo',
                      'senderName': 'Thabo M.',
                      'receiver': 'me',
                      'receiverName': 'Lerato Mokoena',
                      'message': 'I’ll meet you at the entrance.',
                      'timestamp': '2026-11-16T09:38:00Z'
                    },
                  ]
                : []));
      }));
    final controller = TripChatController(
        userId: 'me',
        api: TripMessageApi(token: () => 'fixture', dio: dio),
        realtime: FakeRealtime());
    await mount(Messages(controller: controller));
    await capture('messages');
    await mount(const SizedBox());
    controller.dispose();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('lyokone/location'), (_) async => 0);
    messenger.setMockMessageHandler('plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    await mount(const PrivateCommuter());
    await capture('map-awaiting-location');
    await tester.tap(find.text('Plan your journey'));
    await capture('booking-form');
  }, skip: !const bool.fromEnvironment('CAPTURE_REVIEW'));
}
