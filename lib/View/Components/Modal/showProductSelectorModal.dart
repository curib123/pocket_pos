import 'package:flutter/material.dart';
import 'package:paninda/Model/product_model.dart';

void showProductCalculatorModal(BuildContext context, List<Product> products) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        final Map<String, double> quantities = {};
        final Map<String, bool> unitSelections = {};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Product Calculator",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final id = product.id;
                    final quantity = quantities[id] ?? 0;
                    final isKilo = unitSelections[id] ?? false;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (quantity > 0) quantities[id] = quantity - 1;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    quantity.toStringAsFixed(1),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      quantities[id] = quantity + 1;
                                    });
                                  },
                                ),
                                Switch(
                                  value: isKilo,
                                  onChanged: (val) {
                                    setState(() {
                                      unitSelections[id] = val;
                                    });
                                  },
                                ),
                                Text(isKilo ? "Kilos" : "Sacks"),
                              ],
                            ),
                            Text(
                              "Total: ${(quantity * product.retailPrice).toStringAsFixed(2)}",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                child: const Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      });
    },
  );
}
