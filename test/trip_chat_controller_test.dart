import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:kapame/services/trip_message_realtime.dart';
import 'package:kapame/services/trip_chat_controller.dart';
import 'package:kapame/views/home/messages.dart';

class FakeRealtime implements TripMessageRealtime {
  final events = StreamController<TripMessage?>.broadcast();
  final states = StreamController<ChatConnection>.broadcast();
  final joined = <String>[];
  @override
  Stream<TripMessage?> get messages => events.stream;
  @override
  Stream<ChatConnection> get connection => states.stream;
  @override
  Future<void> start() async {
    states.add(ChatConnection.connected);
  }

  @override
  Future<void> joinTrip(String tripId) async {
    joined.add(tripId);
  }

  @override
  Future<void> dispose() async {
    await events.close();
    await states.close();
  }
}

Map<String, dynamic> message(
  String id,
  String sender,
  String receiver, {
  String trip = 'trip-a',
  int minute = 0,
  String text = 'Hello',
}) =>
    {
      'tripMessageId': id,
      'tripId': trip,
      'sender': sender,
      'receiver': receiver,
      'senderName': sender == 'bob' ? 'Bob' : sender,
      'receiverName': receiver == 'bob' ? 'Bob' : receiver,
      'message': text,
      'timestamp': DateTime.utc(2026, 9, 5, 12, minute).toIso8601String()
    };

