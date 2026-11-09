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
}
