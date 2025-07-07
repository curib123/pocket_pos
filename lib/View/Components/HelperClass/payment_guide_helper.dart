import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentGuideHelper {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch payment guides
  Future<List<Map<String, dynamic>>> fetchPaymentGuides() async {
    final response = await _supabase
        .from('payment_guides')
        .select('id, method_name, instruction')
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Insert new payment guide
  Future<void> insertPaymentGuide({
    required String methodName,
    required String instruction,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('payment_guides').insert({
      'method_name': methodName,
      'instruction': instruction,
    });
  }
}
