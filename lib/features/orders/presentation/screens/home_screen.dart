import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/date_picker.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/home_app_bar_actions.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/inactive_account_banner.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/welcome_card.dart';
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
        actions: const [
          OrderSearchButton(),

          SizedBox(width: 8),
          NotificationBellButton(),
          SizedBox(width: 8),
          SmsMessagesButton(),

          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            final ordersBloc = context.read<OrdersBloc>();
            final vendorBloc = context.read<VendorBloc>();

            ordersBloc.add(const FetchOrdersEvent());
            vendorBloc.add(const FetchVendorEvent());

            await ordersBloc.stream.firstWhere(
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
                      const WelcomeCard(),
                      BlocBuilder<VendorBloc, VendorState>(
                        builder: (context, state) {
                          if (state is VendorLoaded) {
                            return InactiveAccountBanner(
                              activation:
                                  state.vendorResponse.vendor?.activation,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
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
                        // logger.w(state.response.orders);

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
