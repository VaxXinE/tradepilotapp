import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale_controller.dart';
import '../l10n/l10n.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleController>().locale.languageCode;
    final next = current == 'en' ? 'id' : 'en';
    return IconButton(
      tooltip: context.l10n.language,
      onPressed: () => context.read<LocaleController>().setLanguage(next),
      icon: _FlagIcon(languageCode: current),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(36),
        maximumSize: const Size.square(36),
        padding: const EdgeInsets.all(8),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FlagIcon extends StatelessWidget {
  const _FlagIcon({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) => Semantics(
    label: languageCode == 'en' ? 'US' : 'Indonesia',
    image: true,
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          size: const Size(20, 14),
          painter: _FlagPainter(isIndonesia: languageCode == 'id'),
        ),
      ),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter({required this.isIndonesia});

  final bool isIndonesia;

  @override
  void paint(Canvas canvas, Size size) {
    if (isIndonesia) {
      canvas.drawRect(
        Offset.zero & Size(size.width, size.height / 2),
        Paint()..color = const Color(0xFFE70011),
      );
      canvas.drawRect(
        Offset(0, size.height / 2) & Size(size.width, size.height / 2),
        Paint()..color = Colors.white,
      );
      return;
    }

    final stripeHeight = size.height / 7;
    for (var index = 0; index < 7; index++) {
      canvas.drawRect(
        Offset(0, index * stripeHeight) & Size(size.width, stripeHeight),
        Paint()..color = index.isEven ? const Color(0xFFB22234) : Colors.white,
      );
    }
    canvas.drawRect(
      Offset.zero & Size(size.width * 0.44, size.height * 0.55),
      Paint()..color = const Color(0xFF3C3B6E),
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.isIndonesia != isIndonesia;
}