void main() {
  late Dio dio;
  late FakeRealtime live;
  late TripChatController controller;
  late List<RequestOptions> requests;
  dynamic history;
  dynamic tripHistory;
  Object? failure;
  Completer<Response>? pending;

  setUp(() {
    requests = [];
    history = [];
    tripHistory = [];
    failure = null;
    pending = null;
    dio = Dio();
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      requests.add(options);
      if (failure != null) {
        handler.reject(DioException(requestOptions: options, error: failure));
        return;
      }
      if (pending != null && options.method == 'GET') {
        handler.resolve(await pending!.future);
        return;
      }
      if (options.method == 'POST') {
        final saved = message(
            'sent-id', options.data['sender'], options.data['receiver'],
            trip: options.data['tripId'],
            text: options.data['message'],
            minute: 10);
        // Simulate SignalR reaching the client before the POST response.
        live.events.add(TripMessage.fromMap(saved));
        handler.resolve(
            Response(requestOptions: options, statusCode: 201, data: saved));
      } else {
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: options.path.contains('/senders/') ? history : tripHistory));
      }
    }));
    live = FakeRealtime();
    controller = TripChatController(
        userId: 'alice',
        api: TripMessageApi(token: () => 'test-token', dio: dio),
        realtime: live);
  });
  tearDown(() => controller.dispose());

  test('loads grouped history in both directions and scopes by trip and pair',
      () async {
    history = [
      [message('2', 'bob', 'alice', minute: 2), message('1', 'alice', 'bob')],
      [message('3', 'alice', 'carol', minute: 3)],
      [message('4', 'bob', 'alice', trip: 'trip-b', minute: 4)],
      [message('5', 'carol', 'dave')],
    ];
    await controller.start();
    expect(requests.first.path, endsWith('/api/tripmessages/senders/alice'));
    expect(requests.first.headers['Authorization'], 'Bearer test-token');
    expect(controller.messagesFor('trip-a', 'bob').map((m) => m.tripMessageId),
        ['1', '2']);
    expect(controller.conversations, hasLength(3));
    expect(controller.contacts, hasLength(2));
    expect(controller.messagesWith('bob'), hasLength(3));
    expect(controller.contactName('bob'), 'Bob');
    expect(controller.conversations.first.tripId, 'trip-b');
  });

  test('REST send includes receiver and hub echo is deduplicated', () async {
    await controller.start();
    await controller.send('trip-a', 'bob', '  On my way  ');
    await Future<void>.delayed(Duration.zero);
    expect(controller.messagesFor('trip-a', 'bob'), hasLength(1));
    final post = requests.lastWhere((r) => r.method == 'POST');
    expect(post.data, {
      'tripId': 'trip-a',
      'sender': 'alice',
      'receiver': 'bob',
      'message': 'On my way'
    });
    live.events.add(TripMessage.fromMap(message('outsider', 'bob', 'carol')));
    await Future<void>.delayed(Duration.zero);
    expect(controller.conversations, hasLength(1));
  });

  test('received-only conversation uses the sender name from the trip',
      () async {
    history = [
      {
        ...message('incoming', 'bob', 'alice'),
        'trip': {
          'tripId': 'trip-a',
          'requester': 'bob',
          'requesterName': 'Bongani Nkosi',
          'transporter': 'alice',
          'transporterName': 'Alice Driver',
          'tripDateTime': null,
          'tripLastingTime': null,
          'tripLocationInfo': null,
        },
      },
    ];
    await controller.start();
    expect(controller.contacts.single.otherUserId, 'bob');
    expect(controller.messagesWith('bob').single.receiver, 'alice');
    expect(controller.contactName('bob'), 'Bongani Nkosi');
    // A hub update without the trip must not replace the trip-derived name.
    live.events.add(TripMessage.fromMap(message('incoming', 'bob', 'alice')));
    await Future<void>.delayed(Duration.zero);
    expect(controller.contactName('bob'), 'Bongani Nkosi');
    expect(controller.messagesWith('bob').single.trip!.requesterName,
        'Bongani Nkosi');
  });

  test('outgoing conversation uses the recipient trip participant name',
      () async {
    history = [
      {
        ...message('outgoing', 'alice', 'bob'),
        'trip': {
          'tripId': 'trip-a',
          'requester': 'alice',
          'requesterName': 'Alice',
          'transporter': 'BOB',
          'transporterName': 'Bongani Driver'
        },
      }
    ];
    await controller.start();
    expect(controller.contacts.single.otherUserId, 'bob');
    expect(controller.contactName('bob'), 'Bongani Driver');
  });

  test('trip map provides a contact name before any messages exist', () {
    controller
        .registerTrip(Trip(requester: 'bob', requesterName: 'Bongani Nkosi'));
    expect(controller.contactName('bob'), 'Bongani Nkosi');
    expect(controller.contactName('carol'), 'Trip contact');
    expect(controller.contacts, isEmpty);
  });

  test('reconnect rejoins active trip and recovers missed incoming history',
      () async {
    await controller.start();
    await controller.openConversation('trip-a');
    tripHistory = [message('missed', 'bob', 'alice')];
    live.events.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(live.joined, ['trip-a', 'trip-a']);
    expect(
        controller.messagesFor('trip-a', 'bob').single.tripMessageId, 'missed');
  });

  test('history completion does not discard a newer live event', () async {
    pending = Completer<Response>();
    final loading = controller.start();
    await Future<void>.delayed(Duration.zero);
    live.events
        .add(TripMessage.fromMap(message('new', 'bob', 'alice', minute: 3)));
    await Future<void>.delayed(Duration.zero);
    pending!.complete(Response(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: [message('old', 'alice', 'bob')]));
    await loading;
    expect(controller.messagesFor('trip-a', 'bob').map((m) => m.tripMessageId),
        ['old', 'new']);
  });

  test('a history failure keeps existing messages and exposes retry', () async {
    history = [message('old', 'alice', 'bob')];
    await controller.start();
    failure = Exception('offline');
    await controller.refresh();
    expect(controller.error, isNotNull);
    expect(controller.messagesFor('trip-a', 'bob'), hasLength(1));
    expect(controller.loading, isFalse);
  });

  test('parses nullable trip and SignalR messageId alias', () {
    final parsed = TripMessage.fromMap({'messageId': 'event-id', 'trip': null});
    expect(parsed.tripMessageId, 'event-id');
    expect(parsed.trip, isNull);
    expect(parsed.timestamp, isNull);
  });

  testWidgets('inbox groups by person and opens their history across trips',
      (tester) async {
    history = [
      {
        ...message('first', 'bob', 'alice',
            minute: 2, text: 'Meet at the entrance'),
        'trip': {
          'tripId': 'trip-a',
          'requester': 'bob',
          'requesterName': 'Bongani Nkosi',
          'transporter': 'alice',
          'transporterName': 'Alice'
        },
      },
      message('previous', 'bob', 'alice',
          trip: 'older-trip', text: 'Previous trip message'),
    ];
    tripHistory = [history.first];
    await tester
        .pumpWidget(MaterialApp(home: Messages(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('Bongani Nkosi'), findsOneWidget);
    expect(find.text('Previous trip message'), findsNothing);
    await tester.tap(find.text('Meet at the entrance'));
    await tester.pumpAndSettle();
    expect(find.text('Chat preview · Messages are not sent'), findsNothing);
    expect(find.text('Meet at the entrance'), findsOneWidget);
    expect(find.text('Previous trip message'), findsOneWidget);
    live.events.add(TripMessage.fromMap(
        message('reply', 'bob', 'alice', minute: 5, text: 'I have arrived')));
    await tester.pumpAndSettle();
    expect(find.text('I have arrived'), findsOneWidget);
    expect(find.text('Bongani Nkosi'), findsOneWidget);
    live.events.add(TripMessage.fromMap(
        message('other', 'carol', 'alice', text: 'Other conversation')));
    await tester.pumpAndSettle();
    expect(find.text('Other conversation'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
