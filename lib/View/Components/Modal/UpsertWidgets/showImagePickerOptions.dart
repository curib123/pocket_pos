
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showImagePickerOptions({
  required BuildContext context,
  required void Function(ImageSource source) onImagePicked,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Choose an option',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),

          // 📸 Gallery option
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: Colors.teal),
            title: const Text('Pick from Gallery'),
            onTap: () {
              Navigator.pop(context);
              onImagePicked(ImageSource.gallery);
            },
          ),

          const Divider(height: 1),

          // 📷 Camera option
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Colors.deepOrange),
            title: const Text('Capture from Camera'),
            onTap: () {
              Navigator.pop(context);
              onImagePicked(ImageSource.camera);
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
