import 'dart:math';

import 'package:drift/drift.dart';

import '../core/calendar_date.dart';
import '../core/actions.dart';
import '../core/daily_nudges.dart';
import '../core/due_dates.dart';
import '../core/models.dart';

part 'database.g.dart';

/// Stores [CalendarDate] as an integer number of days since 1970-01-01.
class CalendarDateConverter extends TypeConverter<CalendarDate, int> {
  const CalendarDateConverter();

  @override
  CalendarDate fromSql(int fromDb) => CalendarDate.fromEpochDay(fromDb);

  @override
  int toSql(CalendarDate value) => value.epochDay;
}

@DataClassName('RingRow')
class Rings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get periodDays => integer()();

  @override
  List<String> get customConstraints => ['CHECK (period_days > 0)'];
}

@DataClassName('MemberRow')
class Members extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UNIQUE: enforces one ring per contact at the database level.
  TextColumn get contactKey => text().unique()();
  TextColumn get cachedName => text()();

  /// RESTRICT: a ring with members can't be deleted until they're moved.
  IntColumn get ringId =>
      integer().references(Rings, #id, onDelete: KeyAction.restrict)();

  IntColumn get baselineDate => integer().map(const CalendarDateConverter())();
  IntColumn get lastContacted =>
      integer().map(const CalendarDateConverter()).nullable()();
  IntColumn get snoozedUntil =>
      integer().map(const CalendarDateConverter()).nullable()();
  IntColumn get lastSurfaced =>
      integer().map(const CalendarDateConverter()).nullable()();
}

@DataClassName('DailyNudgeRow')
class DailyNudges extends Table {
  IntColumn get date => integer().map(const CalendarDateConverter())();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => textEnum<NudgeStatus>()();

  @override
  Set<Column> get primaryKey => {date, memberId};
}

/// A contact to add to a ring.
class NewMember {
  final String contactKey;
  final String cachedName;

  const NewMember({required this.contactKey, required this.cachedName});
}

class RingSummary {
  final Ring ring;
  final int memberCount;

  const RingSummary(this.ring, this.memberCount);
}

/// A saved nudge with the member and ring it refers to.
class NudgeEntry {
  final DailyNudge nudge;
  final Member member;
  final Ring ring;

  const NudgeEntry(this.nudge, this.member, this.ring);
}

