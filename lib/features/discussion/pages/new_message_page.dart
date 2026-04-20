import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/handi_scaffold.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../services/sms_service.dart';

class NewMessagePage extends StatefulWidget {
  /// Pré-remplit le destinataire (depuis les favoris).
  final String? initialAddress;

  const NewMessagePage({super.key, this.initialAddress});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  final _recipientFocus = FocusNode();

  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _showSuggestions = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _recipientController.text = widget.initialAddress!;
    }
    _loadContacts();
    _recipientController.addListener(_onRecipientChanged);
    _recipientFocus.addListener(() {
      if (!_recipientFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _recipientController.removeListener(_onRecipientChanged);
    _recipientController.dispose();
    _messageController.dispose();
    _recipientFocus.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.getContacts();
    if (!mounted) return;
    setState(() => _contacts = contacts);
    _onRecipientChanged();
  }

  void _onRecipientChanged() {
    final query = _recipientController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filtered = _contacts.take(8).toList();
        _showSuggestions = _recipientFocus.hasFocus && _contacts.isNotEmpty;
      });
      return;
    }
    setState(() {
      _filtered = _contacts
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.phones.any((p) => p.contains(query)))
          .take(8)
          .toList();
      _showSuggestions = _filtered.isNotEmpty;
    });
  }

  void _selectContact(Contact contact) {
    _recipientController.text = contact.phones.first;
    _recipientController.selection = TextSelection.collapsed(
      offset: _recipientController.text.length,
    );
    setState(() => _showSuggestions = false);
    _recipientFocus.unfocus();
  }

  Future<void> _send() async {
    final address = _recipientController.text.trim();
    final body = _messageController.text.trim();
    if (address.isEmpty || body.isEmpty || _sending) return;

    setState(() => _sending = true);

    final threadId = await SmsService.sendSms(address, body, '');
    if (!mounted) return;
    setState(() => _sending = false);

    if (threadId != null) {
      context.go('/discussion/conversation/$threadId', extra: address);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi. Vérifiez le numéro.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Nouveau message',
      onBack: () => context.go('/discussion'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecipientField(),
          if (_showSuggestions) _buildSuggestions(),
          const SizedBox(height: 16),
          _buildMessageField(),
          const SizedBox(height: 20),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildRecipientField() {
    return TextField(
      controller: _recipientController,
      focusNode: _recipientFocus,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: HandiTheme.fontSize),
      decoration: InputDecoration(
        labelText: 'Destinataire',
        hintText: 'Nom ou numéro…',
        hintStyle: const TextStyle(fontSize: HandiTheme.fontSize, color: HandiTheme.textSecondary),
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        border: Border.all(color: HandiTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = _filtered[i];
          return InkWell(
            onTap: () => _selectContact(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: HandiTheme.primary,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                          c.phones.first,
                          style: const TextStyle(
                            fontSize: 16,
                            color: HandiTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      maxLines: 5,
      minLines: 3,
      style: const TextStyle(fontSize: HandiTheme.fontSize),
      decoration: InputDecoration(
        labelText: 'Message',
        hintText: 'Écrire un message…',
        hintStyle: const TextStyle(fontSize: HandiTheme.fontSize, color: HandiTheme.textSecondary),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: HandiTheme.buttonHeight,
      child: FilledButton.icon(
        onPressed: _sending ? null : _send,
        icon: _sending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : const Icon(Icons.send_rounded, size: 28),
        label: Text(
          _sending ? 'Envoi…' : 'Envoyer',
          style: const TextStyle(fontSize: HandiTheme.fontSize),
        ),
      ),
    );
  }
}
