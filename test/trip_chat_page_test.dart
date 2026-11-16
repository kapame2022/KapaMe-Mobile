import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/views/trips/trip_chat_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('own unassigned request explains why chat is unavailable',
      (tester) async {
    final auth = AuthUserState(inToken: 'test-token');
    await auth.updateAuthUser(inAppUser: AppUser(id: 'requester'));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        home: TripChatPage(
          trip: Trip(tripId: 'trip', requester: 'REQUESTER'),
        ),
      ),
    ));

    expect(find.textContaining('You created this request.'), findsOneWidget);
    expect(find.textContaining('You cannot start a chat with yourself.'),
        findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
