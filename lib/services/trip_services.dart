import 'package:dio/dio.dart';
import 'package:kapame/models/trip.dart';

class TripServices {
  TripServices({Dio? dio}) : dio = dio ?? Dio();

  final Dio dio;
  final String apiKey = 'AIzaSyB_oEV-wBOY2BZhHtZhrRbE_JDC-4eAYOc';

  final String directionsApiKey = 'AIzaSyB_oEV-wBOY2BZhHtZhrRbE_JDC-4eAYOc';

  Future<List<dynamic>> getSuggestions(String input) async {
    input = input.trim();
    if (input.isEmpty) return [];

    final data = await _requestPlaces(
      'https://places.googleapis.com/v1/places:autocomplete',
      method: 'POST',
      body: {
        'input': input,
        // Include suburbs and landmarks as well as street addresses.
        'includedRegionCodes': ['za'],
      },
      fieldMask: 'suggestions.placePrediction.placeId,'
          'suggestions.placePrediction.text.text',
    );

    // An empty JSON object is a valid response when there are no matches.
    final suggestions = data['suggestions'] ?? [];
    if (suggestions is! List) {
      throw Exception('Invalid place search response. Please try again.');
    }
    final predictions = <Map<String, String>>[];
    for (final suggestion in suggestions) {
      final prediction =
          suggestion is Map ? suggestion['placePrediction'] : null;
      final text = prediction is Map ? prediction['text'] : null;
      final placeId = prediction is Map ? prediction['placeId'] : null;
      final description = text is Map ? text['text'] : null;
      if (placeId is! String || description is! String) {
        throw Exception('Invalid place search response. Please try again.');
      }
      // Preserve the format consumed by the pickup and destination screens.
      predictions.add({'place_id': placeId, 'description': description});
    }
    return predictions;
  }

  Future<TripLocationInfo> getPlaceDetails(String placeId) async {
    final data = await _requestPlaces(
      'https://places.googleapis.com/v1/places/${Uri.encodeComponent(placeId)}',
      fieldMask: 'location',
    );
    final location = data['location'];
    if (location is! Map ||
        location['latitude'] is! num ||
        location['longitude'] is! num) {
      throw Exception(
          'This place has no usable coordinates. Choose another place.');
    }
    return TripLocationInfo(
      pickUpLatitude: location['latitude'].toString(),
      pickUpLongitude: location['longitude'].toString(),
    );
  }

  Future<Map> _requestPlaces(
    String url, {
    String method = 'GET',
    Map<String, dynamic>? body,
    required String fieldMask,
  }) async {
    final Response response;
    try {
      response = await dio.request(
        url,
        data: body,
        options: Options(
          method: method,
          headers: {'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': fieldMask},
          contentType: Headers.jsonContentType,
        ),
      );
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) throw _placesError(response);
      throw Exception(
          'Unable to load places. Check your connection and retry.');
    }
    if (response.statusCode != 200 ||
        response.data is! Map ||
        (response.data as Map).containsKey('error')) {
      throw _placesError(response);
    }
    return response.data as Map;
  }

  Exception _placesError(Response response) {
    final data = response.data;
    final error = data is Map ? data['error'] : null;
    final status = error is Map ? error['status'] : response.statusCode;
    final message = error is Map ? error['message']?.toString() : null;
    return Exception(
      'Places request failed (${status ?? 'UNKNOWN'}): '
      '${(message ?? 'Unable to load places. Please try again.').replaceAll(apiKey, '[REDACTED]')}',
    );
  }
}
