import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';
import 'package:whats_order/features/wallet/presentation/bloc/transaction_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:whats_order/injection/injection_container.dart';
import '../../../orders/presentation/screens/home_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

/*
|--------------------------------------------------------------------------
| MainShell — app-wide bottom navigation (replaces the old side drawer).
|
| Holds the 3 main destinations in an IndexedStack so each tab keeps its
| own scroll position / Bloc state when switching back and forth, and
| shows a Material 3 NavigationBar (styled globally in AppTheme).
|
| This is the screen NamedRoutes.home now points to.
|--------------------------------------------------------------------------
*/

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  final List<Widget?> _tabs = [
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<OrdersBloc>()..add(const FetchOrdersEvent()),
        ),
      ],
      child: const HomeScreen(),
    ),
    null,
    null,
  ];

  List<Widget> get _pages {
    return List.generate(_tabs.length, (i) {
      if (_tabs[i] != null) {
        return _tabs[i]!;
      }
      return const SizedBox.shrink();
    });
  }

  void _loadPage(int index) {
    if (_tabs[index] != null) return;

    switch (index) {
      case 1:
        _tabs[index] = MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<WalletBloc>()..add(GetWalletEvent()),
            ),
            BlocProvider(
              create: (_) =>
                  sl<TransactionBloc>()..add(const GetTransactionsEvent()),
            ),
          ],
          child: const WalletScreen(),
        );
        break;
      case 2:
        _tabs[index] = const SettingsScreen();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    NotificationCounter.loadFromCache();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i("========== FOREGROUND MESSAGE ==========");
      logger.i("Message ID: ${message.messageId}");
      logger.i("Title: ${message.notification?.title}");
      logger.i("Body: ${message.notification?.body}");
      logger.i("Data: ${message.data}");

      final title = message.data['title'] ?? message.notification?.title ?? '';

      if (title.contains('العميل اختارك')) {
        NotificationCounter.incrementSms();
      } else {
        NotificationCounter.incrementNotification();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i("========== OPENED APP FROM NOTIFICATION ==========");
      logger.i("Message ID: ${message.messageId}");
      logger.i("Title: ${message.notification?.title}");
      logger.i("Body: ${message.notification?.body}");
      logger.i("Data: ${message.data}");

      _handleNotification(message);
    });

    _checkInitialMessage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // logger.i("STATE = $state");

    if (state == AppLifecycleState.resumed) {
      // logger.i("LOAD CACHE");
      await NotificationCounter.loadFromCache();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleNotification(RemoteMessage message) {
    final title = message.data['title'] ?? message.notification?.title ?? '';

    if (title.contains('العميل اختارك')) {
      NotificationCounter.resetSms();

      Navigator.pushNamed(context, NamedRoutes.smsMessages);
    } else {
      NotificationCounter.resetNotification();

      Navigator.pushNamed(context, NamedRoutes.notification);
    }
  }

  Future<void> _checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();

    if (message == null) return;

    logger.i("========== INITIAL MESSAGE ==========");
    logger.i("Message ID: ${message.messageId}");
    logger.i("Title: ${message.notification?.title}");
    logger.i("Body: ${message.notification?.body}");
    logger.i("Data: ${message.data}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotification(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItemData(
        icon: Icons.shopping_bag_outlined,
        label: context.tr('nav_orders'),
      ),
      _NavItemData(
        icon: Icons.account_balance_wallet_outlined,
        label: context.tr('nav_wallet'),
      ),
      _NavItemData(
        icon: Icons.settings_outlined,
        label: context.tr('nav_settings'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _index, children: _pages),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _FloatingNavBar(
                selectedIndex: _index,
                items: items,
                // onTap: (i) => setState(() => _index = i),
                onTap: (i) {
                  setState(() {
                    _loadPage(i);
                    _index = i;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFF14B85E);
  static const Color _inactiveColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final selected = i == selectedIndex;
          final item = items[i];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _activeColor.withOpacity(0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: selected ? _activeColor : _inactiveColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _activeColor : _inactiveColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
