import 'package:flutter/material.dart';
import 'package:retailpos/View/Components/Modal/CartListModal.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:retailpos/Helper/AppColor.dart';
import 'package:retailpos/Provider/CartListProvider.dart';
import 'package:retailpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:retailpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:retailpos/View/Components/BouncingCartIcon.dart';

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
  final MobileScannerController controller = MobileScannerController();
  final Set<String> _scannedBarcodes = {};
  final List<Map<String, dynamic>> _scannedItems = [];

  bool? _globalIsPack = false;
  bool _initialDialogShown = false;
  bool _canScan = true;
  bool _showScanHint = false;



  Future<void> _handleBarcode(String? barcode) async {
    if (barcode == null || barcode.trim().isEmpty || !_canScan || _scannedBarcodes.contains(barcode)) return;

    _scannedBarcodes.add(barcode);
    setState(() => _canScan = false);

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
            showThirdButton: true,
            thirdButtonText: "Proceed Now?",
              thirdButtonIcon: Icons.add_shopping_cart,
            onThirdButton: (){
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.90,
                  child: CartListModal(),
                ),
              );
              _canScan = true;
              _showScanHint = true;
              _scannedBarcodes.clear();
            },
            title: result.success ? 'Scan Successful' : 'Scan Failed',
            customContent: result.success
                ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Scanned: $barcode'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Selling Type: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Text(_globalIsPack! ? 'Pack' : 'Piece'),
                  ],
                ),
              ],
            )
                : Text(result.error ?? 'An unknown error occurred.'),
            confirmText: widget.multiScan ? 'Scan Another' : 'Done',
            cancelText: 'Switch to ${_globalIsPack! ? "Piece" : "Pack"}',
            icon: result.success ? LucideIcons.checkCircle : LucideIcons.alertOctagon,
            iconColor: result.success ? Colors.green : Colors.redAccent,
              onCancel: () {
                setState(() {
                  isPack = !isPack;
                  _globalIsPack = isPack;
                  _canScan = true;
                  _showScanHint = true;
                  _scannedBarcodes.clear();
                });
              },
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
                setState(() => _canScan = true);
              }
            },
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: widget.multiScan || !widget.isSelling
            ? AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _cleanupScannerState();
            },
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: AppColor.textSecondary),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            'Scan Now',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.primary,
            ),
          ),
          actions: [
            if (widget.multiScan && _globalIsPack != null)
              InkWell(
                onTap: () => setState(() {
                  _globalIsPack = !_globalIsPack!;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColor.background),
                  ),
                  child: Text(
                    _globalIsPack! ? 'Switch to Piece' : 'Switch to Pack',
                    style: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),


            if (widget.multiScan) BouncingCartIcon(),
          ],
        )
            : null,
        body: Stack(
          children: [
            // 📸 The actual camera scanner
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  _handleBarcode(barcode.rawValue);
                }
              },
            ),

            // 🕶️ Frame overlay with outside dimmed
            LayoutBuilder(
              builder: (context, constraints) {
                final double overlayWidth = MediaQuery.of(context).size.width ;
                final double overlayHeight = 120;
                final double left = (constraints.maxWidth - overlayWidth) / 2;
                final double top = (constraints.maxHeight - overlayHeight) / 2;

                return Stack(
                  children: [
                    // 🔲 Top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: top,
                      child: Container(color: Colors.black.withOpacity(0.6)),
                    ),

                    // 🔲 Bottom
                    Positioned(
                      top: top + overlayHeight,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(color: Colors.black.withOpacity(0.6)),
                    ),

                    // 🔲 Left
                    Positioned(
                      top: top,
                      left: 0,
                      width: left,
                      height: overlayHeight,
                      child: Container(color: Colors.black.withOpacity(0.6)),
                    ),

                    // 🔲 Right
                    Positioned(
                      top: top,
                      left: left + overlayWidth,
                      right: 0,
                      height: overlayHeight,
                      child: Container(color: Colors.black.withOpacity(0.6)),
                    ),

                    // ✨ The transparent frame with border
                    Positioned(
                      left: left,
                      top: top,
                      width: overlayWidth,
                      height: overlayHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 🏷️ Mode label
            if (_globalIsPack != null && widget.isSelling)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade800,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _globalIsPack! ? Icons.inventory_2_rounded : Icons.widgets_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scanning: ${_globalIsPack! ? "Pack" : "Piece"} Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


            // 📄 Bottom instruction
            if (widget.multiScan || !widget.isSelling)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LucideIcons.scanLine, size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Align barcode within frame to scan',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
