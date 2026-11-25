import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:kapame/widgets/trip_date_time_picker.dart';
import 'package:kapame/widgets/trip_route_map.dart';

class ReviewTripRequest extends StatefulWidget {
  const ReviewTripRequest(
      {super.key, required this.request, this.token, this.dio});

  final Map<String, dynamic> request;
  final String? token;
  final Dio? dio;

  @override
  State<ReviewTripRequest> createState() => _ReviewTripRequestState();
}

class _ReviewTripRequestState extends State<ReviewTripRequest> {
  late final _location = TripLocationInfo.fromMap(
    widget.request['tripLocationInfo'] as Map<String, dynamic>?,
  );
  bool _sending = false;
  bool _sent = false;
  bool _error = false;

  Future<void> _submit() async {
    if (_sending || _sent) return;
    setState(() {
      _sending = true;
      _error = false;
    });
    final dio = widget.dio ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));
    try {
      await dio.post<void>(
        'https://kapameapi.azurewebsites.net/api/trips',
        data: widget.request,
        options: Options(headers: {
          if (widget.token?.isNotEmpty == true)
            'Authorization': 'Bearer ${widget.token}',
        }),
      );
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (widget.dio == null) dio.close();
      if (mounted) setState(() => _sending = false);
    }
  }

  void _goToTrips() {
    Navigator.pushNamedAndRemoveUntil(
        context, '/triphistory', ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final location = _location;
    final date = DateTime.tryParse(request['tripDateTime']?.toString() ?? '');
    final values = {
      'Service': request['tripType'],
      'Departure': date == null ? null : formatTripDateTime(date.toLocal()),
      'Priority': request['tripPriority'],
      'Schedule': request['tripScheduling'],
      'Passengers': (request['groupTransport'] as Map?)?['numberOfPeople'],
      'Item': (request['itemTransport'] as Map?)?['description'],
      'Phone number': request['contactDetailsPhoneNumber'],
      'Email address': request['contactDetailsEmail'],
    };
    return PopScope(
      canPop: !_sending && !_sent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sent ? 'Request sent' : 'Review request'),
          automaticallyImplyLeading: !_sending && !_sent,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_sent)
                const ListTile(
                  tileColor: ClearBlue.soft,
                  leading:
                      Icon(Icons.check_circle_outline, color: ClearBlue.accent),
                  title: Text('Your request was sent'),
                  subtitle: Text('Your trip is pending.'),
                )
              else
                SizedBox(height: 220, child: TripRouteMap(location: location)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RouteSummary(location: location),
                      if (!_sent)
                        for (final entry in values.entries)
                          if (entry.value?.toString().trim().isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text('${entry.key}: ${entry.value}'),
                            ),
                      if (_error)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                                'Couldn’t send your request. Your details are still here.',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _sending
                            ? null
                            : _sent
                                ? _goToTrips
                                : _submit,
                        child: Text(_sending
                            ? 'Sending request…'
                            : _sent
                                ? 'See upcoming trips'
                                : 'Request trip'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
