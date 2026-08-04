import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_event.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_state.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/date_picker.dart';

class SmsMessagesScreen extends StatefulWidget {
  const SmsMessagesScreen({super.key});

  @override
  State<SmsMessagesScreen> createState() => _SmsMessagesScreenState();
}

class _SmsMessagesScreenState extends State<SmsMessagesScreen> {
  DateTime _selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const FetchSmsEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationCounter.resetSms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("sms_messages"), style: AppTextStyles.heading18),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DatePickerButton(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });

                context.read<NotificationBloc>().add(FetchSmsEvent(day: date));
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is SmsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SmsErrorState) {
            return Center(child: Text(context.tr(state.message)));
          }

          if (state is SmsLoadedState) {
            final messages = state.response.smsMessages;

            if (messages.isEmpty) {
              return const Center(child: Text("No Messages"));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(const FetchSmsEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final message = messages[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: message.pressed == false
                        ? Colors.white
                        : Colors.green.withOpacity(.15),
                    child: ListTile(
                      title: Text(message.title ?? ""),
                      subtitle: Text(message.components ?? ""),
                      trailing: Text("#${message.orderId}"),
                      onTap: () async {
                        await _openDialer(message.components ?? "");
                        context.read<NotificationBloc>().add(
                          PressSmsEvent(message.id),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  String? extractPhoneNumber(String text) {
    final match = RegExp(r'01\d{9}').firstMatch(text);
    return match?.group(0);
  }

  Future<void> _openDialer(String text) async {
    final phone = extractPhoneNumber(text);

    if (phone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No phone number found")));
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
