import 'package:flutter/material.dart';

enum ProductStateKind { loading, error, empty }

class ProductStateView extends StatelessWidget {
  const ProductStateView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final ProductStateKind kind;
  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stateIcon =
        icon ??
        switch (kind) {
          ProductStateKind.loading => Icons.hourglass_top_rounded,
          ProductStateKind.error => Icons.cloud_off_rounded,
          ProductStateKind.empty => Icons.inbox_outlined,
        };

    return Semantics(
      container: true,
      liveRegion: true,
      label: [title, message].whereType<String>().join('. '),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (kind == ProductStateKind.loading)
              const CircularProgressIndicator()
            else
              Icon(
                stateIcon,
                size: 40,
                color: kind == ProductStateKind.error
                    ? colors.error
                    : colors.onSurfaceVariant,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message case final message?) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(
                  kind == ProductStateKind.error
                      ? Icons.refresh_rounded
                      : Icons.add_rounded,
                ),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
