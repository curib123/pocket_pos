import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class PurchaseService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Creates default purchase values
  Map<String, dynamic> createDefaults({
    bool isTrial = false,
    bool isPurchase = false,
    DateTime? trialExpiration,
    String paymentMethod = '',
    String paymentProofUrl = '',
  }) {
    final data = {
      'id': _userId,
      'is_trial': isTrial,
      'is_purchase': isPurchase,
      'trial_expiration_date':
      (trialExpiration ?? DateTime.now().add(Duration(days: 7)))
          .toIso8601String(),
      'payment_method': paymentMethod,
      'payment_proof_url': paymentProofUrl,
    };
    print('[createDefaults] => $data');
    return data;
  }

  /// Upserts default purchase data for the current user
  Future<void> upsertPurchaseDefaults({
    bool isTrial = false,
    bool isPurchase = false,
    DateTime? trialExpiration,
    String paymentMethod = '',
    String paymentProofUrl = '',
  }) async {
    if (_userId == null) return;

    final data = createDefaults(
      isTrial: isTrial,
      isPurchase: isPurchase,
      trialExpiration: trialExpiration,
      paymentMethod: paymentMethod,
      paymentProofUrl: paymentProofUrl,
    );

    print('[upsertPurchaseDefaults] Upserting: $data');

    await _client
        .from('purchase')
        .upsert(data, onConflict: 'id');
  }


  Future<Map<String, dynamic>?> getPaymentDetails() async {
    if (_userId == null) return null;

    print('[getPaymentDetails] Fetching for user: $_userId');
    final result = await _client
        .from('purchase')
        .select('payment_method, payment_proof_url, trial_expiration_date')
        .eq('id', _userId!)
        .maybeSingle();

    print('[getPaymentDetails] Result => $result');
    if (result == null) return null;

    return {
      'paymentMethod': result['payment_method'],
      'paymentProofUrl': result['payment_proof_url'],
      'expirationDate': result['trial_expiration_date'],
    };
  }

  Future<void> toggleTrial(bool isTrial, {DateTime? trialExpiration}) async {
    if (_userId == null) return;
    print('[toggleTrial] User: $_userId, isTrial: $isTrial');

    final existing = await _client
        .from('purchase')
        .select('id')
        .eq('id', _userId!)
        .maybeSingle();

    final data = {
      'is_trial': isTrial,
      'trial_expiration_date': trialExpiration?.toIso8601String() ??
          DateTime.now().add(Duration(days: 7)).toIso8601String(),
    };

    print('[toggleTrial] Existing: $existing');
    if (existing != null) {
      print('[toggleTrial] Updating with $data');
      await _client.from('purchase').update(data).eq('id', _userId!);
    } else {
      print('[toggleTrial] Inserting with defaults');
      await upsertPurchaseDefaults(
        isTrial: isTrial,
        trialExpiration: trialExpiration,
      );
    }
  }

  Future<void> togglePurchase(bool isPurchase) async {
    if (_userId == null) return;
    print('[togglePurchase] User: $_userId, isPurchase: $isPurchase');

    final existing = await _client
        .from('purchase')
        .select('id')
        .eq('id', _userId!)
        .maybeSingle();

    if (existing != null) {
      print('[togglePurchase] Updating only is_purchase');
      await _client
          .from('purchase')
          .update({'is_purchase': isPurchase}).eq('id', _userId!);
    } else {
      print('[togglePurchase] Inserting full defaults');
      await upsertPurchaseDefaults(isPurchase: isPurchase);
    }
  }

  Future<bool> getTrial() async {
    if (_userId == null) return false;
    print('[getTrial] User: $_userId');

    final result = await _client
        .from('purchase')
        .select('is_trial')
        .eq('id', _userId!)
        .maybeSingle();

    print('[getTrial] Result: $result');
    return result?['is_trial'] ?? false;
  }

  Future<bool> getPurchase() async {
    if (_userId == null) return false;
    print('[getPurchase] User: $_userId');

    final result = await _client
        .from('purchase')
        .select('is_purchase')
        .eq('id', _userId!)
        .maybeSingle();

    print('[getPurchase] Result: $result');
    return result?['is_purchase'] ?? false;
  }

  Future<void> sendPayment({
    required File file,
    required String paymentMethod,
  }) async {
    if (_userId == null) return;
    print('[sendPayment] User: $_userId, Method: $paymentMethod');

    final compressedBytes = await _compressImage(file);
    print('[sendPayment] Image compressed');

    final fileName = 'payment-$_userId-${const Uuid().v4()}.jpg';
    final filePath = 'payment/$_userId/$fileName';
    final storage = _client.storage.from('payment');

    await storage.uploadBinary(
      filePath,
      compressedBytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    print('[sendPayment] Uploaded to $filePath');

    final publicUrl = storage.getPublicUrl(filePath);
    print('[sendPayment] Public URL => $publicUrl');

    final existing = await _client
        .from('purchase')
        .select('id')
        .eq('id', _userId!)
        .maybeSingle();

    print('[sendPayment] Existing purchase: $existing');
    if (existing != null) {
      await _client.from('purchase').update({
        'payment_method': paymentMethod,
        'payment_proof_url': publicUrl,
      }).eq('id', _userId!);
      print('[sendPayment] Updated payment details');
    } else {
      await upsertPurchaseDefaults(
        paymentMethod: paymentMethod,
        paymentProofUrl: publicUrl,
      );
      print('[sendPayment] Inserted new payment record');
    }
  }

  Future<Uint8List> _compressImage(File file) async {
    print('[compressImage] Reading and compressing image...');
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image format');

    final resized = img.copyResize(image, width: 800);
    final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
    print('[compressImage] Compression done');
    return compressed;
  }
}
