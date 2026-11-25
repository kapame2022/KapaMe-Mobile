import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/views/trips/review_trip_request.dart';

void main() {
  testWidgets('review sends only on confirmation and keeps details for retry',
      (tester) async {
    final dio = Dio();
    addTearDown(dio.close);
    const payload = <String, dynamic>{
      'tripType': 'Group Transport',
      'tripLocationInfo': {
        'pickUpAddress': 'Rosebank',
        'destinationAddress': 'Sandton'
      },
      'groupTransport': {'numberOfPeople': '5'},
    };
    var calls = 0;
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      if (++calls == 1) {
        handler.reject(DioException(requestOptions: options));
      } else {
        handler
            .resolve(Response<void>(requestOptions: options, statusCode: 201));
      }
    }));
    await tester.pumpWidget(MaterialApp(
      theme: ClearBlue.theme,
      home: ReviewTripRequest(request: payload, token: 'test-token', dio: dio),
      routes: {
        '/triphistory': (_) => const Scaffold(body: Text('Upcoming trips'))
      },
    ));
    expect(calls, 0);
    expect(find.text('Passengers: 5'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Request trip');
    await tester.scrollUntilVisible(submit, 100);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Rosebank'), findsOneWidget);
    expect(find.textContaining('Couldn’t send your request'), findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(requests.last.data, payload);
    expect(requests.last.headers['Authorization'], 'Bearer test-token');
    expect(find.text('Request sent'), findsOneWidget);
    await tester.tap(find.text('See upcoming trips'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming trips'), findsOneWidget);
  });
}
