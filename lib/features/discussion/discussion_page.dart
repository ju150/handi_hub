import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'models/sms_conversation.dart';
import 'services/contacts_service.dart';
import 'services/favorites_service.dart';
import 'services/sms_service.dart';
import 'widgets/favorite_contact_card.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key});

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  List<String> _favorites = [];
  Map<String, String> _nameMap = {};
  Map<String, Uint8List?> _photoMap = {};
  List<SmsConversation> _conversations = [];
  bool _loading = true;
  bool _hasPermissions = false;
  DateTime? _lastFavoriteTap;
  GoRouter? _goRouter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // S'abonner une seule fois aux changements de route pour recharger au retour.
    if (_goRouter == null) {
      _goRouter = GoRouter.of(context);
      _goRouter!.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    _goRouter?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted || _loading) return;
    final path = _goRouter?.routerDelegate.currentConfiguration.uri.path;
    if (path == '/discussion') {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final perms = await SmsService.hasPermissions();
    if (!mounted) return;
    if (!perms) {
      setState(() {
        _hasPermissions = false;
        _loading = false;
      });
      return;
    }

    final results = await Future.wait([
      FavoritesService.getFavorites(),
      SmsService.getConversations(),
    ]);
    if (!mounted) return;

    final favorites = results[0] as List<String>;
    final conversations = results[1] as List<SmsConversation>;

    final nameMap = await ContactsService.buildNameMap(favorites);
    final photoMap = await ContactsService.buildPhotoMap(favorites);
    if (!mounted) return;

    setState(() {
      _hasPermissions = true;
      _favorites = favorites;
      _conversations = conversations;
      _nameMap = nameMap;
      _photoMap = photoMap;
      _loading = false;
    });
  }

  void _openFavorite(String address) {
    // Debounce anti-double-tap : 800 ms.
    final now = DateTime.now();
    if (_lastFavoriteTap != null &&
        now.difference(_lastFavoriteTap!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastFavoriteTap = now;

    final n = ContactsService.normalize(address);
    final conv = _conversations
        .where((c) => ContactsService.normalize(c.address) == n)
        .firstOrNull;
    if (conv != null) {
      context.go('/discussion/conversation/${conv.threadId}', extra: conv.address);
    } else {
      context.go('/discussion/conversation/new', extra: address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 26),
          tooltip: 'Réglages',
          onPressed: () => context.go('/discussion/settings'),
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
        child: const Center(
          child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hasPermissions
                ? _buildHub()
                : _buildNoPermissions(),
      ),
    );
  }

  Widget _buildHub() {
    return Padding(
      padding: const EdgeInsets.all(HandiTheme.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildFavoritesSection()),
          const SizedBox(height: 16),
          _buildConversationsButton(),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    if (_favorites.isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: () => context.go('/discussion/favorites-config'),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HandiTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
              border: Border.all(color: HandiTheme.primary.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_border_rounded, size: 40, color: HandiTheme.primary),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Appuyer pour configurer\nvos 6 contacts favoris',
                    style: TextStyle(
                      fontSize: HandiTheme.fontSize,
                      color: HandiTheme.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: HandiTheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: _favorites.map((address) {
        return FavoriteContactCard(
          name: _nameMap[address] ?? address,
          photo: _photoMap[address],
          onTap: () => _openFavorite(address),
        );
      }).toList(),
    );
  }

  Widget _buildConversationsButton() {
    return SizedBox(
      height: HandiTheme.buttonHeight,
      child: FilledButton.icon(
        onPressed: () => context.go('/discussion/conversations'),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
        label: const Text(
          'Mes autres conversations',
          style: TextStyle(fontSize: HandiTheme.fontSize),
        ),
      ),
    );
  }

  Widget _buildNoPermissions() {
    return Padding(
      padding: const EdgeInsets.all(HandiTheme.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: HandiTheme.textSecondary),
          const SizedBox(height: 24),
          const Text(
            'L\'accès aux SMS n\'est pas encore configuré.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: HandiTheme.fontSize,
              color: HandiTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: HandiTheme.buttonHeight,
            child: FilledButton.icon(
              onPressed: () => context.go('/discussion/settings'),
              icon: const Icon(Icons.settings_rounded),
              label: const Text(
                'Configurer l\'accès',
                style: TextStyle(fontSize: HandiTheme.fontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
