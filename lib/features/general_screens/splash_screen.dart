import 'package:flutter/material.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import '../../core/routing/named_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.accessToken,
    );

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      token != null && token.toString().isNotEmpty
          ? NamedRoutes.home
          : NamedRoutes.signin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE4FFEE),
      body: Center(
        child: Image.asset(
          'assets/images/new_whats_icon.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
