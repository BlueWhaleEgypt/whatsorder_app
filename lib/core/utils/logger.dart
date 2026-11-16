import 'package:logger/logger.dart';
import 'dart:convert';

/*
|--------------------------------------------------------------------------
| Global logger instance used across DioHelper / repositories / blocs.
|--------------------------------------------------------------------------
*/

/*
| لتنظيم سجلات التطبيق بشكل أفضل، يمكن استخدام AppLogPrinter لتنسيق JSON بشكل جميل عند تسجيل الاستجابات من واجهة برمجة التطبيقات.
|
|logger.i(
|  'Products API response:\n${AppLogPrinter.formatJson(response.data)}',
|);
*/

class AppLogPrinter extends LogPrinter {
  final PrettyPrinter _prettyPrinter = PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    stackTraceBeginIndex: 1,
  );

  @override
  List<String> log(LogEvent event) {
    return _prettyPrinter.log(event);
  }

  static String formatJson(dynamic data) {
    try {
      final json = data is String ? jsonDecode(data) : data;

      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return data.toString();
    }
  }
}

final logger = Logger(printer: AppLogPrinter());
// final logger = Logger(
//   printer: PrettyPrinter(
//     methodCount: 3,
//     errorMethodCount: 8,
//     lineLength: 120,
//     stackTraceBeginIndex: 1,
//   ),
// );
