import 'dart:io';
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

  /// ⬆️ Compress, upload, and upsert products
  Future<void> upsertProductsListToServer(
      List<Product> updatedSubset,
      ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final now = DateTime.now().toIso8601String();
    final tempDir = await getTemporaryDirectory();

    // 1️⃣ Fetch existing product list
    final existing = await fetchProductsFromServer();

    // 2️⃣ Create a new map of all products
    final productMap = {for (var p in existing) p.id: p};

    // 3️⃣ Process and overwrite any updated entries
    await processInChunks<Product>(updatedSubset, (product) async {
      String? finalImagePath = product.imagePath;

      if (finalImagePath != null && !finalImagePath.startsWith('http')) {
        final originalFile = File(finalImagePath);
        if (await originalFile.exists()) {
          try {
            final fileNameBase = p.basenameWithoutExtension(finalImagePath);
            final compressedPath =
            p.join(tempDir.path, 'compressed_$fileNameBase.jpg');

            final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
              originalFile.path,
              compressedPath,
              quality: 75,
            );

            final fileToUpload = compressed != null
                ? File(compressed.path)
                : originalFile;

            final fileName =
                'product_${DateTime.now().millisecondsSinceEpoch}_${p.basename(fileToUpload.path)}';
            final storagePath = 'products/$fileName';

            await _client.storage.from('products').upload(storagePath, fileToUpload);
            final signedUrl = await _client.storage
                .from('products')
                .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

            finalImagePath = signedUrl;
          } catch (e) {
            print('⚠️ Image upload failed for ${product.name}: $e');
          }
        }
      }

      // Replace in map
      productMap[product.id] = product.copyWith(imagePath: finalImagePath);
    });

    // 4️⃣ Final cleaned and sorted list
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

      // 🧹 Auto-clean unused images after upsert
      final updatedProducts = productMap.values.toList();
      await _deleteUnusedImagesForCurrentUser(updatedProducts);
    } catch (e) {
      print('❌ Upload failed: $e');
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

      final response = await _dio.download(url, savePath, options: Options(responseType: ResponseType.bytes));
      if (response.statusCode == 200) {
        print('✅ Downloaded: $fileName');
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

    // 1️⃣ Get all filenames used in imagePath
    for (final product in userProducts) {
      final path = product.imagePath;
      if (path != null && path.contains('/products/')) {
        final uri = Uri.parse(path);
        final segments = uri.pathSegments;
        final index = segments.indexOf('products');
        if (index != -1 && index + 1 < segments.length) {
          referencedFiles.add(segments[index + 1]);
        }
      }
    }

    try {
      // 2️⃣ List all images in 'products/' bucket
      final files = await bucket.list(path: '');

      // 3️⃣ Filter and delete unused ones
      final toDelete = files
          .where((file) => !referencedFiles.contains(file.name))
          .map((file) => file.name)
          .toList();

      if (toDelete.isEmpty) {
        print('🧼 No unused images to delete.');
        return;
      }

      await processInChunks<String>(toDelete, (fileName) async {
        await bucket.remove([fileName]);
        print('🗑️ Deleted unused image: $fileName');
      });

      print('✅ Cleaned up ${toDelete.length} image(s) for user $userId');
    } catch (e) {
      print('❌ Failed to clean up unused images: $e');
    }
  }

}
