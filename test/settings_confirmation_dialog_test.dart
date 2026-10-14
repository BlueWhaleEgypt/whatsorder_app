import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';

void main() {
  bool? result;
  var resolved = false;

  Future<void> open(WidgetTester tester) async {
    result = null;
    resolved = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showSettingsConfirmationDialog(
                context,
                title: context.tr('delete_branch'),
                message: context.tr('confirm_delete_branch'),
                itemName: 'Main branch',
              );
              resolved = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, message, item name and actions', (tester) async {
    await open(tester);

    expect(find.text('Delete Branch'), findsOneWidget);
    expect(find.text('Main branch'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('keeps the icon badge and button icon by default', (
    tester,
  ) async {
    await open(tester);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SvgPicture),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('confirm resolves true', (tester) async {
    await open(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, true);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cancel resolves false', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, false);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('barrier dismissal resolves null', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
