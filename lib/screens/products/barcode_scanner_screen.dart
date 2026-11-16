
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
  static const Color backgroundColor = Color(0xFF080B10);
  static const Color surfaceColor = Color(0xFF111923);

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

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: accentColor, width: 4)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: accentColor, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: accentColor, width: 4)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: accentColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _scannerFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth.clamp(220.0, 420.0);
        final frameHeight = frameWidth * 0.68;

        return SizedBox(
          width: frameWidth,
          height: frameHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
              ),
              _corner(top: true, left: true),
              _corner(top: true, left: false),
              _corner(top: false, left: true),
              _corner(top: false, left: false),
            ],
          ),
        );
      },
    );
  }

  Widget _cameraControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(
              Icons.cameraswitch_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          Container(
            height: 27,
            width: 1,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(
              Icons.flashlight_on_outlined,
              color: accentColor,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 18,
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: accentColor,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                compact ? 8 : 18,
                20,
                20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 38,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: accentColor,
                            size: 15,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'PRODUCT IDENTIFICATION',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 13 : 22),

                    const Text(
                      'Scan Product Barcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Align the barcode within the scanning area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: compact ? 18 : 30),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 12 : 18),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 7,
                                width: 7,
                                decoration: const BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'CAMERA SCANNER ACTIVE',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: compact ? 13 : 20),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: AspectRatio(
                              aspectRatio: 1.35,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: MobileScanner(
                                      controller: _controller,
                                      onDetect: _onDetect,
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: _scannerFrame(),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.65,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Place barcode inside the frame',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: compact ? 12 : 18),

                          _cameraControls(),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 15 : 25),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scanning Tips',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Keep the barcode steady and make sure it is clearly visible. Use the flashlight in low-light conditions.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 15 : 24),

                    const Text(
                      'SYNCORA  •  SMART INVENTORY MANAGEMENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
