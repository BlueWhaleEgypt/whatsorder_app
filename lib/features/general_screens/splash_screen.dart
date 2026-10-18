import 'package:flutter/material.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import '../../core/routing/named_routes.dart';
import '../../core/theme/app_colors.dart';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffF3FFF7), Color(0xffE4FFEE), Color(0xffD2F5E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Soft decorative circles in opposite corners.
            const PositionedDirectional(
              top: -70,
              start: -60,
              child: _Blob(size: 220, alpha: 0.07),
            ),
            const PositionedDirectional(
              bottom: -90,
              end: -70,
              child: _Blob(size: 260, alpha: 0.08),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 148,
                            height: 148,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.16,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/new_whats_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'What\'s Order',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primaryGreenLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;

  const _Blob({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withValues(alpha: alpha),
      ),
    );
  }
}
