import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/Model/product_model.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;
  final Dio _dio = Dio();
  final supabasePublicUrl = Supabase.instance.client.rest.url;

  /// 🔄 Chunk processor
  Future<void> processInChunks<T>(
      List<T> items,
      Future<void> Function(T item) callback, {
        int batchSize = 20,
      }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final chunk = items.skip(i).take(batchSize);
      await Future.wait(chunk.map(callback));
    }
  }

  /// 📥 Fetch products from Supabase and handle image downloading
  Future<List<Product>> fetchProductsFromServer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return [];
    }

    print('🔄 Fetching products for user: $userId');
    final Set<String> downloadedFilenames = {};
    final List<Product> products = [];

    try {
      for (int i = 0;; i += 200) {
        final row = await _client
            .from('products')
            .select('data')
            .eq('user_id', userId)
            .range(i, i + 199);

        final rawData = row.isNotEmpty && row[0]['data'] is List
            ? row[0]['data'] as List
            : [];
        if (rawData.isEmpty) break;

        await processInChunks<Map<String, dynamic>>(rawData.cast(), (map) async {
          final imagePath = map['imagePath'];
          if (imagePath is! String || imagePath.contains('your-project-id')) return;

          if (imagePath.contains('product_')) {
            await ensureImageIsLocal(imagePath, map, downloadedFilenames);
          }

          final product = Product.fromMap(map);
          if (product.deletedAt == null) {
            products.add(product);
          }
        });
      }

      print('📦 Supabase fetched: ${products.length} item(s)');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// 📦 Ensure image is downloaded only once and used locally
  Future<void> ensureImageIsLocal(
      String imageUrl,
      Map<String, dynamic> map,
      Set<String> downloadedFilenames,
      ) async {
    try {
      final fileName = p.basename(Uri.parse(imageUrl).path);
      if (downloadedFilenames.contains(fileName)) return;

      final dir = await getApplicationDocumentsDirectory();
      final localPath = p.join(dir.path, fileName);
      final file = File(localPath);

      if (await file.exists()) {
        map['imagePath'] = localPath;
        downloadedFilenames.add(fileName);
        return;
      }

      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      await file.writeAsBytes(response.data!);
      map['imagePath'] = localPath;
      downloadedFilenames.add(fileName);
      print('✅ Downloaded image: $fileName for ${map['name']}');
    } catch (e) {
      print('❌ Failed to download image for ${map['name']}: $e');
    }
  }

  Future<List<Product>> fetchProductsFromServerRaw() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return [];
    }

    print('🔄 Fetching products (raw) for user: $userId');
    final List<Product> products = [];

    try {
      for (int i = 0;; i += 200) {
        final row = await _client
            .from('products')
            .select('data')
            .eq('user_id', userId)
            .range(i, i + 199);

        final rawData = row.isNotEmpty && row[0]['data'] is List
            ? row[0]['data'] as List
            : [];

        if (rawData.isEmpty) break;

        for (final map in rawData.cast<Map<String, dynamic>>()) {
          final product = Product.fromMap(map);
          if (product.deletedAt == null) {
            products.add(product);
          }
        }
      }

      print('📦 Supabase raw fetch: ${products.length} item(s)');
      return products;
    } catch (e) {
      print('❌ Error fetching raw products: $e');
      return [];
    }
  }

  /// ⬆️ Compress, upload, and upsert products (including variant images)
  Future<void> upsertProductsListToServer(List<Product> updatedSubset) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final now = DateTime.now().toIso8601String();
    final tempDir = await getTemporaryDirectory();

    // 1️⃣ Fetch existing product list from server
    final existing = await fetchProductsFromServerRaw();
    final productMap = {for (var p in existing) p.id: p};

    // 2️⃣ Loop through updated products
    await processInChunks<Product>(updatedSubset, (product) async {
      String? finalImagePath = await _uploadImageIfNeeded(product.imagePath, tempDir, product.name,userId);

      // 🧬 Handle variant images too
      final updatedVariants = <Product>[];
      for (var variant in product.variants) {
        final variantImage = await _uploadImageIfNeeded(variant.imagePath, tempDir, variant.name,userId);
        updatedVariants.add(variant.copyWith(imagePath: variantImage));
      }

      // Replace in map
      productMap[product.id] = product.copyWith(
        imagePath: finalImagePath,
        variants: updatedVariants,
      );
    });

    // 3️⃣ Final cleaned and sorted list
    final cleanedProducts = productMap.values
        .where((p) => !(p.imagePath?.contains('your-project-id') ?? false))
        .map((p) => p.toMap())
        .toList();

    final payload = {
      'user_id': userId,
      'data': cleanedProducts,
      'updated_at': now,
    };

    try {
      await _client.from('products').upsert(payload, onConflict: 'user_id');
      print('✅ Upload complete with ${cleanedProducts.length} items!');

      final updatedProducts = productMap.values.toList();
      await _deleteUnusedImagesForCurrentUser(updatedProducts);
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }

  bool _isAlreadyUploaded(String? path) {
    if (path == null) return false;
    final uri = Uri.tryParse(path);
    final filename = uri?.pathSegments.last;
    return filename != null && filename.startsWith('product_') && filename.endsWith('.jpg');
  }


  Future<String?> _uploadImageIfNeeded(String? path, Directory tempDir, String label, String userId) async {
    if (path == null || path.startsWith('http') || _isAlreadyUploaded(path)) return path;

    final originalFile = File(path);
    if (!await originalFile.exists()) return path;

    try {
      final fileNameBase = p.basenameWithoutExtension(path);
      final compressedPath = p.join(tempDir.path, 'compressed_$fileNameBase.jpg');

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        compressedPath,
        quality: 75,
      );

      final fileToUpload = compressed != null ? File(compressed.path) : originalFile;

      // 💡 Generate deterministic hash for file content to avoid duplicate uploads
      final bytes = await fileToUpload.readAsBytes();
      final hash = sha256.convert(bytes).toString().substring(0, 10); // 10-char hash
      final fileName = 'product_${userId}_$hash.jpg';
      final storagePath = 'products/$fileName';

      final exists = await _client.storage.from('products').list(path: 'products');
      if (exists.any((f) => f.name == fileName)) {
        print('🟡 Skipped upload: $fileName already exists.');
      } else {
        await _client.storage.from('products').upload(storagePath, fileToUpload);
        print('📸 Uploaded image for $label');
      }

      final signedUrl = await _client.storage
          .from('products')
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (e) {
      print('⚠️ Image upload failed for $label: $e');
      return path;
    }
  }


  /// 🗑 Delete all products
  Future<void> deleteAllProductsFromServer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('products').upsert({
        'user_id': userId,
        'data': [],
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('🗑 All products cleared for user $userId');
    } catch (e) {
      print('❌ Clear failed: $e');
    }
  }

  /// ❌ Soft delete a product
  Future<void> softDeleteProductFromServer(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = await _client
          .from('products')
          .select('data')
          .eq('user_id', userId)
          .maybeSingle();

      final rawData = row?['data'] as List? ?? [];
      final products = rawData.map((e) => Product.fromMap(e)).toList();

      final updated = products.map((p) =>
      p.id == productId
          ? p.copyWith(deletedAt: DateTime.now(), lastModified: DateTime.now())
          : p,
      ).toList();

      await upsertProductsListToServer(updated);
      print('🗑 Soft-deleted product $productId for user $userId');
    } catch (e) {
      print('❌ Soft delete failed: $e');
    }
  }

  /// 📥 Silent image downloader
  Future<void> downloadImageWithDioSilent(String url, String fileName) async {
    if (url.contains('your-project-id')) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = p.join(dir.path, fileName);

      // Avoid re-downloading if file already exists
      final file = File(savePath);
      if (await file.exists()) {
        print('⚠️ Skipping download: $fileName already exists.');
        return;
      }

      final response = await _dio.download(
        url,
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        print('✅ Downloaded: $fileName');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Dio download error: $e');
    }
  }

  /// 🧹 Auto-delete unused images from Supabase bucket for current user
  Future<void> _deleteUnusedImagesForCurrentUser(List<Product> userProducts) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return;
    }

    final bucket = _client.storage.from('products');
    final referencedFiles = <String>{};

    // 1️⃣ Collect all image filenames from signed URLs
    void collectImageFileNames(String? imagePath) {
      if (imagePath == null) return;

      try {
        final uri = Uri.parse(imagePath);
        final segments = uri.pathSegments;
        final filename = segments.isNotEmpty ? segments.last.split('?').first : null;

        if (filename != null && filename.startsWith('product_${userId}_')) {
          referencedFiles.add(filename);
          print('📎 Referenced image: $filename');
        }
      } catch (e) {
        print('⚠️ Failed to parse imagePath: $imagePath -> $e');
      }
    }

    for (final product in userProducts) {
      collectImageFileNames(product.imagePath);
      for (final variant in product.variants) {
        collectImageFileNames(variant.imagePath);
      }
    }

    try {
      // 2️⃣ List all files in the 'products' folder
      final files = await bucket.list(path: 'products');

      // 3️⃣ Filter unused files for this user
      final toDelete = files
          .where((file) =>
      file.name.startsWith('product_${userId}_') &&
          !referencedFiles.contains(file.name))
          .map((file) => file.name)
          .toList();

      if (toDelete.isEmpty) {
        print('🧼 No unused images to delete for user $userId.');
        return;
      }

      await processInChunks<String>(toDelete, (fileName) async {
        await bucket.remove(['products/$fileName']);
        print('🗑️ Deleted unused image: $fileName');
      });

      print('✅ Cleaned up ${toDelete.length} unused image(s) for user $userId');
    } catch (e) {
      print('❌ Failed to clean up unused images: $e');
    }
  }

  Future<void> hardDeleteProductFromServer(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = await _client
          .from('products')
          .select('data')
          .eq('user_id', userId)
          .maybeSingle();

      final rawData = row?['data'] as List? ?? [];
      final products = rawData.map((e) => Product.fromMap(e)).toList();

      final productToDelete = products.firstWhere(
            (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final imagePath = productToDelete.imagePath;
      if (imagePath != null && imagePath.contains('product_')) {
        final fileName = Uri.parse(imagePath).pathSegments.last;
        await _client.storage.from('products').remove(['products/$fileName']);
        print('🗑️ Deleted image from storage: $fileName');
      }

      final updated = products.where((p) => p.id != productId).toList();
      await upsertProductsListToServer(updated);

      print('✅ Hard-deleted product $productId for user $userId');
    } catch (e) {
      print('❌ Hard delete failed: $e');
    }
  }

}