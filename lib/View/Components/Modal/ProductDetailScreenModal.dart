import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Model/cart_item_model.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/Provider/CartListProvider.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductStockProvider.dart';
import 'package:pocketpos/Provider/VariantProductProvider.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Custom/CustomStepper.dart';
import 'package:pocketpos/View/Components/Custom/CustomSwitchPill.dart';
import 'package:pocketpos/View/Components/Modal/CartListModal.dart';
import 'package:pocketpos/View/Components/Modal/UpsertProductModal.dart';
import 'package:provider/provider.dart';

class ProductDetailModal {
  static void show(BuildContext context, String productId,ModalAsVariant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return FractionallySizedBox(
          heightFactor: 0.80,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: _ProductDetailContent(productId: productId,ModalAsVariant: ModalAsVariant),
          ),
        );
      },
    );
  }
}

class _ProductDetailContent extends StatefulWidget {
  final String productId;
  final bool? ModalAsVariant ;
  const _ProductDetailContent({required this.productId,  this.ModalAsVariant});

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {

  final List<String> stockLogReasonStrings = [
    'sale',     // 🟢 for StockLogReason.sold
    'expired',
    'damaged',
    'donated',
    'used',     // 🔄 instead of "consumed"
  ];


  bool isUsePackSwitch = true;
  double price = 0;
  double cost = 0;
  String unit = '';
  bool usePack = false;
  bool usePiece = false;
  double qty = 0;
  double quantityChosen = 0;
  bool useQtyInput = false;
  bool _hasVariant = true;
  SellingType sellingType = SellingType.pack;
  // This is your selected reason as string (UI value)
  String _selectedReason = 'sale';

// Map from String (UI) → Enum (logic)
  StockLogReason? getStockLogReasonFromString(String reason) {
    switch (reason.trim().toLowerCase()) {
      case 'sale':
        return StockLogReason.sold;
      case 'expired':
        return StockLogReason.expired;
      case 'damaged':
        return StockLogReason.damaged;
      case 'donated':
        return StockLogReason.donated;
      case 'used':
        return StockLogReason.consumed;
      default:
        return null; // 🫠 not recognized
    }
  }

// Map from Enum (logic) → String (UI)
  String getStringFromStockLogReason(StockLogReason reason) {
    switch (reason) {
      case StockLogReason.sold:
        return 'sale';
      case StockLogReason.expired:
        return 'expired';
      case StockLogReason.damaged:
        return 'damaged';
      case StockLogReason.donated:
        return 'donated';
      case StockLogReason.consumed:
        return 'used';
      default:
        return 'unknown';
    }
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final product = context.read<ProductProvider>().getProductById(widget.productId);
    if (product == null) return;

    usePack = product.isSoldByPack;
    usePiece = product.isSoldByPiece;
    unit = product.unit ?? "unit";

    final latest = product.stocks.isNotEmpty ? product.stocks.last : null;
    if (latest == null) return;

    final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);

    final bool isPieceOnly = !product.isSoldByPack && product.isSoldByPiece;
    final bool isPackView = product.isSoldByPack && isUsePackSwitch;

    price = isPieceOnly
        ? latest.retailPrice
        : isPackView
        ? latest.retailPrice
        : latest.retailPrice / perPack;

    cost = isPieceOnly
        ? latest.costPrice
        : isPackView
        ? latest.costPrice
        : latest.costPrice / perPack;

    qty = isPieceOnly
        ? product.totalQuantity.toDouble()
        : isPackView
        ? product.totalQuantity.toDouble()
        : product.looseStock!.remainingPieces.toDouble();

    sellingType = isUsePackSwitch ? SellingType.pack : SellingType.piece;
  }


  Widget get unitType {
    final label = isUsePackSwitch
        ? (usePack ? 'Pack' : 'Piece')
        : (usePiece ? 'Piece' : 'Pack');

    return Row(children: [_buildTag(label)]);
  }

  String formatNumber(num value) => NumberFormat.decimalPattern().format(value);

