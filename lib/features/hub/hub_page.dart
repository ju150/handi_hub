import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

// page principale du hub de l'application
class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  // null = pas de chargement ; sinon = nom du module en cours d'ouverture
  String? _openingModule;
  IconData? _openingIcon;

  Future<void> _navigateTo(
      String label, IconData icon, String route) async {
    if (_openingModule != null) return; // déjà en cours
    setState(() {
      _openingModule = label;
      _openingIcon = icon;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HandiTheme.background,
      bottomNavigationBar: Container(
        height: 112,
        color: HandiTheme.primary,
        child: const Center(
          child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'HandiHub',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: HandiTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(HandiTheme.padding),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      _HubTile(
                        label: 'Lecture',
                        icon: Icons.menu_book,
                        color: const Color(0xFF1565C0),
                        disabled: _openingModule != null,
                        onTap: () => _navigateTo(
                            'Lecture', Icons.menu_book, '/lecture'),
                      ),
                      _HubTile(
                        label: 'Jeux',
                        icon: Icons.sports_esports,
                        color: const Color(0xFF2E7D32),
                        disabled: _openingModule != null,
                        onTap: () => _navigateTo(
                            'Jeux', Icons.sports_esports, '/games'),
                      ),
                      _HubTile(
                        label: 'Discussion',
                        icon: Icons.chat_bubble,
                        color: const Color(0xFF6A1B9A),
                        disabled: _openingModule != null,
                        onTap: () => _navigateTo(
                            'Discussion', Icons.chat_bubble, '/discussion'),
                      ),
                      _HubTile(
                        label: 'Rééducation',
                        icon: Icons.self_improvement,
                        color: const Color(0xFFE65100),
                        disabled: _openingModule != null,
                        onTap: () => _navigateTo('Rééducation',
                            Icons.self_improvement, '/reeducation'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Overlay plein écran ──────────────────────────────────────────
          if (_openingModule != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _openingIcon,
                      size: 96,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Ouverture de $_openingModule…',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 7,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Levez le stylet',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.disabled,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      ),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
          child: Container(
            color: disabled ? color.withValues(alpha: 0.5) : color,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: HandiTheme.iconSize, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: HandiTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
