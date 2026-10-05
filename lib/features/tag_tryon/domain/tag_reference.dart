/// What a shop's garment tag points at: the shop, the product code printed on
/// the tag, and optionally the colour the tag is tied to.
///
/// Tags carry the website link `https://<host>/try/<clientId>/<productCode>`
/// (with `?variant=<code>` on a swing tag hung on one colour). The host is
/// deliberately not checked: the same tag must keep working whether it was
/// printed against production, staging or a shop's own domain, and nothing
/// here is trusted beyond being two path segments — Inventory decides whether
/// they mean anything.
class TagReference {
  final String clientId;
  final String productCode;

  /// The colour the tag names, or null when the shopper should choose.
  final String? variant;

  const TagReference({
    required this.clientId,
    required this.productCode,
    this.variant,
  });

  static const _tryPathSegment = 'try';

  /// Parses a scanned QR payload, or returns null when it is not a tag.
  ///
  /// Accepts the full link, a scheme-less link (`tryon2buy.com/try/a/b`) and
  /// a bare path (`/try/a/b`), because printed codes have shipped in all
  /// three forms.
  static TagReference? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // No scheme fix-up needed: a host-less `tryon2buy.com/try/a/b` parses
    // with the host as the first path segment, which the search skips.
    final uri = Uri.tryParse(text);
    if (uri == null) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final at = segments.indexOf(_tryPathSegment);
    if (at < 0 || segments.length < at + 3) return null;

    final clientId = segments[at + 1].trim();
    final productCode = segments[at + 2].trim();
    if (clientId.isEmpty || productCode.isEmpty) return null;

    final variant = uri.queryParameters['variant']?.trim();
    return TagReference(
      clientId: clientId,
      productCode: productCode,
      variant: (variant == null || variant.isEmpty) ? null : variant,
    );
  }

  TagReference withVariant(String? variant) => TagReference(
        clientId: clientId,
        productCode: productCode,
        variant: variant,
      );

  @override
  bool operator ==(Object other) =>
      other is TagReference &&
      other.clientId == clientId &&
      other.productCode == productCode &&
      other.variant == variant;

  @override
  int get hashCode => Object.hash(clientId, productCode, variant);

  @override
  String toString() => 'TagReference($clientId/$productCode, variant: $variant)';
}
