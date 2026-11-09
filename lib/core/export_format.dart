import 'dart:convert';

import 'calendar_date.dart';
import 'models.dart';
import 'reach_methods.dart';
import 'reminder.dart';

/// The JSON backup file. Pure Dart.
///
/// Version 1 layout:
/// ```json
/// {
///   "app": "nudge",
///   "version": 1,
///   "exportedAt": "2026-11-09T18:00:00.000Z",
///   "rings":   [{"id": 1, "name": "Close friends", "periodDays": 14}],
///   "members": [{"id": 1, "contactKey": "...", "name": "Jane Doe",
///                "nickname": "Mom", "ringId": 1,
///                "baselineDate": "2026-11-01", "lastContacted": null,
///                "snoozedUntil": null, "lastSurfaced": null,
///                "reachVia": "whatsapp", "reachValue": null}],
///   "history": [{"date": "2026-11-09", "memberId": 1, "status": "done"}],
///   "settings": {"reminder": {"enabled": true, "time": "09:00",
///                             "offerDismissed": true}}
/// }
/// ```
/// Dates are ISO 8601 calendar dates.
const exportFormatVersion = 1;

class ExportData {
  final List<Ring> rings;
  final List<Member> members;
  final List<DailyNudge> history;
  final ReminderSettings reminder;

  /// When the file was written. Null for data not read from a file.
  final DateTime? exportedAt;

  const ExportData({
    required this.rings,
    required this.members,
    required this.history,
    required this.reminder,
    this.exportedAt,
  });

  ExportData copyWith({List<Member>? members}) => ExportData(
    rings: rings,
    members: members ?? this.members,
    history: history,
    reminder: reminder,
    exportedAt: exportedAt,
  );
}

/// Pretty-printed JSON for [data].
String encodeExport(ExportData data, {required DateTime exportedAt}) {
  String? date(CalendarDate? d) => d?.toString();
  final json = {
    'app': 'nudge',
    'version': exportFormatVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'rings': [
      for (final r in data.rings)
        {'id': r.id, 'name': r.name, 'periodDays': r.periodDays},
    ],
    'members': [
      for (final m in data.members)
        {
          'id': m.id,
          'contactKey': m.contactKey,
          'name': m.cachedName,
          'nickname': m.nickname,
          'ringId': m.ringId,
          'baselineDate': date(m.baselineDate),
          'lastContacted': date(m.lastContacted),
          'snoozedUntil': date(m.snoozedUntil),
          'lastSurfaced': date(m.lastSurfaced),
          'reachVia': m.reachVia?.name,
          'reachValue': m.reachValue,
        },
    ],
    'history': [
      for (final n in data.history)
        {'date': date(n.date), 'memberId': n.memberId, 'status': n.status.name},
    ],
    'settings': {
      'reminder': {
        'enabled': data.reminder.enabled,
        'time': data.reminder.time.toString(),
        'offerDismissed': data.reminder.offerDismissed,
      },
    },
  };
  return const JsonEncoder.withIndent('  ').convert(json);
}

/// Parses and validates a backup file. Throws [FormatException] with a
/// message that can be shown to the user.
ExportData decodeExport(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException {
    throw const FormatException('This isn\'t a Nudge backup file.');
  }
  if (root is! Map<String, Object?> || root['app'] != 'nudge') {
    throw const FormatException('This isn\'t a Nudge backup file.');
  }
  final version = root['version'];
  if (version is! int) {
    throw const FormatException('This isn\'t a Nudge backup file.');
  }
  if (version > exportFormatVersion) {
    throw const FormatException(
      'This backup is from a newer version of Nudge. Update the app first.',
    );
  }

  try {
    return _decodeV1(root);
  } on FormatException catch (e) {
    // Messages from _validate are already written for the user.
    if (e.message.startsWith(_damaged)) rethrow;
    throw FormatException('$_damaged (${e.message}).');
  } on Object catch (e) {
    // Wrong types (e.g. a string where a number belongs) and the like.
    throw FormatException('$_damaged ($e).');
  }
}

const _damaged = 'This backup file is damaged';

ExportData _decodeV1(Map<String, Object?> root) {
  List<Map<String, Object?>> list(String key) => [
    for (final item in (root[key] as List?) ?? const [])
      item as Map<String, Object?>,
  ];
  CalendarDate? date(Object? v) =>
      v == null ? null : CalendarDate.parse(v as String);

  final rings = [
    for (final r in list('rings'))
      Ring(
        id: r['id']! as int,
        name: r['name']! as String,
        periodDays: r['periodDays']! as int,
      ),
  ];
  final members = [
    for (final m in list('members'))
      Member(
        id: m['id']! as int,
        contactKey: m['contactKey']! as String,
        cachedName: m['name']! as String,
        nickname: normalizeNickname(m['nickname'] as String?),
        ringId: m['ringId']! as int,
        baselineDate: date(m['baselineDate'])!,
        lastContacted: date(m['lastContacted']),
        snoozedUntil: date(m['snoozedUntil']),
        lastSurfaced: date(m['lastSurfaced']),
        reachVia: ReachMethod.values.asNameMap()[m['reachVia']],
        reachValue: m['reachValue'] as String?,
      ),
  ];
  final history = [
    for (final n in list('history'))
      DailyNudge(
        date: date(n['date'])!,
        memberId: n['memberId']! as int,
        status: NudgeStatus.values.byName(n['status']! as String),
      ),
  ];
  final settings = (root['settings'] as Map<String, Object?>?) ?? const {};
  final reminder = (settings['reminder'] as Map<String, Object?>?) ?? const {};
  final time = reminder['time'] as String?;

  final exportedAt = root['exportedAt'] as String?;
  final data = ExportData(
    rings: rings,
    members: members,
    history: history,
    reminder: ReminderSettings(
      enabled: reminder['enabled'] == true,
      time: time == null ? defaultReminderTime : _parseTime(time),
      offerDismissed: reminder['offerDismissed'] == true,
    ),
    exportedAt: exportedAt == null ? null : DateTime.parse(exportedAt),
  );
  _validate(data);
  return data;
}

ReminderTime _parseTime(String text) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
  final h = int.tryParse(match?[1] ?? '');
  final m = int.tryParse(match?[2] ?? '');
  if (h == null || m == null || h > 23 || m > 59) {
    throw FormatException('Not a time: $text');
  }
  return ReminderTime(h, m);
}

/// The same rules the database enforces, checked up front so a bad file
/// is rejected with a clear message instead of failing half-way.
void _validate(ExportData data) {
  void fail(String why) => throw FormatException('$_damaged ($why).');

  final ringIds = <int>{};
  for (final r in data.rings) {
    if (!ringIds.add(r.id)) fail('ring ${r.id} appears twice');
    if (r.name.trim().isEmpty) fail('ring ${r.id} has no name');
  }
  final memberIds = <int>{};
  final keys = <String>{};
  for (final m in data.members) {
    if (!memberIds.add(m.id)) fail('person ${m.id} appears twice');
    if (!keys.add(m.contactKey)) fail('a contact is in two rings');
    if (!ringIds.contains(m.ringId)) fail('person ${m.id} has no ring');
  }
  final days = <(CalendarDate, int)>{};
  for (final n in data.history) {
    if (!memberIds.contains(n.memberId)) fail('history for unknown person');
    if (!days.add((n.date, n.memberId))) fail('duplicate history entry');
  }
}
