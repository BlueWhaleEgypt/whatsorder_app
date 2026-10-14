import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';
import 'package:whats_order/features/settings/presentation/taps/branches_tab.dart';

import 'helpers/harness.dart';

String _tr(String locale, String key) => kTranslations[locale]![key]!;

const _branch = BranchModel(
  id: 'b-7',
  name: 'الفرع الرئيسي',
  nameEn: 'Main branch',
  latitude: 30.1,
  longitude: 31.2,
  address: '1 Nile St',
);

void main() {
  late RecordingBranchesBloc bloc;

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    List<BranchModel> branches = const [_branch],
  }) async {
    await initPrefs({
      CacheKeys.userModel: jsonEncode({'id': 'v1'}),
    });
    useTallScreen(tester);
    bloc = RecordingBranchesBloc();
    await tester.pumpWidget(
      localizedApp(
        BlocProvider<BranchesBloc>.value(
          value: bloc,
          child: const BranchesTab(),
        ),
        locale: locale,
      ),
    );
    await tester.pump();
    bloc.show(BranchesLoadedState(branches));
    await tester.pumpAndSettle();
  }

  Future<void> openAdd(WidgetTester tester, String locale) async {
    await tester.tap(find.text(_tr(locale, 'add_branch')));
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(WidgetTester tester, String locale) async {
    final edit = find.text(_tr(locale, 'edit'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) =>
      find.descendant(of: find.byType(Dialog), matching: f);

  group('Add mode', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('shows the $locale title, labels and Add button', (
        tester,
      ) async {
        await pump(tester, locale: locale, branches: const []);
        await openAdd(tester, locale);

        expect(inDialog(find.text(_tr(locale, 'add_branch'))), findsOneWidget);
        expect(inDialog(find.text(_tr(locale, 'add'))), findsOneWidget);
        expect(inDialog(find.text(_tr(locale, 'cancel'))), findsOneWidget);
        expect(
          inDialog(find.text(_tr(locale, 'choose_on_map'))),
          findsOneWidget,
        );
        expect(inDialog(find.byType(TextFormField)), findsNWidgets(3));
      });
    }

    testWidgets('empty required fields and missing location are reported', (
      tester,
    ) async {
      await pump(tester, branches: const []);
      await openAdd(tester, 'en');
      await tester.tap(inDialog(find.text(_tr('en', 'add'))));
      await tester.pumpAndSettle();

      expect(find.text(_tr('en', 'invalid_coordinates')), findsOneWidget);
      // Dialog stays open and nothing is sent.
      expect(find.byType(Dialog), findsOneWidget);
      expect(bloc.of<AddBranchEvent>(), isEmpty);
      // All three empty required fields are flagged too.
      expect(
        inDialog(find.text(_tr('en', 'required_field'))),
        findsNWidgets(3),
      );
    });

    testWidgets('Cancel closes the dialog without any event', (tester) async {
      await pump(tester, branches: const []);
      await openAdd(tester, 'en');
      await tester.tap(inDialog(find.text(_tr('en', 'cancel'))));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(bloc.of<AddBranchEvent>(), isEmpty);
    });
  });

  group('Edit mode', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('shows the $locale title, Save and prefilled values', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        await openEdit(tester, locale);

        expect(inDialog(find.text(_tr(locale, 'edit_branch'))), findsOneWidget);
        expect(inDialog(find.text(_tr(locale, 'save'))), findsOneWidget);
        expect(inDialog(find.text(_tr(locale, 'add'))), findsNothing);
        expect(inDialog(find.text('الفرع الرئيسي')), findsOneWidget);
        expect(inDialog(find.text('Main branch')), findsOneWidget);
        expect(inDialog(find.text('1 Nile St')), findsOneWidget);
        expect(
          inDialog(find.text(_tr(locale, 'location_selected'))),
          findsOneWidget,
        );
      });
    }

    testWidgets('a blank required field blocks Save', (tester) async {
      await pump(tester);
      await openEdit(tester, 'en');
      await tester.enterText(inDialog(find.byType(TextFormField)).at(0), '');
      await tester.tap(inDialog(find.text(_tr('en', 'save'))));
      await tester.pumpAndSettle();

      expect(inDialog(find.text(_tr('en', 'required_field'))), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(bloc.of<UpdateBranchEvent>(), isEmpty);
    });

    testWidgets('Save submits the edited branch for its id', (tester) async {
      await pump(tester);
      await openEdit(tester, 'en');
      await tester.enterText(
        inDialog(find.byType(TextFormField)).at(1),
        '  Downtown  ',
      );
      await tester.tap(inDialog(find.text(_tr('en', 'save'))));
      await tester.pumpAndSettle();

      final sent = bloc.of<UpdateBranchEvent>().single;
      expect(sent.userId, 'v1');
      expect(sent.branchId, 'b-7');
      expect(sent.branch.id, 'b-7');
      expect(sent.branch.name, 'الفرع الرئيسي');
      expect(sent.branch.nameEn, 'Downtown');
      expect(sent.branch.latitude, 30.1);
      expect(sent.branch.longitude, 31.2);
      expect(sent.branch.address, '1 Nile St');
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('stays usable when the keyboard takes most of the screen', (
      tester,
    ) async {
      await pump(tester);
      tester.view.physicalSize = const Size(400, 500);
      await openEdit(tester, 'en');
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(inDialog(find.text(_tr('en', 'save'))));
      await tester.tap(inDialog(find.text(_tr('en', 'save'))));
      await tester.pumpAndSettle();
      expect(bloc.of<UpdateBranchEvent>(), hasLength(1));
    });
  });
}
