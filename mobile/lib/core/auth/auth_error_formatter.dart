/// Formatter utility for cleaning raw Auth & Database exceptions into user-friendly strings
class AuthErrorFormatter {
  AuthErrorFormatter._();

  static String format(dynamic e) {
    final str = e.toString();
    if (str.contains('Database error querying schema') ||
        str.contains('unexpected_failure') ||
        str.contains('statusCode: 500')) {
      return 'Backend database error. Logging in via local session...';
    }
    if (str.contains('Invalid login credentials') || str.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (str.contains('User already registered') || str.contains('user_already_exists')) {
      return 'An account with this email already exists. Please Sign In.';
    }
    if (str.contains('SocketException') || str.contains('NetworkException')) {
      return 'Network error. Please check your internet connection.';
    }
    return str.replaceAll(RegExp(r'^AuthException\(|\)$'), '').trim();
  }
}
