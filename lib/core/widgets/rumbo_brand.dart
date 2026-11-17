import 'package:flutter/material.dart';

class RumboBrand extends StatelessWidget {
  final double iconSize;
  final double textSize;
  final bool showSubtitle;

  const RumboBrand({
    super.key,
    this.iconSize = 44,
    this.textSize = 23,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(iconSize * 0.32),
          ),
          child: Icon(
            Icons.explore_rounded,
            color: colorScheme.onPrimary,
            size: iconSize * 0.60,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rumbo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: textSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 1),
              Text(
                'Prepara tu próximo viaje',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
