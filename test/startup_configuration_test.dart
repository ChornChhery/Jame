import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Flutter source and assets do not include database configuration',
    () async {
      final libFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final source = <String, String>{
        for (final file in libFiles) file.path: await file.readAsString(),
      };
      final pubspec = await File('pubspec.yaml').readAsString();
      final violations = <String>[];
      final forbiddenSource = [
        'ConnectDB',
        'mysql1',
        'DB_PASSWORD',
        'dotenv.load',
      ];

      for (final entry in source.entries) {
        for (final token in forbiddenSource) {
          if (entry.value.contains(token)) {
            violations.add('${entry.key} contains $token');
          }
        }
      }

      for (final token in ['mysql1', 'flutter_dotenv']) {
        if (pubspec.contains(token)) {
          violations.add('pubspec.yaml contains $token');
        }
      }
      if (RegExp(r'^\s*-\s*\.env\s*$', multiLine: true).hasMatch(pubspec)) {
        violations.add('pubspec.yaml bundles the root .env file');
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}
