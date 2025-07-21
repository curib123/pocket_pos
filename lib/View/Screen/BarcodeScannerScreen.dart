// 📦 Flutter & Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 🎯 App Utilities
import 'package:mobile_stock_inventory/Helper/AppColor.dart';

// 🌐 Providers
import 'package:mobile_stock_inventory/Provider/CartListProvider.dart';

// 🧩 Custom Components
import 'package:mobile_stock_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_stock_inventory/View/Components/BouncingCartIcon.dart';

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

  bool? _globalIsPack;
  bool _initialDialogShown = false;
  String? _firstScannedBarcode;
  bool _canScan = true;
  bool _showScanHint = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSelling) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showInitialIsPackDialog());
    }
  }

  Future<void> _showInitialIsPackDialog() async {
    if (_initialDialogShown) return;
    _initialDialogShown = true;

    bool? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: CustomConfirmDialog(
          title: 'Scan Mode',
          content: 'Will all scanned items be in pack mode?',
          confirmText: 'Yes, all are packs',
          cancelText: 'No',
          icon: LucideIcons.box,
          iconColor: Colors.teal,
          onConfirm: () => result = true,
          onCancel: () => result = false,
        ),
      ),
    );

    setState(() => _globalIsPack = result);
  }

  Future<void> _handleBarcode(String? barcode) async {
    if (barcode == null || barcode.trim().isEmpty || !_canScan || _scannedBarcodes.contains(barcode)) return;

    _scannedBarcodes.add(barcode);

    if (!widget.isSelling) {
      // 🔁 Non-selling mode
      setState(() => _canScan = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CustomNotificationDialog(
          title: 'Scanned Barcode',
          content: 'Scanned: $barcode',
          type: 'success',
          buttonText: 'Use This',
          onConfirm: () {
            widget.onScanned?.call(barcode);
            _cleanupScannerState();
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // close scanner
          },
        ),
      );

      return;
    }

    if (_globalIsPack == null) return;

    setState(() => _canScan = false);

    bool isPack = _globalIsPack ?? await _askIsPackDialog(barcode);

    final result = Provider.of<CartListProvider>(context, listen: false)
        .scanAndAddByBarcode(barcode: barcode, isPackView: isPack);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomNotificationDialog(
        title: result.success ? 'Scan Successful' : 'Scan Failed',
        content: result.success
            ? 'Scanned: $barcode\nType: ${isPack ? "Pack" : "Piece"}'
            : result.error ?? 'An unknown error occurred.',
        type: result.success ? 'success' : 'error',
        buttonText: widget.multiScan ? 'Scan Another' : 'Done',
        onConfirm: () {
          Navigator.pop(context); // close dialog

          if (result.success) {
            if (!widget.multiScan) {
              Navigator.pop(context); // close scanner
            } else {
              setState(() {
                _canScan = true;
                _showScanHint = true;
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
    );
  }

  Future<bool> _askIsPackDialog(String barcode) async {
    bool? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: CustomConfirmDialog(
          title: 'Is this a Pack?',
          content: 'Scanned barcode:\n$barcode\n\nScan this item as a pack?',
          confirmText: 'Yes',
          cancelText: 'No',
          icon: LucideIcons.qrCode,
          iconColor: Colors.teal,
          onConfirm: () => result = true,
          onCancel: () => result = false,
        ),
      ),
    );
    return result ?? false;
  }

  void _cleanupScannerState() {
    _scannedBarcodes.clear();
    _scannedItems.clear();
    _firstScannedBarcode = null;
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
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColor.textSecondary,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: Text(
            widget.multiScan ? '🔍 Scan Items' : '🏷️ Scan Product',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColor.textSecondary,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColor.textSecondary),
          actions: [
            if (widget.multiScan) BouncingCartIcon(),
          ],
        )
            : null,
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
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.barcode_reader, size: 18, color: Colors.white70),
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
