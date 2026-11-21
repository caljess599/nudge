/// How a person prefers to be contacted, and how to build the link that
/// opens it. Pure Dart: no Flutter or plugin imports.
enum ReachMethod {
  call('Phone call'),
  text('Text message'),
  whatsapp('WhatsApp'),
  signal('Signal'),
  telegram('Telegram'),
  link('Custom link');

  final String label;

  const ReachMethod(this.label);

  /// Methods that are reached through a phone number.
  bool get usesPhoneNumber => this != link;

  /// Messaging apps opened through their own web links. These must open
  /// in the app itself, never a browser, so the number isn't sent to the
  /// service's website when the app isn't installed.
  bool get isMessagingApp =>
      this == whatsapp || this == signal || this == telegram;

  /// These apps find people by international number, so a number without
  /// a country code (+...) may not work.
  bool get needsInternationalNumber => isMessagingApp;

  /// Signal and Telegram can also be reached by username, for people who
  /// don't let others find them by phone number.
  bool get supportsUsername => this == signal || this == telegram;
}

/// A Signal username link, as shared from someone's Signal profile.
///
/// Deliberately lenient about what follows the `#`: any https link on
/// signal.me counts, except phone-number links (`#p/...`), which Nudge
/// builds itself from a number. Adds https:// if it was left off.
Uri? parseSignalUsernameLink(String input) {
  var text = input.trim();
  if (text.isEmpty || text.contains(' ')) return null;
  if (text.startsWith('signal.me/')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.scheme != 'https' || uri.host != 'signal.me') {
    return null;
  }
  if (uri.fragment.isEmpty || uri.fragment.startsWith('p/')) return null;
  return uri;
}

/// A Telegram username from `@name`, `name`, `t.me/name` or
/// `https://t.me/name`, returned as `@name`. Telegram usernames start with
/// a letter and use letters, digits and underscores, so they can't be
/// confused with a phone number.
String? parseTelegramUsername(String input) {
  var text = input.trim();
  final link = RegExp(
    r'^(?:https?://)?(?:t|telegram)\.me/([^/?#]+)/?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (link != null) text = link[1]!;
  if (text.startsWith('@')) text = text.substring(1);
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{3,31}$').hasMatch(text)) return null;
  return '@$text';
}

/// Whether [value] is a username (or username link) rather than a phone
/// number. Only Signal and Telegram support usernames.
bool isUsernameValue(ReachMethod method, String value) => switch (method) {
  ReachMethod.signal => parseSignalUsernameLink(value) != null,
  ReachMethod.telegram => parseTelegramUsername(value) != null,
  _ => false,
};

/// Keeps a leading + and digits only: "(202) 555-0101" -> "2025550101".
String dialableNumber(String number) {
  final trimmed = number.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

bool hasCountryCode(String number) => number.trim().startsWith('+');

/// The link that opens [method] for [value]: a phone number, a Signal
/// username link, a Telegram username, or for [ReachMethod.link] the URL.
/// Returns null if [value] can't be used.
Uri? reachUri(ReachMethod method, String value) {
  if (method == ReachMethod.link) return parseCustomLink(value);
  if (method == ReachMethod.signal) {
    final link = parseSignalUsernameLink(value);
    if (link != null) return link;
  }
  if (method == ReachMethod.telegram) {
    final username = parseTelegramUsername(value);
    if (username != null) return Uri.https('t.me', '/${username.substring(1)}');
  }

  final dialable = dialableNumber(value);
  final digits = dialable.replaceAll('+', '');
  if (digits.isEmpty) return null;
  return switch (method) {
    ReachMethod.call => Uri(scheme: 'tel', path: dialable),
    ReachMethod.text => Uri(scheme: 'sms', path: dialable),
    // https://faq.whatsapp.com/5913398998672934: digits only, no + or 0s.
    ReachMethod.whatsapp => Uri.https('wa.me', '/$digits'),
    // Signal phone-number links: https://signal.me/#p/+<E.164>
    ReachMethod.signal => Uri.parse('https://signal.me/#p/+$digits'),
    // Telegram: https://t.me/+<number> (only if they allow being found
    // by phone number).
    ReachMethod.telegram => Uri.https('t.me', '/+$digits'),
    ReachMethod.link => null,
  };
}

/// Accepts links like `https://m.me/name` or `instagram://user?username=x`.
/// Adds https:// to bare domains. Rejects schemes that could run code or
/// read files.
Uri? parseCustomLink(String input) {
  var text = input.trim();
  if (text.isEmpty || text.contains(' ')) return null;
  if (!text.contains('://') && !text.contains(':')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.scheme.isEmpty) return null;
  const blocked = {'javascript', 'file', 'data', 'content', 'intent'};
  if (blocked.contains(uri.scheme.toLowerCase())) return null;
  if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty) {
    return null;
  }
  return uri;
}