@DriftDatabase(tables: [Rings, Members, DailyNudges])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---------- Rings ----------

  Future<List<Ring>> allRings() async =>
      (await (select(
            rings,
          )..orderBy([(r) => OrderingTerm(expression: r.id)])).get())
          .map(_ring)
          .toList();

  Future<Ring> createRing(String name, int periodDays) async {
    final id = await into(rings)
        .insert(RingsCompanion.insert(name: name, periodDays: periodDays));
    return Ring(id: id, name: name, periodDays: periodDays);
  }

  /// Rename a ring or change its period. Members' due dates follow
  /// automatically because they are derived.
  Future<void> updateRing(Ring ring) =>
      (update(rings)..where((r) => r.id.equals(ring.id))).write(
        RingsCompanion(
          name: Value(ring.name),
          periodDays: Value(ring.periodDays),
        ),
      );

  /// Fails with a foreign key error if the ring still has members.
  Future<void> deleteRing(int ringId) =>
      (delete(rings)..where((r) => r.id.equals(ringId))).go();

  // ---------- Members ----------

  Future<List<Member>> allMembers() async =>
      (await select(members).get()).map(_member).toList();

  Future<Member?> memberById(int id) async {
    final row = await (select(
      members,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row == null ? null : _member(row);
  }

  /// Adds all [contacts] to [ring] in one transaction, each with a random
  /// baseline within the ring's period. If any contact is already in a
  /// ring, the UNIQUE constraint fails and nothing is added.
  Future<List<Member>> addMembers(
    Ring ring,
    List<NewMember> contacts, {
    required CalendarDate today,
    required Random random,
  }) => transaction(() async {
    final added = <Member>[];
    for (final c in contacts) {
      final baseline = initialBaseline(today, ring.periodDays, random);
      final id = await into(members).insert(
        MembersCompanion.insert(
          contactKey: c.contactKey,
          cachedName: c.cachedName,
          ringId: ring.id,
          baselineDate: baseline,
        ),
      );
      added.add(
        Member(
          id: id,
          contactKey: c.contactKey,
          cachedName: c.cachedName,
          ringId: ring.id,
          baselineDate: baseline,
        ),
      );
    }
    return added;
  });

  /// Writes every field of [member] back to its row.
  Future<void> saveMember(Member member) =>
      (update(members)..where((m) => m.id.equals(member.id))).write(
        MembersCompanion(
          contactKey: Value(member.contactKey),
          cachedName: Value(member.cachedName),
          ringId: Value(member.ringId),
          baselineDate: Value(member.baselineDate),
          lastContacted: Value(member.lastContacted),
          snoozedUntil: Value(member.snoozedUntil),
          lastSurfaced: Value(member.lastSurfaced),
        ),
      );

  Future<void> moveMember(Member member, Ring ring) =>
      saveMember(moveToRing(member, ring));

  Future<void> deleteMember(int memberId) =>
      (delete(members)..where((m) => m.id.equals(memberId))).go();

  // ---------- Daily nudges ----------

  Future<List<DailyNudge>> nudgesOn(CalendarDate date) async => (await (select(
    dailyNudges,
  )..where((n) => n.date.equalsValue(date))).get()).map(_nudge).toList();

  Future<List<DailyNudge>> nudgesSince(CalendarDate from) async =>
      (await (select(dailyNudges)
                ..where((n) => n.date.isBiggerOrEqualValue(from.epochDay))
                ..orderBy([
                  (n) => OrderingTerm.desc(n.date),
                  (n) => OrderingTerm(expression: n.memberId),
                ]))
              .get())
          .map(_nudge)
          .toList();

  /// Returns today's nudges, generating and saving them on the first call
  /// of the day. Later calls on the same day return the saved ones.
  Future<DailyNudgePlan> ensureDailyNudges(
    CalendarDate today, {
    Random? random,
  }) => transaction(() async {
    final plan = planDailyNudges(
      today: today,
      existingToday: await nudgesOn(today),
      members: await allMembers(),
      rings: await allRings(),
      random: random,
    );
    if (plan.isNew) {
      for (final nudge in plan.nudges) {
        await into(dailyNudges).insert(_nudgeCompanion(nudge));
      }
      for (final member in plan.updatedMembers) {
        await saveMember(member);
      }
    }
    return plan;
  });

  /// Saves the result of an action (reached out, snooze, skip).
  Future<void> applyAction(ActionResult result) => transaction(() async {
    await saveMember(result.member);
    final nudge = result.nudge;
    if (nudge != null) {
      await into(dailyNudges).insertOnConflictUpdate(_nudgeCompanion(nudge));
    }
  });

  // ---------- Live queries for the UI ----------

  /// Rings ordered by period then name, each with its member count.
  Stream<List<RingSummary>> watchRingSummaries() {
    final count = members.id.count();
    final query =
        select(rings)
            .join([leftOuterJoin(members, members.ringId.equalsExp(rings.id))])
          ..addColumns([count])
          ..groupBy([rings.id])
          ..orderBy([
            OrderingTerm(expression: rings.periodDays),
            OrderingTerm(expression: rings.name),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          RingSummary(_ring(row.readTable(rings)), row.read(count) ?? 0),
      ],
    );
  }

  Stream<Ring?> watchRing(int ringId) =>
      (select(rings)..where((r) => r.id.equals(ringId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _ring(r));

  Stream<List<Member>> watchMembersOfRing(int ringId) =>
      (select(members)..where((m) => m.ringId.equals(ringId))).watch().map(
        (rows) => rows.map(_member).toList(),
      );

  /// Nudges on or after [from], newest first, with their member and ring.
  Stream<List<NudgeEntry>> watchNudgeEntries(CalendarDate from) {
    final query =
        select(dailyNudges).join([
            innerJoin(members, members.id.equalsExp(dailyNudges.memberId)),
            innerJoin(rings, rings.id.equalsExp(members.ringId)),
          ])
          ..where(dailyNudges.date.isBiggerOrEqualValue(from.epochDay))
          ..orderBy([
            OrderingTerm.desc(dailyNudges.date),
            OrderingTerm(expression: members.cachedName),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          NudgeEntry(
            _nudge(row.readTable(dailyNudges)),
            _member(row.readTable(members)),
            _ring(row.readTable(rings)),
          ),
      ],
    );
  }

  /// Moves every member of [ringId] to [toRingId], then deletes the ring,
  /// in one transaction.
  Future<void> deleteRingMovingMembers(int ringId, {required int toRingId}) {
    if (ringId == toRingId) {
      throw ArgumentError.value(toRingId, 'toRingId', 'is the ring to delete');
    }
    return transaction(() async {
      await (update(members)..where((m) => m.ringId.equals(ringId))).write(
        MembersCompanion(ringId: Value(toRingId)),
      );
      await deleteRing(ringId);
    });
  }

  /// Deletes everything. Used by the debug-only reset.
  Future<void> deleteAllData() => transaction(() async {
    await delete(dailyNudges).go();
    await delete(members).go();
    await delete(rings).go();
  });

  // ---------- Mapping ----------

  static Ring _ring(RingRow r) =>
      Ring(id: r.id, name: r.name, periodDays: r.periodDays);

  static Member _member(MemberRow r) => Member(
    id: r.id,
    contactKey: r.contactKey,
    cachedName: r.cachedName,
    ringId: r.ringId,
    baselineDate: r.baselineDate,
    lastContacted: r.lastContacted,
    snoozedUntil: r.snoozedUntil,
    lastSurfaced: r.lastSurfaced,
  );

  static DailyNudge _nudge(DailyNudgeRow r) =>
      DailyNudge(date: r.date, memberId: r.memberId, status: r.status);

  static DailyNudgesCompanion _nudgeCompanion(DailyNudge n) =>
      DailyNudgesCompanion.insert(
        date: n.date,
        memberId: n.memberId,
        status: n.status,
      );
}
