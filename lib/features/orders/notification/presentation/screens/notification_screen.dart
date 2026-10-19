import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_event.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_state.dart';
import 'package:whats_order/features/orders/notification/presentation/widgets/notification_card.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/date_picker.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    context.read<NotificationBloc>().add(const FetchNotificationEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationCounter.resetNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr("notifications"),
          style: AppTextStyles.heading18,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DatePickerButton(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });

                context.read<NotificationBloc>().add(
                  FetchNotificationEvent(day: date),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<NotificationBloc>().add(const FetchNotificationEvent());

          await context.read<NotificationBloc>().stream.firstWhere(
            (state) => state is! NotificationLoadingState,
          );
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoadingState) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 500,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (state is NotificationErrorState) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 500,
                    child: Center(child: Text(context.tr(state.message))),
                  ),
                ],
              );
            }

            if (state is NotificationLoadedState) {
              final notifications = state.response.notifications;

              if (notifications.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 500,
                      child: Center(
                        child: Text(context.tr("no_Notifications")),
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = notifications[index];

                  return NotificationCard(
                    notification: item,
                    onTap: () {
                      // The bloc shows it as read right away, persists it, and
                      // ignores notifications that are already read.
                      final id = item.id;
                      if (id != null) {
                        context.read<NotificationBloc>().add(
                          PressNotificationEvent(id),
                        );
                      }
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
                          'orderId': item.orderId,
                          'userId': user.id,
                          'latitude': item.latitude,
                          'longitude': item.longitude,
                          'components': item.components,
                        },
                      );
                    },
                  );
                },
              );
            }

            return ListView(physics: const AlwaysScrollableScrollPhysics());
          },
        ),
      ),
    );
  }
}
