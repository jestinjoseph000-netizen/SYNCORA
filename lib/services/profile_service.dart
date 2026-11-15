
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _bucketName = 'profile-avatars';

  User? get _currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>> getMyProfile() async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('Please sign in to view your profile.');
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return {
      ...profile,
      'email': user.email ?? '',
    };
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
    }).eq('id', user.id);
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    final extension = fileExtension.toLowerCase().replaceAll('.', '');

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('Please select a JPG, PNG or WebP image.');
    }

    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('Avatar image must be smaller than 5 MB.');
    }

    final path = '${user.id}/avatar.$extension';

    await _client.storage.from(_bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    await _client.from('profiles').update({
      'avatar_url': path,
    }).eq('id', user.id);

    return path;
  }

  Future<String?> getAvatarSignedUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    return _client.storage
        .from(_bucketName)
        .createSignedUrl(avatarPath, 3600);
  }

  Future<void> removeAvatar(String? avatarPath) async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    if (avatarPath != null && avatarPath.isNotEmpty) {
      await _client.storage.from(_bucketName).remove([avatarPath]);
    }

    await _client.from('profiles').update({
      'avatar_url': null,
    }).eq('id', user.id);
  }
}
