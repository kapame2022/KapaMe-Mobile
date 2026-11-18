// Opt-in review screenshots of production widgets; all data is synthetic.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:provider/provider.dart';
import 'package:kapame/services/new_user.dart';
import 'package:kapame/views/auth/register.dart';

void main() {
  testWidgets('capture registration-consistency review', (tester) async {
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
        final file = File('docs/registration-consistency/$name.png');
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
    final user = UserState()
      ..updateFullName('Lerato Mokoena')
      ..updateEmail('lerato@example.com')
      ..updatePhoneNumber('0825550142');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: user, child: app(const Register())));
    await capture('contact');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await capture('about-you');
    user.updateDateOfBirth(DateTime(1998, 6, 15));
    user.updateGender('Female');
    await tester.pumpAndSettle();
    // Choose gender through the control, which owns its field state.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await capture('security');
  }, skip: !const bool.fromEnvironment('CAPTURE_REVIEW'));
}
