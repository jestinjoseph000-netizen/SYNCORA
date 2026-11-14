
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createEmployee({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-employee',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      );

      if (response.status != 200) {
        final message = response.data is Map
            ? response.data['error']?.toString()
            : null;

        throw Exception(message ?? 'Unable to create employee.');
      }

      return Map<String, dynamic>.from(response.data);
    } on FunctionException catch (error) {
      final details = error.details;

      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }

      throw Exception(
        error.reasonPhrase ?? 'Employee creation failed.',
      );
    }
  }
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await _supabase.functions.invoke(
        'list-employees',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        final message = response.data is Map
            ? response.data['error']?.toString()
            : null;

        throw Exception(message ?? 'Unable to load employees.');
      }

      final data = Map<String, dynamic>.from(response.data);

      return List<Map<String, dynamic>>.from(
        data['employees'] ?? [],
      );
    } on FunctionException catch (error) {
      final details = error.details;

      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }

      throw Exception(
        error.reasonPhrase ?? 'Unable to load employees.',
      );
    }
  }
}
