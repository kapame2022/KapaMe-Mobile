import 'package:flutter/material.dart';

import '../models/trip.dart';

class TripState extends ChangeNotifier {
  String _requester = '';
  String _transporter = '';
  String _tripType = '';
  String _tripStatus = '';
  TripLocationInfo _tripLocationInfo = TripLocationInfo();
  String _contactDetailsPhoneNumber = '';
  String _contactDetailsEmail = '';
  String _tripPriority = '';
  String _tripScheduling = '';
  DateTime _tripLastingTime = DateTime.now();
  DateTime _tripDateTime = DateTime.now();
  GroupTransportDetails _groupTransport = GroupTransportDetails();
  ItemTransportDetails _itemTransport = ItemTransportDetails();

  String get requester => _requester;
  String get transporter => _transporter;
  String get tripType => _tripType;
  String get tripStatus => _tripStatus;
  TripLocationInfo get tripLocationInfo => _tripLocationInfo;
  String get contactDetailsPhoneNumber => _contactDetailsPhoneNumber;
  String get contactDetailsEmail => _contactDetailsEmail;
  String get tripPriority => _tripPriority;
  String get tripScheduling => _tripScheduling;
  DateTime get tripLastingTime => _tripLastingTime;
  DateTime get tripDateTime => _tripDateTime;
  GroupTransportDetails get groupTransport => _groupTransport;
  ItemTransportDetails get itemTransport => _itemTransport;

  void updateRequester(String newRequester) {
    _requester = newRequester;
    notifyListeners();
  }

  void updateTransporter(String newTransporter) {
    _transporter = newTransporter;
    notifyListeners();
  }

  void updateTripType(String newTripType) {
    _tripType = newTripType;
    notifyListeners();
  }

  void updateTripStatus(String newTripStatus) {
    _tripStatus = newTripStatus;
    notifyListeners();
  }

  void updateTripLocationInfo(TripLocationInfo newTripLocationInfo) {
    _tripLocationInfo = newTripLocationInfo;
    notifyListeners();
  }
}
