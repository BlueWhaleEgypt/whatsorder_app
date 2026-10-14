import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/orders/data/order_model.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';

/// Search-by-order-number delegate used from the Home app bar.
class OrderSearchDelegate extends SearchDelegate<OrderModel?> {
  final List<OrderModel> orders;

  OrderSearchDelegate(this.orders);

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
