import 'package:url_launcher/url_launcher.dart';

/// Opens the dialer or messaging app. Injected so tests don't launch
/// anything.
abstract interface class ReachOutLauncher {
  /// Returns false if no app could handle it.
  Future<bool> call(String number);

  Future<bool> text(String number);
}

/// Keeps a leading + and digits only: "(202) 555-0101" -> "2025550101".
String dialableNumber(String number) {
  final trimmed = number.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

class UrlReachOutLauncher implements ReachOutLauncher {
  const UrlReachOutLauncher();

  @override
  Future<bool> call(String number) =>
      _launch(Uri(scheme: 'tel', path: dialableNumber(number)));

  @override
  Future<bool> text(String number) =>
      _launch(Uri(scheme: 'sms', path: dialableNumber(number)));

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri);
    } on Exception {
      return false;
    }
  }
}
