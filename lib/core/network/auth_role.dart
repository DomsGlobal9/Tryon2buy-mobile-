/// Which persisted JWT to attach to a request.
///
/// The app has one kind of account — the business (merchant or B2B client),
/// whose JWT carries a `role` claim the backend keys authorization off.
/// Shoppers are guests and send no token, exactly as on the website.
enum AuthRole {
  /// The business token; the route requires it (`vendor/generations`,
  /// `catalog/*`, `save-to-library`).
  vendor,

  /// The business token if one is stored, otherwise nothing. For routes that
  /// also serve guests (`generate`, `change-background`, `modify-outfit`,
  /// `upload`, public reads).
  any,

  /// No token at all. For sign-in and other anonymous calls, so a stale
  /// token from a previous session cannot turn a wrong-password 401 into a
  /// forced sign-out.
  none,
}
