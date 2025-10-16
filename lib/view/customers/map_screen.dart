import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import '../../provider/provider.dart';

class CustomerMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String customerName; // ✅ add this

  const CustomerMapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.customerName, // ✅ add this
  }) : super(key: key);

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  String _city = '';
  String _state = '';
  String _area = '';

  @override
  void initState() {
    super.initState();
    _fetchPlaceName();
  }

  Future<void> _fetchPlaceName() async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${widget.latitude}&lon=${widget.longitude}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MyFlutterApp/1.0 (your_email@example.com)',
        },
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

  Future<void> _saveLocation() async {
    final api = Provider.of<SalesOrderProvider>(context, listen: false).apiService;
    if (api == null) return;

    // ✅ Fetch existing ERP location
    final customerDetails = await api.fetchCustomerLocation(widget.customerName, context);
    final double? existingLat = customerDetails?["latitude"]?.toDouble();
    final double? existingLng = customerDetails?["longitude"]?.toDouble();

    bool shouldSave = true;

    // ✅ If ERP already has location, ask for confirmation
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
      ) ?? false; // treat null as "No"
    }

    if (!shouldSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not saved.")),
      );
      return;
    }

    // ✅ Save location
    await api.saveCustomerLocation(
      widget.customerName,
      widget.latitude,
      widget.longitude,
      context,
    );
  }


  @override
  Widget build(BuildContext context) {
    final LatLng customerLatLng = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customer Location',
        onBackTap: () {
          Navigator.pop(context);
        },
        actions: IconButton(
          icon: const Icon(Icons.save, color: Colors.white),
          onPressed: _saveLocation, // Save action
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
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
