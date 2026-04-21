import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/handi_scaffold.dart';
import '../../../core/widgets/handi_button.dart';
import '../../../app/theme.dart';
import '../services/sms_service.dart';

class DiscussionSettingsPage extends StatefulWidget {
  const DiscussionSettingsPage({super.key});

  @override
  State<DiscussionSettingsPage> createState() => _DiscussionSettingsPageState();
}

class _DiscussionSettingsPageState extends State<DiscussionSettingsPage> {
  bool _isDefault = false;
  bool _hasPermissions = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    final isDefault = await SmsService.isDefaultSmsApp();
    final hasPerms = await SmsService.hasPermissions();
    if (!mounted) return;
    setState(() {
      _isDefault = isDefault;
      _hasPermissions = hasPerms;
      _loading = false;
    });
  }

  Future<void> _requestPermissions() async {
    await SmsService.requestPermissions();
    await Future.delayed(const Duration(milliseconds: 1200));
    _checkStatus();
  }

  Future<void> _showDiagnostic() async {
    final data = await SmsService.debugAllSms();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diagnostic SMS brut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: data.isEmpty
              ? const Text('Aucun SMS trouvé dans la base Android.')
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final e = data[i];
                    final type = e['type'];
                    final typeLabel = type == 1 ? 'REÇU' : type == 2 ? 'ENVOYÉ' : 'type=$type';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('[$typeLabel] thread:${e['threadId']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: type == 1 ? Colors.blue : Colors.green,
                              )),
                          Text('addr: ${e['address']}', style: const TextStyle(fontSize: 12)),
                          Text('${e['body']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDefault() async {
    await SmsService.requestDefaultSmsApp();
    await Future.delayed(const Duration(milliseconds: 800));
    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Réglages SMS',
      onBack: () => context.go('/discussion'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_hasPermissions) ...[
                  _buildStep(
                    icon: Icons.lock_open_rounded,
                    color: HandiTheme.warning,
                    title: 'Étape 1 — Autoriser l\'accès SMS',
                    description:
                        'L\'application a besoin d\'accéder à vos SMS pour les lire et en envoyer.',
                    buttonLabel: 'Autoriser les SMS',
                    onTap: _requestPermissions,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_hasPermissions && !_isDefault) ...[
                  _buildStep(
                    icon: Icons.check_circle_outline,
                    color: HandiTheme.accent,
                    title: 'Étape 2 — App SMS principale',
                    description:
                        'Pour recevoir les SMS dans cette app, définissez-la comme messagerie principale.',
                    buttonLabel: 'Définir comme app SMS',
                    onTap: _requestDefault,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_hasPermissions && _isDefault) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HandiTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
                      border: Border.all(color: HandiTheme.accent.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: HandiTheme.accent, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tout est configuré correctement.',
                            style: TextStyle(
                              fontSize: HandiTheme.fontSize,
                              fontWeight: FontWeight.w600,
                              color: HandiTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Vérifier le statut'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, HandiTheme.buttonHeight),
                    textStyle: const TextStyle(fontSize: HandiTheme.fontSize),
                  ),
                ),
                if (_hasPermissions) ...[
                  const SizedBox(height: 16),
                  HandiButton(
                    label: 'Retour à Messages',
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.go('/discussion'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showDiagnostic,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Diagnostic SMS brut'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, HandiTheme.buttonHeight),
                      textStyle: const TextStyle(fontSize: HandiTheme.fontSize),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: HandiTheme.fontSize,
                    fontWeight: FontWeight.bold,
                    color: HandiTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 17,
              color: HandiTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          HandiButton(label: buttonLabel, icon: icon, color: color, onTap: onTap),
        ],
      ),
    );
  }
}
