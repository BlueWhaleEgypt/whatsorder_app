import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/transaction_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_bloc.dart';
import '../core/network/network_info.dart';
import '../features/auth/sign_in/presentation/bloc/sign_in_bloc.dart';
import '../features/auth/sign_up/presentation/bloc/sign_up_bloc.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';

/*
|--------------------------------------------------------------------------
| Dependency Injection Setup (GetIt Service Locator)
|--------------------------------------------------------------------------
|
| Registers every Bloc as a factory (new instance each time it's
| requested) and shared services as lazy singletons. Call init() once
| at app startup, before runApp().
|
|--------------------------------------------------------------------------
*/

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => SignInBloc(sl()));
  sl.registerFactory(() => SignUpBloc(sl()));
  sl.registerFactory(() => OrdersBloc(sl()));
  sl.registerFactory(() => OtpBloc(sl()));
  sl.registerFactory(() => WalletBloc(sl()));
  sl.registerFactory(() => TransactionBloc(sl()));
  sl.registerFactory(() => NotificationBloc(sl()));
  // Add every new feature's Bloc here, e.g.:
  // sl.registerFactory(() => WalletBloc(sl()));

  // Network info
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  // Locale (persisted via CacheHelper — one instance for the whole app)
  sl.registerLazySingleton(() => LocaleCubit());
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
