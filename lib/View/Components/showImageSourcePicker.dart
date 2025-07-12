import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

Future<void> showImageSourcePicker({
  required BuildContext context,
  required Function(ImageSource) onPick,
}) async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Colors.blue),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context); // ✅ Close modal first
                  onPick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Colors.green),
                title: const Text('Pick from gallery'),
                onTap: () {
                  Navigator.pop(context); // ✅ Close modal first
                  onPick(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
