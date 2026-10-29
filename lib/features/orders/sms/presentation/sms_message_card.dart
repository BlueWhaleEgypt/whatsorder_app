import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/sms/data/sms_message_model.dart';
import 'package:whats_order/features/orders/sms/presentation/sms_phone.dart';

/// One SMS message, split into header, content, order chip and phone section.
/// Unread: light-green card with a "new" badge. Read: plain surface.
class SmsMessageCard extends StatelessWidget {
  final SmsMessageModel message;
  final VoidCallback onTap;

  /// Called when the phone section is tapped (only shown if a number exists).
  final void Function(String phone) onCall;

  const SmsMessageCard({
    super.key,
    required this.message,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !message.pressed;
    final body = message.components?.trim() ?? '';
    final phone = extractPhoneNumber(body);

    return Material(
      color: unread ? AppColors.lightGreenBg : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: unread
                          ? AppColors.primaryGreen.withValues(alpha: 0.14)
                          : AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unread
                          ? Icons.mark_chat_unread_outlined
                          : Icons.sms_outlined,
                      size: 22,
                      color: unread
                          ? AppColors.primaryGreen
                          : AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.title ?? '',
                      style: AppTextStyles.cardTitle15.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(unread: unread),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unread ? AppColors.surface : AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    body,
                    key: const ValueKey('sms-body'),
                    style: AppTextStyles.cellMuted13.copyWith(
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
              if (phone != null) ...[
                const SizedBox(height: 10),
                _PhoneSection(phone: phone, onTap: () => onCall(phone)),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: unread ? AppColors.surface : AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${context.tr('order_id_label')}  #${message.orderId ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
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

class _StatusBadge extends StatelessWidget {
  final bool unread;
  const _StatusBadge({required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(unread ? 'sms-status-new' : 'sms-status-read'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: unread ? AppColors.primaryGreen : AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr(unread ? 'status_new' : 'status_read'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: unread ? Colors.white : AppColors.textGrey,
        ),
      ),
    );
  }
}

class _PhoneSection extends StatelessWidget {
  final String phone;
  final VoidCallback onTap;
  const _PhoneSection({required this.phone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const ValueKey('sms-phone'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.call, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('call_customer'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      phone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
