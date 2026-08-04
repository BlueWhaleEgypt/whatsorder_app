import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserModel user;

  String address = "Loading...";
  @override
  void initState() {
    super.initState();

    user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(
              key: CacheKeys.userModel,
            ) ??
            "{}",
      ),
    );

    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      final places = await placemarkFromCoordinates(
        user.latitude!,
        user.longitude!,
      );

      if (places.isNotEmpty) {
        final place = places.first;

        address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(", ");
      } else {
        address = context.tr("unknown_location");
      }
    } catch (_) {
      address = context.tr("unknown_location");
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(
              key: CacheKeys.userModel,
            ) ??
            "{}",
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr("profile"),
          style: AppTextStyles.heading18,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryGreen,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 55,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "${user.firstName ?? ""} ${user.lastName ?? ""}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _ProfileTile(
              icon: Icons.phone,
              title: context.tr("phone"),
              value: user.phone ?? "-",
            ),
            _ProfileTile(
              icon: Icons.email,
              title: context.tr("email"),
              value: user.email ?? "-",
            ),
            _ProfileTile(
              icon: Icons.location_on,
              title: context.tr("address"),
              value: address,
              // "${user.latitude?.toStringAsFixed(5)}, ${user.longitude?.toStringAsFixed(5)}",
            ),
            _ProfileTile(
              icon: Icons.work,
              title: context.tr("sector"),
              value: user.sectors!.isNotEmpty ? user.sectors!.first.name : "-",
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryGreen.withOpacity(.1),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cellMuted13,
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? "-",
                  style: AppTextStyles.cardTitle15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
