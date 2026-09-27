import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../widgets/language_menu_button.dart';

Color authBorderColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF60656F)
    : const Color(0xFF767676);

Color authFieldColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0C0E12)
    : Colors.white;

Color authAccentColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkPrimary
    : AppColors.lightPrimaryText;

class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.brandKey,
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final Key brandKey;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                authAccentColor(context).withValues(alpha: 0.07),
                background,
              ),
              background,
              background,
            ],
            stops: const [0, 0.34, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: context.l10n.back,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(44),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHigh,
                                side: BorderSide(
                                  color: authBorderColor(context),
                                ),
                              ),
                            ),
                            Theme(
                              data: theme.copyWith(
                                colorScheme: theme.colorScheme.copyWith(
                                  outline: authBorderColor(context),
                                ),
                              ),
                              child: const LanguageMenuButton(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Container(
                            key: brandKey,
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark
                                    ? const [
                                        Color(0xFF1C2028),
                                        Color(0xFF121419),
                                      ]
                                    : const [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFFFF8E1),
                                      ],
                              ),
                              border: Border.all(
                                color: authAccentColor(
                                  context,
                                ).withValues(alpha: isDark ? 0.55 : 0.75),
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: authAccentColor(
                                    context,
                                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                                  blurRadius: 32,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/trade_pilot_app_icon.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: context.l10n.tradePilotLogo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: authBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFFFF8A8A)
        : const Color(0xFFB91C1C);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1012) : const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 19, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(color: foreground, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF16181F) : Colors.white,
        side: BorderSide(color: authBorderColor(context)),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const ExcludeSemantics(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
      label: Text(label),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    required this.mark,
    required this.markColor,
    super.key,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final String mark;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF16181F) : Colors.white,
        side: BorderSide(color: authBorderColor(context)),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: ExcludeSemantics(
        child: Text(
          mark,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: markColor,
          ),
        ),
      ),
      label: Text(label),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Flexible(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
