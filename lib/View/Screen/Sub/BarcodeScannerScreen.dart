import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final void Function(String barcode)? onScanned;
  final bool multiScan;
  final bool isSelling;

  const BarcodeScannerScreen({
    super.key,
    this.onScanned,
    this.multiScan = false,
    this.isSelling = false,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    autoZoom: true,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    _handled = true;
    await _controller.stop();

    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 70);
    }

    if (!mounted) return;
    widget.onScanned?.call(value);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan product barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Point the camera at the product barcode. The code will be added to the product form.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
