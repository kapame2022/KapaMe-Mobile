// Opt-in review screenshots of production widgets; all data is synthetic.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:provider/provider.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/views/home/edit_profile.dart';

void main() {
  testWidgets('capture profile-edit-consistency review', (tester) async {
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
        final file = File('docs/profile-edit-consistency/$name.png');
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
    final auth = AuthUserState();
    await auth.updateAuthUser(
        inAppUser: AppUser(
            id: 'fixture',
            fullName: 'Lerato Mokoena',
            email: 'lerato@example.com',
            phoneNumber: '0825550142'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth, child: app(const EditProfile())));
    await capture('account-details');
    await tester.enterText(find.byType(TextFormField).first, 'Lerato M.');
    await tester.pump();
    await tester.tap(find.byTooltip('Back to profile'));
    await capture('unsaved-changes');
  }, skip: !const bool.fromEnvironment('CAPTURE_REVIEW'));
}
