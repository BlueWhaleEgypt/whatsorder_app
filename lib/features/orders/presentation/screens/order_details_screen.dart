import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:geocoding/geocoding.dart';
import 'package:whats_order/features/orders/presentation/screens/order_map_screen.dart';
import '../bloc/make_offer_event.dart';

class OrderDetailsScreen extends StatefulWidget {
  // final OrderModel order;
  final int orderId;
  final String userId;
  final double? latitude;
  final double? longitude;
  final String? components;

  const OrderDetailsScreen({
    super.key,
    // required this.order,
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
  final _formKey = GlobalKey<FormState>();
  String? address;
  bool loadingAddress = true;
  final depreciationController = TextEditingController();

  late List<String> executionTimes = [
    context.tr("15_minutes"),
    context.tr("30_minutes"),
    context.tr("45_minutes"),
    context.tr("1_hour"),
    context.tr("2_hours"),
  ];

  String? selectedExecutionTime;
  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      final places = await placemarkFromCoordinates(
        widget.latitude!,
        widget.longitude!,
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
      }
    } catch (e) {
      address = context.tr("unknown_location");
    }

    if (mounted) {
      setState(() {
        loadingAddress = false;
      });
    }
  }

  @override
  void dispose() {
    depreciationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is MakeOfferSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr("offer_sent_successfully"))),
          );

          Navigator.pop(context);
        }

        if (state is MakeOfferErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is MakeOfferLoadingState;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr("order_details"),
              style: const TextStyle(
                fontSize: 18,
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreenDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr("order_details"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.components ?? "",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              context.tr("order_id_label"),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              "#${widget.orderId}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    context.tr("location"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mapGreenLight,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.primaryGreenLight,
                              width: 1,
                            ),
                          ),
                          child: loadingAddress
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text("${context.tr("loading_location")}"),
                                  ],
                                )
                              : Text(
                                  address ?? context.tr("unknown_location"),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Material(
                        color: AppColors.mapGreenLight,
                        borderRadius: BorderRadius.circular(15),

                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            if (widget.latitude == null ||
                                widget.longitude == null)
                              return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderMapScreen(
                                  latitude: widget.latitude!,
                                  longitude: widget.longitude!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.primaryGreenLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  size: 18,
                                  color: AppColors.textDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('open_map'),
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr("offer_details"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: depreciationController,
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.tr(
                                    "please_enter_offer_details",
                                  );
                                }

                                if (value.trim().length < 5) {
                                  return context.tr("offer_details_too_short");
                                }

                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: context.tr("write_your_offer"),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("order_execution_time"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedExecutionTime,
                        validator: (value) {
                          if (value == null) {
                            return context.tr("please_select_execution_time");
                          }
                          return null;
                        },
                        items: executionTimes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  selectedExecutionTime = value;
                                });
                              },
                        decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              final offerDetails =
                                  "${depreciationController.text.trim()}\nمدة التنفيذ: ${selectedExecutionTime ?? ""}";
                              context.read<OrdersBloc>().add(
                                MakeOfferEvent(
                                  orderId: widget.orderId,
                                  userId: widget.userId,
                                  offerDetails: offerDetails,
                                  // offerDetails: depreciationController.text
                                  //     .trim(),
                                ),
                              );
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.tr("make_offer"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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
