import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

class OrderMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const OrderMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  GoogleMapController? controller;

  @override
  Widget build(BuildContext context) {
    final location = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr("order_location"),
          style: AppTextStyles.heading18,
        ),
      ),
      body: GoogleMap(
        onMapCreated: (c) {
          controller = c;
        },
        initialCameraPosition: CameraPosition(
          target: location,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId(context.tr("your_order")),
            position: location,
          ),
        },
      ),
    );
  }
}
