import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_config.dart';
import '../l10n/l10n.dart';
import '../models/market_models.dart';
import '../providers/auth_provider.dart';

class TradePilotAppHeader extends StatelessWidget {
  const TradePilotAppHeader({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.unreadCount,
    required this.languageButton,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onOpenHome,
    required this.profileActive,
    this.onBack,
    required this.notificationsLabel,
    required this.profileLabel,
    required this.themeLabel,
    required this.logoLabel,
    required this.backLabel,
  });

  final String displayName;
  final String? avatarUrl;
  final int unreadCount;
  final Widget languageButton;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;

  /// Membuka layar utama, sama seperti tautan brand pada header web.
  final VoidCallback onOpenHome;

  /// Menyalakan cincin pada avatar ketika layar Profil sedang terbuka.
  final bool profileActive;

  /// Diisi ketika layar aktif bukan salah satu tab utama. Web menampilkan
  /// tombol kembali pada kondisi yang sama.
  final VoidCallback? onBack;
  final String notificationsLabel;
  final String profileLabel;
  final String themeLabel;
  final String logoLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: 0.96),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  key: const Key('app-header-back'),
                  tooltip: backLabel,
                  onPressed: onBack,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                ),
              InkWell(
                key: const Key('app-header-brand'),
                onTap: onOpenHome,
                borderRadius: BorderRadius.circular(8),
                child: Semantics(
                  label: logoLabel,
                  image: true,
                  child: Image.asset(
                    'assets/images/trade_pilot_app_icon.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'TradePilot',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '.id',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              languageButton,
              IconButton(
                tooltip: themeLabel,
                onPressed: onToggleTheme,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 19,
                  color: isDarkMode ? const Color(0xFFFAB505) : null,
                ),
              ),
              // Urutan mengikuti header web: bahasa, tema, avatar, lonceng.
              const SizedBox(width: 2),
              Tooltip(
                message: profileLabel,
                child: InkWell(
                  key: const Key('app-header-profile'),
                  onTap: onOpenProfile,
                  customBorder: const CircleBorder(),
                  child: _ProfileAvatar(
                    displayName: displayName,
                    avatarUrl: avatarUrl,
                    isActive: profileActive,
                  ),
                ),
              ),
              IconButton(
                tooltip: notificationsLabel,
                onPressed: onOpenNotifications,
                visualDensity: VisualDensity.compact,
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  child: const Icon(Icons.notifications_none_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ticker atas seperti mobile web: badge Live Quote, harga live, badge Breaking
/// News, lalu headline berita yang dapat dibuka.
///
/// Konten digandakan dan digeser terus-menerus seperti animasi marquee web.
/// Ketika sistem meminta pengurangan animasi, ticker berhenti bergerak dan
/// tetap dapat digeser manual.
class LiveMarketTicker extends StatefulWidget {
  const LiveMarketTicker({super.key, required this.quotes, this.newsLimit = 3});

  final Iterable<LiveMarketQuote> quotes;
  final int newsLimit;

  @override
  State<LiveMarketTicker> createState() => _LiveMarketTickerState();
}

class _LiveMarketTickerState extends State<LiveMarketTicker>
    with SingleTickerProviderStateMixin {
  static const _pausedKey = 'tradepilot_ticker_paused';
  static const _hiddenKey = 'tradepilot_ticker_hidden';
  static const _pixelsPerSecond = 34.0;
  static const _newsRefreshInterval = Duration(minutes: 5);

  final ScrollController _scrollController = ScrollController();
  List<_TickerArticle> _articles = const [];
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  Timer? _newsTimer;
  bool _paused = false;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    unawaited(_restorePreferences());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadNews());
      _newsTimer = Timer.periodic(
        _newsRefreshInterval,
        (_) => unawaited(_loadNews()),
      );
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .dio
          .get<Object>(
            '/ticker-news',
            queryParameters: {'limit': widget.newsLimit},
          );
      final root = response.data;
      final raw = root is Map ? root['articles'] : null;
      final articles = raw is List
          ? raw
                .whereType<Map>()
                .map(_TickerArticle.fromJson)
                .whereType<_TickerArticle>()
                .take(widget.newsLimit)
                .toList()
          : const <_TickerArticle>[];
      if (mounted) setState(() => _articles = articles);
    } catch (_) {
      // Ticker tetap menampilkan harga ketika berita gagal dimuat.
    }
  }

  Future<void> _restorePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _paused = preferences.getBool(_pausedKey) ?? false;
      _hidden = preferences.getBool(_hiddenKey) ?? false;
    });
  }

  Future<void> _setPaused(bool value) async {
    setState(() => _paused = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pausedKey, value);
  }

  Future<void> _setHidden(bool value) async {
    setState(() => _hidden = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hiddenKey, value);
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    if (_paused) return;
    if (!_scrollController.hasClients) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;

    final position = _scrollController.position;
    // Konten digandakan, jadi satu putaran penuh adalah setengah lebar total.
    final loopWidth =
        (position.maxScrollExtent + position.viewportDimension) / 2;
    if (loopWidth <= 0) return;

    var offset =
        position.pixels + _pixelsPerSecond * delta.inMicroseconds / 1000000;
    if (offset >= loopWidth) offset -= loopWidth;
    _scrollController.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final quotes = widget.quotes.where((quote) => quote.price > 0).toList();
    if (quotes.isEmpty && _articles.isEmpty) return const SizedBox.shrink();
    if (_hidden) {
      return Container(
        height: 30,
        alignment: Alignment.centerRight,
        color: const Color(0xFF020617),
        child: TextButton.icon(
          onPressed: () => unawaited(_setHidden(false)),
          icon: const Icon(Icons.visibility_rounded, size: 15),
          label: Text(context.l10n.showTicker),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
        ),
      );
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final items = <Widget>[
      if (quotes.isNotEmpty) ...[
        const _TickerBadge(
          label: 'LIVE QUOTE',
          gradient: [Color(0xFFFBBF24), Color(0xFFFDE68A)],
          dotColor: Color(0xFFDC2626),
          foreground: Colors.black,
        ),
        for (final quote in quotes) _TickerItem(quote: quote),
      ],
      if (_articles.isNotEmpty) ...[
        const _TickerSeparator(),
        const _TickerBadge(
          label: 'BREAKING NEWS',
          gradient: [Color(0xFFDC2626), Color(0xFFEF4444)],
          dotColor: Colors.white,
          foreground: Colors.white,
        ),
        for (final article in _articles) _TickerNewsItem(article: article),
        const _TickerSeparator(),
      ],
    ];

    return Semantics(
      container: true,
      label: context.l10n.marketNews,
      child: Container(
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF020617),
          border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              right: 78,
              child: SingleChildScrollView(
                key: const Key('live-market-ticker'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: reduceMotion || _paused
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (var pass = 0; pass < 2; pass++)
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: item,
                        ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: const Color(0xFF020617),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _paused
                          ? context.l10n.resumeTicker
                          : context.l10n.pauseTicker,
                      onPressed: () => unawaited(_setPaused(!_paused)),
                      icon: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 17,
                      ),
                      color: Colors.white70,
                    ),
                    IconButton(
                      tooltip: context.l10n.hideTicker,
                      onPressed: () => unawaited(_setHidden(true)),
                      icon: const Icon(Icons.visibility_off_rounded, size: 16),
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TickerSeparator extends StatelessWidget {
  const _TickerSeparator();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Text('|', style: TextStyle(color: Color(0x66F59E0B), fontSize: 12)),
  );
}

class _TickerBadge extends StatelessWidget {
  const _TickerBadge({
    required this.label,
    required this.gradient,
    required this.dotColor,
    required this.foreground,
  });

  final String label;
  final List<Color> gradient;
  final Color dotColor;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gradient),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}

class _TickerNewsItem extends StatelessWidget {
  const _TickerNewsItem({required this.article});

  final _TickerArticle article;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(article.link);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => unawaited(_open(context)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.newspaper_outlined,
          size: 12,
          color: Color(0xFFFCD34D),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            article.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
          ),
        ),
        if (article.source.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            '· ${article.source}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ],
      ],
    ),
  );
}

