import 'dart:async';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:signalr_netcore/signalr_client.dart';

enum ChatConnection { connecting, connected, reconnecting, offline }

abstract class TripMessageRealtime {
  Stream<TripMessage?> get messages;
  Stream<ChatConnection> get connection;
  Future<void> start();
  Future<void> joinTrip(String tripId);
  Future<void> dispose();
}

class SignalRTripMessages implements TripMessageRealtime {
  SignalRTripMessages({required String Function() token}) {
    _hub = HubConnectionBuilder()
        .withUrl('${TripMessageApi.baseUrl}/tripmessage',
            options:
                HttpConnectionOptions(accessTokenFactory: () async => token()))
        .withAutomaticReconnect()
        .build();
    _hub.on('ReceiveMessage', (arguments) {
      if (_disposed) return;
      final payload = arguments?.isNotEmpty == true ? arguments!.first : null;
      try {
        _messages.add(payload is Map
            ? TripMessage.fromMap(Map<String, dynamic>.from(payload))
            : null);
      } catch (_) {
        _messages
            .add(null); // Recover from a changed event shape using history.
      }
    });
    _hub.onreconnecting(({error}) => _status(ChatConnection.reconnecting));
    _hub.onreconnected(({connectionId}) {
      _joined.clear();
      _status(ChatConnection.connected);
      if (!_disposed) {
        _messages.add(null); // Rejoin groups and recover missed messages.
      }
    });
    _hub.onclose(({error}) {
      _joined.clear();
      _status(ChatConnection.offline);
      _retry();
    });
  }

  late final HubConnection _hub;
  final _messages = StreamController<TripMessage?>.broadcast();
  final _connection = StreamController<ChatConnection>.broadcast();
  final _joined = <String>{};
  Timer? _retryTimer;
  bool _disposed = false;
  bool _starting = false;

  @override
  Stream<TripMessage?> get messages => _messages.stream;
  @override
  Stream<ChatConnection> get connection => _connection.stream;

  void _status(ChatConnection status) {
    if (!_disposed) _connection.add(status);
  }

  void _retry() {
    if (_disposed || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(const Duration(seconds: 5), () => unawaited(start()));
  }

  @override
  Future<void> start() async {
    if (_disposed ||
        _starting ||
        _hub.state != HubConnectionState.Disconnected) {
      return;
    }
    _starting = true;
    _status(ChatConnection.connecting);
    try {
      await _hub.start();
      if (_disposed) {
        await _hub.stop();
        return;
      }
      _status(ChatConnection.connected);
      _messages.add(null);
    } catch (_) {
      _status(ChatConnection.offline);
      _retry();
    } finally {
      _starting = false;
    }
  }

  @override
  Future<void> joinTrip(String tripId) async {
    if (_disposed ||
        _hub.state != HubConnectionState.Connected ||
        _joined.contains(tripId)) {
      return;
    }
    await _hub.invoke('JoinGroup', args: [tripId]);
    _joined.add(tripId);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    _hub.off('ReceiveMessage');
    try {
      await _hub.stop();
    } catch (_) {
      // The transport may already be gone when a page/session is disposed.
    }
    await _messages.close();
    await _connection.close();
  }
}
