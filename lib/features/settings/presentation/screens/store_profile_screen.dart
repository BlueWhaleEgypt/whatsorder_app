import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/dashed_upload_box.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';

/*
|--------------------------------------------------------------------------
| StoreProfileScreen — edit the store's public page: identity, contact &
| delivery, and WhatsApp ordering options.
|
| State is local for now; wire [_save] to a Bloc once the endpoint exists.
|--------------------------------------------------------------------------
*/

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  static const _maxAbout = 300;
  static const _dayKeys = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];
  static const _deliveryTimes = [
    'within_1_hour',
    'within_3_hours',
    'within_24_hours',
    'within_2_days',
  ];

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  final _slug = TextEditingController();
  final _address = TextEditingController();
  final _fee = TextEditingController();
  final _welcome = TextEditingController();

  File? _cover;
  File? _logo;
  String? _category;
  TimeOfDay _opensAt = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closesAt = const TimeOfDay(hour: 23, minute: 0);
  String _deliveryTime = 'within_24_hours';
  final Set<String> _days = {'sat', 'sun', 'mon', 'tue', 'wed', 'thu'};
  final List<String> _areas = [];

  bool _acceptOrders = true;
  bool _showPrices = true;
  bool _askAddress = true;
  bool _cod = true;

  @override
  void initState() {
    super.initState();
    _about.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _about, _phone, _slug, _address, _fee, _welcome]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({required bool cover}) async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => cover ? _cover = File(x.path) : _logo = File(x.path));
  }

  Future<void> _pickTime({required bool opens}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: opens ? _opensAt : _closesAt,
    );
    if (t == null) return;
    setState(() => opens ? _opensAt = t : _closesAt = t);
  }

  Future<void> _addArea() async {
    final ctrl = TextEditingController();
    final area = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('sp_add_area')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: ctx.tr('sp_area_hint')),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(ctx.tr('sp_add')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    final v = area?.trim() ?? '';
    if (v.isEmpty || _areas.contains(v)) return;
    setState(() => _areas.add(v));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: dispatch a save event once the store-profile endpoint exists.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('sp_saved')),
        backgroundColor: AppColors.primaryGreenTint,
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('field_required') : null;

  @override
  Widget build(BuildContext context) {
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('store_profile'), style: AppTextStyles.heading18),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Store identity ──────────────────────────────────────────
              _SectionCard(
                title: context.tr('sp_identity'),
                subtitle: context.tr('sp_identity_sub'),
                children: [
                  DashedUploadBox(
                    file: _cover,
                    height: 140,
                    onTap: () => _pickImage(cover: true),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('sp_cover_hint'),
                    style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
                  ),
                  const SizedBox(height: 16),
                  _LogoRow(
                    file: _logo,
                    onChange: () => _pickImage(cover: false),
                    onRemove: () => setState(() => _logo = null),
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: context.tr('sp_store_name'),
                    required: true,
                    child: TextFormField(
                      controller: _name,
                      validator: _required,
                      decoration: _decoration(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_category'),
                    required: true,
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      validator: _required,
                      decoration: _decoration(),
                      items: const [
                        'cat_home_appliances',
                        'cat_fashion',
                        'cat_food',
                        'cat_electronics',
                        'cat_beauty',
                        'cat_other',
                      ]
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(context.tr(k)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_about'),
                    child: TextFormField(
                      controller: _about,
                      maxLines: 4,
                      maxLength: _maxAbout,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      decoration: _decoration(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('sp_about_hint', {
                      'count': '${_about.text.length}',
                      'max': '$_maxAbout',
                    }),
                    style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Contact & delivery ──────────────────────────────────────
              _SectionCard(
                title: context.tr('sp_contact'),
                subtitle: context.tr('sp_contact_sub'),
                children: [
                  _Field(
                    label: context.tr('sp_phone'),
                    required: true,
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _required,
                      decoration: _decoration(
                        prefix: const _Prefix('+20'),
                        suffix: const _VerifiedBadge(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_store_link'),
                    child: TextFormField(
                      controller: _slug,
                      textDirection: TextDirection.ltr,
                      decoration: _decoration(
                        prefix: const _Prefix('whatsorder.app/'),
                        suffix: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: AppColors.textGrey,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: 'whatsorder.app/${_slug.text.trim()}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('sp_copied'))),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('sp_store_link_hint'),
                    style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_address'),
                    child: TextFormField(
                      controller: _address,
                      decoration: _decoration(
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Field(
                          label: context.tr('sp_opens_at'),
                          child: _PickerBox(
                            icon: Icons.access_time_rounded,
                            label: timeLabel(_opensAt),
                            onTap: () => _pickTime(opens: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Field(
                          label: context.tr('sp_closes_at'),
                          child: _PickerBox(
                            icon: Icons.access_time_rounded,
                            label: timeLabel(_closesAt),
                            onTap: () => _pickTime(opens: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Field(
                          label: context.tr('sp_delivery_fee'),
                          child: TextFormField(
                            controller: _fee,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _decoration(
                              prefix: _Prefix(context.tr('sp_egp')),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Field(
                          label: context.tr('sp_delivery_time'),
                          child: DropdownButtonFormField<String>(
                            initialValue: _deliveryTime,
                            isExpanded: true,
                            decoration: _decoration(),
                            items: _deliveryTimes
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(
                                      context.tr(k),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _deliveryTime = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_working_days'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dayKeys.map((d) {
                        final on = _days.contains(d);
                        return _Chip(
                          label: context.tr('day_$d'),
                          selected: on,
                          onTap: () =>
                              setState(() => on ? _days.remove(d) : _days.add(d)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: context.tr('sp_delivery_areas'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in _areas)
                          _Chip(
                            label: a,
                            selected: true,
                            onRemove: () => setState(() => _areas.remove(a)),
                          ),
                        _Chip(
                          label: context.tr('sp_add_area'),
                          icon: Icons.add,
                          dashed: true,
                          onTap: _addArea,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Ordering on WhatsApp ────────────────────────────────────
              _SectionCard(
                title: context.tr('sp_ordering'),
                subtitle: context.tr('sp_ordering_sub'),
                children: [
                  _SwitchRow(
                    title: context.tr('sp_accept_orders'),
                    subtitle: context.tr('sp_accept_orders_sub'),
                    value: _acceptOrders,
                    onChanged: (v) => setState(() => _acceptOrders = v),
                  ),
                  _SwitchRow(
                    title: context.tr('sp_show_prices'),
                    subtitle: context.tr('sp_show_prices_sub'),
                    value: _showPrices,
                    onChanged: (v) => setState(() => _showPrices = v),
                  ),
                  _SwitchRow(
                    title: context.tr('sp_ask_address'),
                    subtitle: context.tr('sp_ask_address_sub'),
                    value: _askAddress,
                    onChanged: (v) => setState(() => _askAddress = v),
                  ),
                  _SwitchRow(
                    title: context.tr('sp_cod'),
                    subtitle: context.tr('sp_cod_sub'),
                    value: _cod,
                    onChanged: (v) => setState(() => _cod = v),
                  ),
                  _SwitchRow(
                    title: context.tr('sp_online_payment'),
                    subtitle: context.tr('sp_online_payment_sub'),
                    value: false,
                    onChanged: null,
                    last: true,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: context.tr('sp_welcome'),
                    child: TextFormField(
                      controller: _welcome,
                      maxLines: 3,
                      decoration: _decoration(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('sp_welcome_hint'),
                    style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GradientButton(label: context.tr('sp_save'), onPressed: _save),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── helpers ─────────────────────────────────────

InputDecoration _decoration({
  Widget? prefix,
  Widget? suffix,
  Widget? prefixIcon,
}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    prefix: null,
    prefixIcon: prefix != null
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
            child: prefix,
          )
        : prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: b(AppColors.border),
    border: b(AppColors.border),
    focusedBorder: b(AppColors.primaryGreen, 1.4),
    errorBorder: b(AppColors.danger),
    focusedErrorBorder: b(AppColors.danger, 1.4),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading18),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.cellMuted13),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _Field({required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ]
                : null,
          ),
          style: AppTextStyles.cellText13.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Prefix extends StatelessWidget {
  final String text;
  const _Prefix(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: TextDirection.ltr,
    style: AppTextStyles.cellMuted13,
  );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    child: Container(
      margin: const EdgeInsetsDirectional.only(end: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.editIconBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: AppColors.primaryGreenTint),
          const SizedBox(width: 4),
          Text(
            context.tr('sp_verified'),
            style: AppTextStyles.cellText13.copyWith(
              fontSize: 12,
              color: AppColors.primaryGreenTint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickerBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cellText13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dashed;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  const _Chip({
    required this.label,
    this.selected = false,
    this.dashed = false,
    this.icon,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected || dashed ? AppColors.primaryGreen : AppColors.textGrey;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.cellText13.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 15, color: fg),
            ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: dashed
          ? CustomPaint(
              painter: DashedBorderPainter(
                color: AppColors.textFaint,
                radius: 30,
                dashWidth: 4,
                dashGap: 3,
              ),
              child: content,
            )
          : Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.editIconBg : AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: selected ? null : Border.all(color: AppColors.border),
              ),
              child: content,
            ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  final File? file;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const _LogoRow({
    required this.file,
    required this.onChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.editIconBg,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('sp_logo'),
                style: AppTextStyles.cellText13.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('sp_logo_hint'),
                style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onChange,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(context.tr('sp_change')),
        ),
        if (file != null)
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr('sp_remove')),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool last;
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.border),
          bottom: last
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cellText13.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}
