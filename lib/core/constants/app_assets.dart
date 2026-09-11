class AppAssets {
  // ── Brand (shared with the web frontend's /public logo set) ───────────────
  /// Full "TRYON2BUY" wordmark, black type + orange "2". Use on light surfaces.
  static const String logoWordmarkBlack = 'assets/images/logo_wordmark_black.png';

  /// Full wordmark in white. Use on dark surfaces.
  static const String logoWordmarkWhite = 'assets/images/logo_wordmark_white.png';

  /// Square "T2B" app mark, black type. Splash / app bar / avatars.
  static const String logoMarkBlack = 'assets/icons/logo_mark_black.png';

  /// Square "T2B" app mark, white type.
  static const String logoMarkWhite = 'assets/icons/logo_mark_white.png';

  // ── Garment Category Avatars ──────────────────────────────────────────────
  static const String categorySaree = 'assets/images/category_saree.jpg';
  static const String categoryLehenga = 'assets/images/category_lehenga.jpg';
  static const String categoryAnarkali = 'assets/images/category_anarkali.jpg';
  static const String categoryKurti = 'assets/images/category_kurti.jpg';
  static const String categorySharara = 'assets/images/category_sharara.jpg';

  // ── Blouse Retoucher Styles (Web Frontend Line Art) ───────────────────────
  static const String sleeveElbow = 'assets/images/elbow_sleeve.png';
  static const String sleeveFull = 'assets/images/full_sleeve.png';
  static const String sleeveLess = 'assets/images/sleeve_less.png';

  static const String neckBoat = 'assets/images/boat_neck.png';
  static const String neckRound = 'assets/images/round_neck.png';
  static const String neckCollar = 'assets/images/collar_neck.png';

  // The hotlinked Unsplash stand-ins that used to sit here are gone: the
  // category rail and the retoucher both ship real artwork now, and nothing
  // referenced them. Every asset above is bundled, so these lists render
  // offline and cannot be broken by someone else's CDN.
}
