
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  bool _hasScanned = false;
  bool _torchEnabled = false;

  late final AnimationController _lineController;

  @override
  void initState() {
    super.initState();

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CommonAppBar(
        title: "Scan QR Code",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () => Navigator.pop(context),
        isAction: false,
      ),
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          MobileScanner(
            controller: MobileScannerController(
              torchEnabled: _torchEnabled,
            ),
            onDetect: (barcodeCapture) {
              if (_hasScanned) return;

              final barcode = barcodeCapture.barcodes.first;
              final String? value = barcode.rawValue;

              if (value != null && value.isNotEmpty) {
                _hasScanned = true;
                Navigator.of(context).pop(value);
              }
            },
          ),

          /// DARK OVERLAY WITH CUTOUT
          _ScannerOverlay(),

          /// SCAN LINE ANIMATION
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: AnimatedBuilder(
                animation: _lineController,
                builder: (_, __) {
                  return Align(
                    alignment: Alignment(
                      0,
                      _lineController.value * 2 - 1,
                    ),
                    child: Container(
                      height: 2,
                      width: 240,
                      color: Colors.greenAccent,
                    ),
                  );
                },
              ),
            ),
          ),

          /// INSTRUCTION TEXT
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: Column(
              children: const [
                Text(
                  "Align the QR code within the frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Scanning will happen automatically",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          /// TORCH BUTTON
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                iconSize: 32,
                color: Colors.white,
                icon: Icon(
                  _torchEnabled
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () {
                  setState(() {
                    _torchEnabled = !_torchEnabled;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
