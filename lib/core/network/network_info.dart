import 'package:internet_connection_checker/internet_connection_checker.dart';

/*
|--------------------------------------------------------------------------
| NetworkInfo
|--------------------------------------------------------------------------
|
| Simple connectivity abstraction so Blocs / repositories never depend
| directly on a third-party connectivity package.
|
|--------------------------------------------------------------------------
*/

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
