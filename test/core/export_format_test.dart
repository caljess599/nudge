import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/contact_matching.dart';
import 'package:nudge/core/export_format.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/core/reach_methods.dart';
import 'package:nudge/core/reminder.dart';

import 'test_helpers.dart';

void main() {
  final data = ExportData(
    rings: [
      Ring(id: 1, name: 'Close friends', periodDays: 14),
      Ring(id: 2, name: 'Family', periodDays: 30),
    ],
    members: [
      member(1, baseline: d(1), lastContacted: d(5), lastSurfaced: d(4)),
      member(2, ringId: 2, baseline: d(2), snoozedUntil: d(22)).copyWith(
        nickname: () => 'Mom',
        reachVia: () => ReachMethod.whatsapp,
        reachValue: () => '+1 202 555 0101',
      ),
    ],
    history: [
      DailyNudge(date: d(4), memberId: 1, status: NudgeStatus.done),
      DailyNudge(date: d(9), memberId: 2),
    ],
    reminder: const ReminderSettings(
      enabled: true,
      time: ReminderTime(7, 30),
      offerDismissed: true,
    ),
  );
  final exportedAt = DateTime.utc(2026, 11, 9, 18);

  test('round-trips everything', () {
    final text = encodeExport(data, exportedAt: exportedAt);
    final back = decodeExport(text);
    expect(back.rings, data.rings);
    expect(back.members, data.members);
    expect(back.history, data.history);
    expect(back.reminder, data.reminder);
    expect(back.exportedAt, exportedAt);
  });

  test('includes app name, schema version and readable dates', () {
    final json = jsonDecode(encodeExport(data, exportedAt: exportedAt)) as Map;
    expect(json['app'], 'nudge');
    expect(json['version'], exportFormatVersion);
    final first = (json['members'] as List).first as Map;
    expect(first['baselineDate'], '2026-11-01');
    expect(first['name'], 'Person 1');
  });

  group('rejects bad files with a clear message', () {
    String withJson(void Function(Map<String, Object?> json) change) {
      final json = jsonDecode(
        encodeExport(data, exportedAt: exportedAt),
      ) as Map<String, Object?>;
      change(json);
      return jsonEncode(json);
    }

    void rejects(String text, String messagePart) => expect(
      () => decodeExport(text),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains(messagePart),
        ),
      ),
    );

    test('not JSON, or not ours', () {
      rejects('hello', 'isn\'t a Nudge backup');
      rejects('[]', 'isn\'t a Nudge backup');
      rejects('{"app": "other", "version": 1}', 'isn\'t a Nudge backup');
    });

    test('from a newer version', () {
      rejects(withJson((j) => j['version'] = 99), 'newer version');
    });

    test('broken references and duplicates', () {
      rejects(
        withJson((j) => ((j['members'] as List)[0] as Map)['ringId'] = 9),
        'has no ring',
      );
      rejects(
        withJson(
          (j) => ((j['members'] as List)[1] as Map)['contactKey'] = 'key-1',
        ),
        'a contact is in two rings',
      );
      rejects(
        withJson((j) => ((j['history'] as List)[0] as Map)['memberId'] = 9),
        'unknown person',
      );
    });

    test('wrong types and impossible dates', () {
      rejects(
        withJson((j) => ((j['rings'] as List)[0] as Map)['periodDays'] = 'x'),
        'damaged',
      );
      rejects(
        withJson(
          (j) =>
              ((j['members'] as List)[0] as Map)['baselineDate'] = '2026-02-30',
        ),
        'damaged',
      );
    });
  });

  test('unknown reach method is dropped rather than failing', () {
    final json = jsonDecode(
      encodeExport(data, exportedAt: exportedAt),
    ) as Map<String, Object?>;
    ((json['members'] as List)[1] as Map)['reachVia'] = 'carrier-pigeon';
    expect(decodeExport(jsonEncode(json)).members[1].reachVia, isNull);
  });

  test('CalendarDate.parse', () {
    expect(CalendarDate.parse('2028-02-29'), CalendarDate(2028, 2, 29));
    expect(() => CalendarDate.parse('2026-2-1'), throwsFormatException);
    expect(() => CalendarDate.parse('2026-02-29'), throwsFormatException);
  });

  group('matching imported contacts', () {
    Member m(int id, String key, String name) => Member(
      id: id,
      contactKey: key,
      cachedName: name,
      ringId: 1,
      baselineDate: d(1),
    );

    test('key first, then a unique name', () {
      final result = matchMembersToContacts(
        [m(1, 'same-key', 'Ana'), m(2, 'old-phone-key', 'Ben  Okoro ')],
        [
          (key: 'same-key', name: 'Ana Renamed'),
          (key: 'new-key', name: 'ben okoro'),
        ],
      );
      expect(result.map((x) => x.contactKey), ['same-key', 'new-key']);
    });

    test('ambiguous or missing names stay unmatched', () {
      final result = matchMembersToContacts(
        [m(1, 'old-1', 'Sam'), m(2, 'old-2', 'Nobody')],
        [(key: 'a', name: 'Sam'), (key: 'b', name: 'Sam')],
      );
      expect(result.map((x) => x.contactKey), ['old-1', 'old-2']);
    });

    test('a contact is never given to two members', () {
      final result = matchMembersToContacts(
        [m(1, 'k-ana', 'Ana'), m(2, 'old', 'Ana'), m(3, 'old2', 'Cy')],
        [(key: 'k-ana', name: 'Ana'), (key: 'k-cy', name: 'Cy')],
      );
      expect(result.map((x) => x.contactKey), ['k-ana', 'old', 'k-cy']);
    });
  });
}
