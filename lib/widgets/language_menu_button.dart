import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale_controller.dart';
import '../l10n/l10n.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleController>().locale.languageCode;
    return PopupMenuButton<String>(
      tooltip: context.l10n.language,
      icon: const Icon(Icons.language_rounded),
      initialValue: current,
      onSelected: context.read<LocaleController>().setLanguage,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
      ],
    );
  }
}
