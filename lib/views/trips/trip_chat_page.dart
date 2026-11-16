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
  String? _unavailableReason;

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
    final session =
        '$userId:$token:${trip?.tripId}:${trip?.requester}:${trip?.transporter}';
    if (_sessionKey == session) return;
    _sessionKey = session;
    _controller?.dispose();
    _controller = null;
    _unavailableReason = null;
    if (userId == null || userId.isEmpty || token.isEmpty) {
      _unavailableReason = 'Please sign in to chat about this trip.';
      return;
    }
    if (trip?.tripId?.isNotEmpty != true) {
      _unavailableReason =
          'Trip details are missing. Go back and open the request again.';
      return;
    }
    _recipient = trip!.requester?.toLowerCase() == userId.toLowerCase()
        ? trip.transporter
        : trip.requester;
    if (_recipient == null ||
        _recipient!.isEmpty ||
        _recipient == '00000000-0000-0000-0000-000000000000' ||
        _recipient!.toLowerCase() == userId.toLowerCase()) {
      _unavailableReason = trip.requester?.toLowerCase() == userId.toLowerCase()
          ? 'You created this request. There is no transporter to chat with '
              'yet. You cannot start a chat with yourself.'
          : 'This request is missing the requester’s contact details, '
              'so a chat cannot be opened.';
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
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      _unavailableReason ?? 'This trip chat is unavailable.',
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
