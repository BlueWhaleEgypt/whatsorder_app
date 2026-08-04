import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';
import 'package:whats_order/features/orders/presentation/screens/order_details_screen.dart';
import 'package:whats_order/features/orders/presentation/screens/order_map_screen.dart';
import '../../../data/order_model.dart';
import 'order_row.dart';

/*
|--------------------------------------------------------------------------
| OrdersTable — mobile list of order cards.
|
| The desktop version had a 4-column header (Order ID / Date / Location /
| Details). On mobile that header doesn't map to anything since each
| OrderRow is now a stacked card, so this is just a section label + list.
|--------------------------------------------------------------------------
*/

class OrdersTable extends StatelessWidget {
  final List<OrderModel> orders;
  const OrdersTable({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TableHeader(),
        const Divider(height: 1),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    context.tr("no_orders_yet"),
                    style: AppTextStyles.tableHeader12,
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110),
                  // controller: controller,
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    if (index == orders.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return OrderRow(
                      order: orders[index],
                      onToggle: (_) {
                        context.read<OrdersBloc>().add(
                          ToggleOrderSelectionEvent(orders[index].id),
                        );
                      },
                      onOpenMap: () {
                        final order = orders[index];

                        if (order.latitude == null || order.longitude == null)
                          return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderMapScreen(
                              latitude: order.latitude!,
                              longitude: order.longitude!,
                            ),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<OrdersBloc>(),
                              child: OrderDetailsScreen(
                                userId: orders[index].vendorId!,
                                latitude: orders[index].latitude!,
                                longitude: orders[index].longitude!,
                                components: orders[index].components!,
                                orderId: orders[index].orderId!,
                              ),
                            ),
                          ),
                        );
                        context.read<OrdersBloc>().add(
                          ViewOrderEvent(orders[index].id),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              context.tr("order_id_label"),
              style: AppTextStyles.cellTextbold,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              context.tr("date_label"),
              style: AppTextStyles.cellTextbold,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.tr("location_label"),
              style: AppTextStyles.cellTextbold,
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                context.tr("view"),
                style: AppTextStyles.cellTextbold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
