import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kapame/services/ad_unit_ids.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:kapame/widgets/clear_blue_widgets.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
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
  const HomeContent({super.key, this.name, this.advertisement});
  final String? name;
  final Widget? advertisement;
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _offering = false;
  static const _find = [
    ('car', 'Private ride', 'A ride that fits your plans', '/privatecommuter'),
    ('bus', 'Public transport', 'Find your next connection', '/publiccommuter'),
    ('people', 'Group trip', 'Travel together', '/grouptransport'),
    (
      'package',
      'Send an item',
      'Get it where it needs to go',
      '/itemtransport'
    ),
  ];
  static const _offer = [
    ('car', 'Drive privately', 'Connect with commuters', '/privatedriver'),
    ('bus', 'Public route', 'Help people get moving', '/publicdriver'),
    ('people', 'Host a group', 'Make room for everyone', '/grouptransporter'),
    (
      'package',
      'Deliver an item',
      'Make the journey useful',
      '/itemtransporter'
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final name = (widget.name ?? '').trim();
    final services = _offering ? _offer : _find;
    return Scaffold(
      bottomNavigationBar: const MainNavigation(selected: 0),
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 32)
                                .clamp(0, double.infinity)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BrandHeader(name: widget.name),
                              const SizedBox(height: 16),
                              PageHeading(
                                  eyebrow: name.isEmpty
                                      ? 'HELLO THERE'
                                      : 'HELLO, ${name.split(RegExp(r'\s+')).first.toUpperCase()}',
                                  title: _offering
                                      ? 'Make room for\nsomeone’s journey.'
                                      : 'Where are\nyou headed?',
                                  subtitle: _offering
                                      ? 'A little space. A big difference.'
                                      : 'Your next journey starts here.'),
                              const SizedBox(height: 24),
                              JourneyTabs(
                                  labels: const [
                                    'Find transport',
                                    'Offer transport'
                                  ],
                                  selected: _offering ? 1 : 0,
                                  onChanged: (i) =>
                                      setState(() => _offering = i == 1)),
                              const SizedBox(height: 16),
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: ClearBlue.soft,
                                      foregroundColor: ClearBlue.accent),
                                  onPressed: () => Navigator.pushNamed(
                                      context, services.first.$4),
                                  child: Text(_offering
                                      ? 'Find nearby requests'
                                      : 'Plan your journey')),
                              const SizedBox(height: 16),
                              LayoutBuilder(builder: (context, grid) {
                                final singleColumn = grid.maxWidth < 280 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        22;
                                return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final service in services)
                                        SizedBox(
                                          width: singleColumn
                                              ? grid.maxWidth
                                              : (grid.maxWidth - 12) / 2,
                                          child: Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: InkWell(
                                                  onTap: () =>
                                                      Navigator.pushNamed(
                                                          context, service.$4),
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            DesignIcon(
                                                                service.$1),
                                                            const SizedBox(
                                                                height: 10),
                                                            Text(service.$2,
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        14)),
                                                            const SizedBox(
                                                                height: 6),
                                                            Text(service.$3,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: ClearBlue
                                                                        .muted)),
                                                          ])))),
                                        )
                                    ]);
                              }),
                              if (widget.advertisement != null) ...[
                                const SizedBox(height: 32),
                                Center(child: widget.advertisement!)
                              ],
                            ])),
                  ))),
    );
  }
}
