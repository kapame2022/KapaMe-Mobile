import 'package:flutter/material.dart';
import 'package:kapame/services/trip_message.dart';
import 'package:kapame/services/trip_chat_controller.dart';
import 'package:kapame/services/trip_message_realtime.dart';

/// A trip conversation. Without [onSend], messages are local previews only.
class Chat extends StatefulWidget {
  const Chat({
    super.key,
    this.recipientName = 'Trip chat',
    this.tripLabel,
    this.currentUserId = 'me',
    this.initialMessages = const [],
    this.onSend,
    this.controller,
    this.tripId,
    this.recipientId,
    this.allTrips = false,
  }) : assert(controller == null || (tripId != null && recipientId != null));

  final String recipientName;
  final String? tripLabel;
  final String currentUserId;
  final List<TripMessage> initialMessages;
  final Future<TripMessage> Function(String text)? onSend;
  final TripChatController? controller;
  final String? tripId;
  final String? recipientId;
  final bool allTrips;

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  late final List<TripMessage> _previewMessages;
  List<TripMessage> get _messages => widget.controller == null
      ? _previewMessages
      : widget.allTrips
          ? widget.controller!.messagesWith(widget.recipientId!)
          : widget.controller!.messagesFor(widget.tripId!, widget.recipientId!);
  bool _loadingHistory = false;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _previewMessages = List.of(widget.initialMessages);
    widget.controller?.addListener(_updated);
    if (widget.controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadHistory();
      });
    }
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    if (widget.allTrips) await widget.controller!.refresh();
    if (!mounted) return;
    await widget.controller!.openConversation(widget.tripId!);
    if (mounted) setState(() => _loadingHistory = false);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updated);
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final message = widget.controller != null
          ? await widget.controller!
              .send(widget.tripId!, widget.recipientId!, text)
          : widget.onSend == null
              ? TripMessage(
                  sender: widget.currentUserId,
                  message: text,
                  timestamp: DateTime.now(),
                )
              : await widget.onSend!(text);
      if (!mounted) return;
      setState(() {
        if (widget.controller == null) _previewMessages.add(message);
        _composer.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sendError =
          'Message could not be sent. Your text is saved here. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _dayLabel(DateTime date) {
    final local = date.toLocal();
    final day = DateUtils.dateOnly(local);
    final today = DateUtils.dateOnly(DateTime.now());
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return MaterialLocalizations.of(context).formatMediumDate(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final preview = widget.onSend == null && widget.controller == null;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        actions: [
          if (widget.controller != null)
            IconButton(
                onPressed: _loadingHistory ? null : _loadHistory,
                tooltip: 'Refresh conversation',
                icon: const Icon(Icons.refresh)),
        ],
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.controller?.contactName(widget.recipientId!) ??
                        widget.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('Trip conversation',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ]),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          if (_loadingHistory) const LinearProgressIndicator(),
          if (widget.controller != null &&
              widget.controller!.connection != ChatConnection.connected)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                    widget.controller!.connection == ChatConnection.offline
                        ? 'Live updates offline · Tap refresh for new messages'
                        : 'Connecting to live updates…',
                    style: theme.textTheme.bodySmall)),
          if (widget.controller?.error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(widget.controller!.error!,
                    style: TextStyle(color: colors.error))),
          if (widget.tripLabel != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Icons.directions_car_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(widget.tripLabel!,
                        style: theme.textTheme.bodyMedium)),
              ]),
            ),
          if (preview)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text('Chat preview · Messages are not sent',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(Icons.chat_bubble_outline_rounded,
                                size: 32, color: colors.onPrimaryContainer),
                          ),
                          const SizedBox(height: 20),
                          Text('Start the conversation',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                              'Share your pickup point or ask a question about your trip.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ))
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final position = _messages.length - 1 - index;
                      final message = _messages[position];
                      final date = message.timestamp?.toLocal();
                      final previousDate = position > 0
                          ? _messages[position - 1].timestamp?.toLocal()
                          : null;
                      final showDate = date != null &&
                          (position == 0 ||
                              !DateUtils.isSameDay(date, previousDate));
                      return Column(children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(_dayLabel(date),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: colors.onSurfaceVariant)),
                          ),
                        _MessageBubble(
                          message: message,
                          isMine: message.sender == widget.currentUserId,
                          preview: preview,
                        ),
                      ]);
                    },
                  ),
          ),
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Semantics(
                liveRegion: true,
                child: Text(_sendError!, style: TextStyle(color: colors.error)),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _composer,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _composer,
                builder: (context, value, child) => IconButton.filled(
                  tooltip: preview ? 'Add preview message' : 'Send message',
                  onPressed:
                      _sending || value.text.trim().isEmpty ? null : _send,
                  padding: const EdgeInsets.all(14),
                  icon: _sending
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.onSurfaceVariant))
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(
      {required this.message, required this.isMine, required this.preview});

  final TripMessage message;
  final bool isMine;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isMine ? colors.onPrimaryContainer : colors.onSurface;
    final date = message.timestamp?.toLocal();
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? colors.primaryContainer : colors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message.message ?? '',
              style: TextStyle(color: foreground, fontSize: 15, height: 1.4)),
          if (date != null || (isMine && preview)) ...[
            const SizedBox(height: 5),
            Text(
                [
                  if (date != null)
                    MaterialLocalizations.of(context)
                        .formatTimeOfDay(TimeOfDay.fromDateTime(date)),
                  if (isMine && preview) 'Preview',
                ].join(' · '),
                style: TextStyle(
                    fontSize: 11, color: foreground.withValues(alpha: 0.7))),
          ],
        ]),
      ),
    );
  }
}
