import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/reach_methods.dart';

void main() {
  const number = '+1 (202) 555-0101';

  test('phone and SMS links keep the + and digits', () {
    expect(reachUri(ReachMethod.call, number).toString(), 'tel:+12025550101');
    expect(reachUri(ReachMethod.text, number).toString(), 'sms:+12025550101');
    expect(
      reachUri(ReachMethod.call, '202 555 0101').toString(),
      'tel:2025550101',
    );
  });

  test('WhatsApp uses wa.me with digits only', () {
    expect(
      reachUri(ReachMethod.whatsapp, number).toString(),
      'https://wa.me/12025550101',
    );
  });

  test('Signal uses signal.me with a + number in the fragment', () {
    final uri = reachUri(ReachMethod.signal, number)!;
    expect(uri.toString(), 'https://signal.me/#p/+12025550101');
    expect(uri.host, 'signal.me');
    expect(uri.fragment, 'p/+12025550101');
  });

  test('Telegram uses t.me/+number', () {
    expect(
      reachUri(ReachMethod.telegram, number).toString(),
      'https://t.me/+12025550101',
    );
  });

  test('a number with no digits gives no link', () {
    for (final m in ReachMethod.values.where((m) => m.usesPhoneNumber)) {
      expect(reachUri(m, ' - '), isNull, reason: m.name);
    }
  });

  test('custom links: bare domains get https, unsafe schemes rejected', () {
    expect(parseCustomLink('m.me/jane').toString(), 'https://m.me/jane');
    expect(
      parseCustomLink(' https://instagram.com/jane ').toString(),
      'https://instagram.com/jane',
    );
    expect(
      parseCustomLink('discord://-/users/123').toString(),
      'discord://-/users/123',
    );
    expect(parseCustomLink(''), isNull);
    expect(parseCustomLink('not a link'), isNull);
    expect(parseCustomLink('javascript:alert(1)'), isNull);
    expect(parseCustomLink('file:///etc/passwd'), isNull);
    expect(parseCustomLink('https://'), isNull);
    expect(
      reachUri(ReachMethod.link, 'm.me/jane').toString(),
      'https://m.me/jane',
    );
  });

  test('method properties', () {
    expect(ReachMethod.whatsapp.isMessagingApp, isTrue);
    expect(ReachMethod.call.isMessagingApp, isFalse);
    expect(ReachMethod.link.usesPhoneNumber, isFalse);
    expect(ReachMethod.signal.needsInternationalNumber, isTrue);
    expect(hasCountryCode(' +44 20 7946 0000'), isTrue);
    expect(hasCountryCode('020 7946 0000'), isFalse);
  });

  group('Signal username links', () {
    const link = 'https://signal.me/#eu/Example-Opaque_Token123';

    test('opened as-is, not turned into a phone link', () {
      expect(reachUri(ReachMethod.signal, link).toString(), link);
      expect(reachUri(ReachMethod.signal, '  $link ').toString(), link);
      expect(isUsernameValue(ReachMethod.signal, link), isTrue);
    });

    test('lenient about the part after #, adds a missing https', () {
      expect(
        parseSignalUsernameLink('signal.me/#u/anything').toString(),
        'https://signal.me/#u/anything',
      );
    });

    test('rejects other hosts, phone links, http and plain usernames', () {
      for (final bad in [
        'https://evil.example/#eu/x',
        'https://signal.me/#p/+12025550101',
        'https://signal.me/',
        'http://signal.me/#eu/x',
        'cousin.01',
        '+1 202 555 0101',
      ]) {
        expect(parseSignalUsernameLink(bad), isNull, reason: bad);
      }
    });

    test('phone numbers still build phone links', () {
      expect(isUsernameValue(ReachMethod.signal, number), isFalse);
      expect(
        reachUri(ReachMethod.signal, number).toString(),
        'https://signal.me/#p/+12025550101',
      );
    });
  });

  group('Telegram usernames', () {
    test('accepts @name, name and t.me links, normalised to @name', () {
      for (final input in [
        '@jane_doe',
        'jane_doe',
        't.me/jane_doe',
        'https://t.me/jane_doe',
        'https://telegram.me/jane_doe/',
      ]) {
        expect(parseTelegramUsername(input), '@jane_doe', reason: input);
      }
    });

    test('opens t.me/<name>', () {
      expect(
        reachUri(ReachMethod.telegram, '@jane_doe').toString(),
        'https://t.me/jane_doe',
      );
    });

    test('phone numbers are never mistaken for usernames', () {
      for (final input in [number, '2025550101', 't.me/+12025550101']) {
        expect(parseTelegramUsername(input), isNull, reason: input);
        expect(isUsernameValue(ReachMethod.telegram, input), isFalse);
      }
      expect(
        reachUri(ReachMethod.telegram, number).toString(),
        'https://t.me/+12025550101',
      );
    });

    test('rejects invalid usernames', () {
      for (final bad in ['@ab', '_jane', 'jane doe', '@' * 3, 'a' * 40]) {
        expect(parseTelegramUsername(bad), isNull, reason: bad);
      }
    });
  });

  test('only Signal and Telegram support usernames', () {
    expect(ReachMethod.values.where((m) => m.supportsUsername), [
      ReachMethod.signal,
      ReachMethod.telegram,
    ]);
    expect(isUsernameValue(ReachMethod.whatsapp, '@jane_doe'), isFalse);
  });
}
