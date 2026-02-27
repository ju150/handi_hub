import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class HubPage extends StatelessWidget {
  const HubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HandiTheme.background,
      body: SafeArea(
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
                    onTap: () => context.go('/lecture'),
                  ),
                  _HubTile(
                    label: 'Jeux',
                    icon: Icons.sports_esports,
                    color: const Color(0xFF2E7D32),
                    onTap: () => context.go('/games'),
                  ),
                  _HubTile(
                    label: 'Discussion',
                    icon: Icons.chat_bubble,
                    color: const Color(0xFF6A1B9A),
                    onTap: () => context.go('/discussion'),
                  ),
                  _HubTile(
                    label: 'Rééducation',
                    icon: Icons.self_improvement,
                    color: const Color(0xFFE65100),
                    onTap: () => context.go('/reeducation'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatefulWidget {
  const _HubTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_HubTile> createState() => _HubTileState();
}

class _HubTileState extends State<_HubTile> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      ),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: HandiTheme.iconSize, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                widget.label,
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
    );
  }
}
