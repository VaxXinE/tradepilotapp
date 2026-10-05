/// Outcome the web top-up page reports when it sends the user back to the app.
enum TopupReturnStatus { approved, failed, cancelled, processing }

/// Parsed `id.tradepilot.app://topup/result?status=...&id=...` link.
///
/// The link is only a signal that the browser part is over. It carries no
/// amount and no credit count, and the app never trusts it for either: the
/// balance is always read from the server afterwards.
class TopupReturnLink {
  const TopupReturnLink({required this.status, this.topupId});

  static const scheme = 'id.tradepilot.app';
  static const host = 'topup';

  final TopupReturnStatus status;
  final int? topupId;

  /// Returns `null` for any URI that is not a well-formed top-up return link.
  static TopupReturnLink? tryParse(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    final status = switch (uri.queryParameters['status']?.toLowerCase()) {
      'approved' || 'success' => TopupReturnStatus.approved,
      'failed' || 'rejected' => TopupReturnStatus.failed,
      'cancelled' || 'cancel' => TopupReturnStatus.cancelled,
      'processing' || 'pending' => TopupReturnStatus.processing,
      _ => null,
    };
    if (status == null) return null;
    final id = int.tryParse(uri.queryParameters['id'] ?? '');
    return TopupReturnLink(
      status: status,
      topupId: id != null && id > 0 ? id : null,
    );
  }
}
