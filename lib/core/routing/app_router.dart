import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/forgot_password_screen.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/verify_otp_screen.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/onboarding_screen.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/screens/notification_screen.dart';
import 'package:whats_order/features/orders/notification/presentation/screens/sms_messages_screen.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/screens/order_details_screen.dart';
import 'package:whats_order/features/settings/presentation/profile_screen.dart';

import 'package:whats_order/injection/injection_container.dart';
import '../../features/auth/sign_in/presentation/screens/sign_in_screen.dart';
import '../../features/auth/sign_up/presentation/screens/sign_up_screen.dart';
import '../../features/general_screens/splash_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import 'named_routes.dart';

/*
|--------------------------------------------------------------------------
| AppRouter
|--------------------------------------------------------------------------
|
| Central onGenerateRoute so MaterialApp stays clean.
| NamedRoutes.home now points to MainShell (bottom-nav container with
| Orders / Wallet / Settings tabs) instead of a single screen.
|
|--------------------------------------------------------------------------
*/

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NamedRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case NamedRoutes.signin:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case NamedRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case NamedRoutes.onboarding:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OtpBloc>(),
            child: OnboardingScreen(
              phone: args['phone']!,
              password: args['password']!,
            ),
          ),
        );
      case NamedRoutes.forgotPassword:
        final args = settings.arguments as String;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OtpBloc>(),
            child: ForgotPasswordScreen(phone: args),
          ),
        );

      case NamedRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case NamedRoutes.wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case NamedRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case NamedRoutes.orderDetail:
        // final args = settings.arguments as OrderModel;
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OrdersBloc>(),
            child: OrderDetailsScreen(
              orderId: args['orderId'] as int,
              userId: args['userId'] as String,
              latitude: args['latitude'] as double?,
              longitude: args['longitude'] as double?,
              components: args['components'] as String?,
            ),
          ),
        );
      case NamedRoutes.verifyOtp:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<OtpBloc>(),
            child: VerifyOtpScreen(phone: settings.arguments as String),
          ),
        );
      case NamedRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case NamedRoutes.notification:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<NotificationBloc>(),
            child: const NotificationScreen(),
          ),
        );
      case NamedRoutes.smsMessages:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<NotificationBloc>(),
            child: const SmsMessagesScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
