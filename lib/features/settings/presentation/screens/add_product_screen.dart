import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/utils/price_formatter.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/sector_dropdown.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
import 'package:whats_order/features/settings/data/product/add_product_request.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/data/product/update_product_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/add_product_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/add_product_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/add_product_state.dart';
import 'package:whats_order/features/settings/presentation/utils/add_product_form_rules.dart';
import 'package:whats_order/features/settings/presentation/utils/product_photos_controller.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/product_form_field.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/product_photos_picker.dart';
import 'package:whats_order/injection/injection_container.dart';

/*
|--------------------------------------------------------------------------
| AddProductScreen — POST /api/auth/vendor-services, or, when given a
| [product], PUT /api/auth/vendor-services/{id} to edit it.
|
| Pops with `true` once the product is saved so the caller can refresh.
| Every field is required; validation rules live in AddProductFormRules and
| the picked photos in ProductPhotosController.
|--------------------------------------------------------------------------
*/

/// Opens the gallery and returns the photos the user picked (empty if they
/// cancelled). Replaceable so the screen can be tested without a gallery.
typedef PickPhotos = Future<List<XFile>> Function();

Future<List<XFile>> _pickFromGallery() =>
    ImagePicker().pickMultiImage(imageQuality: 80);

class AddProductScreen extends StatelessWidget {
  /// The product to edit; null adds a new one.
  final ProductModel? product;
  final PickPhotos pickPhotos;

  const AddProductScreen({
    super.key,
    this.product,
    this.pickPhotos = _pickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AddProductBloc>()),
        BlocProvider(create: (_) => sl<OnboardingCubit>()..loadSectors()),
      ],
      child: _AddProductView(product: product, pickPhotos: pickPhotos),
    );
  }
}

class _AddProductView extends StatefulWidget {
  final ProductModel? product;
  final PickPhotos pickPhotos;

  const _AddProductView({required this.product, required this.pickPhotos});

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<_AddProductView> {
  static const _pagePadding = EdgeInsets.all(16);
  static const _fieldSpacing = SizedBox(height: 16);
  static const _columnSpacing = SizedBox(width: 12);

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(text: _initialPrice);
  late final _delivery = TextEditingController(
    text: widget.product?.deliveryTime,
  );
  late final _note = TextEditingController(text: widget.product?.note);

  /// Holds the photos of a product being edited too, so they can be removed
  /// or replaced.
  late final _photos = ProductPhotosController(
    // A product that has photos can't end up with none; one without may.
    isRequired: widget.product?.photos.isNotEmpty ?? true,
    existingPhotos: widget.product?.photos ?? const [],
  );

  /// Read back from the dropdown; it is validated as non-null on submit.
  late String? _sectorId = widget.product?.sectorId;

  /// Set synchronously on submit. The Bloc only emits `Loading` after an
  /// async connectivity check, so this is what stops a quick double tap
  /// from sending the product twice.
  bool _isSubmitting = false;
  bool _isPickingPhotos = false;

  bool get _isEditing => widget.product != null;

  String? get _initialPrice {
    final price = widget.product?.price;
    if (price == null) return null;
    return price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _delivery.dispose();
    _note.dispose();
    _photos.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_isPickingPhotos || !_photos.canAddMore) return;
    _isPickingPhotos = true;
    try {
      final picked = await widget.pickPhotos();
      if (!mounted) return;
      _photos.add(picked);
    } catch (e, st) {
      logger.e('Picking product photos failed: $e\n$st');
      if (mounted) _snack(context.tr('something_went_wrong'));
    } finally {
      _isPickingPhotos = false;
    }
  }

  void _submit() {
    if (_isSubmitting) return;

    final formValid = _formKey.currentState!.validate();
    final photosValid = _photos.validate();
    if (!formValid || !photosValid) return;
    if (_sectorId == null) {
      _snack(context.tr('field_required'));
      return;
    }

    final vendorId =
        CacheHelper.getDataFromSharedPreference(
          key: CacheKeys.vendorId,
        )?.toString() ??
        '';
    if (vendorId.isEmpty) {
      _snack(context.tr('user_id_missing'));
      return;
    }

    final request = AddProductRequest(
      name: _name.text.trim(),
      price: AddProductFormRules.parsePrice(_price.text)!,
      deliveryTime: _delivery.text.trim(),
      sectorId: _sectorId!,
      vendorId: vendorId,
      note: _note.text.trim(),
      photoPaths: _photos.paths,
      // Only touch the photos when they changed; see keptPhotoFileNames.
      keptPhotoFileNames: _photos.hasChanges
          ? _photos.existingPhotos.toList()
          : const [],
    );

    _isSubmitting = true;
    final product = widget.product;
    context.read<AddProductBloc>().add(
      product == null
          ? SubmitAddProductEvent(request)
          : SubmitUpdateProductEvent(
              UpdateProductRequest(id: product.id, product: request),
            ),
    );
  }

  void _onStateChanged(BuildContext context, AddProductState state) {
    if (state is AddProductSuccess) {
      _snack(context.tr(state.message));
      Navigator.pop(context, true);
    } else if (state is AddProductError) {
      _isSubmitting = false;
      _snack(context.trMessage(state.message));
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String? _validateRequired(String? value) =>
      AddProductFormRules.hasText(value) ? null : context.tr('field_required');

  String? _validatePrice(String? value) =>
      AddProductFormRules.parsePrice(value) == null
      ? context.tr('field_required')
      : null;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddProductBloc, AddProductState>(
      listener: _onStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: Text(
            context.tr(_isEditing ? 'edit_product' : 'add_new_product'),
            style: AppTextStyles.heading18,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: _pagePadding,
            children: [
              ProductPhotosPicker(
                controller: _photos,
                onAddPressed: _pickPhotos,
              ),
              _fieldSpacing,
              ProductFormField(
                label: context.tr('product_name'),
                controller: _name,
                validator: _validateRequired,
              ),
              _fieldSpacing,
              BlocBuilder<OnboardingCubit, OnboardingState>(
                buildWhen: (previous, current) =>
                    previous.sectors != current.sectors ||
                    previous.sectorsLoading != current.sectorsLoading ||
                    previous.sectorsError != current.sectorsError,
                builder: (context, state) => SectorDropdown(
                  sectors: state.sectors,
                  loading: state.sectorsLoading,
                  error: state.sectorsError,
                  value: _sectorId,
                  onChanged: (v) => setState(() => _sectorId = v),
                  onRetry: () => context.read<OnboardingCubit>().loadSectors(),
                ),
              ),
              _fieldSpacing,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProductFormField(
                      label: context.tr('price'),
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: '${PriceFormatter.currency} ',
                      validator: _validatePrice,
                    ),
                  ),
                  _columnSpacing,
                  Expanded(
                    child: ProductFormField(
                      label: context.tr('delivery_time'),
                      controller: _delivery,
                      validator: _validateRequired,
                    ),
                  ),
                ],
              ),
              _fieldSpacing,
              ProductFormField(
                label: context.tr('description'),
                controller: _note,
                maxLines: 4,
                validator: _validateRequired,
              ),
              const SizedBox(height: 24),
              BlocBuilder<AddProductBloc, AddProductState>(
                buildWhen: (previous, current) =>
                    (previous is AddProductLoading) !=
                    (current is AddProductLoading),
                builder: (context, state) {
                  final loading = state is AddProductLoading;
                  return GradientButton(
                    onPressed: loading ? null : _submit,
                    loading: loading,
                    label: context.tr(
                      _isEditing ? 'save_changes' : 'publish_product',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
