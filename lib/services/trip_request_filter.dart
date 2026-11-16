import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_chat_controller.dart';

/// Filters requests before they are used by map markers and search filters.
List<Trip> filterTripRequests(
  Iterable<Trip> trips, {
  required String tripType,
  required AuthUserState auth,
}) {
  final profileId = auth.appUser?.id?.trim();
  final userId = (profileId?.isNotEmpty == true
          ? profileId
          : TripChatController.userIdFromToken(auth.token ?? ''))
      ?.trim()
      .toLowerCase();

  return trips.where((trip) {
    final isOwnRequest = userId != null &&
        userId.isNotEmpty &&
        trip.requester?.trim().toLowerCase() == userId;
    return trip.tripType == tripType && !isOwnRequest;
  }).toList();
}
