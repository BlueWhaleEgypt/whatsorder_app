import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';

/// Red warning shown when the vendor account is explicitly inactive
/// (`activation == false`); empty otherwise.
class InactiveAccountBanner extends StatelessWidget {
  final bool? activation;

  const InactiveAccountBanner({super.key, required this.activation});

  @override
  Widget build(BuildContext context) {
    if (activation != false) {
      return const SizedBox.shrink();
    }

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
