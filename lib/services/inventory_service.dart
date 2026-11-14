
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get products that have reached their low-stock threshold
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final response = await _supabase
        .from('low_stock_products')
        .select()
        .order('stock_quantity', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Add or remove stock through the secure database function
  Future<void> adjustStock({
    required String productId,
    required String movementType,
    required int quantity,
    String? note,
  }) async {
    await _supabase.rpc(
      'adjust_inventory_stock',
      params: {
        'p_product_id': productId,
        'p_movement_type': movementType,
        'p_quantity': quantity,
        'p_note': note,
      },
    );
  }

  // Get inventory movement history
  Future<List<Map<String, dynamic>>> getStockMovements() async {
    final response = await _supabase.rpc(
      'get_stock_movement_report',
    );

    return List<Map<String, dynamic>>.from(response);
  }
}
