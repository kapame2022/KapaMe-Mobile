import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:provider/provider.dart';

class TripHistory extends StatefulWidget {
  const TripHistory({super.key, this.loadTrips});
  final Future<List<Trip>> Function()? loadTrips;
  @override
  State<TripHistory> createState() => _TripHistoryState();
}

class _TripHistoryState extends State<TripHistory> {
  late Future<List<Trip>> _trips;
  int _tab = 0;
  @override
  void initState() {
    super.initState();
    _trips = _load();
  }

  Future<List<Trip>> _load() async {
    if (widget.loadTrips != null) return widget.loadTrips!();
    final auth = context.read<AuthUserState>();
    final response = await Dio().get(
        'https://kapameapi.azurewebsites.net/api/trips',
        options: Options(headers: {
          if (auth.token?.isNotEmpty == true)
            'Authorization': 'Bearer ${auth.token}'
        }));
    return (response.data as List)
        .map((item) => Trip.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _trips = next;
    });
    // FutureBuilder owns the error UI; refresh must always dismiss its spinner.
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthUserState>().appUser?.id;
    return Scaffold(
      bottomNavigationBar: const MainNavigation(selected: 1),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  BrandHeader(
                      name: context.watch<AuthUserState>().appUser?.fullName),
                  const SizedBox(height: 16),
                  const PageHeading(
                      eyebrow: 'YOUR JOURNEYS',
                      title: 'All your trips.\nOne place.'),
                  const SizedBox(height: 24),
                  JourneyTabs(
                      labels: const ['Upcoming', 'Past'],
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i)),
                  const SizedBox(height: 20),
                  FutureBuilder<List<Trip>>(
                      future: _trips,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                              padding: EdgeInsets.all(48),
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        if (snapshot.hasError) {
                          return Column(children: [
                            const Text(
                                'We couldn’t load your trips. Please try again.'),
                            const SizedBox(height: 16),
                            OutlinedButton(
                                onPressed: _refresh, child: const Text('Retry'))
                          ]);
                        }
                        final now = DateTime.now();
                        final trips = (snapshot.data ?? <Trip>[]).where((trip) {
                          if (userId == null || userId.isEmpty) return false;
                          if (trip.requester?.toLowerCase() !=
                                  userId.toLowerCase() &&
                              trip.transporter?.toLowerCase() !=
                                  userId.toLowerCase()) {
                            return false;
                          }
                          final status = (trip.tripStatus ?? '').toLowerCase();
                          final past = [
                                'completed',
                                'cancelled',
                                'canceled',
                                'expired'
                              ].contains(status) ||
                              (trip.tripDateTime?.isBefore(now) ?? false);
                          return _tab == 1 ? past : !past;
                        }).toList()
                          ..sort((a, b) => _tab == 0
                              ? (a.tripDateTime ?? now)
                                  .compareTo(b.tripDateTime ?? now)
                              : (b.tripDateTime ?? now)
                                  .compareTo(a.tripDateTime ?? now));
                        if (trips.isEmpty) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(children: [
                                const Icon(Icons.route_outlined,
                                    size: 40, color: ClearBlue.accent),
                                const SizedBox(height: 16),
                                Text(
                                    _tab == 0
                                        ? 'No upcoming trips yet'
                                        : 'No past trips yet',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                const Text('Your journeys will appear here.',
                                    style: TextStyle(color: ClearBlue.muted))
                              ]));
                        }
                        return Column(children: [
                          for (final trip in trips)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TripSummaryCard(
                                    trip: trip,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/viewrequest',
                                        arguments: trip)))
                        ]);
                      }),
                ],
              ))),
    );
  }
}

class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({super.key, required this.trip, this.onTap});
  final Trip trip;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final date = trip.tripDateTime?.toLocal();
    final locale = MaterialLocalizations.of(context);
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: ClearBlue.soft,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                    trip.tripStatus ?? 'Status unavailable',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: ClearBlue.accent))),
                            Text(trip.tripType ?? 'Journey',
                                style: const TextStyle(
                                    fontSize: 12, color: ClearBlue.muted))
                          ]),
                      const SizedBox(height: 8),
                      RouteSummary(location: trip.tripLocationInfo),
                      const Divider(height: 24),
                      Text(
                          date == null
                              ? 'Departure not provided'
                              : '${locale.formatMediumDate(date)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                          style: const TextStyle(
                              color: ClearBlue.muted, fontSize: 12)),
                    ]))));
  }
}
