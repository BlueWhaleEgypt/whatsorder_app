import 'package:logger/logger.dart';

/*
|--------------------------------------------------------------------------
| Global logger instance used across DioHelper / repositories / blocs.
|--------------------------------------------------------------------------
*/

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 3,
    errorMethodCount: 8,
    lineLength: 120,
    stackTraceBeginIndex: 1,
  ),
);
