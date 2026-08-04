import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| NavigationHelper
|--------------------------------------------------------------------------
|
| A global navigatorKey lets code outside the widget tree (like the
| DioHelper 401 interceptor) trigger navigation.
| Attach `navigatorKey` to your MaterialApp in main.dart.
|
|--------------------------------------------------------------------------
*/

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void pushAndRemoveUntil(String routeName) {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    routeName,
    (route) => false,
  );
}

void pushNamed(String routeName, {Object? arguments}) {
  navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
}

void pop() {
  navigatorKey.currentState?.pop();
}