class _TickerArticle {
  const _TickerArticle({
    required this.title,
    required this.source,
    required this.link,
  });

  final String title;
  final String source;
  final String link;

  static _TickerArticle? fromJson(Map value) {
    final title = value['title']?.toString().trim() ?? '';
    final link = value['link']?.toString().trim() ?? '';
    final uri = Uri.tryParse(link);
    if (title.isEmpty ||
        uri == null ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return null;
    }
    return _TickerArticle(
      title: title,
      source: value['sourceName']?.toString().trim() ?? '',
      link: link,
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem({required this.quote});

  final LiveMarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final changeColor = quote.isUp
        ? const Color(0xFF34D399)
        : quote.isDown
        ? const Color(0xFFF87171)
        : const Color(0xFF94A3B8);
    final decimals = quote.price.abs() < 10 ? 4 : 2;

    return Semantics(
      label:
          '${quote.instrument}, ${quote.price.toStringAsFixed(decimals)}, '
          '${quote.changePercent.toStringAsFixed(2)} percent',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            quote.instrument,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            quote.price.toStringAsFixed(decimals),
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            quote.isDown ? Icons.arrow_downward : Icons.arrow_upward,
            size: 11,
            color: changeColor,
          ),
          const SizedBox(width: 1),
          Text(
            '${quote.changePercent.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarUrl,
    this.isActive = false,
  });

  final String displayName;
  final String? avatarUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _resolveAvatarUrl(avatarUrl);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      foregroundColor: colors.primary,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
      child: Text(
        displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

    if (!isActive) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: avatar,
    );
  }

  String? _resolveAvatarUrl(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri?.hasScheme == true) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/storage/$clean';
  }
}

// =============================================================================
// BOTTOM NAVIGATION
// =============================================================================

class AppNavItem {
  const AppNavItem({required this.id, required this.icon, required this.label});

  final int id;
  final IconData icon;
  final String label;
}

/// Navigasi bawah mengikuti shell mobile dengan Beranda di samping Analisis.
/// Profil tetap dibuka lewat avatar sehingga tidak memerlukan tab sendiri.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.activeId,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int? activeId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final item in items)
                  Expanded(
                    child: _NavButton(
                      item: item,
                      isActive: item.id == activeId,
                      onTap: () => onSelected(item.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isActive ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 18, color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  color: foreground,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
