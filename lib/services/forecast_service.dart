
import 'package:supabase_flutter/supabase_flutter.dart';

class ForecastService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch product performance for the selected period.
  Future<List<Map<String, dynamic>>> getProductPerformance({
    int days = 30,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_product_performance',
        params: {
          'p_days': days,
        },
      );

      return List<Map<String, dynamic>>.from(
        (response as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    } catch (error) {
      throw Exception(
        'Unable to load product performance: $error',
      );
    }
  }

  /// Return products ranked by units sold.
  Future<List<Map<String, dynamic>>> getBestSellingProducts({
    int days = 30,
  }) async {
    final products = await getProductPerformance(days: days);

    products.sort(
      (a, b) => _toInt(b['units_sold']).compareTo(
        _toInt(a['units_sold']),
      ),
    );

    return products;
  }

  /// Return products with the highest revenue.
  Future<List<Map<String, dynamic>>> getTopRevenueProducts({
    int days = 30,
  }) async {
    final products = await getProductPerformance(days: days);

    products.sort(
      (a, b) => _toDouble(b['revenue']).compareTo(
        _toDouble(a['revenue']),
      ),
    );

    return products;
  }

  /// Return products with a positive or negative sales trend.
  List<Map<String, dynamic>> getTrendingProducts(
    List<Map<String, dynamic>> products, {
    bool increasing = true,
  }) {
    final result = products.where((product) {
      final trend = product['trend_percent'];

      if (trend == null) return false;

      final value = _toDouble(trend);

      return increasing ? value > 0 : value < 0;
    }).toList();

    result.sort((a, b) {
      return _toDouble(b['trend_percent']).compareTo(
        _toDouble(a['trend_percent']),
      );
    });

    return result;
  }

  /// Safely convert database values into integers.
  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  /// Safely convert database values into doubles.
  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }
}
