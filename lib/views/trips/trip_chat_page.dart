import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_chat_controller.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:kapame/services/trip_message_realtime.dart';
import 'package:kapame/views/trips/chat.dart';
import 'package:provider/provider.dart';

/// Owns a live conversation opened directly from a trip map marker.
class TripChatPage extends StatefulWidget {
  const TripChatPage({super.key, this.trip});
  final Trip? trip;
  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage>
    with WidgetsBindingObserver {
  TripChatController? _controller;
  String? _recipient;
  String? _sessionKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthUserState>(context);
    final token = auth.token ?? '';
    final userId = auth.appUser?.id?.isNotEmpty == true
        ? auth.appUser!.id
        : TripChatController.userIdFromToken(token);
    final trip = widget.trip;
    final session = '$userId:$token:${trip?.tripId}';
    if (_sessionKey == session) return;
    _sessionKey = session;
    _controller?.dispose();
    _controller = null;
    if (userId == null || token.isEmpty || trip?.tripId?.isNotEmpty != true) {
      return;
    }
    _recipient = trip!.requester?.toLowerCase() == userId.toLowerCase()
        ? trip.transporter
        : trip.requester;
    if (_recipient == null ||
        _recipient!.isEmpty ||
        _recipient == '00000000-0000-0000-0000-000000000000' ||
        _recipient!.toLowerCase() == userId.toLowerCase()) {
      return;
    }
    _controller = TripChatController(
        userId: userId,
        api: TripMessageApi(token: () => auth.token ?? ''),
        realtime: SignalRTripMessages(token: () => auth.token ?? ''));
    _controller!.registerTrip(trip);
    unawaited(_controller!.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.resumed && controller != null) {
      unawaited(controller.realtime.start());
      unawaited(controller.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Trip chat')),
          body: const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Open a trip with a contact to start chatting. Make sure you are signed in.',
                      textAlign: TextAlign.center))));
    }
    return Chat(
        key: ObjectKey(controller),
        controller: controller,
        currentUserId: controller.userId,
        tripId: widget.trip!.tripId,
        recipientId: _recipient,
        recipientName: 'Trip contact',
        tripLabel: widget.trip!.tripLocationInfo?.destinationAddress ??
            'Trip conversation');
  }
}
