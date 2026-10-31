import 'package:flutter/material.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';

class SeparateurOu extends StatelessWidget {
  const SeparateurOu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espacements.m),
          child: Text(
            context.l10n.ouSeparateur,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}