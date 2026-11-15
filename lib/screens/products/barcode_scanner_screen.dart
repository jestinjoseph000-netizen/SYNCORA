
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;

  static const Color accentColor = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        _hasScanned = true;

        Navigator.pop(context, value.trim());
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch_outlined,
              color: accentColor,
            ),
          ),
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(
              Icons.flashlight_on_outlined,
              color: accentColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          const Text(
            'Position the barcode inside the frame',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Keep the barcode steady until it is detected.',
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: accentColor,
                ),
                SizedBox(width: 10),
                Text(
                  'SYNCORA Barcode Scanner',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
