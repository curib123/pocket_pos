import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageHelper {
  static final _supabase = Supabase.instance.client;
  static const String _bucket = "products";
  static const String _forcedExt = ".jpg";
  static final Dio _dio = Dio();

  /// Builds a standardized storage path based on user and product name.
  static String getStoragePath(String userId, String productName) {
    return "$userId/$productName$_forcedExt";
  }

  /// Uploads a compressed image to Supabase Storage.
  static Future<String?> uploadCompressedImageFromPath({
    required String imagePath,
    required String userId,
    required String productName,
    int quality = 85,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) throw Exception("❌ Image not found at $imagePath");

      final filename = "$productName$_forcedExt";
      final storagePath = getStoragePath(userId, productName);

      final tempDir = await getTemporaryDirectory();
      final compressedPath = p.join(tempDir.path, "compressed_$filename");

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        compressedPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) throw Exception("❌ Compression failed");

      await _supabase.storage.from(_bucket).upload(
        storagePath,
        File(compressedPath),
        fileOptions: const FileOptions(upsert: true),
      );

      return storagePath;
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  /// Returns a signed URL with limited access time.


  /// Returns a public URL for a file in storage.
  static String getPublicUrl(String storagePath) {
    return _supabase.storage.from(_bucket).getPublicUrl(storagePath);
  }
  /// Returns a signed URL from Supabase storage
  static Future<String?> getSignedUrl({
    required String storagePath,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(storagePath, expiresIn.inSeconds);
      return signedUrl;
    } catch (e) {
      print("❌ Signed URL error: $e");
      return null;
    }
  }

  /// Returns the best available image URL (public or signed).
  static Future<String?> getAccessibleImageUrl(String storagePath) async {
    if (storagePath.isEmpty) {
      print("🚫 storagePath is null or empty");
      return null;
    }

    final publicUrl = getPublicUrl(storagePath);

    try {
      final res = await _dio.head(publicUrl);
      if (res.statusCode == 200) {
        print("🌐 Public URL works: $publicUrl");
        return publicUrl;
      }
    } catch (e) {
      print("⚠️ Public URL check failed: $e");
    }

    print("🔐 Falling back to signed URL");
    final signedUrl = await getSignedUrl(storagePath: storagePath);
    if (signedUrl != null) {
      print("✅ Signed URL: $signedUrl");
      return signedUrl;
    }

    print("❌ Couldn't get any accessible URL");
    return null;
  }

  /// Downloads image from a Future URL and saves it locally as .jpg.
  static Future<String?> downloadImage({
    required Future<String?> url,
  }) async {
    try {
      final resolvedUrl = await url;

      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        print("❌ Empty or null URL");
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      String name = p.basename(Uri.parse(resolvedUrl).path).trim();

      if (name.isEmpty || name == ".jpg") {
        name = "downloaded_${DateTime.now().millisecondsSinceEpoch}.jpg";
      } else if (!name.toLowerCase().endsWith('.jpg')) {
        name += ".jpg";
      }

      final savePath = p.join(appDir.path, name);
      final file = File(savePath);

      if (await file.exists()) {
        print("📦 File already exists: $savePath");
        return savePath;
      }

      final response = await _dio.download(resolvedUrl, savePath);
      if (response.statusCode == 200) {
        print("✅ Downloaded: $savePath");
        return savePath;
      } else {
        print("❌ Download failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Download error: $e");
      return null;
    }
  }

  /// Deletes any images in storage that don’t match current product names.
  static Future<List<String>> deleteOrphanedProductImages({
    required String userId,
    required List<String> productNames,
  }) async {
    final deletedImages = <String>[];

    try {
      final userFolderPath = "$userId/";
      final validFileNames = productNames.map((name) => "$name$_forcedExt").toSet();

      final storageList = await _supabase.storage
          .from(_bucket)
          .list(path: userFolderPath);

      for (final item in storageList) {
        final isFile = item.name.endsWith(_forcedExt);
        final isOrphan = isFile && !validFileNames.contains(item.name);

        if (isOrphan) {
          final fullPath = "$userFolderPath${item.name}";
          final res = await _supabase.storage.from(_bucket).remove([fullPath]);

          if (res.isNotEmpty) {
            print("🧹 Deleted orphaned image: $fullPath");
            deletedImages.add(fullPath);
          }
        }
      }
    } catch (e) {
      print("❌ Orphan cleanup failed: $e");
    }

    return deletedImages;
  }
}
