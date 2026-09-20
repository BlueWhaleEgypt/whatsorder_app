import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/utils/pdf_export.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/orders/data/order_model.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/presentation/screens/account_verification_screen.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/date_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import 'widgets/orders_table.dart';

/*
|--------------------------------------------------------------------------
| HomeScreen — "Your Order" tab, now living inside MainShell's
| IndexedStack (no more drawer / hamburger — navigation is the bottom
| NavigationBar in MainShell).
|--------------------------------------------------------------------------
*/

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("your_order"), style: AppTextStyles.heading18),
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.search),
                onPressed: state is LoadedOrdersState
                    ? () {
                        showSearch(
                          context: context,
                          delegate: _OrderSearchDelegate(state.response.orders),
                        );
                      }
                    : null,
              );
            },
          ),

          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: NotificationCounter.notificationCount,
            builder: (context, count, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, NamedRoutes.notification);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryGreen,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: NotificationCounter.smsCount,
            builder: (context, count, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, NamedRoutes.smsMessages);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryGreen,
                      child: Icon(Icons.message, color: Colors.white, size: 16),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, NamedRoutes.profile),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),

          const SizedBox(width: 16), // بعد عن حافة الشاشة
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            final bloc = context.read<OrdersBloc>();

            bloc.add(const FetchOrdersEvent());

            await bloc.stream.firstWhere(
              (state) => state is! LoadingOrdersState,
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _WelcomeCard(),
                      const _InactiveAccountBanner(),
                      const SizedBox(height: 10),

                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: DatePickerButton(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });

                            context.read<OrdersBloc>().add(
                              FetchOrdersEvent(day: date),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                // hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (context, state) {
                      if (state is LoadingOrdersState) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is LoadedOrdersState) {
                        logger.w(state.response.orders);

                        return OrdersTable(orders: state.response.orders);
                      }

                      if (state is ErrorOrdersState) {
                        return Center(child: Text(context.tr(state.message)));
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
            '{}',
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${context.tr("welcome")} ${user.firstName ?? 'UserName'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr("welcome_subtitle"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                Builder(
                  builder: (context) {
                    final verificationStatus =
                        CacheHelper.getDataFromSharedPreference(
                          key: CacheKeys.verificationStatus,
                        );

                    final isVerified =
                        verificationStatus?.toString().toLowerCase() ==
                        'verified';

                    return Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: InkWell(
                        onTap: isVerified
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AccountVerificationScreen(),
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVerified ? Icons.check_circle_rounded : null,
                                color: isVerified ? Colors.greenAccent : null,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isVerified
                                    ? context.tr("account_verified")
                                    : context.tr("account_not_verified"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final state = context.read<OrdersBloc>().state;

              if (state is! LoadedOrdersState) return;

              final selectedOrders = state.response.orders
                  .where((order) => order.isChecked)
                  .toList();

              if (selectedOrders.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr("select_at_least_one_order")),
                  ),
                );
                return;
              }

              await PdfExport.exportOrders(selectedOrders);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr("orders_exported_successfully")),
                ),
              );
            },
            icon: const Icon(
              Icons.file_download_outlined,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              context.tr("export"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveAccountBanner extends StatelessWidget {
  const _InactiveAccountBanner();

  @override
  Widget build(BuildContext context) {
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
            '{}',
      ),
    );

    if (user.activation ?? true) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF5C6C2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC0392B),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr("account_inactive_banner"),
                style: const TextStyle(
                  color: Color(0xFFC0392B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSearchDelegate extends SearchDelegate<OrderModel?> {
  final List<OrderModel> orders;

  _OrderSearchDelegate(this.orders);

  List<OrderModel> get filteredOrders {
    if (query.trim().isEmpty) {
      return [];
    }

    return orders.where((order) {
      return order.orderId.toString().toLowerCase().contains(
        query.toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(context.tr("search_hint"), style: TextStyle(fontSize: 16)),
      );
    }

    return _buildList(filteredOrders, context);
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildList(filteredOrders, context);
  }

  Widget _buildList(List<OrderModel> orders, BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text("No matching orders found"));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (_, index) {
        final order = orders[index];

        return GestureDetector(
          onTap: () {
            final user = UserModel.fromJson(
              jsonDecode(
                CacheHelper.getDataFromSharedPreference(
                      key: CacheKeys.userModel,
                    ) ??
                    '{}',
              ),
            );

            Navigator.pushNamed(
              context,
              NamedRoutes.orderDetail,
              arguments: {
                'orderId': order.orderId,
                'userId': user.id,
                'latitude': order.latitude,
                'longitude': order.longitude,
                'components': order.components,
              },
            );

            context.read<OrdersBloc>().add(ViewOrderEvent(orders[index].id));
            // close(context, order);
          },
          child: ListTile(
            title: Text("${order.orderId}"),
            subtitle: Text(order.createdDate ?? ''),
            // onTap: () => close( order),
          ),
        );
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
}
