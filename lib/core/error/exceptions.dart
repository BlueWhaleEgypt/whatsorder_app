/*
|--------------------------------------------------------------------------
| Exceptions
|--------------------------------------------------------------------------
|
| Low-level exceptions thrown from the network/cache layer before being
| caught and converted into Failures inside a response's getData().
|
|--------------------------------------------------------------------------
*/

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
