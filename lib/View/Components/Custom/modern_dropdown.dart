import 'package:flutter/material.dart';

Widget modernDropdown(String label, IconData icon, String? value, List<String> items, void Function(String?) onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: label,
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  );
}