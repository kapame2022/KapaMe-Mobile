import 'package:dio/dio.dart';
import 'package:kapame/models/trip.dart';

class TripServices {
  Future<List<dynamic>>? suggestions;
  Dio dio = Dio();
  final String apiKey = 'AIzaSyD6VLyBCAZHp-hi2QssKeRRZDlmvweZHT0';

  Future<List<dynamic>> getSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final Uri requestUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&types=address');

    final Response response = await dio.get(requestUrl.toString());

    if (response.statusCode == 200) {
      print(response.data['predictions']);
      //suggestions = response.data['predictions'];
      return Future.value(response.data['predictions']);
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<TripLocationInfo> getPlaceDetails(String placeId) async {
    final Uri requestUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey');

    final response = await dio.get(requestUrl.toString());

    if (response.statusCode == 200) {
      final placeDetails = response.data['result'];
      final lat = placeDetails['geometry']['location']['lat'].toString();
      final lng = placeDetails['geometry']['location']['lng'].toString();

      TripLocationInfo locationCoord =
          TripLocationInfo(pickUpLatitude: lat, pickUpLongitude: lng);

      return locationCoord;
      // Handle the coordinates (e.g., pass them to another screen or use them in the current screen)
    } else {
      throw Exception('Failed to load place details');
    }
  }
}
