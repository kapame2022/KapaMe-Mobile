import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:kapame/widgets/trip_date_time_picker.dart';
import 'package:kapame/widgets/trip_route_map.dart';

class ViewRequest extends StatefulWidget {
  const ViewRequest({super.key});

  @override
  State<ViewRequest> createState() => _ViewRequestState();
}

class _ViewRequestState extends State<ViewRequest> {
  BannerAd? _bannerAd;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.groupTransporterAd,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          if (!mounted) return;
          ad.dispose();
          setState(() {
            _adLoaded = false;
            _bannerAd = null;
          });
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
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final trip = args is Trip ? args : null;
    final departure = trip?.tripDateTime;
    final location = trip?.tripLocationInfo;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: SafeArea(
        child: trip == null
            ? const Center(child: Text('Trip details are unavailable.'))
            : LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * .44,
                      child: TripRouteMap(location: location),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(trip.tripType ?? 'Trip details',
                              style: ClearBlue.subheading),
                          if (trip.tripStatus?.trim().isNotEmpty == true)
                            Text(trip.tripStatus!, style: ClearBlue.label),
                          RouteSummary(location: location),
                          if (departure != null)
                            Text(formatTripDateTime(departure.toLocal())),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message trip contact'),
                            onPressed: () => Navigator.pushNamed(
                                context, '/chat',
                                arguments: trip),
                          ),
                          if (tripCoordinates(location?.pickUpLatitude,
                                  location?.pickUpLongitude) !=
                              null)
                            OutlinedButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/drivertracker',
                                  arguments: trip),
                              child: const Text('View pick-up on map'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _adLoaded && _bannerAd != null
          ? SafeArea(
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                child: Center(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
