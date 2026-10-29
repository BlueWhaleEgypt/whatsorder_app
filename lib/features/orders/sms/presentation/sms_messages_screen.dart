import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_event.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_state.dart';
import 'package:whats_order/features/orders/sms/presentation/sms_message_card.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/date_picker.dart';

class SmsMessagesScreen extends StatefulWidget {
  /// Opens a `tel:` uri; true if the dialer was launched. Overridable in tests.
  final Future<bool> Function(Uri uri) launcher;

  const SmsMessagesScreen({super.key, this.launcher = _defaultLauncher});

  @override
  State<SmsMessagesScreen> createState() => _SmsMessagesScreenState();
}

class _SmsMessagesScreenState extends State<SmsMessagesScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _dialing = false;

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
        title: Text(context.tr("accepted_offers"), style: AppTextStyles.heading18),
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
            return Center(child: Text(context.trMessage(state.message)));
          }

          if (state is SmsLoadedState) {
            final messages = state.response.smsMessages;

            if (messages.isEmpty) {
              return Center(child: Text(context.tr("no_accepted_offers")));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(
                  FetchSmsEvent(day: _selectedDate),
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final message = messages[index];

                  return SmsMessageCard(
                    message: message,
                    // Bloc shows it read right away, persists once, and
                    // ignores messages that are already read.
                    onTap: () => context.read<NotificationBloc>().add(
                      PressSmsEvent(message.id),
                    ),
                    onCall: (phone) => _call(message.id, phone),
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

  /// Opens the dialer; the message is only marked read if the dialer opened.
  Future<void> _call(String id, String phone) async {
    if (_dialing) return;
    _dialing = true;
    var opened = false;
    try {
      opened = await widget.launcher(Uri(scheme: 'tel', path: phone));
    } catch (_) {
      opened = false;
    } finally {
      _dialing = false;
    }
    if (!mounted) return;
    if (opened) {
      context.read<NotificationBloc>().add(PressSmsEvent(id));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('cannot_open_dialer'))));
    }
  }
}

Future<bool> _defaultLauncher(Uri uri) async {
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
