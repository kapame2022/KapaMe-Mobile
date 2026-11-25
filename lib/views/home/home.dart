import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/services/owned_trips.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:provider/provider.dart';

import 'trip_history.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.loadTrips});

  final Future<List<Trip>> Function()? loadTrips;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  Future<List<Trip>>? _trips;
  String? _userId;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthUserState>();
    final userId = auth.appUser?.id;
    if (_userId != userId || _token != auth.token) {
      _userId = userId;
      _token = auth.token;
      _trips = _loadTrips();
    }
  }

  Future<List<Trip>> _loadTrips() async {
    final userId = _userId;
    final load = widget.loadTrips;
    if (load == null) return loadOwnedTrips(userId: userId, token: _token);
    return (await load()).where((trip) => tripBelongsTo(trip, userId)).toList();
  }

  void _refreshTrips() {
    if (!mounted || _userId == null) return;
    setState(() => _trips = _loadTrips());
  }

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.homeBannerAd,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeContent(
        name: context.watch<AuthUserState>().appUser?.fullName,
        nextTrip: _trips == null
            ? null
            : FutureBuilder<List<Trip>>(
                key: ValueKey((_userId, _token)),
                future: _trips,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  final now = DateTime.now();
                  final upcoming = snapshot.data!
                      .where((trip) =>
                          trip.tripDateTime != null && !isPastTrip(trip, now))
                      .toList()
                    ..sort(compareUpcomingTrips);
                  if (upcoming.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Text('Next trip', style: ClearBlue.subheading),
                      const SizedBox(height: 8),
                      TripSummaryCard(
                        trip: upcoming.first,
                        featured: true,
                        onTap: () => Navigator.pushNamed(
                            context, '/viewrequest',
                            arguments: upcoming.first),
                      ),
                    ],
                  );
                },
              ),
        onServiceReturn: _refreshTrips,
        advertisement: _isAdLoaded && _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      );
}

/// Presentation separated from the platform ad lifecycle for layout testing.
class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    this.name,
    this.advertisement,
    this.nextTrip,
    this.onServiceReturn,
  });
  final String? name;
  final Widget? advertisement;
  final Widget? nextTrip;
  final VoidCallback? onServiceReturn;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _offering = false;
  static const _find = [
    ('car', 'Private ride', '/privatecommuter'),
    ('bus', 'Public transport', '/publiccommuter'),
    ('people', 'Group trip', '/grouptransport'),
    ('package', 'Send an item', '/itemtransport'),
  ];
  static const _offer = [
    ('car', 'Drive privately', '/privatedriver'),
    ('bus', 'Public route', '/publicdriver'),
    ('people', 'Host a group', '/grouptransporter'),
    ('package', 'Deliver an item', '/itemtransporter'),
  ];

  @override
  Widget build(BuildContext context) {
    final services = _offering ? _offer : _find;
    return Scaffold(
      bottomNavigationBar: const MainNavigation(selected: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            BrandHeader(name: widget.name),
            const SizedBox(height: 12),
            Text(_offering ? 'Offer transport' : 'Find transport',
                style: ClearBlue.heading),
            const SizedBox(height: 14),
            JourneyTabs(
              labels: const ['Find transport', 'Offer transport'],
              selected: _offering ? 1 : 0,
              onChanged: (i) => setState(() => _offering = i == 1),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, grid) {
              final singleColumn = grid.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(14) > 22;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (icon, label, route) in services)
                    SizedBox(
                      width: singleColumn
                          ? grid.maxWidth
                          : (grid.maxWidth - 8) / 2,
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.pushNamed(context, route);
                            if (mounted) widget.onServiceReturn?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DesignIcon(icon),
                                const SizedBox(height: 8),
                                Text(label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            if (widget.nextTrip != null) widget.nextTrip!,
            if (widget.advertisement != null) ...[
              const SizedBox(height: 24),
              Center(child: widget.advertisement!),
            ],
          ],
        ),
      ),
    );
  }
}
