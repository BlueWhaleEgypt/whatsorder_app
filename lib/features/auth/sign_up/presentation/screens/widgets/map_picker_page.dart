import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/logger.dart';

class MapPickerPage extends StatefulWidget {
  /// Optional starting point; when set, the map opens here instead of
  /// the device's current location.
  final LatLng? initialLocation;

  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with WidgetsBindingObserver {
  GoogleMapController? controller;

  LatLng? selectedLocation;

  bool _isServiceDialogShowing = false;
  bool _waitingForSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedLocation = widget.initialLocation;
    if (selectedLocation == null) _loadCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.initialLocation == null) {
      logger.i("App resumed");
      _waitingForSettings = false;
      _loadCurrentLocation();
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      // هل خدمة الموقع شغالة؟
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      logger.i("Service Enabled: $serviceEnabled");

      if (!serviceEnabled) {
        logger.w("Location service is disabled");
        // Don't stack dialogs, and don't re-prompt while the user is in settings.
        if (!_isServiceDialogShowing && !_waitingForSettings) {
          await _showLocationServiceDialog();
        }
        return;
      }

      // التحقق من البرمشن
      LocationPermission permission = await Geolocator.checkPermission();

      logger.i("Permission: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        logger.i("After Permission Request: $permission");
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        logger.w("Location permission denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      logger.i("Lat: ${position.latitude}, Lng: ${position.longitude}");

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
    }
  }

  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;
    _isServiceDialogShowing = true;

    final openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('location_services_disabled')),
        content: Text(context.tr('location_services_disabled_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('open_settings')),
          ),
        ],
      ),
    );

    _isServiceDialogShowing = false;

    if (openSettings == true) {
      _waitingForSettings = true;
      await Geolocator.openLocationSettings();
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
