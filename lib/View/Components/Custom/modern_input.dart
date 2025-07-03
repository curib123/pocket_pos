import 'package:flutter/material.dart';

Widget modernInput(
    TextEditingController c,
    String label,
    String hint,
    IconData icon, {
      TextInputType type = TextInputType.text,
      int maxLines = 1,
    }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,     // Label shown above the field or floating
        hintText: hint,       // Hint inside the field
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
