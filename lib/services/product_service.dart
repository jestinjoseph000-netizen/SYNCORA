
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch products and their categories.
  Future<List<Map<String, dynamic>>> getProducts({
    String searchQuery = '',
  }) async {
    var query = _client
        .from('products')
        .select('*, categories(name)');

    if (searchQuery.trim().isNotEmpty) {
      final search = searchQuery.trim().replaceAll(',', '');
      query = query.or(
        'name.ilike.%$search%,sku.ilike.%$search%',
      );
    }

    final response = await query.order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch product categories.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  // Add a new product.
  Future<void> addProduct({
    required String name,
    required String sku,
    required String description,
    required double unitPrice,
    required int stockQuantity,
    required int lowStockThreshold,
    String? categoryId,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'sku': sku,
      'description': description,
      'unit_price': unitPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'category_id': categoryId,
    });
  }

  // Update product details.
  Future<void> updateProduct({
    required String id,
    required String name,
    required String sku,
    required String description,
    required double unitPrice,
    required int lowStockThreshold,
    String? categoryId,
  }) async {
    await _client.from('products').update({
      'name': name,
      'sku': sku,
      'description': description,
      'unit_price': unitPrice,
      'low_stock_threshold': lowStockThreshold,
      'category_id': categoryId,
    }).eq('id', id);
  }

  // Delete a product.
  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .delete()
        .eq('id', id);
  }
}
