import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../provider/provider.dart';

class CustomerMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String customerName;

  const CustomerMapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.customerName,
  }) : super(key: key);

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  late double _latitude;
  late double _longitude;
  String _city = '';
  String _state = '';
  String _area = '';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _latitude = widget.latitude;
    _longitude = widget.longitude;
    _fetchPlaceName();
  }

  // ✅ Reverse geocode to get city/state/area
  Future<void> _fetchPlaceName() async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$_latitude&lon=$_longitude';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'MyFlutterApp/1.0 (your_email@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        setState(() {
          _city = address['city'] ??
              address['town'] ??
              address['village'] ??
              'Unknown city';
          _state = address['state'] ?? 'Unknown state';
          _area = address['neighbourhood'] ??
              address['suburb'] ??
              address['city_district'] ??
              'Unknown area';
        });
      }
    } catch (e) {
      debugPrint('Exception: $e');
    }
  }

  // ✅ Get device location (with permission)
  Future<Position?> _getDeviceLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied.')),
      );
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ✅ Fetch current device location and update marker
  Future<void> _updateToCurrentLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final position = await _getDeviceLocation(context);
    Navigator.pop(context);

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _fetchPlaceName();
      _mapController.move(LatLng(_latitude, _longitude), 16.0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location fetched successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch current location.")),
      );
    }
  }

  // ✅ Save location to ERP
  Future<void> _saveLocation() async {
    final api = Provider.of<SalesOrderProvider>(context, listen: false).apiService;
    if (api == null) return;

    // Fetch existing ERP location
    final customerDetails = await api.fetchCustomerLocation(widget.customerName, context);
    final double? existingLat = customerDetails?["latitude"]?.toDouble();
    final double? existingLng = customerDetails?["longitude"]?.toDouble();

    bool shouldSave = true;

    // Ask before overwriting existing ERP location
    if (existingLat != null && existingLng != null && existingLat != 0.0 && existingLng != 0.0) {
      shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirm Save"),
          content: const Text(
              "This customer already has a location. Do you want to overwrite it with the current location?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Yes"),
            ),
          ],
        ),
      ) ??
          false;
    }

    if (!shouldSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not saved.")),
      );
      return;
    }

    await api.saveCustomerLocation(
      widget.customerName,
      _latitude,
      _longitude,
      context,
    );
  }
  Future<void> _shareLocation() async {
    try {
      if (_latitude == 0.0 || _longitude == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available to share.')),
        );
        return;
      }

      // 🌍 Create a shareable Google Maps link
      final String googleMapsUrl =
          'https://www.google.com/maps?q=$_latitude,$_longitude';

      final String message =
          '📍 Location of ${widget.customerName}\n'
          'City: $_city\n'
          'State: $_state\n'
          'Area: $_area\n\n'
          'View on map: $googleMapsUrl';

      await Share.share(message);

    } catch (e) {
      debugPrint('Error sharing location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share location.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final LatLng customerLatLng = LatLng(_latitude, _longitude);

    return Scaffold(
      appBar: CommonAppBar(
        // title: 'Customer Location',
        title: widget.customerName,

        onBackTap: () => Navigator.pop(context),
        // actions: Row(
        //   children: [
        //     IconButton(
        //       icon: const Icon(Icons.location_on_sharp, color: Colors.white),
        //       tooltip: 'Get Current Location',
        //       onPressed: _updateToCurrentLocation,
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.save, color: Colors.white),
        //       tooltip: 'Save Location',
        //       onPressed: _saveLocation,
        //     ),
        //   ],
        // ),
        actions: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.location_on_sharp, color: Colors.white),
              tooltip: 'Get Current Location',
              onPressed: _updateToCurrentLocation,
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: 'Save Location',
              onPressed: _saveLocation,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share Location',
              onPressed: _shareLocation,
            ),
          ],
        ),

      ),
      body: Column(
        children: [
          Expanded(
            child:
            FlutterMap(
              mapController: _mapController, // ✅ Attach controller
              options: MapOptions(
                initialCenter: customerLatLng,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.sales_ordering_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: customerLatLng,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("City: $_city"),
                Text("State: $_state"),
                Text("Area: $_area"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
