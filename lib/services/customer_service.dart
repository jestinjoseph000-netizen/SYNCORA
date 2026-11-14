
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get customers with optional search
  Future<List<Map<String, dynamic>>> getCustomers({
    String searchQuery = '',
  }) async {
    var query = _supabase.from('customers').select();

    if (searchQuery.trim().isNotEmpty) {
      final search = searchQuery.trim().replaceAll(',', ' ');
      query = query.or(
        'name.ilike.%$search%,email.ilike.%$search%,phone.ilike.%$search%',
      );
    }

    final response = await query.order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // Add a customer
  Future<void> addCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    await _supabase.from('customers').insert({
      'name': name.trim(),
      'email': _emptyToNull(email),
      'phone': _emptyToNull(phone),
      'address': _emptyToNull(address),
    });
  }

  // Update customer details
  Future<void> updateCustomer({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    await _supabase.from('customers').update({
      'name': name.trim(),
      'email': _emptyToNull(email),
      'phone': _emptyToNull(phone),
      'address': _emptyToNull(address),
    }).eq('id', id);
  }

  // Delete a customer
  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
