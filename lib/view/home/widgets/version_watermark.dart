// widgets/version_watermark.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionWatermark extends StatefulWidget {
  final Widget child;

  const VersionWatermark({super.key, required this.child});

  @override
  State<VersionWatermark> createState() => _VersionWatermarkState();
}

class _VersionWatermarkState extends State<VersionWatermark> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_version.isNotEmpty)
          Positioned(
            top: 30,
            right: 16,
            child: IgnorePointer(
              child: Text(
                _version,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.18),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}