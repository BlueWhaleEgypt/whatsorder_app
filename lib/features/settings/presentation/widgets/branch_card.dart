import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';

/// One branch in the Branches list: names, address and Edit / Delete actions.
///
/// City and area come from the API when present; otherwise they are resolved
/// once from the branch coordinates by reverse geocoding (cached per
/// coordinate pair, and never re-requested on rebuilds).
class BranchCard extends StatefulWidget {
  final BranchModel branch;

  /// Disables Delete while another branch action is running.
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BranchCard({
    super.key,
    required this.branch,
    required this.onEdit,
    required this.onDelete,
    this.isBusy = false,
  });

  /// Resolved (city, area) per coordinate pair, shared by all cards so the
  /// list can rebuild or reorder without new lookups. Failures are not cached.
  static final Map<String, ({String? city, String? area})> _geoCache = {};

  @visibleForTesting
  static void clearGeoCache() => _geoCache.clear();

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard> {
  BranchModel get branch => widget.branch;
  bool get isBusy => widget.isBusy;

  String? _geoCity;
  String? _geoArea;
  String? _requestedKey;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void didUpdateWidget(covariant BranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = oldWidget.branch, b = widget.branch;
    if (a.latitude != b.latitude ||
        a.longitude != b.longitude ||
        a.city != b.city ||
        a.area != b.area) {
      _resolveLocation();
    }
  }

  static String? _clean(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  /// The address without segments that are just the city or area, which are
  /// shown separately as chips.
  static String _addressWithout(String address, List<String> shown) {
    final known = shown.map((e) => e.toLowerCase()).toSet();
    return address
        .split(RegExp(r'[,،]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !known.contains(e.toLowerCase()))
        .join(', ');
  }

  /// Fills [_geoCity]/[_geoArea] from the coordinates when the API did not
  /// provide both values.
  Future<void> _resolveLocation() async {
    _geoCity = null;
    _geoArea = null;

    final lat = branch.latitude, lng = branch.longitude;
    final needed = _clean(branch.city) == null || _clean(branch.area) == null;
    if (!needed || lat == null || lng == null) return;
    if (lat.abs() > 90 || lng.abs() > 180) return;

    final key = '$lat,$lng';
    _requestedKey = key;

    final cached = BranchCard._geoCache[key];
    if (cached != null) {
      _geoCity = cached.city;
      _geoArea = cached.area;
      return;
    }

    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return;
      final resolved = _extract(places.first);
      BranchCard._geoCache[key] = resolved;

      // Ignore stale answers (card disposed or pointed at other coordinates).
      if (!mounted || _requestedKey != key) return;
      setState(() {
        _geoCity = resolved.city;
        _geoArea = resolved.area;
      });
    } catch (e) {
      logger.e('Branch reverse geocoding failed: $e');
    }
  }

  /// City: locality, else sub-administrative area, else administrative area.
  /// Area: sub-locality (district/neighbourhood), else sub-administrative
  /// area when that is not already the city. Never the same text as the city.
  static ({String? city, String? area}) _extract(Placemark p) {
    final city =
        _clean(p.locality) ??
        _clean(p.subAdministrativeArea) ??
        _clean(p.administrativeArea);
    var area =
        _clean(p.subLocality) ??
        (_clean(p.subAdministrativeArea) != city
            ? _clean(p.subAdministrativeArea)
            : null);
    if (area != null &&
        city != null &&
        area.toLowerCase() == city.toLowerCase()) {
      area = null;
    }
    return (city: city, area: area);
  }

  @override
  Widget build(BuildContext context) {
    final name = _clean(branch.name);
    final nameEn = _clean(branch.nameEn);
    final title = name ?? nameEn ?? '';
    final subtitle =
        (name != null &&
            nameEn != null &&
            name.toLowerCase() != nameEn.toLowerCase())
        ? nameEn
        : null;

    final city = _clean(branch.city) ?? _geoCity;
    final area = _clean(branch.area) ?? _geoArea;
    final address = _addressWithout(branch.address, [?city, ?area]);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: icon + names
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.stor,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle15.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cellMuted13,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // City / area
            if (city != null || area != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (city != null)
                    _InfoChip(
                      icon: Icons.location_city_outlined,
                      label: context.tr('city'),
                      value: city,
                    ),
                  if (area != null)
                    _InfoChip(
                      icon: Icons.map_outlined,
                      label: context.tr('area'),
                      value: area,
                    ),
                ],
              ),
            ],

            // Address
            if (address.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: AppTextStyles.cellText13.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: SvgPicture.asset(
                      AppAssets.edit,
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryGreenTint,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: Text(context.tr('edit')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.04,
                      ),
                      side: BorderSide(
                        color: AppColors.primaryGreen.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : widget.onDelete,
                    icon: SvgPicture.asset(
                      AppAssets.delete,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        isBusy ? AppColors.textFaint : AppColors.danger,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: Text(context.tr('delete')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: isBusy
                            ? AppColors.border
                            : AppColors.danger.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small labelled location tag (city or area).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.62,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
