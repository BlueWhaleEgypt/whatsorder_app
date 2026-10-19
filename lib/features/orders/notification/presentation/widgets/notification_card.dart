import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/notification/data/notification_model.dart';

/// One notification. Unread: light-green card with an unread dot. Read:
/// plain surface with less emphasis.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final message = notification.components?.trim() ?? '';

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unread
                      ? AppColors.primaryGreen.withValues(alpha: 0.05)
                      : AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  unread
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_rounded,
                  color: unread
                      ? const Color.fromARGB(255, 34, 183, 88)
                      : AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title ?? '',
                            style: AppTextStyles.cardTitle15.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              key: const ValueKey('unread-dot'),
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 34, 183, 88),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cellMuted13.copyWith(
                          height: 1.4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: unread
                            ? AppColors.surface
                            : AppColors.lightGreenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${context.tr('order_id_label')}  #${notification.orderId ?? ''}',
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
