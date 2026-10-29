import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/session_cleaner.dart';
import 'package:whats_order/features/settings/data/logout/logout_response.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/presentation/bloc/logout_bloc.dart';
import 'package:whats_order/injection/injection_container.dart';
import 'package:whats_order/features/orders/presentation/bloc/make_offer_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/sectors_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/change_password_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/change_phone_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/sectors_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';

/// Shared test setup: localized app shell and event-recording blocs.
/// Nothing here talks to a real API.

class FakeNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class RecordingUpdateProfileBloc extends UpdateProfileBloc {
  final events = <UpdateProfileEvent>[];
  RecordingUpdateProfileBloc() : super(FakeNetwork());

  @override
  void add(UpdateProfileEvent event) => events.add(event);

  void show(UpdateProfileState state) => emit(state);

  List<T> of<T extends UpdateProfileEvent>() => events.whereType<T>().toList();
}

class RecordingBranchesBloc extends BranchesBloc {
  final events = <BranchesEvent>[];
  RecordingBranchesBloc() : super(FakeNetwork());

  @override
  void add(BranchesEvent event) => events.add(event);

  void show(BranchesState state) => emit(state);

  List<T> of<T extends BranchesEvent>() => events.whereType<T>().toList();
}

class RecordingSectorsBloc extends SectorsBloc {
  final events = <SectorsEvent>[];
  RecordingSectorsBloc() : super(FakeNetwork());

  @override
  void add(SectorsEvent event) => events.add(event);

  void show(SectorsState state) => emit(state);

  List<T> of<T extends SectorsEvent>() => events.whereType<T>().toList();
}

class RecordingChangePhoneBloc extends ChangePhoneBloc {
  final events = <ChangePhoneEvent>[];
  RecordingChangePhoneBloc() : super(FakeNetwork());

  @override
  void add(ChangePhoneEvent event) => events.add(event);

  void show(ChangePhoneState state) => emit(state);

  List<T> of<T extends ChangePhoneEvent>() => events.whereType<T>().toList();
}

class RecordingChangePasswordBloc extends ChangePasswordBloc {
  final events = <ChangePasswordEvent>[];
  RecordingChangePasswordBloc() : super(FakeNetwork());

  @override
  void add(ChangePasswordEvent event) => events.add(event);

  void show(ChangePasswordState state) => emit(state);

  List<T> of<T extends ChangePasswordEvent>() => events.whereType<T>().toList();
}

class RecordingVendorBloc extends VendorBloc {
  final events = <VendorEvent>[];
  RecordingVendorBloc() : super(FakeNetwork());

  @override
  void add(VendorEvent event) => events.add(event);

  void show(VendorState state) => emit(state);

  List<T> of<T extends VendorEvent>() => events.whereType<T>().toList();
}

Future<void> initPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  await CacheHelper.init();
}

/// Same delegates as the real app, so Arabic really resolves to RTL.
Widget localizedApp(
  Widget child, {
  String locale = 'en',
  Route<dynamic>? Function(RouteSettings)? onGenerateRoute,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(locale),
    onGenerateRoute: onGenerateRoute,
    home: Scaffold(body: child),
  );
}

/// Looks a key up in the real translation tables.
String t(WidgetTester tester, String key) =>
    tester.element(find.byType(Scaffold).first).tr(key);

/// Text of the currently visible snackbar.
Finder snackBarText(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

/// The default 800x600 surface hides most of a tab; use a phone-like tall one.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Dismisses visible snackbars so the next message shows immediately.
Future<void> clearSnackBars(WidgetTester tester) async {
  ScaffoldMessenger.of(
    tester.element(find.byType(Scaffold).first),
  ).clearSnackBars();
  await tester.pumpAndSettle();
}

class RecordingOrdersBloc extends OrdersBloc {
  final events = <OrdersEvent>[];
  RecordingOrdersBloc() : super(FakeNetwork());

  @override
  void add(OrdersEvent event) => events.add(event);

  void show(OrdersState state) => emit(state);

  List<MakeOfferEvent> get offers =>
      events.whereType<MakeOfferEvent>().toList();
}

class FakeLogoutResponse implements BaseRepository {
  FakeLogoutResponse({this.fails = false});

  final bool fails;
  int calls = 0;

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    calls++;
    return fails
        ? const Left(ServerFailure('boom'))
        : const Right(LogoutResponse());
  }
}

