import 'package:dio/dio.dart';
import 'package:kapame/services/trip_message.dart';

class TripMessageApi {
  TripMessageApi({required this.token, Dio? dio}) : _dio = dio ?? Dio();

  static const baseUrl = 'https://kapameapi.azurewebsites.net';
  final String Function() token;
  final Dio _dio;

  Options get _options =>
      Options(headers: {'Authorization': 'Bearer ${token()}'});

  Future<List<TripMessage>> forSender(String sender) async {
    final response = await _dio.get(
      '$baseUrl/api/tripmessages/senders/${Uri.encodeComponent(sender)}',
      options: _options,
    );
    return _parse(response.data);
  }

  Future<List<TripMessage>> forTrip(String tripId) async {
    final response = await _dio.get(
      '$baseUrl/api/tripmessages/${Uri.encodeComponent(tripId)}',
      options: _options,
    );
    return _parse(response.data);
  }

  // Accept both the original arrays grouped by receiver and the flat API list.
  List<TripMessage> _parse(dynamic data) {
    if (data is! List) throw const FormatException('Invalid message history.');
    final messages = <TripMessage>[];
    for (final item in data) {
      if (item is List) {
        messages.addAll(_parse(item));
      } else if (item is Map) {
        messages.add(TripMessage.fromMap(Map<String, dynamic>.from(item)));
      } else {
        throw const FormatException('Invalid message in history.');
      }
    }
    return messages;
  }

  Future<TripMessage> send({
    required String tripId,
    required String sender,
    required String receiver,
    required String text,
  }) async {
    final response = await _dio.post(
      '$baseUrl/api/tripmessages',
      options: _options,
      data: {
        'tripId': tripId,
        'sender': sender,
        'receiver': receiver,
        'message': text.trim()
      },
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid send response.');
    }
    return TripMessage.fromMap(Map<String, dynamic>.from(response.data));
  }

  void dispose() => _dio.close();
}
