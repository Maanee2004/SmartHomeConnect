import 'package:flutter/material.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Message d’erreur réseau / Firestore avec « Réessayer » et action secondaire optionnelle.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Impossible de charger',
    this.hint,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final String? hint;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering_error_rounded,
                size: 48, color: c.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: c.textSecondary,
                  ),
            ),
            if (hint != null && hint!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: c.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
              label: Text('Réessayer'),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
