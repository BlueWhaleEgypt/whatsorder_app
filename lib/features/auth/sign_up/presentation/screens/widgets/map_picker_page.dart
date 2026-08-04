import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:whats_order/core/utils/logger.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with WidgetsBindingObserver {
  GoogleMapController? controller;

  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.i("App resumed");
      _loadCurrentLocation();
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final location = Location();

      // هل خدمة الموقع شغالة؟
      bool serviceEnabled = await location.serviceEnabled();

      logger.i("Service Enabled: $serviceEnabled");

      if (!serviceEnabled) {
        // هيظهر Dialog للمستخدم
        serviceEnabled = await location.requestService();

        logger.i("After Request Service: $serviceEnabled");

        if (!serviceEnabled) {
          logger.w("User refused to enable location service");
          return;
        }
      }

      // التحقق من البرمشن
      PermissionStatus permission = await location.hasPermission();

      logger.i("Permission: $permission");

      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();

        logger.i("After Permission Request: $permission");
      }

      if (permission != PermissionStatus.granted) {
        logger.w("Location permission denied");
        return;
      }

      final locationData = await location.getLocation();

      logger.i("Lat: ${locationData.latitude}, Lng: ${locationData.longitude}");

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Choose Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation!,
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (c) => controller = c,
        markers: {
          Marker(
            markerId: const MarkerId("selected"),
            position: selectedLocation!,
          ),
        },
        onTap: (latLng) {
          setState(() {
            selectedLocation = latLng;
          });
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
              icon: const Icon(Icons.check),
              label: const Text(
                "Confirm Location",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
