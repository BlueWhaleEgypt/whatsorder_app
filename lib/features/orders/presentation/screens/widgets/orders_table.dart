import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
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
        const SizedBox(height: 10),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.cube_box,
                          size: 46,
                          color: AppColors.primaryGreenLight,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.tr("no_orders_yet"),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardTitle15.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110, top: 2),
                  // controller: controller,
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final style = AppTextStyles.cellTextbold.copyWith(
      color: AppColors.primaryGreen,
      fontSize: 13,
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.editIconBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Same widths as OrderRow: checkbox column, then the 2/3/3 columns.
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              context.tr("order_id_label"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: 44),
          Expanded(
            flex: 3,
            child: Text(
              context.tr("date_label"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.tr("location_label"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                context.tr("view"),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
