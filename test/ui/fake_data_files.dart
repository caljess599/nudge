import 'dart:typed_data';

import 'package:nudge/backup/data_files.dart';

/// In-memory stand-in for the system's save/open file screens.
class FakeDataFiles implements DataFiles {
  /// Files "saved" so far, by name.
  final saved = <String, Uint8List>{};

  /// What the next open() returns; null simulates cancelling.
  Uint8List? toOpen;

  bool cancelSave = false;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    if (cancelSave) return false;
    saved[fileName] = bytes;
    return true;
  }

  @override
  Future<Uint8List?> open() async => toOpen;
}
