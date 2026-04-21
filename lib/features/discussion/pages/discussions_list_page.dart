import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/handi_scaffold.dart';
import '../../../app/theme.dart';
import '../models/sms_conversation.dart';
import '../services/contacts_service.dart';
import '../services/sms_service.dart';

class DiscussionsListPage extends StatefulWidget {
  const DiscussionsListPage({super.key});

  @override
  State<DiscussionsListPage> createState() => _DiscussionsListPageState();
}

class _DiscussionsListPageState extends State<DiscussionsListPage> with WidgetsBindingObserver {
  List<SmsConversation> _conversations = [];
  Map<String, String> _nameMap = {};
  Map<String, Uint8List?> _photoMap = {};
  bool _loading = true;
  bool _navigating = false;
  bool? _hasPermissions;
  StreamSubscription<void>? _smsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _smsSub = SmsService.smsEvents.listen((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_navigating) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_navigating && mounted) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final perms = await SmsService.hasPermissions();
    if (!mounted) return;
    if (!perms) {
      setState(() { _hasPermissions = false; _loading = false; });
      return;
    }

    final conversations = await SmsService.getConversations();
    if (!mounted) return;

    final phones = conversations.map((c) => c.address).toList();
    final nameMap = await ContactsService.buildNameMap(phones);
    final photoMap = await ContactsService.buildPhotoMap(phones);
    if (!mounted) return;

    setState(() {
      _hasPermissions = true;
      _conversations = conversations;
      _nameMap = nameMap;
      _photoMap = photoMap;
      _loading = false;
    });
  }

  Future<void> _openConversation(SmsConversation conv) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.go('/discussion/conversation/${conv.threadId}', extra: conv.address);
    }
  }

  String _displayName(String address) => _nameMap[address] ?? address;

  String _formatDate(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Conversations',
      onBack: () => context.go('/discussion'),
      actions: [
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Nouveau message',
          onPressed: () => context.go('/discussion/new'),
        ),
      ],
      body: Stack(
        children: [
          _buildContent(),
          if (_navigating)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_hasPermissions == false) return _buildNoPermission();
    if (_conversations.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildNoPermission() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 72, color: HandiTheme.warning),
          const SizedBox(height: 24),
          const Text(
            'Permissions SMS manquantes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: HandiTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: HandiTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/discussion/settings'),
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Configurer l\'accès'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: HandiTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(fontSize: HandiTheme.fontSizeLarge, color: HandiTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
        itemBuilder: (_, i) {
          final conv = _conversations[i];
          return _ConversationTile(
            conversation: conv,
            displayName: _displayName(conv.address),
            photo: _photoMap[conv.address],
            dateLabel: _formatDate(conv.date),
            onTap: () => _openConversation(conv),
          );
        },
      ),
    );
  }
}

// ── Tile de conversation ──────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.displayName,
    required this.dateLabel,
    required this.onTap,
    this.photo,
  });

  final SmsConversation conversation;
  final String displayName;
  final String dateLabel;
  final Uint8List? photo;
  final VoidCallback onTap;

  String _initial(String name) {
    if (name.isEmpty) return '?';
    if (RegExp(r'^\+?[\d\s\-]+$').hasMatch(name)) return '#';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              photo != null
                  ? CircleAvatar(
                      radius: 36,
                      backgroundImage: MemoryImage(photo!),
                    )
                  : CircleAvatar(
                      radius: 36,
                      backgroundColor: HandiTheme.primary,
                      child: Text(
                        _initial(displayName),
                        style: const TextStyle(
                          fontSize: HandiTheme.fontSizeLarge,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: HandiTheme.fontSizeLarge,
                              fontWeight: conversation.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: HandiTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 16, color: HandiTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conversation.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: HandiTheme.fontSize,
                        color: conversation.isRead ? HandiTheme.textSecondary : HandiTheme.textPrimary,
                        fontWeight: conversation.isRead ? FontWeight.normal : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!conversation.isRead)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    color: HandiTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
