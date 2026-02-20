import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Bouton accessible avec protection anti-double-tap (seuil 800 ms).
/// Taille minimale conforme aux recommandations WCAG (72 dp de hauteur).
class HandiButton extends StatefulWidget {
  const HandiButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  State<HandiButton> createState() => _HandiButtonState();
}

class _HandiButtonState extends State<HandiButton> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) {
      return; // Ignore les double-taps involontaires
    }
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? HandiTheme.primary;
    return FilledButton.icon(
      onPressed: _handleTap,
      style: FilledButton.styleFrom(backgroundColor: color),
      icon: widget.icon != null
          ? Icon(widget.icon, size: HandiTheme.iconSize * 0.6)
          : const SizedBox.shrink(),
      label: Text(widget.label),
    );
  }
}