  void _editVariant(BuildContext context, Product variant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: '',
                    existingProduct: variant,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteVariant(BuildContext context, String parentId, String ,VariantProductProvider variantProductProvider, String variantId) {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: "Delete Variant",
        content: "Are you sure you want to delete this variant?\nThis action cannot be undone.",
        onConfirm: () {
          variantProductProvider.deleteVariant(parentId, variantId);
        },
      ),
    );
  }

  String _formatReasonName(String reason) {
    return reason[0].toUpperCase() + reason.substring(1);
  }


  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getProductById(widget.productId);
    final currency = context.read<CurrencyProvider>().currencyFormat;

    if (product == null) {
      return const Center(child: Text("Product not found"));
    }

    final hasImage = product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        File(product.imagePath!).existsSync();

    return SafeArea(
      child: Consumer4<ProductProvider, ProductStockProvider,VariantProductProvider,CartListProvider  >(
        builder: (context, productProvider, productStockProvider,variantProductProvider,cartListProvider, _) {
          return Scaffold(
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(getStockLogReasonFromString(_selectedReason) == StockLogReason.sold)...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                                text: 'Add to Cart',
                                icon: Icons.shopping_cart_outlined,
                                isFilled: false,
                                onPressed: () {
                                  if (qty <= 0) {
                                    // ❗ Show warning when there's NO stock
                                    showDialog(
                                      context: context,
                                      builder: (_) => CustomNotificationDialog(
                                        onConfirm: () => Navigator.pop(context),
                                        type: 'warning',
                                        title: 'Out of Stock',
                                        content: 'This product is currently out of stock. Please restock before adding to cart.',
                                      ),
                                    );
                                  } else {

                                    // ✅ Proceed to add to cart
                                    cartListProvider.addToCart(CartItem(
                                      productId: product.id,
                                      name: product.name,
                                      price: price,
                                      quantity: quantityChosen.toInt(),
                                      imagePath: product.imagePath,
                                      maxQuantity: qty.toInt(),
                                      sellingType: sellingType,
                                      isSoldPerPack: product.isSoldByPack,
                                      isSoldPerPiece: product.isSoldByPiece,
                                    ));

                                    Navigator.pop(context);
                                  }
                                }

                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                                text: 'Proceed',
                                icon: Icons.check_circle_outline,
                                onPressed: () {
                                  if (qty <= 0) {
                                    // ❗ Show warning when there's NO stock
                                    showDialog(
                                      context: context,
                                      builder: (_) => CustomNotificationDialog(
                                        onConfirm: () => Navigator.pop(context),
                                        type: 'warning',
                                        title: 'Out of Stock',
                                        content: 'This product is currently out of stock. Please restock before adding to cart.',
                                      ),
                                    );
                                  } else {

                                    Navigator.pop(context);
                                    // ✅ Proceed when there is stock
                                    cartListProvider.addToCart(CartItem(
                                      productId: product.id,
                                      name: product.name,
                                      price: price,
                                      quantity: quantityChosen.toInt(),
                                      imagePath: product.imagePath,
                                      maxQuantity: qty.toInt(),
                                      sellingType: sellingType,
                                      isSoldPerPack: product.isSoldByPack,
                                      isSoldPerPiece: product.isSoldByPiece,
                                    ));

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const FractionallySizedBox(
                                        heightFactor: 0.90,
                                        child: CartListModal(),
                                      ),
                                    );


                                  }
                                }

                            ),
                          ),
                        ],
                      ),
                    ]else...[
                      CustomButton(
                        text: "Deduct Product",
                        onPressed: () async {
                          if (quantityChosen <= 0) {
                            showDialog(
                              context: context,
                              builder: (_) => CustomNotificationDialog(
                                onConfirm: () => Navigator.pop(context),
                                type: 'warning',
                                title: "Hold up! 🚫",
                                content: "You need to enter a quantity greater than 0 before deducting stock. Try again!",
                              ),
                            );
                            return;
                          }

                          final isPackOnly = product.isSoldByPack && !product.isSoldByPiece;
                          final isPieceOnly = !product.isSoldByPack && product.isSoldByPiece;
                          final isBoth = product.isSoldByPack && product.isSoldByPiece;

                          final reason = getStockLogReasonFromString(_selectedReason);
                          if (reason == null) {
                            showDialog(
                              context: context,
                              builder: (_) => CustomNotificationDialog(
                                onConfirm: () => Navigator.pop(context),
                                type: 'warning',
                                title: "Missing Reason",
                                content: "Please select a reason for this stock deduction to keep your logs clean and accurate.",
                              ),
                            );
                            return;
                          }

                          // ✅ Confirmation dialog before deducting
                          await showDialog(
                            context: context,
                            builder: (_) => CustomConfirmDialog(
                              title: 'Confirm Deduction',
                              content:
                              'Are you sure you want to deduct ${quantityChosen.toInt()} ${isUsePackSwitch ? 'pack(s)' : 'piece(s)'} '
                                  'from "${product.name}" for reason: ${_selectedReason}?',
                              onConfirm: () async {
                                bool success = false;

                                if (isPieceOnly) {
                                  success = await productStockProvider.sellPack(
                                    product.id,
                                    quantityChosen.toInt(),
                                    reason,
                                  );
                                } else if (isPackOnly || (isBoth && isUsePackSwitch)) {
                                  success = await productStockProvider.sellPack(
                                    product.id,
                                    quantityChosen.toInt(),
                                    reason,
                                  );
                                } else {
                                  success = await productStockProvider.sellPiece(
                                    product.id,
                                    quantityChosen.toInt(),
                                    reason,
                                    context,
                                  );
                                }

                                if (success) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomNotificationDialog(
                                      onConfirm: () {
                                        Navigator.pop(context);
                                        quantityChosen = 0;
                                        productProvider.refreshProducts();
                                      },
                                      type: 'success',
                                      title: "Stock Deducted ✅",
                                      content:
                                      "${quantityChosen.toInt()} ${isUsePackSwitch ? 'pack(s)' : 'piece(s)'} of ${product.name} successfully deducted.",
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomNotificationDialog(
                                      onConfirm: () => Navigator.pop(context),
                                      type: 'error',
                                      title: "Deduction Failed ❌",
                                      content:
                                      "Something went wrong while deducting stock. Try again or check your inventory level.",
                                    ),
                                  );
                                }
                              },
                            ),
                          );

                        },
                      )

                    ]
                  ],
                ),
              ),
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Selling Switch ---
                  if (product.isSoldByPiece && product.isSoldByPack)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.center,
                        child: CustomSwitchPill(
                          options: ['Pack', 'Pcs'],
                          selected: isUsePackSwitch ? 'Pack' : 'Pcs',
                          onSelected: (label) => setState(() {
                            isUsePackSwitch = label == 'Pack';
                            final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);
                            final stock = product.stocks.isNotEmpty ? product.stocks.last : null;

                            price = stock != null
                                ? (!product.isSoldByPack && product.isSoldByPiece)
                                ? stock.retailPrice
                                : isUsePackSwitch
                                ? stock.retailPrice
                                : stock.retailPrice / perPack
                                : 0;

                            cost = stock != null
                                ? (!product.isSoldByPack && product.isSoldByPiece)
                                ? stock.costPrice
                                : isUsePackSwitch
                                ? stock.costPrice
                                : stock.costPrice / perPack
                                : 0;
                            // For quantity logic
                            qty = (!product.isSoldByPack && product.isSoldByPiece)
                                ? product.totalQuantity.toDouble()
                                : isUsePackSwitch
                                ? product.totalQuantity.toDouble()
                                : product.looseStock!.remainingPieces.toDouble();

                             // For selling type logic — structured like qty logic
                            sellingType = isUsePackSwitch ? SellingType.pack : SellingType.piece;

                            quantityChosen = quantityChosen > qty ? qty : quantityChosen;
                          }),
                        ),
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10,horizontal: 20),
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.secondarySurface),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08), // slightly darker base
                          offset: Offset(0, 4), // close shadow
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), // soft diffused shadow
                          offset: Offset(0, 10), // deeper layer
                          blurRadius: 20,
                        ),
                      ],
                    ),


                    child: Column(
                      children: [
                        // --- Product Image & Price Tag ---
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 130,
                                child: hasImage
                                    ? Image.file(
                                  File(product.imagePath!),
                                  key: UniqueKey(),
                                  fit: BoxFit.contain,
                                )
                                    : Container(
                                  color: AppColor.secondarySurface.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Delete Button (top-right)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _deleteProductButton(
                                productProvider,
                                product,
                                variantProductProvider,
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Price Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.sell, size: 13, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          currency.format(price),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // --- Product Name & Link to Main ---
                             Text(
                                product.name,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _getFontSizeForName(product.name) + 5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColor.textPrimary,
                                ),
                              ),


                        const SizedBox(height: 6),

                        // --- Tags: Category, Type, Selling ---
                        if (usePack || usePiece)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: -4,
                              alignment: WrapAlignment.center,
                              children: [
                                if (product.category != null) _buildTag(product.category!),
                                if (product.isVariant) _buildTag("Variant"),
                                if (!product.isVariant) _buildTag("Main Product"),
                                if (usePack) _buildTag('Pack'),
                                if (usePiece) _buildTag('Piece'),
                              ],
                            ),
                          ),

                        const SizedBox(height: 5),

                        // --- Stock Label ---
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2,color: AppColor.textSecondary,size: 15,),
                                  SizedBox(width: 10,),
                                  Text('${product.barcode}',style: TextStyle(fontSize: 14,color: AppColor.textSecondary),)
                                ],
                              ),
                              _buildStockLabel('Available Piece: ${formatNumber(qty)}')
                          ],
                        ),

                        const SizedBox(height: 10),

                        // --- Action Buttons ---
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    backgroundColor: AppColor.primary,
                                    isSlimmer: true,
                                    text: 'Edit',
                                    icon: Icons.edit,
                                    isFilled: true,
                                    onPressed: () => _openEditSheet(product),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: CustomButton(
                                    backgroundColor: AppColor.secondary,
                                    isSlimmer: true,
                                    text: 'Restock',
                                    icon: Icons.inventory_2_outlined,
                                    isFilled: true,
                                    onPressed: () => _openRestockSheet(product),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                            CustomFlatDropdown<String>(
                              hint: 'Select a reason...',
                              value: _selectedReason,
                              items: stockLogReasonStrings, // ✅ Complete this
                              prefixIcon: Icons.inventory_2_outlined,
                              onChanged: (selected) {
                                if (selected != null) {
                                  setState(() => _selectedReason = selected);
                                }
                              },
                              itemBuilder: (reason) => Text(
                                _formatReasonName(reason), // e.g., converts 'sold' -> 'Sold'
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),


                          ]
                        ),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: CustomStepperField(
                                  value: quantityChosen.toInt(),
                                  min: 0,
                                  max: qty.toInt(),
                                  useTextInput: useQtyInput,
                                  onChanged: (val) => setState(() {
                                    quantityChosen = val.toDouble();
                                    // Auto-switch to input mode if reaching/exceeding max qty
                                    if (val >= qty.toInt()) {
                                      useQtyInput = true;
                                    }
                                  }),
                                  themeColor: AppColor.primary,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: CustomSwitchPill(
                                  options: ['Stepper', 'Input'],
                                  selected: useQtyInput ? 'Input' : 'Stepper',
                                  onSelected: (val) => setState(() {
                                    useQtyInput = (val == 'Input');
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Product Variant Info Section ---
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Variants Section ---
                        if (!product.isVariant) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'View Variant Now?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.primary,
                                ),
                              ),
                              Switch(
                                value: _hasVariant,
                                activeColor: AppColor.primary,
                                activeTrackColor: AppColor.primary.withOpacity(0.3),
                                onChanged: (val) => setState(() => _hasVariant = val),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          if (_hasVariant)...[
                            ...product.variants.map(
                                  (variant) => _buildVariantCard(context, variant, product, variantProductProvider),
                            ),
                            if (!product.isVariant)
                              SizedBox(height: 10,),
                               CustomButton(
                                  isSlimmer: false,
                                  text: 'Add Variant',
                                  isFilled: false,
                                  onPressed: () => _openAddVariantSheet(context, product),

                              ),
                          ]
                        ],

                        SizedBox(height: 10 ),
                        product.isVariant ? CustomButton(
                            isSlimmer: false,
                            isFilled: false,
                            icon: LucideIcons.package2,
                            text: "Main product", onPressed: (){
                          if (widget.ModalAsVariant == true) {
                            Navigator.pop(context);
                          } else {
                            final parentId = variantProductProvider.getParentProductIdFromVariantId(widget.productId);
                            if (parentId != null) {
                              showDialog(
                                context: context,
                                builder: (context) => CustomConfirmDialog(
                                  title: "Go to Main Product",
                                  content: "Are you sure you want to view the main product?\nYou’ll leave this product view.",
                                  onConfirm: () {
                                    Navigator.pop(context);
                                    ProductDetailModal.show(context, parentId, false);
                                  },
                                ),
                              );
                            }
                          }
                        }) : SizedBox.shrink(),
                        SizedBox(height: 10 ),
                      ],
                    ),
                ],
              ),
            ),



          );
        },
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.secondarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColor.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStockLabel(String label) {
    // Adjust font size based on label length
    double fontSize;
    if (label.length <= 20) {
      fontSize = 16;
    } else if (label.length <= 35) {
      fontSize = 14;
    } else {
      fontSize = 13;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          color: AppColor.textPrimary,
        ),
      ),
    );
  }

  double _getFontSizeForName(String name) {
    return (22 - (name.length * 0.3)).clamp(10.0, 16.0);
  }




  Widget _deleteProductButton(
      ProductProvider productProvider,
      Product product,
      VariantProductProvider variantProductProvider,
      ) {
    return IconButton(
      onPressed: () {
        final isVariant = product.isVariant;
        final title = isVariant ? "Delete Variant" : "Delete Product";
        final content = isVariant
            ? "Are you sure you want to delete this variant?\nIt will be removed from its parent product."
            : "Are you sure you want to delete this product?\nThis action cannot be undone.";

        showDialog(
          context: context,
          builder: (context) => CustomConfirmDialog(
            title: title,
            content: content,
            onConfirm: () {
              if (isVariant) {
                final parentId = variantProductProvider.getParentProductIdFromVariantId(widget.productId).toString();
                variantProductProvider.deleteVariant(parentId, widget.productId);
              } else {
                productProvider.softDeleteProduct(widget.productId);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                     '🗑️ "${product.name}" has been deleted.'
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColor.textSecondary,
                ),
              );
            },
          ),
        );
      },
      icon: Icon(LucideIcons.trash, color: AppColor.textSecondary, size: 18),
      tooltip: "Delete Product",
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: AppColor.secondarySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }


  void _openEditSheet(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.7,
          minChildSize: 0.65,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: '',
                    existingProduct: p,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openRestockSheet(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.6,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: '',
                    isRestock: true,
                    existingProduct: p,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddVariantSheet(BuildContext ctx, Product parent) async {
    final addedVariant = await showModalBottomSheet<Product>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return UpsertProductModal(
          Category: parent.category.toString(),
          isVariant: true,
          existingProduct: null,
          parentProduct: parent,
        );
      },
    );

    if (addedVariant != null) {
      showDialog(
        context: ctx,
        builder: (context) => CustomNotificationDialog(
          type: 'success',
          title: "Variant Added",
          content: "\"${addedVariant.name}\" has been successfully added to this product.",
          onConfirm: () => Navigator.pop(context),
        ),
      );
    }
  }

  Widget _buildVariantCard(BuildContext ctx, Product v, Product parent,VariantProductProvider variantProductProvider) {
    return InkWell(
      onTap: () => ProductDetailModal.show(ctx, v.id, true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: (v.imagePath != null && v.imagePath!.isNotEmpty)
                    ? DecorationImage(
                  image: FileImage(File(v.imagePath!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: (v.imagePath == null || v.imagePath!.isEmpty)
                  ? const Icon(LucideIcons.image, color: AppColor.textSecondary, size: 20)
                  : null,
            ),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: [
                      if (usePack) _buildTag('Pack'),
                      if (usePiece) _buildTag('Piece'),
                    ],
                  ),
                ],
              ),
            ),
            // Edit/Delete
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                  onPressed: () => _editVariant(context, v),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash, color: AppColor.errorText),
                  onPressed: () => _deleteVariant(context, parent.id, v.id, variantProductProvider, v.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}