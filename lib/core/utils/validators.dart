/// Input validation for sign-in forms. Returns an error message, or null
/// when the value is acceptable.
class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? name(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Please enter your name.';
    if (v.length < 2) return 'Name is too short.';
    return null;
  }

  /// Accepts spaces, dashes and a leading +; requires 10 to 15 digits.
  static String? phone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Please enter your phone number.';
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number with 10 to 15 digits.';
    }
    return null;
  }

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Please enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String value, {int minLength = 6}) {
    if (value.isEmpty) return 'Please enter your password.';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }
}
