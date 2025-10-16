import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


class LocationWidget extends StatefulWidget {
  @override
  _LocationWidgetState createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  static const platform = MethodChannel('com.example/location');
  String _currentLocation = 'Fetching location...';
  String _placeName = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final result = await platform.invokeMethod('getCurrentLocation');
      final latitude = result['latitude'];
      final longitude = result['longitude'];

      setState(() {
        _currentLocation = 'Lat: $latitude, Lon: $longitude';
      });

      final place = await _getPlaceName(latitude, longitude);
      setState(() {
        _placeName = place;
      });

    } on PlatformException catch (e) {
      setState(() {
        _currentLocation = "Failed to get location: '${e.message}'.";
      });
    }
  }

  Future<String> _getPlaceName(double latitude, double longitude) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'] ?? 'No place found for the given coordinates.';
    } else {
      return 'Failed to fetch place name.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_currentLocation),
          if (_placeName.isNotEmpty) Text('Place: $_placeName'),
        ],
      ),
    ));
  }
}