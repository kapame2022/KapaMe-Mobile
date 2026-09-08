import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/trip_chat_controller.dart';
import 'package:kapame/services/trip_message_api.dart';
import 'package:kapame/services/trip_message_realtime.dart';
import 'package:kapame/views/trips/chat.dart';
import 'package:provider/provider.dart';

class Messages extends StatefulWidget {
  const Messages({super.key, this.controller});
  final TripChatController? controller;

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _read = <String, String?>{};
  TripChatController? _controller;
  String? _sessionKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      if (_controller == null) {
        _controller = widget.controller;
        unawaited(_controller!.start());
      }
      return;
    }
    final auth = Provider.of<AuthUserState>(context);
    final token = auth.token ?? '';
    final userId = auth.appUser?.id?.isNotEmpty == true
        ? auth.appUser!.id
        : TripChatController.userIdFromToken(token);
    final sessionKey = '$userId:$token';
    if (_sessionKey == sessionKey) return;
    _sessionKey = sessionKey;
    _controller?.dispose();
    _controller = null;
    _read.clear();
    if (userId == null || userId.isEmpty || token.isEmpty) return;
    _controller = TripChatController(
      userId: userId,
      api: TripMessageApi(token: () => auth.token ?? ''),
      realtime: SignalRTripMessages(token: () => auth.token ?? ''),
    );
    unawaited(_controller!.start());
  }

  void _changed() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final controller = _controller;
      if (controller != null) {
        unawaited(controller.realtime.start());
        unawaited(controller.refresh());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  String _stamp(TripConversation conversation) =>
      conversation.latest.tripMessageId ??
      '${conversation.latest.timestamp}:${conversation.latest.message}';

  bool _unread(TripConversation conversation) =>
      conversation.latest.sender?.toLowerCase() !=
          _controller!.userId.toLowerCase() &&
      _read[conversation.otherUserId.toLowerCase()] != _stamp(conversation);

  Future<void> _open(TripConversation conversation) async {
    final controller = _controller!;
    setState(() =>
        _read[conversation.otherUserId.toLowerCase()] = _stamp(conversation));
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Chat(
        controller: controller,
        tripId: conversation.tripId,
        recipientId: conversation.otherUserId,
        recipientName: controller.contactName(conversation.otherUserId),
        allTrips: true,
        tripLabel: conversation.title,
        currentUserId: controller.userId,
      ),
    ));
    if (!mounted) return;
    final latest = controller.contacts.where((item) =>
        item.otherUserId.toLowerCase() ==
        conversation.otherUserId.toLowerCase());
    if (latest.isNotEmpty) {
      setState(() =>
          _read[conversation.otherUserId.toLowerCase()] = _stamp(latest.first));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Messages')),
          body: const Center(child: Text('Sign in to view your messages.')));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final query = _search.text.trim().toLowerCase();
        final conversations = controller.contacts
            .where((item) =>
                controller
                    .contactName(item.otherUserId)
                    .toLowerCase()
                    .contains(query) ||
                item.title.toLowerCase().contains(query) ||
                (item.latest.message ?? '').toLowerCase().contains(query))
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Messages'), actions: [
            IconButton(
                tooltip: 'Refresh messages',
                icon: const Icon(Icons.refresh),
                onPressed: controller.loading ? null : controller.refresh),
          ]),
          body: SafeArea(
              top: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      )),
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                        switch (controller.connection) {
                          ChatConnection.connected => 'Live updates connected',
                          ChatConnection.connecting =>
                            'Connecting to live updates…',
                          ChatConnection.reconnecting => 'Reconnecting…',
                          ChatConnection.offline =>
                            'Live updates offline · Pull down to refresh',
                        },
                        style: TextStyle(
                            color: colors.onSurfaceVariant, fontSize: 12))),
                if (controller.loading) const LinearProgressIndicator(),
                if (controller.error != null)
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(controller.error!,
                          style: TextStyle(color: colors.error))),
                Expanded(
                    child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: conversations.isEmpty ? 1 : conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (conversations.isEmpty) {
                        return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Column(children: [
                              Icon(Icons.forum_outlined,
                                  size: 48, color: colors.primary),
                              const SizedBox(height: 16),
                              Text(controller.loading
                                  ? 'Loading conversations…'
                                  : query.isEmpty
                                      ? 'No conversations yet'
                                      : 'No matching conversations'),
                            ]));
                      }
                      final conversation = conversations[index];
                      final unread = _unread(conversation);
                      final date = conversation.latest.timestamp?.toLocal();
                      return Material(
                        color: unread
                            ? colors.primaryContainer.withValues(alpha: 0.4)
                            : colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              child: Icon(Icons.chat_bubble_outline,
                                  color: colors.onPrimaryContainer)),
                          title: Text(
                              controller.contactName(conversation.otherUserId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                          subtitle: Text(conversation.latest.message ?? '',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (date != null)
                                  Text(
                                      DateUtils.isSameDay(date, DateTime.now())
                                          ? MaterialLocalizations.of(context)
                                              .formatTimeOfDay(
                                                  TimeOfDay.fromDateTime(date))
                                          : MaterialLocalizations.of(context)
                                              .formatShortDate(date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                if (unread) ...[
                                  const SizedBox(height: 8),
                                  CircleAvatar(
                                      radius: 4,
                                      backgroundColor: colors.primary)
                                ],
                              ]),
                          onTap: () => _open(conversation),
                        ),
                      );
                    },
                  ),
                )),
              ])),
        );
      },
    );
  }
}
