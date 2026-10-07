/// Form checks shared by sign-up and settings. Each returns an error message,
/// or null when the value is fine (the shape Flutter's `validator:` expects).
String? validateUsername(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Pick a username';
  if (v.length < 3) return 'At least 3 characters';
  if (v.length > 20) return 'At most 20 characters';
  if (!RegExp(r'^[A-Za-z0-9._]+$').hasMatch(v)) return 'Letters, numbers, dots and underscores only';
  return null;
}

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'That doesn\'t look like an email address';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Choose a password';
  if (v.length < 8) return 'At least 8 characters';
  return null;
}
