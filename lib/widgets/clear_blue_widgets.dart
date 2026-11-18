import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/theme/clear_blue.dart';
import 'package:provider/provider.dart';

String userInitials(String? name) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'K';
  return words.take(2).map((w) => w.characters.first).join().toUpperCase();
}

class DesignIcon extends StatelessWidget {
  const DesignIcon(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/clear_blue/$name.svg',
          excludeFromSemantics: true);
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.name});
  final String? name;
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(
            child: Text('kapame.',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ClearBlue.accent))),
        IconButton(
            tooltip: 'Edit profile',
            onPressed: () => Navigator.pushNamed(context, '/editprofile'),
            icon: CircleAvatar(
                radius: 20,
                backgroundColor: ClearBlue.soft,
                foregroundColor: ClearBlue.accent,
                child: Text(userInitials(name),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)))),
      ]);
}

class PageHeading extends StatelessWidget {
  const PageHeading(
      {super.key, required this.eyebrow, required this.title, this.subtitle});
  final String eyebrow, title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow, style: ClearBlue.label),
        const SizedBox(height: 16),
        Text(title, style: ClearBlue.heading),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(subtitle!, style: const TextStyle(color: ClearBlue.muted))
        ],
      ]);
}

class JourneyTabs extends StatelessWidget {
  const JourneyTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: ClearBlue.line, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
                child: Semantics(
                    selected: i == selected,
                    child: Material(
                      color:
                          selected == i ? ClearBlue.panel : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () => onChanged(i),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 8),
                              child: Text(labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: selected == i
                                          ? ClearBlue.accent
                                          : ClearBlue.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)))),
                    )))
        ]),
      );
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key, required this.selected});
  final int selected;
  static const routes = ['/home', '/triphistory', '/messages', '/settings'];
  @override
  Widget build(BuildContext context) => Material(
      color: ClearBlue.panel,
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                for (var i = 0; i < routes.length; i++)
                  Expanded(
                      child: Semantics(
                          selected: i == selected,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (i == selected) return;
                              if (i == 0) {
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/home'));
                              } else if (selected == 0) {
                                Navigator.pushNamed(context, routes[i]);
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, routes[i]);
                              }
                            },
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                    color: i == selected
                                        ? ClearBlue.soft
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DesignIcon('${[
                                        'home',
                                        'trips',
                                        'messages',
                                        'profile'
                                      ][i]}${selected == i && i != 3 ? '_active' : ''}'),
                                      const SizedBox(height: 6),
                                      Text(
                                          [
                                            'Home',
                                            'Trips',
                                            'Messages',
                                            'Profile'
                                          ][i],
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: i == selected
                                                  ? ClearBlue.accent
                                                  : ClearBlue.muted)),
                                    ])),
                          ))),
              ]))));
}

class JourneyPage extends StatelessWidget {
  const JourneyPage(
      {super.key,
      required this.selected,
      required this.eyebrow,
      required this.title,
      required this.children});
  final int selected;
  final String eyebrow, title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: MainNavigation(selected: selected),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
              BrandHeader(
                  name: context.watch<AuthUserState>().appUser?.fullName),
              const SizedBox(height: 16),
              PageHeading(eyebrow: eyebrow, title: title),
              const SizedBox(height: 24),
              ...children,
            ])),
      );
}

class RouteSummary extends StatelessWidget {
  const RouteSummary({super.key, required this.location});
  final TripLocationInfo? location;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final entry in [
          ('A', 'Pick-up', location?.pickUpAddress),
          ('B', 'Destination', location?.destinationAddress)
        ])
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color:
                            entry.$1 == 'A' ? ClearBlue.soft : ClearBlue.accent,
                        shape: BoxShape.circle),
                    child: Text(entry.$1,
                        style: TextStyle(
                            fontSize: 11,
                            color: entry.$1 == 'A'
                                ? ClearBlue.accent
                                : Colors.white))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(entry.$2, style: ClearBlue.label),
                      const SizedBox(height: 4),
                      Text(
                          entry.$3?.isNotEmpty == true
                              ? entry.$3!
                              : 'Not provided',
                          style: const TextStyle(fontWeight: FontWeight.w600))
                    ])),
              ])),
      ]);
}

/// Persistent map action; uses the existing booking/filter callback.
class MapActionPanel extends StatelessWidget {
  const MapActionPanel(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.action,
      required this.onPressed});
  final String title, subtitle, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
      child: SingleChildScrollView(
          child: Material(
              color: ClearBlue.panel,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: ClearBlue.subheading),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: const TextStyle(
                              color: ClearBlue.muted, fontSize: 12)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: onPressed, child: Text(action)),
                    ]),
              ))));
}
