// Route integrity gate — a regex-based starter check, not full Dart AST
// parsing. It verifies that every Navigator.push*Named(...) call this repo
// can resolve statically (string literals, `Screen.routeName`, or
// `AppRoutes.xxx`) points at something actually registered in one of the
// app's route tables (lib/app/router.dart, lib/app/app.dart). Dynamic route
// expressions (built at runtime) are skipped rather than flagged, since a
// regex can't evaluate them — a stronger long-term version should use
// package:analyzer instead.
import 'dart:io';

final _classDeclarationPattern = RegExp(r'^\s*class\s+(\w+)\b');
final _routeNameDeclarationPattern = RegExp(
  '''static const routeName\\s*=\\s*['"]([^'"]+)['"]''',
);
final _routeConstantPattern = RegExp(
  '''static const (\\w+)\\s*=\\s*['"]([^'"]+)['"]''',
);
final _routeMapKeyPattern = RegExp(
  '''(?:^|[{,\\s])(?:(\\w+)\\.routeName|['"]([^'"]+)['"])\\s*:\\s*\\(''',
  multiLine: true,
);
final _pushNamedPattern = RegExp(
  r'Navigator(?:\.of\(context\))?\.(?:push(?:Replacement)?Named|popAndPushNamed)\(\s*context,\s*([^,)]+)',
);

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib directory not found.');
    exitCode = 2;
    return;
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  // 1. Collect every `static const routeName = '...'` declaration, keyed by
  // the nearest enclosing class in that file.
  final routeNameLiteralByClass = <String, String>{};
  // 2. Collect every `static const xxx = '...'` in AppRoutes-style constant
  // holders, keyed as "ClassName.constantName" -> literal.
  final routeConstantByQualifiedName = <String, String>{};

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    String? currentClass;
    for (final line in content.split('\n')) {
      final classMatch = _classDeclarationPattern.firstMatch(line);
      if (classMatch != null) {
        currentClass = classMatch.group(1);
      }
      final routeNameMatch = _routeNameDeclarationPattern.firstMatch(line);
      if (routeNameMatch != null && currentClass != null) {
        routeNameLiteralByClass[currentClass] = routeNameMatch.group(1)!;
      }
      final constantMatch = _routeConstantPattern.firstMatch(line);
      if (constantMatch != null && currentClass != null) {
        final name = constantMatch.group(1)!;
        if (name == 'routeName') continue;
        routeConstantByQualifiedName['$currentClass.$name'] =
            constantMatch.group(2)!;
      }
    }
  }

  // 3. Collect what's actually registered in the app's route tables.
  final registeredSymbols = <String>{};
  final registeredLiterals = <String>{};
  final routeTableFiles = [
    File('lib/app/router.dart'),
    File('lib/app/app.dart'),
  ].where((f) => f.existsSync());

  for (final file in routeTableFiles) {
    final content = file.readAsStringSync();
    for (final match in _routeMapKeyPattern.allMatches(content)) {
      final classRef = match.group(1);
      final literal = match.group(2);
      if (classRef != null) {
        registeredSymbols.add('$classRef.routeName');
      } else if (literal != null) {
        registeredLiterals.add(literal);
      }
    }
  }
  // A registered `Screen.routeName` also registers its literal value, and
  // vice versa — either form used at a call site should count as covered.
  for (final entry in routeNameLiteralByClass.entries) {
    final symbol = '${entry.key}.routeName';
    if (registeredSymbols.contains(symbol)) {
      registeredLiterals.add(entry.value);
    } else if (registeredLiterals.contains(entry.value)) {
      registeredSymbols.add(symbol);
    }
  }

  // 4. Scan every push*Named call site and resolve what it points at.
  final unresolved = <String>[];
  var checkedCount = 0;

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    for (final match in _pushNamedPattern.allMatches(content)) {
      final rawArg = match.group(1)!.trim();

      final literalMatch = RegExp('''^['"]([^'"]*)['"]\$''').firstMatch(rawArg);
      final routeNameSymbolMatch =
          RegExp(r'^(\w+)\.routeName$').firstMatch(rawArg);
      final appRoutesMatch = RegExp(r'^(\w+)\.(\w+)$').firstMatch(rawArg);

      String? resolvedLiteral;
      String? resolvedSymbol;

      if (literalMatch != null) {
        resolvedLiteral = literalMatch.group(1);
        // '/' is deliberately unregistered — MaterialApp.home serves it, and
        // Flutter forbids registering '/' as a named route alongside home.
        if (resolvedLiteral == '/') continue;
      } else if (routeNameSymbolMatch != null) {
        resolvedSymbol = '${routeNameSymbolMatch.group(1)}.routeName';
      } else if (appRoutesMatch != null) {
        // Only treat "Identifier.identifier" as a resolvable constant
        // reference if it matches a known `static const` we collected —
        // otherwise it's likely a property access on a variable (e.g.
        // `action.route`), which can't be resolved by regex and shouldn't
        // be flagged as broken.
        final qualified =
            '${appRoutesMatch.group(1)}.${appRoutesMatch.group(2)}';
        final constant = routeConstantByQualifiedName[qualified];
        if (constant == null) continue;
        resolvedLiteral = constant;
      } else {
        // Dynamic expression (variable, ternary, interpolation) — can't be
        // statically resolved, so it's skipped rather than flagged.
        continue;
      }

      checkedCount++;

      final covered = (resolvedSymbol != null &&
              registeredSymbols.contains(resolvedSymbol)) ||
          (resolvedLiteral != null &&
              registeredLiterals.contains(resolvedLiteral));

      if (!covered) {
        final label = resolvedSymbol ?? resolvedLiteral ?? rawArg;
        unresolved.add('${file.path}: $label');
      }
    }
  }

  if (unresolved.isNotEmpty) {
    stderr.writeln('Unregistered pushed routes:');
    for (final route in unresolved) {
      stderr.writeln('  - $route');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Route integrity passed: $checkedCount statically-resolvable pushed '
    'routes verified.',
  );
}
