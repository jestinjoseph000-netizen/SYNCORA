
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _profile;

  Uint8List? _selectedImageBytes;
  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _textColor = Color(0xFFF4F7FA);
  static const Color _muted = Color(0xFF8995A3);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : _accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getMyProfile();

      final avatarUrl = await _profileService.getAvatarSignedUrl(
        profile['avatar_url'] as String?,
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _nameController.text = profile['full_name'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _avatarUrl = avatarUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load profile: $e', error: true);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Please select an image smaller than 5 MB.',
            error: true);
        return;
      }

      if (!mounted) return;

      setState(() => _selectedImageBytes = bytes);
    } catch (e) {
      _showMessage('Unable to select image: $e', error: true);
    }
  }

  Future<void> _uploadSelectedAvatar() async {
    if (_selectedImageBytes == null) return;

    setState(() => _uploadingImage = true);

    try {
      final fileExtension = _getImageExtension(
        _selectedImageBytes!,
      );

      final contentType = switch (fileExtension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      await _profileService.uploadAvatar(
        bytes: _selectedImageBytes!,
        fileExtension: fileExtension,
        contentType: contentType,
      );

      final profile = await _profileService.getMyProfile();

      final signedUrl = await _profileService.getAvatarSignedUrl(
        profile['avatar_url'] as String?,
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _avatarUrl = signedUrl;
        _selectedImageBytes = null;
        _uploadingImage = false;
      });

      _showMessage('Profile picture updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploadingImage = false);
      _showMessage('Avatar upload failed: $e', error: true);
    }
  }

  String _getImageExtension(Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    return 'jpg';
  }

  Future<void> _removeAvatar() async {
    final currentPath = _profile?['avatar_url'] as String?;

    if ((_selectedImageBytes == null) &&
        (currentPath == null || currentPath.isEmpty)) {
      return;
    }

    try {
      if (_selectedImageBytes != null) {
        setState(() => _selectedImageBytes = null);
        return;
      }

      setState(() => _uploadingImage = true);

      await _profileService.removeAvatar(currentPath);

      if (!mounted) return;

      setState(() {
        _profile?['avatar_url'] = null;
        _avatarUrl = null;
        _selectedImageBytes = null;
        _uploadingImage = false;
      });

      _showMessage('Profile picture removed.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploadingImage = false);
      _showMessage('Unable to remove avatar: $e', error: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _profileService.updateProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      setState(() {
        _profile?['full_name'] = _nameController.text.trim();
        _profile?['phone'] = _phoneController.text.trim();
        _saving = false;
      });

      _showMessage('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage('Unable to update profile: $e', error: true);
    }
  }

  String _formatRole(String? role) {
    if (role == null || role.isEmpty) return 'User';

    return role[0].toUpperCase() + role.substring(1);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textColor),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accent),
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: const Color(0xFF0C1118),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF26313D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF26313D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1118),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF26313D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: _muted,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final imageBytes = _selectedImageBytes;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _accent, width: 2),
          ),
          child: CircleAvatar(
            radius: 58,
            backgroundColor: const Color(0xFF202833),
            backgroundImage: imageBytes != null
                ? MemoryImage(imageBytes)
                : _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null,
            child: imageBytes == null && _avatarUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 55,
                    color: _accent,
                  )
                : null,
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _uploadingImage ? null : _pickAvatar,
            icon: const Icon(
              Icons.camera_alt_rounded,
              color: Color(0xFF080B10),
              size: 19,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _textColor,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Unable to load your profile.',
                        style: TextStyle(color: _textColor),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF26313D),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildAvatar(),
                                  const SizedBox(height: 16),
                                  Text(
                                    _profile?['full_name'] ?? 'SYNCORA User',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _formatRole(_profile?['role']),
                                      style: const TextStyle(
                                        color: _accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_selectedImageBytes != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: _uploadingImage
                                              ? null
                                              : _removeAvatar,
                                          child: const Text(
                                            'Discard',
                                            style: TextStyle(color: _muted),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: _uploadingImage
                                              ? null
                                              : _uploadSelectedAvatar,
                                          icon: _uploadingImage
                                              ? const SizedBox(
                                                  width: 15,
                                                  height: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF080B10),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.upload_rounded,
                                                ),
                                          label: const Text('Upload Picture'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _accent,
                                            foregroundColor:
                                                const Color(0xFF080B10),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (_avatarUrl != null)
                                    TextButton.icon(
                                      onPressed: _uploadingImage
                                          ? null
                                          : _removeAvatar,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      label: const Text(
                                        'Remove Picture',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Personal Information'),
                            _buildTextField(
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildReadOnlyField(
                              label: 'Email Address',
                              value: _profile?['email'] ?? '',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildReadOnlyField(
                              label: 'Account Role',
                              value: _formatRole(_profile?['role']),
                              icon: Icons.verified_user_outlined,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _saveProfile,
                                icon: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF080B10),
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  _saving ? 'Saving...' : 'Save Changes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor:
                                      const Color(0xFF080B10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Your personal profile can only be edited by your own account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
