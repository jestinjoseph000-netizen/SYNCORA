
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  // Dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _client.rpc('get_dashboard_summary');

    if (response == null) {
      throw Exception('Dashboard summary returned no data.');
    }

    return Map<String, dynamic>.from(response as Map);
  }

  // Latest five orders
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final response = await _client.rpc('get_recent_orders');

    if (response == null) return [];

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Daily sales for the last seven days
  Future<List<Map<String, dynamic>>> getDailySales() async {
    final response = await _client.rpc('get_daily_sales');

    if (response == null) return [];

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Recent inventory movements
  Future<List<Map<String, dynamic>>> getStockMovements() async {
    final response = await _client.rpc('get_stock_movement_report');

    if (response == null) return [];

    return List<Map<String, dynamic>>.from(response as List);
  }
}
