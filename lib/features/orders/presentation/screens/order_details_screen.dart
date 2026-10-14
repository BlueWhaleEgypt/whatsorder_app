import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:whats_order/features/orders/presentation/screens/order_map_screen.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/offer_form_fields.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/order_location_section.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/order_summary_card.dart';
import '../bloc/make_offer_event.dart';

/// Order details + "make offer" form. Coordinates the form, the Bloc, the
/// reverse-geocoded address and the map navigation; the sections live in
/// `widgets/`.
class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String userId;
  final double? latitude;
  final double? longitude;
  final String? components;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.components,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  /// Backend-facing label appended to the offer text. It is part of the
  /// stored offer, not UI text, so it is intentionally not localized.
  static const _executionTimePayloadLabel = 'مدة التنفيذ';

  final _formKey = GlobalKey<FormState>();
  final _offerController = TextEditingController();

  String? _address;
  late bool _loadingAddress;

  /// Selected execution-time translation key (see [ExecutionTimeSelector]).
  String? _executionTimeKey;

  bool get _hasCoordinates =>
      widget.latitude != null && widget.longitude != null;

  @override
  void initState() {
    super.initState();
    _loadingAddress = _hasCoordinates;
    if (_hasCoordinates) _resolveAddress();
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    String? resolved;
    try {
      final places = await placemarkFromCoordinates(
        widget.latitude!,
        widget.longitude!,
      );
      if (places.isNotEmpty) resolved = _buildAddress(places.first);
    } catch (e) {
      logger.e('Order address lookup failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _address = resolved;
      _loadingAddress = false;
    });
  }

  /// Joins the non-empty, distinct address parts.
  String? _buildAddress(Placemark place) {
    final parts = <String>[];
    for (final value in [
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country,
    ]) {
      final part = value?.trim() ?? '';
      if (part.isNotEmpty && !parts.contains(part)) parts.add(part);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  void _openMap() {
    if (!_hasCoordinates) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderMapScreen(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
        ),
      ),
    );
  }

  void _submit(bool isLoading) {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final executionTime = context.tr(_executionTimeKey!);
    final offerDetails =
        '${_offerController.text.trim()}\n$_executionTimePayloadLabel: $executionTime';

    context.read<OrdersBloc>().add(
      MakeOfferEvent(
        orderId: widget.orderId,
        userId: widget.userId,
        offerDetails: offerDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is MakeOfferSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('offer_sent_successfully'))),
          );

          Navigator.pop(context);
        }

        if (state is MakeOfferErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is MakeOfferLoadingState;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: Text(
              context.tr('order_details'),
              style: AppTextStyles.heading18,
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OrderSummaryCard(
                    orderId: widget.orderId,
                    description: widget.components,
                  ),
                  const SizedBox(height: 24),
                  OrderLocationSection(
                    address: _address,
                    loading: _loadingAddress,
                    onOpenMap: _hasCoordinates ? _openMap : null,
                  ),
                  const SizedBox(height: 24),
                  OfferDetailsField(controller: _offerController),
                  const SizedBox(height: 20),
                  ExecutionTimeSelector(
                    onChanged: isLoading
                        ? null
                        : (key) => setState(() => _executionTimeKey = key),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: context.tr('make_offer'),
                    loading: isLoading,
                    onPressed: () => _submit(isLoading),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
