import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/home/trip_history.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'trip tabs keep ownership, cache loading and open the selected route',
      (tester) async {
    var loads = 0;
    final upcoming = Trip(
        requester: 'me',
        tripType: 'My upcoming ride',
        tripDateTime: DateTime.now().add(const Duration(days: 2)),
        tripStatus: 'Requested');
    final auth = AuthUserState();
    await auth.updateAuthUser(inAppUser: AppUser(id: 'me'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
            theme: ClearBlue.theme,
            home: TripHistory(loadTrips: () async {
              loads++;
              return [
                upcoming,
                Trip(
                    requester: 'someone-else', tripType: 'Someone else’s ride'),
                Trip(
                    transporter: 'ME',
                    tripType: 'My past ride',
                    tripStatus: 'Completed')
              ];
            }),
            routes: {
              '/viewrequest': (context) => Scaffold(
                  body: Text(
                      (ModalRoute.of(context)!.settings.arguments! as Trip)
                          .tripType!))
            })));
    await tester.pumpAndSettle();
    expect(find.text('My upcoming ride'), findsOneWidget);
    expect(find.text('Someone else’s ride'), findsNothing);
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('My past ride'), findsOneWidget);
    expect(find.text('My upcoming ride'), findsNothing);
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(loads, 1);
    await tester.tap(find.text('My upcoming ride'));
    await tester.pumpAndSettle();
    expect(find.byType(TripSummaryCard), findsNothing);
    expect(find.text('My upcoming ride'), findsOneWidget);
  });

  testWidgets('trips recover from a load failure', (tester) async {
    var calls = 0;
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AuthUserState(),
        child: MaterialApp(
            theme: ClearBlue.theme,
            home: TripHistory(loadTrips: () async {
              if (calls++ == 0) throw Exception('offline');
              return [];
            }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No upcoming trips yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
