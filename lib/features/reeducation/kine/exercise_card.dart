import 'package:flutter/material.dart';
import 'kine_models.dart';

/// Carte affichant un exercice dans une liste (zone).
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Bandeau coloré gauche ────────────────────────────────────
              Container(
                width: 7,
                height: 84,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: exercise.zone.color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),

              // ── Contenu principal ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exercise.objective,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF666666),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (exercise.durationLabel.isNotEmpty)
                          _InfoChip(
                            icon: exercise.repetitions != null
                                ? Icons.repeat
                                : Icons.timer_outlined,
                            label: exercise.durationLabel,
                          ),
                        if (exercise.side != ExerciseSide.bilateral)
                          _InfoChip(
                            icon: Icons.swap_horiz,
                            label: exercise.side.label,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Flèche ───────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
