import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/sectors_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/sectors_state.dart';
import 'package:whats_order/features/settings/presentation/taps/branches_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/sectores_tap.dart';

class _FakeNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

/// Real bloc that records dispatched events instead of hitting the API.
class _RecordingBranchesBloc extends BranchesBloc {
  final events = <BranchesEvent>[];
  _RecordingBranchesBloc() : super(_FakeNetwork());

  @override
  void add(BranchesEvent event) => events.add(event);

  void show(BranchesState s) => emit(s);

  List<DeleteBranchEvent> get deletes =>
      events.whereType<DeleteBranchEvent>().toList();
}

class _RecordingSectorsBloc extends SectorsBloc {
  final events = <SectorsEvent>[];
  _RecordingSectorsBloc() : super(_FakeNetwork());

  @override
  void add(SectorsEvent event) => events.add(event);

  void show(SectorsState s) => emit(s);

  List<DeleteSectorEvent> get deletes =>
      events.whereType<DeleteSectorEvent>().toList();
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      CacheKeys.userModel: jsonEncode({'id': 'user-1'}),
    });
    await CacheHelper.init();
  });

  group('Branches deletion', () {
    const branch = BranchModel(
      id: 'b-7',
      name: 'Main branch',
      nameEn: '',
      address: 'Street 1',
    );
    late _RecordingBranchesBloc bloc;

    Future<void> pump(WidgetTester tester, BranchesState state) async {
      bloc = _RecordingBranchesBloc();
      await tester.pumpWidget(
        _app(
          BlocProvider<BranchesBloc>.value(
            value: bloc,
            child: const BranchesTab(),
          ),
        ),
      );
      bloc.show(state);
      // The loading state shows an endless progress bar, so no pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Finder deleteButton() => find.widgetWithText(OutlinedButton, 'Delete');

    testWidgets('dialog names the branch and asks the question', (
      tester,
    ) async {
      await pump(tester, const BranchesLoadedState([branch]));
      await tester.ensureVisible(deleteButton());
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Main branch')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('delete this branch?'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancel and barrier dismissal do not dispatch a delete', (
      tester,
    ) async {
      await pump(tester, const BranchesLoadedState([branch]));

      await tester.ensureVisible(deleteButton());
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(bloc.deletes, isEmpty);

      await tester.tap(deleteButton());
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(bloc.deletes, isEmpty);
    });

    testWidgets('confirm dispatches DeleteBranchEvent with the right ids', (
      tester,
    ) async {
      await pump(tester, const BranchesLoadedState([branch]));
      await tester.ensureVisible(deleteButton());
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(bloc.deletes, hasLength(1));
      expect(bloc.deletes.single.userId, 'user-1');
      expect(bloc.deletes.single.branchId, 'b-7');
    });

    testWidgets('delete is disabled while an action is loading', (
      tester,
    ) async {
      await pump(tester, const BranchesActionLoadingState([branch]));

      final button = tester.widget<OutlinedButton>(deleteButton());
      expect(button.onPressed, isNull);
    });
  });

  group('Sectors deletion', () {
    late _RecordingSectorsBloc bloc;

    Future<void> pump(WidgetTester tester) async {
      bloc = _RecordingSectorsBloc();
      await tester.pumpWidget(
        _app(
          MultiBlocProvider(
            providers: [
              BlocProvider<SectorsBloc>.value(value: bloc),
              BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
            ],
            child: const SectorsTab(
              vendor: VendorModel(
                id: 'user-1',
                sectors: [VendorSectorModel(id: 's-3', name: 'Food')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
    }

    testWidgets('cancel and barrier dismissal do not dispatch a delete', (
      tester,
    ) async {
      await pump(tester);

      await openDialog(tester);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Food'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(bloc.deletes, isEmpty);

      await openDialog(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(bloc.deletes, isEmpty);
    });

    testWidgets('confirm dispatches DeleteSectorEvent with the right ids', (
      tester,
    ) async {
      await pump(tester);

      await openDialog(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(bloc.deletes, hasLength(1));
      expect(bloc.deletes.single.userId, 'user-1');
      expect(bloc.deletes.single.sectorId, 's-3');
    });

    testWidgets('delete is disabled while an action is loading', (
      tester,
    ) async {
      await pump(tester);
      bloc.show(const SectorsActionLoading());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });
  });
}
