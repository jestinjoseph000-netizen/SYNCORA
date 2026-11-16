
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get currentAuthStateChanges =>
      _supabase.auth.onAuthStateChange;

  // LOGIN - ADMIN AND STAFF ONLY
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    try {
      final role = await getCurrentUserRole();

      if (role == 'admin' || role == 'staff') {
        return response;
      }

      await signOut();

      if (role == 'customer') {
        throw Exception(
          'Customer accounts cannot log in to SYNCORA.',
        );
      }

      if (role == 'manager') {
        throw Exception(
          'Manager dashboard access has been discontinued. '
          'Please contact your administrator.',
        );
      }

      throw Exception(
        'Your account role could not be verified. '
        'Please contact your administrator.',
      );
    } catch (error) {
      if (_supabase.auth.currentUser != null) {
        await signOut();
      }
      rethrow;
    }
  }

  // CUSTOMER REGISTRATION
  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );
  }

  // LOGOUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // GET LOGGED-IN USER ROLE
  Future<String?> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['role'] as String?;
  }

  // CHECK CURRENT USER
  User? get currentUser => _supabase.auth.currentUser;
}
