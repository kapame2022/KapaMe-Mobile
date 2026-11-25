// Opt-in review screenshots of production widgets; all data is synthetic.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/trips/private_commuter.dart';

void main() {
  testWidgets('capture focused-trip-pages review', (tester) async {
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      final font = FontLoader('Roboto');
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        font.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf')
                .readAsBytes()
                .then(ByteData.sublistView));
      }
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(File(
                '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView));
      await icons.load();
    });
    tester.view.physicalSize = const Size(396, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/focused-trip-pages/$name.png');
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Widget app(Widget child) => MaterialApp(
        theme: ClearBlue.theme,
        builder: (context, navigator) =>
            RepaintBoundary(key: boundary, child: navigator!),
        home: child);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('lyokone/location'), (_) async => 0);
    messenger.setMockMessageHandler('plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    await tester.pumpWidget(app(const PrivateCommuter()));
    await capture('private-ride');
  }, skip: !const bool.fromEnvironment('CAPTURE_REVIEW'));
}
