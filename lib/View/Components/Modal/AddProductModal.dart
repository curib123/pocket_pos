import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Helper/Enums/enum.dart';
import 'package:mobile_pos_inventory/Helper/Enums/enum_extensions.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/View/Components/Core/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/Core/CustomFlatDropdown.dart';

class ProductModalForm extends StatefulWidget {
  final Function(Product) onSave;

  const ProductModalForm({super.key, required this.onSave});

  @override
  State<ProductModalForm> createState() => _ProductModalFormState();
}

class _ProductModalFormState extends State<ProductModalForm> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _defaultPrice = TextEditingController();
  final _costPrice = TextEditingController();
  final _taxRate = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _unitConversion = TextEditingController(text: '1');
  final _unitPriceBasis = TextEditingController();

  String? _selectedCategory;
  ProductType? _selectedType;
  ProductStatus? _selectedStatus = ProductStatus.available;
  Unit? _selectedUnit;
  UnitType? _selectedUnitType;

  bool _isActive = true;
  bool _hasVariants = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreCategoryProvider>(
      builder: (context, storeCategoryProvider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Product', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // Dropdowns First
                CustomFlatDropdown<String>(
                  hint: "Select Category",
                  value: _selectedCategory,
                  items: storeCategoryProvider.visibleCategories,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  itemBuilder: (val) => Text(val),
                ),
                CustomFlatDropdown<ProductType>(
                  hint: "Select Type",
                  value: _selectedType,
                  items: ProductType.values,
                  onChanged: (val) => setState(() => _selectedType = val),
                  itemBuilder: (val) => Text(val.label),
                ),
                CustomFlatDropdown<ProductStatus>(
                  hint: "Select Status",
                  value: _selectedStatus,
                  items: ProductStatus.values,
                  onChanged: (val) => setState(() => _selectedStatus = val),
                  itemBuilder: (val) => Text(val.label),
                ),

                const SizedBox(height: 12),

                // Inputs Next
                CustomTextField(
                  label: 'Name',
                  controller: _name,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  hintText: 'Enter product name',
                ),
                CustomTextField(
                  label: 'Description',
                  controller: _description,
                  hintText: 'Optional product description',
                ),
                CustomTextField(
                  label: 'SKU',
                  controller: _sku,
                  hintText: 'Stock Keeping Unit (optional)',
                ),
                CustomTextField(
                  label: 'Barcode',
                  controller: _barcode,
                  hintText: 'Barcode or QR code (optional)',
                ),
                CustomTextField(
                  label: 'Default Price',
                  controller: _defaultPrice,
                  hintText: 'e.g., 9.99',
                ),
                CustomTextField(
                  label: 'Cost Price',
                  controller: _costPrice,
                  hintText: 'Purchase cost',
                ),
                CustomTextField(
                  label: 'Tax Rate (%)',
                  controller: _taxRate,
                  hintText: 'Tax percentage e.g., 12',
                ),
                CustomTextField(
                  label: 'Discount (%)',
                  controller: _discount,
                  hintText: 'Discount percentage if any',
                ),

                const SizedBox(height: 12),

                // Units
                CustomFlatDropdown<Unit>(
                  hint: "Select Unit",
                  value: _selectedUnit,
                  items: Unit.values,
                  onChanged: (val) => setState(() => _selectedUnit = val),
                  itemBuilder: (val) => Text(val.label),
                ),
                CustomFlatDropdown<UnitType>(
                  hint: "Select Unit Type",
                  value: _selectedUnitType,
                  items: UnitType.values,
                  onChanged: (val) => setState(() => _selectedUnitType = val),
                  itemBuilder: (val) => Text(val.label),
                ),
                CustomTextField(
                  label: 'Unit Conversion',
                  controller: _unitConversion,
                  hintText: 'Conversion rate to base unit',
                ),
                CustomTextField(
                  label: 'Unit Price Basis',
                  controller: _unitPriceBasis,
                  hintText: 'Base unit price description',
                ),

                const SizedBox(height: 12),

                // Toggles
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                SwitchListTile(
                  title: const Text('Has Variants'),
                  value: _hasVariants,
                  onChanged: (val) => setState(() => _hasVariants = val),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final product = Product(
                            id: const Uuid().v4(),
                            name: _name.text.trim(),
                            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
                            category: _selectedCategory,
                            type: _selectedType?.label ?? 'Single',
                            status: _selectedStatus?.label ?? 'Active',
                            sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
                            barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
                            defaultPrice: double.tryParse(_defaultPrice.text),
                            costPrice: double.tryParse(_costPrice.text),
                            taxRate: double.tryParse(_taxRate.text),
                            discount: double.tryParse(_discount.text),
                            unit: _selectedUnit?.label,
                            unitType: _selectedUnitType?.label,
                            unitConversion: double.tryParse(_unitConversion.text),
                            unitPriceBasis: _unitPriceBasis.text.trim().isEmpty ? null : _unitPriceBasis.text.trim(),
                            isActive: _isActive,
                            isDeleted: false,
                            hasVariants: _hasVariants,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          widget.onSave(product);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
