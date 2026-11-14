
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all orders with customer information
  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await _supabase
        .from('orders')
        .select('*, customers(name, email, phone)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch details of a particular order
  Future<Map<String, dynamic>> getOrderDetails(
    String orderId,
  ) async {
    final response = await _supabase
        .from('orders')
        .select('''
          *,
          customers(name, email, phone, address),
          order_items(
            id,
            quantity,
            unit_price,
            line_total,
            products(name, sku)
          )
        ''')
        .eq('id', orderId)
        .single();

    return response;
  }

  // Create an order and automatically deduct stock
  Future<String> createOrder({
    required String customerId,
    required List<String> productIds,
    required List<int> quantities,
  }) async {
    if (productIds.isEmpty ||
        productIds.length != quantities.length) {
      throw Exception('Invalid order items.');
    }

    final result = await _supabase.rpc(
      'create_customer_order',
      params: {
        'p_customer_id': customerId,
        'p_product_ids': productIds,
        'p_quantities': quantities,
      },
    );

    return result.toString();
  }

  // Update order status through the secure database function
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await _supabase.rpc(
      'update_order_status',
      params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
      },
    );
  }
}
