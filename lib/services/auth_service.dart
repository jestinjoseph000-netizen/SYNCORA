
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
    Stream<AuthState> get currentAuthStateChanges =>
    _supabase.auth.onAuthStateChange;
  final SupabaseClient _supabase = Supabase.instance.client;

  // LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
