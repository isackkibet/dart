import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/release_certification/'
      'validate_rc1_evidence.dart <evidence-root>',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(args.first);

  if (!root.existsSync()) {
    stderr.writeln('Evidence directory does not exist.');
    exitCode = 66;
    return;
  }

  final manifestFile = File('${root.path}/manifest.json');

  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest.json is missing.');
    exitCode = 1;
    return;
  }

  final manifest = jsonDecode(
    manifestFile.readAsStringSync(),
  ) as Map<String, dynamic>;

  final requiredFields = <String>[
    'release',
    'branch',
    'commitHash',
    'tag',
    'ciRun',
    'androidReport',
    'iosReport',
    'crashlyticsProof',
    'securityReport',
    'rrbResolution',
  ];

  final missingFields = requiredFields.where(
    (field) =>
        !manifest.containsKey(field) ||
        manifest[field] == null ||
        manifest[field].toString().trim().isEmpty ||
        manifest[field].toString().startsWith('REPLACE_WITH_'),
  );

  if (missingFields.isNotEmpty) {
    stderr.writeln(
      'Manifest fields missing or unfilled: ${missingFields.join(', ')}',
    );
    exitCode = 2;
    return;
  }

  final referencedPaths = <String>[
    manifest['androidReport'] as String,
    manifest['iosReport'] as String,
    manifest['crashlyticsProof'] as String,
    manifest['securityReport'] as String,
    manifest['rrbResolution'] as String,
  ];

  final missingPaths = referencedPaths.where(
    (path) => !File(path).existsSync() && !Directory(path).existsSync(),
  );

  if (missingPaths.isNotEmpty) {
    stderr.writeln('Missing referenced evidence:');
    for (final path in missingPaths) {
      stderr.writeln(' - $path');
    }
    exitCode = 3;
    return;
  }

  stdout.writeln(
    'RC1 evidence structure is complete for '
    '${manifest['commitHash']}.',
  );
}
