import 'package:url_launcher/url_launcher.dart';

import '../core/reach_methods.dart';

/// Opens the dialer, messaging app, or a custom link. Injected so tests
/// don't launch anything.
abstract interface class ReachOutLauncher {
  /// Opens [method] for [value] (a phone number or link). Returns false if
  /// [value] isn't usable or no app could handle it.
  Future<bool> open(ReachMethod method, String value);
}

class UrlReachOutLauncher implements ReachOutLauncher {
  const UrlReachOutLauncher();

  @override
  Future<bool> open(ReachMethod method, String value) async {
    final uri = reachUri(method, value);
    if (uri == null) return false;
    final mode = switch (method) {
      // Only the app itself, never a browser: if WhatsApp/Signal/Telegram
      // isn't installed we report that instead of sending the number to
      // the service's website.
      ReachMethod.whatsapp ||
      ReachMethod.signal ||
      ReachMethod.telegram => LaunchMode.externalNonBrowserApplication,
      ReachMethod.link => LaunchMode.externalApplication,
      ReachMethod.call || ReachMethod.text => LaunchMode.platformDefault,
    };
    try {
      return await launchUrl(uri, mode: mode);
    } on Exception {
      return false;
    }
  }
}
