// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:nudge/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'migration from v1 to v2 keeps every row and adds no nickname',
    () async {
      const oldRings = [v1.RingsData(id: 1, name: 'Friends', periodDays: 14)];
      const oldMembers = [
        v1.MembersData(
          id: 1,
          contactKey: 'k-ana',
          cachedName: 'Ana Silva',
          ringId: 1,
          baselineDate: 20000,
          lastContacted: 20400,
          snoozedUntil: 20410,
          lastSurfaced: 20405,
        ),
        v1.MembersData(
          id: 2,
          contactKey: 'k-ben',
          cachedName: 'Ben Okoro',
          ringId: 1,
          baselineDate: 20001,
        ),
      ];
      const oldNudges = [
        v1.DailyNudgesData(date: 20405, memberId: 1, status: 'done'),
      ];

      const expectedRings = [
        v2.RingsData(id: 1, name: 'Friends', periodDays: 14),
      ];
      const expectedMembers = [
        v2.MembersData(
          id: 1,
          contactKey: 'k-ana',
          cachedName: 'Ana Silva',
          ringId: 1,
          baselineDate: 20000,
          lastContacted: 20400,
          snoozedUntil: 20410,
          lastSurfaced: 20405,
        ),
        v2.MembersData(
          id: 2,
          contactKey: 'k-ben',
          cachedName: 'Ben Okoro',
          ringId: 1,
          baselineDate: 20001,
        ),
      ];
      const expectedNudges = [
        v2.DailyNudgesData(date: 20405, memberId: 1, status: 'done'),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.rings, oldRings);
          batch.insertAll(oldDb.members, oldMembers);
          batch.insertAll(oldDb.dailyNudges, oldNudges);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.rings).get(), expectedRings);
          expect(await newDb.select(newDb.members).get(), expectedMembers);
          expect(await newDb.select(newDb.dailyNudges).get(), expectedNudges);
        },
      );
    },
  );

  test('migration from v2 to v3 keeps nicknames, adds no preference', () async {
    const oldRings = [v2.RingsData(id: 1, name: 'Family', periodDays: 30)];
    const oldMembers = [
      v2.MembersData(
        id: 1,
        contactKey: 'k-jane',
        cachedName: 'Jane Doe',
        nickname: 'Mom',
        ringId: 1,
        baselineDate: 20000,
        lastContacted: 20400,
      ),
    ];
    const oldNudges = [
      v2.DailyNudgesData(date: 20405, memberId: 1, status: 'skipped'),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.rings, oldRings);
        batch.insertAll(oldDb.members, oldMembers);
        batch.insertAll(oldDb.dailyNudges, oldNudges);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.rings).get(), const [
          v3.RingsData(id: 1, name: 'Family', periodDays: 30),
        ]);
        expect(await newDb.select(newDb.members).get(), const [
          v3.MembersData(
            id: 1,
            contactKey: 'k-jane',
            cachedName: 'Jane Doe',
            nickname: 'Mom',
            ringId: 1,
            baselineDate: 20000,
            lastContacted: 20400,
          ),
        ]);
        expect(await newDb.select(newDb.dailyNudges).get(), const [
          v3.DailyNudgesData(date: 20405, memberId: 1, status: 'skipped'),
        ]);
      },
    );
  });

  test('migration from v3 to v4 adds an empty settings table', () async {
    const oldRings = [v3.RingsData(id: 1, name: 'Family', periodDays: 30)];
    const oldMembers = [
      v3.MembersData(
        id: 1,
        contactKey: 'k-jane',
        cachedName: 'Jane Doe',
        nickname: 'Mom',
        reachVia: 'whatsapp',
        ringId: 1,
        baselineDate: 20000,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.rings, oldRings);
        batch.insertAll(oldDb.members, oldMembers);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.rings).get(), const [
          v4.RingsData(id: 1, name: 'Family', periodDays: 30),
        ]);
        expect(await newDb.select(newDb.members).get(), const [
          v4.MembersData(
            id: 1,
            contactKey: 'k-jane',
            cachedName: 'Jane Doe',
            nickname: 'Mom',
            reachVia: 'whatsapp',
            ringId: 1,
            baselineDate: 20000,
          ),
        ]);
        expect(await newDb.select(newDb.settings).get(), isEmpty);
      },
    );
  });
}
