import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';

class RestoreProductScreen extends StatelessWidget {
  const RestoreProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: const Text('Restore Products', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          final deletedProducts = productProvider.getAllDeletedProducts();

          if (deletedProducts.isEmpty) {
            return const Center(
              child: Text(
                'No deleted products found.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: deletedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = deletedProducts[index];
              return _buildProductTile(context, productProvider, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, ProductProvider provider, Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildImage(product.imagePath),
              const SizedBox(width: 12),
              Expanded(child: _buildProductDetails(product)),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Restore",
                    icon: Icons.restore,
                    isFilled: true,
                    isSlimmer: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomConfirmDialog(
                          title: "Restore Product",
                          content: "Are you sure you want to restore \"${product.name}\"?",
                          icon: Icons.restore,
                          iconColor: Colors.teal,
                          confirmText: "Restore",
                          cancelText: "Cancel",
                          isPop: true,
                          onConfirm: () async {
                            final success = await provider.restoreProductById(product.id);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success != null
                                      ? '✅ "${product.name}" has been restored.'
                                      : '⚠️ Restore failed. Product might not be deleted.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 5,),
                Expanded(
                  child: CustomButton(
                    text: "Permanent delete",
                    icon: Icons.delete_forever,
                    backgroundColor: AppColor.errorText,
                    isFilled: true,
                    isSlimmer: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomConfirmDialog(
                          title: "Permanent Delete",
                          content: "Are you sure you want to permanently delete \"${product.name}\"? This cannot be undone.",
                          icon: Icons.delete_forever,
                          iconColor: Colors.red,
                          confirmText: "Delete",
                          cancelText: "Cancel",
                          isPop: true,
                          onConfirm: () async {
                            final success = await provider.hardDeleteProduct(product.id);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '🗑️ "${product.name}" has been permanently deleted.'
                                      : '⚠️ Deletion failed. Try again later.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imagePath) {
    final exists = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.grey[200],
        child: exists
            ? Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        )
            : const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        if (product.category != null && product.category!.isNotEmpty)
          Text(
            product.category!,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (product.isSoldByPack) _buildPill('By Pack'),
            if (product.isSoldByPiece) _buildPill('By Piece'),
            if ((product.piecesPerPack ?? 0) > 0)
              _buildPill('${product.piecesPerPack} pcs/pack'),
            if (product.unit != null && product.unit!.isNotEmpty) _buildPill(product.unit!),
            if (product.barcode != null && product.barcode!.isNotEmpty)
              _buildPill('Barcode: ${product.barcode}', soft: true),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Deleted: ${product.deletedAt?.toLocal().toString().split(' ')[0] ?? 'Unknown'}',
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPill(String label, {bool soft = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: soft ? Colors.grey.shade100 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: soft ? Colors.grey.shade300 : Colors.teal.shade200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          color: soft ? Colors.black87 : Colors.teal.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
