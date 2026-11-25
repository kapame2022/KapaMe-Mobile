import 'package:dio/dio.dart';
import 'package:kapame/models/trip.dart';

bool tripBelongsTo(Trip trip, String? userId) {
  final id = userId?.toLowerCase();
  return id != null &&
      id.isNotEmpty &&
      (trip.requester?.toLowerCase() == id ||
          trip.transporter?.toLowerCase() == id);
}

bool isPastTrip(Trip trip, DateTime now) {
  const closedStatuses = {'completed', 'cancelled', 'canceled', 'expired'};
  return closedStatuses.contains(trip.tripStatus?.trim().toLowerCase()) ||
      (trip.tripDateTime?.isBefore(now) ?? false);
}

int compareUpcomingTrips(Trip a, Trip b) {
  final first = a.tripDateTime;
  final second = b.tripDateTime;
  if (first == null) return second == null ? 0 : 1;
  if (second == null) return -1;
  return first.compareTo(second);
}

Future<List<Trip>> loadOwnedTrips({
  required String? userId,
  required String? token,
}) async {
  if (userId == null || userId.isEmpty) return [];
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  try {
    final response = await dio.get<List<dynamic>>(
      'https://kapameapi.azurewebsites.net/api/trips',
      options: Options(headers: {
        if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
      }),
    );
    return (response.data ?? [])
        .map((item) => Trip.fromMap(Map<String, dynamic>.from(item as Map)))
        .where((trip) => tripBelongsTo(trip, userId))
        .toList();
  } finally {
    dio.close();
  }
}
