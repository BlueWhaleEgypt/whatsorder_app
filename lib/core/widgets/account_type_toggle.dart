import 'package:flutter/material.dart';
import 'package:whats_order/core/utils/account_type.dart';
import '../theme/app_colors.dart';

// enum AccountType { person, company }

/*
|--------------------------------------------------------------------------
| AccountTypeToggle — the pill-shaped Person / Company segmented switch
| on the Create Account screen.
|--------------------------------------------------------------------------
*/

class AccountTypeToggle extends StatelessWidget {
  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  const AccountTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              icon: Icons.person_outline,
              label: "Person",
              selected: value == AccountType.person,
              onTap: () => onChanged(AccountType.person),
            ),
          ),
          Expanded(
            child: _Segment(
              icon: Icons.apartment_outlined,
              label: "Company",
              selected: value == AccountType.company,
              onTap: () => onChanged(AccountType.company),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.textDark : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
