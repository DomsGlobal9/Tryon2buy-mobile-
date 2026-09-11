/// Central API surface for the TryOn2Buy backend (Express, `tryon_service`).
///
/// The web frontend talks to the same server. In production the React app is
/// served from Vercel and rewrites `/api/*` to the Render deployment, so its
/// `API_URL` is an empty string. Flutter has no proxy, so we point at the
/// absolute origin instead.
///
/// The origin comes from `--dart-define=API_BASE_URL=…`, normally through the
/// environment files in `env/`:
/// ```
/// flutter run   --dart-define-from-file=env/dev.json
/// flutter build --dart-define-from-file=env/prod.json
/// ```
/// Hosts, as of 2026-09-10:
///   * `https://tryon2buy-backend-dev.onrender.com` runs the backend's `dev`
///     branch — the contract this app is written against (guest generation,
///     B2B catalog, save-to-library). Compiled-in default for debug and
///     profile builds.
///   * `https://tryon2buy-backend.onrender.com` runs `main`, which the
///     website uses but which lacks several routes the app calls. Do not
///     point a release here until `dev` is merged.
///   * `http://10.0.2.2:4000` (Android emulator) / `http://localhost:4000`
///     for a local server; cleartext is allowed in debug builds only.
///
/// A release build refuses to start without an explicit `API_BASE_URL`
/// (see `main.dart`), so a store build can never silently use the dev host.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String devHost = 'https://tryon2buy-backend-dev.onrender.com';

  /// True when the origin was supplied at build time rather than defaulted.
  static const bool hasExplicitBaseUrl = bool.hasEnvironment('API_BASE_URL');

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: devHost,
  );

  /// The origin without a trailing slash. `https://host/` would otherwise
  /// build `https://host//api/…`, which Express does not route, and the only
  /// symptom would be "That item could not be found." on every screen.
  static final String baseUrl = normalizeOrigin(_rawBaseUrl);

  static String normalizeOrigin(String raw) {
    var value = raw.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool get isDevHost => baseUrl == devHost;

  /// Public marketing site — used for share links, not for API calls.
  static const String webAppUrl = 'https://tryon2buy.com';

  // ── Upload folders the server accepts (`POST /api/tryon/upload?folder=`) ──
  // Anything else is rejected with 400.
  static const String folderGarments = 'garments';
  static const String folderUserUploads = 'user-uploads';

  // ── `target_folder` values the website sends with `/api/tryon/generate` ──
  static const String targetVendorDrapes = 'vendor-drapes';
  static const String targetTryonResults = 'results/tryon-results';

  // ── Auth (JWT issued by the backend, HS256, `role` claim, 7-day expiry) ──
  static final String vendorRegister = '$baseUrl/api/auth/vendor/register';
  static final String vendorLogin = '$baseUrl/api/auth/vendor/login';

  // ── Try-On service ────────────────────────────────────────────────────────
  static final String healthCheck = '$baseUrl/api/tryon/health';
  static final String uploadImage = '$baseUrl/api/tryon/upload';
  static final String generateTryon = '$baseUrl/api/tryon/generate';
  static final String changeBackground = '$baseUrl/api/tryon/change-background';
  static final String modifyOutfit = '$baseUrl/api/tryon/modify-outfit';

  /// Vendor-only. Attaches an existing generation to the vendor's library.
  static final String saveToLibrary = '$baseUrl/api/tryon/save-to-library';

  // ── Library / gallery ─────────────────────────────────────────────────────
  /// Vendor's own generations. Requires a *vendor* token.
  static final String vendorGenerations = '$baseUrl/api/tryon/vendor/generations';

  /// Public — no auth. Completed phase-1 drapings for a merchant's shop page.
  static String vendorGallery(String vendorId) =>
      '$baseUrl/api/tryon/vendor/$vendorId/gallery';

  /// Public read of a single generation (used by the deep-link try-on flow).
  static String singleGeneration(String id) =>
      '$baseUrl/api/tryon/generations/$id';

  /// Vendor-scoped delete.
  static String deleteVendorGeneration(String id) =>
      '$baseUrl/api/tryon/vendor/generations/$id';

  // ── B2B Catalog (vendor-scoped, used by the Client Portal) ────────────────
  static final String vendorProfile = '$baseUrl/api/tryon/vendor/profile';
  static final String catalogGenerate = '$baseUrl/api/tryon/catalog/generate';
  static final String catalogSave = '$baseUrl/api/tryon/catalog/save';
  static final String catalogDiscard = '$baseUrl/api/tryon/catalog/discard';
  static final String catalogProducts = '$baseUrl/api/tryon/catalog/products';
  static String catalogProductDelete(String id) =>
      '$baseUrl/api/tryon/catalog/products/$id';

  // ── Auth Profile (read/update business details) ───────────────────────────
  static final String authVendorProfile = '$baseUrl/api/auth/vendor/profile';

  /// Shareable web link for a result, mirroring the React route `/tryon/:id`.
  static String shareLink(String generationId) => '$webAppUrl/tryon/$generationId';

  /// Shareable merchant shop link, mirroring the React route `/shop/:vendorId`.
  static String shopLink(String vendorId) => '$webAppUrl/shop/$vendorId';
}
