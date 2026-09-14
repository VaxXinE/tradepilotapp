import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../l10n/l10n.dart';

class NewsFeedCard extends StatefulWidget {
  const NewsFeedCard({super.key});

  @override
  State<NewsFeedCard> createState() => NewsFeedCardState();
}

class NewsFeedCardState extends State<NewsFeedCard> {
  List<_NewsArticle> _articles = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(load()));
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .dio
          .get<Object>('/news');
      final root = response.data;
      final raw = root is Map ? root['articles'] : null;
      final articles = raw is List
          ? raw
                .whereType<Map>()
                .map(_NewsArticle.fromJson)
                .whereType<_NewsArticle>()
                .take(5)
                .toList()
          : const <_NewsArticle>[];
      if (mounted) setState(() => _articles = articles);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(_NewsArticle article) async {
    final uri = Uri.tryParse(article.link);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.newsLinkFailed)));
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.latestNews,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : load,
                child: Text(context.l10n.refresh),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            _Message(text: context.l10n.newsLoadFailed, onRetry: load)
          else if (_articles.isEmpty)
            _Message(text: context.l10n.newsEmpty)
          else
            ..._articles.indexed.map(
              (item) => Column(
                children: [
                  if (item.$1 > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.$2.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('${item.$2.source} · ${item.$2.date}'),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 17),
                    onTap: () => _open(item.$2),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            context.l10n.newsDisclaimer,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      children: [
        Text(text),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
      ],
    ),
  );
}

class _NewsArticle {
  const _NewsArticle({
    required this.title,
    required this.source,
    required this.date,
    required this.link,
  });
  final String title;
  final String source;
  final String date;
  final String link;

  static _NewsArticle? fromJson(Map value) {
    final title = value['title']?.toString().trim() ?? '';
    final link = value['link']?.toString().trim() ?? '';
    final uri = Uri.tryParse(link);
    if (title.isEmpty ||
        uri == null ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return null;
    }
    return _NewsArticle(
      title: title,
      source: value['sourceName']?.toString().trim() ?? '',
      date: value['date']?.toString().trim() ?? '',
      link: link,
    );
  }
}
