import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/app_translations.dart';

import 'helpers/harness.dart';

/// Audits the real translation tables against the real Profile-related
/// source files, so the test follows the code instead of a hand-kept list.

final _profileSources = [
  'lib/features/settings/presentation',
  'lib/features/settings/data',
];

Iterable<File> _dartFiles() sync* {
  for (final dir in _profileSources) {
    yield* Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
  }
}

/// Keys the Profile tabs ask for: `tr('x')`, plus keys carried as messages
/// from the data/Bloc layer (failures, success messages, message keys).
Set<String> _usedKeys() {
  final keys = <String>{};
  final patterns = [
    RegExp(r'''\btr\(\s*['"]([A-Za-z0-9_]+)['"]'''),
    RegExp(r'''Failure\(\s*['"]([a-z0-9_]+)['"]'''),
    RegExp(r'''(?:Error|Success)\(\s*(?:message:\s*)?['"]([a-z0-9_]+)['"]'''),
    RegExp(
      r'''(?:successMessage|messageKey|message):\s*['"]([a-z0-9_]+)['"]''',
    ),
    RegExp(r'''\?\?\s*['"]([a-z]+(?:_[a-z0-9]+)+)['"]'''),
  ];

  for (final file in _dartFiles()) {
    final source = file.readAsLinesSync().where(
      (l) => !l.trimLeft().startsWith('//'),
    );
    for (final line in source) {
      for (final p in patterns) {
        for (final m in p.allMatches(line)) {
          keys.add(m.group(1)!);
        }
      }
    }
  }
  return keys;
}

void main() {
  final en = kTranslations['en']!;
  final ar = kTranslations['ar']!;

  test('both languages are present and have the same keys', () {
    expect(en.keys.toSet().difference(ar.keys.toSet()), isEmpty);
    expect(ar.keys.toSet().difference(en.keys.toSet()), isEmpty);
  });

  test('no translation is empty', () {
    for (final table in [en, ar]) {
      for (final e in table.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('every key used by the Profile tabs exists in English and Arabic', () {
    final used = _usedKeys();
    expect(used, isNotEmpty, reason: 'key scan found nothing');

    final missing = <String>[
      for (final k in used)
        if (!en.containsKey(k) || !ar.containsKey(k)) k,
    ];
    expect(missing, isEmpty, reason: 'missing in en/ar: $missing');
  });

  test('Arabic values contain Arabic text and differ from English', () {
    final arabic = RegExp(r'[؀-ۿ]');
    for (final k in _usedKeys()) {
      if (!ar.containsKey(k)) continue;
      final value = ar[k]!;
      // Brand names / symbols may legitimately stay Latin.
      if (!arabic.hasMatch(value)) {
        expect(
          value,
          isNot(equals(en[k])),
          reason: 'Arabic text for "$k" is just the English text',
        );
      }
    }
  });

  group('AppLocalizations.message', () {
    final english = AppLocalizations(const Locale('en'));
    final arabic = AppLocalizations(const Locale('ar'));

    test('translates known keys in the active language', () {
      expect(
        english.message('profile_updated_successfully'),
        en['profile_updated_successfully'],
      );
      expect(
        arabic.message('profile_updated_successfully'),
        ar['profile_updated_successfully'],
      );
      expect(
        english.message('profile_updated_successfully'),
        isNot(arabic.message('profile_updated_successfully')),
      );
    });

    test('hides technical errors behind the generic message', () {
      for (final raw in [
        'SocketException: Failed host lookup',
        'DioException [bad response]: status code of 500',
        "type 'Null' is not a subtype of type 'String'",
        'Error 500',
        'ServerFailure(boom)',
        'Instance of Foo',
        '{message: x}',
        '',
        '   ',
      ]) {
        expect(
          english.message(raw),
          en['something_went_wrong'],
          reason: 'raw: "$raw"',
        );
        expect(arabic.message(raw), ar['something_went_wrong']);
      }
      expect(english.message(null), en['something_went_wrong']);
    });

    test('keeps readable server messages', () {
      expect(
        english.message('Phone number already registered'),
        'Phone number already registered',
      );
      expect(
        arabic.message('رقم الهاتف مسجل بالفعل'),
        'رقم الهاتف مسجل بالفعل',
      );
    });

    test('unknown keys fall back to English, then to the key', () {
      expect(
        english.translate('definitely_missing_key'),
        'definitely_missing_key',
      );
    });
  });

  group('rendering and direction', () {
    Widget probe(String raw) => Builder(
      builder: (context) => Column(
        children: [
          Text(context.trMessage(raw), key: const Key('msg')),
          Text(Directionality.of(context).name, key: const Key('dir')),
        ],
      ),
    );

    for (final entry in {'en': 'ltr', 'ar': 'rtl'}.entries) {
      testWidgets('${entry.key}: message and ${entry.value} direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          localizedApp(
            probe('password_changed_successfully'),
            locale: entry.key,
          ),
        );
        await tester.pumpAndSettle();

        final table = kTranslations[entry.key]!;
        expect(
          tester.widget<Text>(find.byKey(const Key('msg'))).data,
          table['password_changed_successfully'],
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('dir'))).data,
          entry.value,
        );
      });
    }

    testWidgets('switching locale swaps the displayed message', (tester) async {
      Future<void> pumpFor(String locale) async {
        await tester.pumpWidget(
          localizedApp(probe('request_failed'), locale: locale),
        );
        await tester.pumpAndSettle();
      }

      await pumpFor('en');
      expect(find.text(en['request_failed']!), findsOneWidget);

      await pumpFor('ar');
      expect(find.text(ar['request_failed']!), findsOneWidget);
      expect(find.text(en['request_failed']!), findsNothing);
    });
  });
}
