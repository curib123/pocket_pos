import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePaymentHelper {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'payment';

  /// Upload payment proof image to Supabase Storage & return public URL
  Future<String> uploadPaymentProof(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final filePath = '$bucketName/$userId-${DateTime.now().millisecondsSinceEpoch}.png';
      print('Uploading payment proof to: $filePath');

      await _supabase.storage.from(bucketName).upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: false),
      );

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      print('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading payment proof: $e');
      rethrow;
    }
  }

  /// Submit manual payment with method & proof image (insert if new, update if existing)
  Future<void> submitPayment({
    required String paymentMethod,
    required File proofImage,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      print('Submitting payment for user: $userId with method: $paymentMethod');

      final proofUrl = await uploadPaymentProof(proofImage);
      const paymentStatus = 'pending';
      final replyMessage = _getDefaultReplyMessage(paymentStatus);

      // Check if user already has payment record
      final existingPayment = await _supabase
          .from('manual_payments')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingPayment == null) {
        // No existing payment → Insert new
        await _supabase.from('manual_payments').insert({
          'user_id': userId,
          'payment_method': paymentMethod,
          'payment_proof_url': proofUrl,
          'payment_status': paymentStatus,
          'payment_reply_message': replyMessage,
        });
        print('New payment submitted successfully.');
      } else {
        // Existing payment → Update
        final paymentId = existingPayment['id'];
        await _supabase.from('manual_payments').update({
          'payment_method': paymentMethod,
          'payment_proof_url': proofUrl,
          'payment_status': paymentStatus,
          'payment_reply_message': replyMessage,
        }).eq('id', paymentId);
        print('Existing payment updated successfully.');
      }
    } catch (e) {
      print('Error submitting payment: $e');
      rethrow;
    }
  }


  Future<String?> getLatestPaymentProofUrl() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      print('Fetching latest payment proof URL for user: $userId');

      final response = await _supabase
          .from('manual_payments')
          .select('payment_proof_url')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final filePathOrUrl = response?['payment_proof_url'] as String?;
      print('Fetched Payment Proof Path or URL: $filePathOrUrl');

      if (filePathOrUrl != null && filePathOrUrl.isNotEmpty) {
        // ✅ Check if it's already a full URL
        final isFullUrl = filePathOrUrl.startsWith('http');
        final publicUrl = isFullUrl
            ? filePathOrUrl
            : _supabase.storage.from('payment').getPublicUrl(filePathOrUrl);

        print('Final Public URL: $publicUrl');
        return publicUrl;
      }

      return null;
    } catch (e) {
      print('Error fetching latest payment proof URL: $e');
      rethrow;
    }
  }



  /// Fetch current user's payment requests
  Future<List<Map<String, dynamic>>> fetchPayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      print('Fetching payments for user: $userId');

      final response = await _supabase
          .from('manual_payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Fetched ${response.length} payment(s).');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching payments: $e');
      rethrow;
    }
  }

  /// Delete a specific payment request (if allowed)
  Future<void> deletePayment(String paymentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      print('Deleting payment with ID: $paymentId for user: $userId');

      await _supabase
          .from('manual_payments')
          .delete()
          .match({'id': paymentId, 'user_id': userId});

      print('Payment deleted successfully.');
    } catch (e) {
      print('Error deleting payment: $e');
      rethrow;
    }
  }

  /// Update payment method, status, and reply message (auto reply message on status change)
  Future<void> updatePayment({
    required String paymentId,
    String? newMethod,
    String? newStatus,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final updates = <String, dynamic>{};
      if (newMethod != null) updates['payment_method'] = newMethod;
      if (newStatus != null) {
        updates['payment_status'] = newStatus;
        updates['payment_reply_message'] = _getDefaultReplyMessage(newStatus);
      }

      if (updates.isNotEmpty) {
        print('Updating payment ID: $paymentId for user: $userId with data: $updates');
        await _supabase
            .from('manual_payments')
            .update(updates)
            .match({'id': paymentId, 'user_id': userId});
        print('Payment updated successfully.');
      } else {
        print('No updates provided for payment ID: $paymentId');
      }
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  /// Default Reply Message Generator
  String _getDefaultReplyMessage(String status) {
    switch (status) {
      case 'approved':
        return 'Your payment has been approved. Thank you!';
      case 'rejected':
        return 'Your payment was rejected. Please try again.';
      case 'pending':
      default:
        return 'Your payment is being reviewed.';
    }
  }
}
