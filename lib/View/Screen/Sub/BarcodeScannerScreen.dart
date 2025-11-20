import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nextpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:nextpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:nextpos/View/Components/Widgets/BouncingCartIcon.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:nextpos/Provider/CartListProvider.dart';

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

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(autoZoom: true);

  final Set<String> _scannedBarcodes = {};
  final List<Map<String, dynamic>> _scannedItems = [];

  bool? _globalIsPack = false;
  bool _initialDialogShown = false;
  bool _canScan = true;
  bool _showScanHint = false;
  bool _showFirstTimeGuide = true;

  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();

    _cameraFacing = controller.facing;

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showFirstTimeGuide = true);
    });
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String? barcode) async {
    if (barcode == null || barcode.trim().isEmpty || !_canScan || _scannedBarcodes.contains(barcode)) return;

    _scannedBarcodes.add(barcode);
    setState(() => _canScan = false);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }

    if (!widget.isSelling) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: CustomNotificationDialog(
            title: 'Scanned Barcode',
            content: 'Scanned: $barcode',
            type: 'success',
            buttonText: 'Use This',
            onConfirm: () {
              widget.onScanned?.call(barcode);
              _cleanupScannerState();
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ),
      );
      return;
    }

    if (_globalIsPack == null) return;
    bool isPack = _globalIsPack!;

    final result = Provider.of<CartListProvider>(context, listen: false)
        .scanAndAddByBarcode(barcode: barcode, isPackView: isPack);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (context, setModalState) => CustomConfirmDialog(
            title: result.success ? 'Scan Successful' : 'Scan Failed',
            customContent: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Scanned: $barcode'),
                const SizedBox(height: 8),
                result.success
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Selling Type: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Text(isPack ? 'Pack' : 'Piece'),
                  ],
                )
                    : Text(
                  result.error ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                ),

              ],
            ),
            confirmText: widget.multiScan ? 'Scan Another' : 'Done',
            cancelText: 'Exit',
            icon: result.success ? LucideIcons.checkCircle : LucideIcons.alertOctagon,
            iconColor: result.success ? Colors.green : Colors.redAccent,
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              if (result.success) {
                if (!widget.multiScan) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _canScan = true;
                    _showScanHint = true;
                    _scannedBarcodes.clear();
                  });
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showScanHint = false);
                  });
                }
              } else {
                setState(() {
                  _canScan = true;
                  _showScanHint = true;
                  _scannedBarcodes.clear();
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _showScanHint = false);
                });
              }
            },
            children: [BouncingCartIcon()],
          ),
        ),
      ),
    );
  }

  void _cleanupScannerState() {
    _scannedBarcodes.clear();
    _scannedItems.clear();
    _globalIsPack = null;
    _initialDialogShown = false;
    _canScan = true;
    _showScanHint = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                _handleBarcode(barcode.rawValue);
              }
            },
          ),

          // 🔳 Overlay Frame with Animation (Back Camera Only)
          if (!_showFirstTimeGuide && _cameraFacing == CameraFacing.back)
            LayoutBuilder(
              builder: (context, constraints) {
                final double overlayHeight = 120;
                final double overlayWidth = MediaQuery.of(context).size.width - 40;
                final double top = (constraints.maxHeight - overlayHeight) / 2;
                final double left = (constraints.maxWidth - overlayWidth) / 2;

                return Stack(
                  children: [
                    Positioned(top: 0, left: 0, right: 0, height: top, child: Container(color: Colors.black87)),
                    Positioned(top: top + overlayHeight, left: 0, right: 0, bottom: 0, child: Container(color: Colors.black87)),
                    Positioned(top: top, left: 0, width: left, height: overlayHeight, child: Container(color: Colors.black87)),
                    Positioned(top: top, left: left + overlayWidth, right: 0, height: overlayHeight, child: Container(color: Colors.black87)),

                    Positioned(
                      top: top,
                      left: left,
                      width: overlayWidth,
                      height: overlayHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),

                    AnimatedBuilder(
                      animation: _lineAnimation,
                      builder: (_, __) {
                        final double dy = top + (_lineAnimation.value * overlayHeight);
                        return Positioned(
                          top: dy,
                          left: left,
                          width: overlayWidth,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.greenAccent.withOpacity(0.2),
                                  Colors.greenAccent,
                                  Colors.greenAccent.withOpacity(0.2),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    Positioned(
                      bottom: top - 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _globalIsPack == true
                                  ? 'Currently scanning: Pack'
                                  : 'Currently scanning: Piece',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Place the barcode inside the box to scan',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          Positioned(
              top: 30,
              left: 0,
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new,size: 30,color: Colors.white,)),
                  Row(
                    children: [
                      Icon(Icons.qr_code_2,color: Colors.white,),
                      SizedBox(width: 10,),
                      Text("Barcode Scan",style: TextStyle(color: Colors.white,fontSize: 20),),
                    ],
                  )
                ],
              )),
          // 🔦 Flash + Flip
          Positioned(
            top: 30,
            right: 0,
            child: Row(
              children: [
                BouncingCartIcon(iconColor: Colors.white,),
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (_, state, __) {
                    final torchState = state.torchState;
                    return IconButton(
                      icon: Icon(
                        torchState == TorchState.on
                            ? Icons.flash_off
                            : torchState == TorchState.off
                            ? Icons.flash_on
                            : Icons.flash_auto,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: torchState == TorchState.unavailable
                          ? null
                          : () async => await controller.toggleTorch(),
                    );
                  },
                ),
              ],
            ),
          ),

          // 🧃 Pack / Piece toggle
          if (_globalIsPack != null && widget.isSelling)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _globalIsPack = !_globalIsPack!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _globalIsPack! ? Icons.inventory_2 : Icons.widgets,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _globalIsPack! ? 'Switch to Per Piece' : 'Switch to Per Pack',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ✅ Scan Hint
          if (_showScanHint)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showScanHint ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LucideIcons.scan, color: Colors.greenAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ready for next scan',
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 👋 First Time Overlay
          if (_showFirstTimeGuide)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFirstTimeGuide = false),
                child: Container(
                  color: Colors.black87.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.scanLine, size: 64, color: Colors.white),
                      const SizedBox(height: 32),
                      const Text(
                        "Scan Your Product",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Point your camera at a barcode.\nIf the product exists, it’ll auto-add to your cart.",
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Tap the 'Pack' or 'Piece' toggle at the bottom\nif you want to switch selling type.",
                        style: TextStyle(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "Tap anywhere to start scanning",
                        style: TextStyle(color: Colors.white54, fontSize: 13.5, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
