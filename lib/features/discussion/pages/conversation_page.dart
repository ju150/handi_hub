import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../models/sms_message.dart';
import '../services/contacts_service.dart';
import '../services/sms_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/quick_replies.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.threadId,
    required this.address,
  });

  // threadId peut être vide ('') pour une nouvelle conversation sans thread existant.
  final String threadId;
  final String address;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> with WidgetsBindingObserver {
  List<SmsMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _navigatingBack = false;
  late String _threadId;
  String _contactName = '';
  Uint8List? _contactPhoto;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  DateTime? _lastSendTap;
  StreamSubscription<void>? _smsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _threadId = widget.threadId;
    _loadContact();
    if (_threadId.isNotEmpty) {
      _load(scrollImmediate: true);
    } else {
      setState(() => _loading = false);
    }
    _smsSub = SmsService.smsEvents.listen((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_sending && _threadId.isNotEmpty) _load(scrollImmediate: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _threadId.isNotEmpty && mounted) {
      _load(scrollImmediate: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContact() async {
    final contact = await ContactsService.findByPhone(widget.address);
    if (!mounted) return;
    setState(() {
      _contactName = contact?.name ?? widget.address;
      _contactPhoto = contact?.photo;
    });
  }

  Future<void> _load({bool scrollImmediate = false}) async {
    if (_threadId.isEmpty) return;
    if (!scrollImmediate) {
      final msgs = await SmsService.getMessages(_threadId, address: widget.address);
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scheduleScrollToBottom(immediate: false);
      return;
    }
    setState(() => _loading = true);
    final msgs = await SmsService.getMessages(_threadId, address: widget.address);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scheduleScrollToBottom(immediate: true);
  }

  void _scheduleScrollToBottom({required bool immediate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (immediate) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final now = DateTime.now();
    if (_lastSendTap != null &&
        now.difference(_lastSendTap!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastSendTap = now;

    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    final resultThread = await SmsService.sendSms(widget.address, text, _threadId);
    if (!mounted) return;
    setState(() => _sending = false);

    if (resultThread != null) {
      if (_threadId.isEmpty) {
        setState(() => _threadId = resultThread);
      }
      await _load(scrollImmediate: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi. Vérifiez la connexion.")),
      );
    }
  }

  Future<void> _goBack() async {
    if (_navigatingBack) return;
    setState(() => _navigatingBack = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) context.go('/discussion/conversations');
  }

  Future<void> _confirmDelete() async {
    if (_threadId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Supprimer la conversation ?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tous les messages seront supprimés définitivement.\nCette action est irréversible.',
          style: TextStyle(fontSize: 18, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await SmsService.deleteThread(_threadId);
    if (!mounted) return;
    if (ok) {
      context.go('/discussion/conversations');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la suppression.')),
      );
    }
  }

  void _insertQuickReply(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  String _initial() {
    if (_contactName.isNotEmpty && _contactName != widget.address) {
      return _contactName[0].toUpperCase();
    }
    if (widget.address.isEmpty) return '?';
    return RegExp(r'^\+?[\d\s\-]+$').hasMatch(widget.address) ? '#' : widget.address[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: _threadId.isNotEmpty
            ? IconButton(
                iconSize: 28,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                tooltip: 'Supprimer la conversation',
                onPressed: _confirmDelete,
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contactPhoto != null
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: MemoryImage(_contactPhoto!),
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Text(
                      _initial(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _contactName.isNotEmpty ? _contactName : widget.address,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_contactName.isNotEmpty &&
                      _contactName != widget.address &&
                      widget.address.isNotEmpty)
                    Text(
                      widget.address,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              iconSize: 56,
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Accueil',
              onPressed: () => context.go('/'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 112,
        color: HandiTheme.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.drag_handle, color: Colors.white54, size: 28),
            Positioned(
              left: 4,
              child: _navigatingBack
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    )
                  : IconButton(
                      iconSize: 52,
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      tooltip: 'Retour',
                      onPressed: _goBack,
                    ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMessageList()),
                QuickReplies(onSelect: _insertQuickReply),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          _threadId.isEmpty
              ? 'Écrivez votre premier message ci-dessous.'
              : 'Aucun message',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: HandiTheme.fontSize, color: HandiTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        HandiTheme.padding,
        HandiTheme.padding,
        HandiTheme.padding,
        8,
      ),
      itemCount: _messages.length,
      itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: HandiTheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: HandiTheme.fontSize),
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                hintStyle: const TextStyle(
                  fontSize: HandiTheme.fontSize,
                  color: HandiTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            height: 72,
            child: _sending
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.send_rounded, size: 32),
                  ),
          ),
        ],
      ),
    );
  }
}
