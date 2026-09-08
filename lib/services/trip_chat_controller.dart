import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:kapame/services/trip_message_realtime.dart';

class TripConversation {
  const TripConversation(
      {required this.tripId, required this.otherUserId, required this.latest});
  final String tripId;
  final String otherUserId;
  final TripMessage latest;
  String get key => '${tripId.toLowerCase()}/${otherUserId.toLowerCase()}';
  String get title =>
      latest.trip?.tripLocationInfo?.destinationAddress ?? 'Trip conversation';
}

class TripChatController extends ChangeNotifier {
  TripChatController(
      {required this.userId, required this.api, required this.realtime});
  final String userId;
  final TripMessageApi api;
  final TripMessageRealtime realtime;
  final Map<String, TripMessage> _messages = {};
  final Map<String, String> _names = {};
  final Map<String, String> _tripNames = {};
  final Set<String> _watchedTrips = {};
  StreamSubscription<TripMessage?>? _messageSubscription;
  StreamSubscription<ChatConnection>? _connectionSubscription;
  bool _disposed = false;
  bool _started = false;
  Future<void>? _refreshing;
  bool loading = false;
  String? error;
  ChatConnection connection = ChatConnection.connecting;

  // Restored logins currently store only a JWT. This extracts the display/query
  // identity; the server remains responsible for validating the token.
  static String? userIdFromToken(String token) {
    try {
      final payload = jsonDecode(utf8
          .decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
      return (payload[
                  'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
              payload['nameid'] ??
              payload['sub'])
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  static bool _same(String? a, String? b) =>
      a?.toLowerCase() == b?.toLowerCase();
  static bool _validId(String? id) =>
      id != null &&
      id.isNotEmpty &&
      id != '00000000-0000-0000-0000-000000000000';
  bool _belongs(TripMessage message) =>
      _validId(message.tripId) &&
      _validId(message.sender) &&
      _validId(message.receiver) &&
      (_same(message.sender, userId) || _same(message.receiver, userId));

  String _key(TripMessage message) => message.tripMessageId?.isNotEmpty == true
      ? message.tripMessageId!.toLowerCase()
      : jsonEncode([
          message.tripId,
          message.sender,
          message.receiver,
          message.timestamp?.toIso8601String(),
          message.message
        ]);

  void _merge(Iterable<TripMessage> messages) {
    if (_disposed) return;
    for (final message in messages) {
      if (!_belongs(message)) continue;
      message.trip ??= _messages[_key(message)]?.trip;
      if (message.trip != null) _rememberTrip(message.trip!);
      for (final entry in {
        message.sender!: message.senderName,
        message.receiver!: message.receiverName,
      }.entries) {
        if (entry.value?.trim().isNotEmpty == true) {
          _names[entry.key.toLowerCase()] = entry.value!.trim();
        }
      }
      _messages[_key(message)] = message;
    }
    notifyListeners();
  }

  List<TripMessage> messagesFor(String tripId, String otherUserId) {
    return messagesWith(otherUserId)
        .where((m) => _same(m.tripId, tripId))
        .toList();
  }

  String contactName(String userId) =>
      _tripNames[userId.toLowerCase()] ??
      _names[userId.toLowerCase()] ??
      'Trip contact';

  void _rememberTrip(Trip trip) {
    for (final entry in {
      trip.requester: trip.requesterName,
      trip.transporter: trip.transporterName,
    }.entries) {
      if (_validId(entry.key) && entry.value?.trim().isNotEmpty == true) {
        _tripNames[entry.key!.toLowerCase()] = entry.value!.trim();
      }
    }
  }

  void registerTrip(Trip trip) {
    if (_disposed) return;
    _rememberTrip(trip);
    notifyListeners();
  }

  List<TripMessage> messagesWith(String otherUserId) {
    final result = _messages.values
        .where((m) =>
            ((_same(m.sender, userId) && _same(m.receiver, otherUserId)) ||
                (_same(m.receiver, userId) && _same(m.sender, otherUserId))))
        .toList();
    result.sort((a, b) {
      final time = (a.timestamp ?? DateTime(1970))
          .compareTo(b.timestamp ?? DateTime(1970));
      return time != 0 ? time : _key(a).compareTo(_key(b));
    });
    return result;
  }

  List<TripConversation> get conversations {
    final grouped = <String, TripConversation>{};
    for (final message in _messages.values) {
      final other =
          _same(message.sender, userId) ? message.receiver! : message.sender!;
      final candidate = TripConversation(
          tripId: message.tripId!, otherUserId: other, latest: message);
      final previous = grouped[candidate.key];
      if (previous == null ||
          (message.timestamp ?? DateTime(1970))
              .isAfter(previous.latest.timestamp ?? DateTime(1970))) {
        grouped[candidate.key] = candidate;
      }
    }
    return grouped.values.toList()
      ..sort((a, b) => (b.latest.timestamp ?? DateTime(1970))
          .compareTo(a.latest.timestamp ?? DateTime(1970)));
  }

  /// One inbox row per person, keeping their latest trip for new replies.
  List<TripConversation> get contacts {
    final seen = <String>{};
    return conversations
        .where(
            (conversation) => seen.add(conversation.otherUserId.toLowerCase()))
        .toList();
  }

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _messageSubscription = realtime.messages.listen((message) {
      if (message == null || !_validId(message.receiver)) {
        unawaited(_recover());
      } else {
        _merge([message]);
      }
    });
    _connectionSubscription = realtime.connection.listen((status) {
      if (_disposed) return;
      connection = status;
      notifyListeners();
    });
    unawaited(realtime.start());
    await refresh();
  }

  Future<void> refresh() {
    if (_disposed) return Future.value();
    return _refreshing ??= _load().whenComplete(() => _refreshing = null);
  }

  Future<void> _recover() async {
    final alreadyLoading = _refreshing != null;
    await refresh();
    // A request started before reconnect may have missed messages sent during
    // the gap. Fetch once more after that older request has completed.
    if (alreadyLoading && !_disposed) await refresh();
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _merge(await api.forSender(userId));
      // Rejoin active trips on reconnection, then fetch to fill any delivery gap.
      for (final tripId in _watchedTrips.toList()) {
        if (_disposed) break;
        await _join(tripId);
        _merge(await api.forTrip(tripId));
      }
    } catch (_) {
      if (!_disposed) error = 'Could not refresh messages. Pull down to retry.';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _join(String tripId) async {
    try {
      await realtime.joinTrip(tripId);
    } catch (_) {
      // History remains available even if the live connection is unavailable.
    }
  }

  Future<void> openConversation(String tripId) async {
    if (_disposed) return;
    _watchedTrips.add(tripId);
    await _join(tripId);
    try {
      final messages = await api.forTrip(tripId);
      if (_disposed) return;
      error = null;
      _merge(messages);
    } catch (_) {
      if (!_disposed) {
        error = 'Could not load the conversation. Tap refresh to retry.';
        notifyListeners();
      }
    }
  }

  Future<TripMessage> send(String tripId, String receiver, String text) async {
    if (!_validId(tripId) || !_validId(receiver) || text.trim().isEmpty) {
      throw ArgumentError('A trip, recipient, and message are required.');
    }
    final message = await api.send(
        tripId: tripId, sender: userId, receiver: receiver, text: text);
    if (!_belongs(message) ||
        !_same(message.tripId, tripId) ||
        !_same(message.sender, userId) ||
        !_same(message.receiver, receiver)) {
      throw const FormatException('Invalid message recipient.');
    }
    _merge([
      message
    ]); // The hub echo uses the same ID and is merged, not appended.
    return message;
  }

  @override
  void dispose() {
    _disposed = true;
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(realtime.dispose());
    api.dispose();
    super.dispose();
  }
}
