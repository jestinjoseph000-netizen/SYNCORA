
import 'package:supabase_flutter/supabase_flutter.dart';

class ReorderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getReorderSuggestions({
    int days = 30,
    int coverDays = 14,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_smart_reorder_suggestions',
        params: {
          'p_days': days,
          'p_cover_days': coverDays,
        },
      );

      return List<Map<String, dynamic>>.from(
        (response as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    } catch (error) {
      throw Exception('Unable to load reorder suggestions: $error');
    }
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int getTotalSuggestedUnits(
    List<Map<String, dynamic>> suggestions,
  ) {
    return suggestions.fold<int>(
      0,
      (total, item) =>
          total + toInt(item['suggested_reorder_quantity']),
    );
  }

  int getOutOfStockCount(
    List<Map<String, dynamic>> suggestions,
  ) {
    return suggestions.where(
      (item) => toInt(item['stock_quantity']) == 0,
    ).length;
  }
}
