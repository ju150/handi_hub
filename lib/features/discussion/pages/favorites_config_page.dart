import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/handi_scaffold.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../services/favorites_service.dart';

class FavoritesConfigPage extends StatefulWidget {
  const FavoritesConfigPage({super.key});

  @override
  State<FavoritesConfigPage> createState() => _FavoritesConfigPageState();
}

class _FavoritesConfigPageState extends State<FavoritesConfigPage> {
  List<Contact> _contacts = [];
  List<String> _selected = []; // numéros de téléphone sélectionnés
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await ContactsService.getContacts();
    final favorites = await FavoritesService.getFavorites();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _selected = favorites;
      _loading = false;
    });
  }

  void _toggle(Contact contact) {
    final phone = contact.phones.first;
    setState(() {
      if (_selected.contains(phone)) {
        _selected.remove(phone);
      } else if (_selected.length < FavoritesService.maxFavorites) {
        _selected.add(phone);
      }
    });
  }

  Future<void> _save() async {
    await FavoritesService.setFavorites(_selected);
    if (!mounted) return;
    context.go('/discussion');
  }

  List<Contact> get _filtered {
    if (_search.isEmpty) return _contacts;
    final q = _search.toLowerCase();
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phones.any((p) => p.contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Choisir les favoris',
      onBack: () => context.go('/discussion'),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            'Enregistrer',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCounter(),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 8),
                Expanded(child: _buildContactList()),
              ],
            ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HandiTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        border: Border.all(color: HandiTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${_selected.length} / ${FavoritesService.maxFavorites} favoris sélectionnés',
        style: TextStyle(
          fontSize: HandiTheme.fontSize,
          fontWeight: FontWeight.w600,
          color: _selected.length == FavoritesService.maxFavorites
              ? HandiTheme.primary
              : HandiTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: const TextStyle(fontSize: HandiTheme.fontSize),
      decoration: InputDecoration(
        hintText: 'Rechercher un contact…',
        hintStyle: const TextStyle(
          fontSize: HandiTheme.fontSize,
          color: HandiTheme.textSecondary,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildContactList() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Aucun contact trouvé',
          style: TextStyle(fontSize: HandiTheme.fontSize, color: HandiTheme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = list[i];
        final phone = c.phones.first;
        final isSelected = _selected.contains(phone);
        final canAdd = _selected.length < FavoritesService.maxFavorites;

        return InkWell(
          onTap: (!isSelected && !canAdd) ? null : () => _toggle(c),
          child: Opacity(
            opacity: (!isSelected && !canAdd) ? 0.4 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  c.photo != null
                      ? CircleAvatar(
                          radius: 28,
                          backgroundImage: MemoryImage(c.photo!),
                        )
                      : CircleAvatar(
                          radius: 28,
                          backgroundColor: HandiTheme.primary,
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: HandiTheme.fontSize,
                            fontWeight: FontWeight.w600,
                            color: HandiTheme.textPrimary,
                          ),
                        ),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 15,
                            color: HandiTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (!isSelected && !canAdd) ? null : (_) => _toggle(c),
                    activeColor: HandiTheme.primary,
                    side: const BorderSide(width: 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
