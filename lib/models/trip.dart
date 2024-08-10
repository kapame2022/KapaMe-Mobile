class Trip {
  String? tripId;
  String? requester;
  String? transporter;
  String? tripType;
  String? tripStatus;
  TripLocationInfo? tripLocationInfo;
  String? contactDetailsPhoneNumber;
  String? contactDetailsEmail;
  String? tripPriority;
  String? tripScheduling;
  DateTime? tripLastingTime;
  DateTime? tripDateTime;
  GroupTransportDetails? groupTransport;
  ItemTransportDetails? itemTransport;

  Trip({
    this.tripId,
    this.requester,
    this.transporter,
    this.tripType,
    this.tripStatus,
    this.tripLocationInfo,
    this.contactDetailsPhoneNumber,
    this.contactDetailsEmail,
    this.tripPriority,
    this.tripScheduling,
    this.tripLastingTime,
    this.tripDateTime,
    this.groupTransport,
    this.itemTransport,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      tripId: map['tripId']?.toString() ?? '',
      requester: map['requester'],
      transporter: map['transporter'],
      tripType: map['tripType'],
      tripStatus: map['tripStatus'],
      tripLocationInfo: TripLocationInfo.fromMap(map['tripLocationInfo']),
      contactDetailsPhoneNumber: map['contactDetailsPhoneNumber'],
      contactDetailsEmail: map['contactDetailsEmail'],
      tripPriority: map['tripPriority'],
      tripScheduling: map['tripScheduling'],
      tripLastingTime: DateTime.parse(map['tripLastingTime']),
      tripDateTime: DateTime.parse(map['tripDateTime']),
      groupTransport: GroupTransportDetails.fromMap(map['groupTransport']),
      itemTransport: ItemTransportDetails.fromMap(map['itemTransport']),
    );
  }
}

class ItemTransportDetails {
  String? itemTransportId;
  String? description;

  ItemTransportDetails({this.itemTransportId, this.description});

  factory ItemTransportDetails.fromMap(Map<String, dynamic>? map) {
    return ItemTransportDetails(
      itemTransportId: map?['itemTransportId'],
      description: map?['description'],
    );
  }
}

class GroupTransportDetails {
  String? groupTransportId;
  int? numberOfPeople;

  GroupTransportDetails({this.groupTransportId, this.numberOfPeople});

  factory GroupTransportDetails.fromMap(Map<String, dynamic>? map) {
    return GroupTransportDetails(
      groupTransportId: map?['groupTransportId'],
      numberOfPeople: map?['numberOfPeople'],
    );
  }
}

class TripLocationInfo {
  String? pickUpAddress;
  String? pickUpLatitude;
  String? pickUpLongitude;
  String? destinationAddress;
  String? destinationLatitude;
  String? destinationLongitude;

  TripLocationInfo(
      {this.pickUpAddress,
      this.pickUpLatitude,
      this.pickUpLongitude,
      this.destinationAddress,
      this.destinationLatitude,
      this.destinationLongitude});

  factory TripLocationInfo.fromMap(Map<String, dynamic> map) {
    return TripLocationInfo(
        pickUpAddress: map['pickUpAddress'],
        pickUpLatitude: map['pickUpLatitude'],
        pickUpLongitude: map['pickUpLongitude'],
        destinationAddress: map['destinationAddress'],
        destinationLatitude: map['destinationLatitude'],
        destinationLongitude: map['destinationLongitude']);
  }
}
