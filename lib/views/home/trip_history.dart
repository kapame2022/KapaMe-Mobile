import 'package:kapame/services/owned_trips.dart';
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
    return loadOwnedTrips(userId: auth.appUser?.id, token: auth.token);
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
                  const Text('Trips', style: ClearBlue.heading),
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
                          return tripBelongsTo(trip, userId) &&
                              isPastTrip(trip, now) == (_tab == 1);
                        }).toList()
                          ..sort(_tab == 0
                              ? compareUpcomingTrips
                              : (a, b) => compareUpcomingTrips(b, a));
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
                          if (_tab == 0) ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  Text('Next up', style: ClearBlue.subheading),
                            ),
                            const SizedBox(height: 10),
                          ],
                          for (final (index, trip) in trips.indexed) ...[
                            if (_tab == 0 && index == 1) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child:
                                    Text('Later', style: ClearBlue.subheading),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TripSummaryCard(
                                trip: trip,
                                featured: _tab == 0 && index == 0,
                                onTap: () => Navigator.pushNamed(
                                    context, '/viewrequest',
                                    arguments: trip),
                              ),
                            ),
                          ],
                        ]);
                      }),
                ],
              ))),
    );
  }
}

class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({
    super.key,
    required this.trip,
    this.onTap,
    this.featured = false,
  });

  final Trip trip;
  final VoidCallback? onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final date = trip.tripDateTime?.toLocal();
    final locale = MaterialLocalizations.of(context);
    final departure = date == null
        ? 'Departure not provided'
        : '${locale.formatMediumDate(date)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final status = trip.tripStatus?.trim() ?? '';
    final (background, foreground) = switch (status.toLowerCase()) {
      'requested' || 'pending' => (
          const Color(0xfffff0d8),
          const Color(0xff704500)
        ),
      'completed' => (const Color(0xffe2f4ec), const Color(0xff1e5b43)),
      'canceled' || 'cancelled' || 'expired' => (
          const Color(0xfff3e9ea),
          const Color(0xff853c46)
        ),
      _ => (ClearBlue.soft, ClearBlue.accent),
    };
    return Card(
      color: featured ? const Color(0xffebf5ff) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(trip.tripType ?? 'Journey', style: ClearBlue.label),
                  DecoratedBox(
                    decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Text(
                          status.isEmpty ? 'Status unavailable' : status,
                          style: TextStyle(fontSize: 12, color: foreground)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(departure,
                  style: TextStyle(
                      fontSize: featured ? 18 : 14,
                      fontWeight: FontWeight.w700)),
              RouteSummary(location: trip.tripLocationInfo),
            ],
          ),
        ),
      ),
    );
  }
}
