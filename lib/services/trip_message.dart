import 'package:kapame/models/trip.dart';

class TripMessage {
  String? tripId;
  String? tripMessageId;
  Trip? trip;
  String? sender;
  String? receiver;
  String? senderName;
  String? receiverName;
  String? message;
  DateTime? timestamp;

  TripMessage({
    this.tripId,
    this.tripMessageId,
    this.trip,
    this.sender,
    this.receiver,
    this.senderName,
    this.receiverName,
    this.message,
    this.timestamp,
  });

  factory TripMessage.fromMap(Map<String, dynamic> map) {
    return TripMessage(
      tripId: map['tripId']?.toString() ?? '',
      tripMessageId: (map['tripMessageId'] ?? map['messageId'])?.toString(),
      trip: map['trip'] is Map
          ? Trip.fromMap(Map<String, dynamic>.from(map['trip']))
          : null,
      sender: map['sender']?.toString() ?? '',
      receiver: map['receiver']?.toString() ?? '',
      senderName: map['senderName']?.toString(),
      receiverName: map['receiverName']?.toString(),
      message: map['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? ''),
    );
  }
}
