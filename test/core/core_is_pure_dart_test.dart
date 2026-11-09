import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md: core logic stays in pure Dart with no Flutter or database
/// imports. This test fails if anything under lib/core imports a package.
void main() {
  test('lib/core only imports dart: libraries and other core files', () {
    final files = Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);

    final directive = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''');
    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final match = directive.firstMatch(line);
        if (match == null) continue;
        final uri = match.group(2)!;
        final allowed =
            uri.startsWith('dart:') && uri != 'dart:ui' ||
            !uri.contains(':') && !uri.startsWith('../');
        expect(allowed, isTrue, reason: '${file.path} imports $uri');
      }
    }
  });
}
