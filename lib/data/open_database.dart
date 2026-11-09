import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Opens the on-device database file in the app's private documents
/// directory. Nothing leaves the device.
AppDatabase openAppDatabase() => AppDatabase(
  LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}nudge.sqlite');
    return NativeDatabase.createInBackground(file);
  }),
);
