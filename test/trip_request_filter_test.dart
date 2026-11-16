import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_request_filter.dart';

void main() {
  for (final type in [
    'Private Commute',
    'Public Commute',
    'Group Transport',
    'Item Transport',
  ]) {
    test('$type excludes own requests and preserves other requesters',
        () async {
      final auth = AuthUserState();
      await auth.updateAuthUser(inAppUser: AppUser(id: 'USER'));
      final own = Trip(requester: 'user', tripType: type);
      final other = Trip(requester: 'other', tripType: type);
      final wrongType = Trip(requester: 'other', tripType: 'Other');

      expect(
          filterTripRequests([own, other, wrongType],
              tripType: type, auth: auth),
          [other]);
      auth.dispose();
    });
  }

  test('restored token-only session excludes own requests', () {
    final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': 'user'})));
    final auth = AuthUserState(inToken: 'header.$payload.signature');
    final own = Trip(requester: 'USER', tripType: 'Group Transport');
    final other = Trip(requester: 'other', tripType: 'Group Transport');

    expect(
        filterTripRequests([own, other],
            tripType: 'Group Transport', auth: auth),
        [other]);
    auth.dispose();
  });
}
