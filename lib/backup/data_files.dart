import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Saving and opening backup files through the system's file screens.
/// Injected so tests don't open any UI. No storage permissions needed:
/// the user picks the location each time.
abstract interface class DataFiles {
  /// Returns false if the user cancelled.
  Future<bool> save(String fileName, Uint8List bytes);

  /// Returns null if the user cancelled.
  Future<Uint8List?> open();
}

class PickerDataFiles implements DataFiles {
  const PickerDataFiles();

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Save Nudge backup',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
    return saved != null;
  }

  @override
  Future<Uint8List?> open() async {
    // Any file type: Android's file screens don't reliably recognise
    // .json. The contents are validated instead.
    final file = await FilePicker.pickFile(dialogTitle: 'Open Nudge backup');
    return file?.readAsBytes();
  }
}
