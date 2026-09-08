import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/services/trip_services.dart';

void main() {
  late Dio dio;
  late TripServices service;
  late List<RequestOptions> requests;
  late Map<String, dynamic> responseData;

  setUp(() {
    requests = [];
    responseData = {};
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: responseData,
      ));
    }));
    service = TripServices(dio: dio);
  });

  tearDown(() => dio.close());

  test('blank input does not make a request', () async {
    expect(await service.getSuggestions('   '), isEmpty);
    expect(requests, isEmpty);
  });

  test('search accepts suburbs and retains the South Africa restriction',
      () async {
    responseData = {
      'suggestions': [
        {
          'placePrediction': {
            'placeId': 'suburb',
            'text': {'text': 'Blue Hills, Midrand, South Africa'},
          }
        },
      ],
    };

    expect(await service.getSuggestions(' blue hills '), [
      {
        'place_id': 'suburb',
        'description': 'Blue Hills, Midrand, South Africa'
      },
    ]);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(),
        'https://places.googleapis.com/v1/places:autocomplete');
    expect(request.data['input'], 'blue hills');
    expect(request.data['includedRegionCodes'], ['za']);
    expect(request.data, isNot(contains('includedPrimaryTypes')));
    expect(request.headers['X-Goog-Api-Key'], service.apiKey);
    expect(request.headers['X-Goog-FieldMask'], contains('placeId'));
    expect(request.uri.queryParameters, isNot(contains('key')));
  });

  test('special characters remain part of the JSON input', () async {
    const input = 'Main & First + Square';
    await service.getSuggestions(input);
    expect(requests.single.data['input'], input);
  });

  test('empty JSON and empty suggestions are valid no-match responses',
      () async {
    expect(await service.getSuggestions('unknown place'), isEmpty);
    responseData = {'suggestions': []};
    expect(await service.getSuggestions('unknown place'), isEmpty);
  });

  for (final entry in {
    403: 'PERMISSION_DENIED',
    429: 'RESOURCE_EXHAUSTED',
    400: 'INVALID_ARGUMENT'
  }.entries) {
    test('${entry.value} HTTP errors retain the provider explanation',
        () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response:
              Response(requestOptions: options, statusCode: entry.key, data: {
            'error': {'status': entry.value, 'message': 'Provider explanation'},
          }),
        ));
      }));
      await expectLater(
          service.getSuggestions('blue hills'),
          throwsA(
            isA<Exception>().having((error) => error.toString(), 'message',
                allOf(contains(entry.value), contains('Provider explanation'))),
          ));
    });
  }

  test('malformed predictions are reported as errors', () async {
    responseData = {
      'suggestions': [
        {
          'placePrediction': {'placeId': 'suburb'}
        }
      ]
    };
    await expectLater(service.getSuggestions('blue hills'), throwsException);
  });

  test('place details provide coordinates using the new endpoint', () async {
    responseData = {
      'location': {'latitude': -25.95, 'longitude': 28.1}
    };
    final location = await service.getPlaceDetails('suburb');
    expect(location.pickUpLatitude, '-25.95');
    expect(location.pickUpLongitude, '28.1');
    expect(requests.single.method, 'GET');
    expect(requests.single.uri.toString(),
        'https://places.googleapis.com/v1/places/suburb');
    expect(requests.single.headers['X-Goog-FieldMask'], 'location');
    expect(requests.single.headers['X-Goog-Api-Key'], service.apiKey);
  });

  test('place details reject missing coordinates', () async {
    await expectLater(service.getPlaceDetails('suburb'), throwsException);
  });

  test('provider errors do not expose the API key', () async {
    responseData = {
      'error': {
        'status': 'PERMISSION_DENIED',
        'message': 'Invalid key: ${service.apiKey}'
      },
    };
    await expectLater(
      service.getSuggestions('blue hills'),
      throwsA(isA<Exception>().having(
        (error) => error.toString(),
        'message',
        isNot(contains(service.apiKey)),
      )),
    );
  });

  test('network failures produce a readable error', () async {
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ));
    }));
    await expectLater(
      service.getSuggestions('blue hills'),
      throwsA(isA<Exception>().having(
        (error) => error.toString(),
        'message',
        contains('Check your connection'),
      )),
    );
  });
}
