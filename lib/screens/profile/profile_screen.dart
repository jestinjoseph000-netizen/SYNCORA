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
  static const Color _surface = Color(0xFF111923);
  static const Color _raised = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _textColor = Color(0xFFF4F7FA);
  static const Color _muted = Color(0xFF91A0AF);

  bool get _hasSavedAvatar {
    final path = _profile?['avatar_url']?.toString();
    return path != null && path.isNotEmpty;
  }

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
    setState(() => _loading = true);

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
        _showMessage(
          'Please select an image smaller than 5 MB.',
          error: true,
        );
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

    if (_selectedImageBytes == null &&
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

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _accent,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final imageBytes = _selectedImageBytes;

    ImageProvider? imageProvider;

    if (imageBytes != null) {
      imageProvider = MemoryImage(imageBytes);
    } else if (_avatarUrl != null) {
      imageProvider = NetworkImage(_avatarUrl!);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: _raised,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: _accent,
                  )
                : null,
          ),
        ),
        Material(
          color: _accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _uploadingImage ? null : _pickAvatar,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.camera_alt_rounded,
                color: _background,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileIdentity() {
    final name = _profile?['full_name']?.toString().trim();
    final email = _profile?['email']?.toString() ?? '';
    final role = _formatRole(_profile?['role']?.toString());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: _accent,
                size: 17,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ACCOUNT IDENTITY',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _accent,
                      size: 6,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          _buildAvatar(),

          const SizedBox(height: 19),

          Text(
            name == null || name.isEmpty ? 'SYNCORA User' : name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _accent.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: _accent,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Text(
                  '$role Account',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Container(
            height: 1,
            color: Colors.white10,
          ),

          const SizedBox(height: 16),

          if (_selectedImageBytes != null) ...[
            const Text(
              'New profile picture selected',
              style: TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _uploadingImage
                        ? null
                        : _removeAvatar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadingImage
                        ? null
                        : _uploadSelectedAvatar,
                    icon: _uploadingImage
                        ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _background,
                            ),
                          )
                        : const Icon(
                            Icons.cloud_upload_outlined,
                            size: 16,
                          ),
                    label: Text(
                      _uploadingImage ? 'Uploading' : 'Upload',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _pickAvatar,
                icon: const Icon(
                  Icons.photo_library_outlined,
                  size: 17,
                ),
                label: const Text('Change Profile Picture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(
                    color: _accent.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_hasSavedAvatar) ...[
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: _uploadingImage ? null : _removeAvatar,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Remove Picture',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: _accent,
        size: 20,
      ),
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: _accent,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.3,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: _textColor,
            fontSize: 13,
          ),
          decoration: _inputDecoration(
            label: 'Enter $label',
            icon: icon,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            height: 37,
            width: 37,
            decoration: BoxDecoration(
              color: _raised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _muted,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.lock_outline_rounded,
            color: Colors.white30,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Personal Information',
            subtitle: 'Update your account details',
            icon: Icons.manage_accounts_outlined,
          ),

          const SizedBox(height: 25),

          _buildTextField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 26),

          Container(
            height: 1,
            color: Colors.white10,
          ),

          const SizedBox(height: 21),

          const Text(
            'ACCOUNT DETAILS',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 13),

          _buildReadOnlyField(
            label: 'Email Address',
            value: _profile?['email']?.toString() ?? '',
            icon: Icons.email_outlined,
          ),

          const SizedBox(height: 12),

          _buildReadOnlyField(
            label: 'Account Role',
            value: _formatRole(
              _profile?['role']?.toString(),
            ),
            icon: Icons.verified_user_outlined,
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _background,
                      ),
                    )
                  : const Icon(
                      Icons.save_rounded,
                      size: 19,
                    ),
              label: Text(
                _saving ? 'Saving Changes...' : 'Save Changes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                disabledBackgroundColor:
                    _accent.withValues(alpha: 0.65),
                disabledForegroundColor: _background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.all_inclusive_rounded,
                color: _accent,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNCORA',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'ACCOUNT CENTRE',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 25),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accent.withValues(alpha: 0.20),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: _accent,
                size: 14,
              ),
              SizedBox(width: 7),
              Text(
                'PERSONAL WORKSPACE',
                style: TextStyle(
                  color: _accent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 13),

        const Text(
          'My Profile',
          style: TextStyle(
            color: _textColor,
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Manage your personal information and account identity.',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(double availableWidth) {
    final isWide = availableWidth >= 850;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 310,
            child: _buildProfileIdentity(),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: _buildPersonalInformation(),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildProfileIdentity(),
        const SizedBox(height: 22),
        _buildPersonalInformation(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Unable to load your profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
              ),
            ),
          ],
        ),
      ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 2.5,
              ),
            )
          : _profile == null
              ? _buildErrorState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 600 ? 16.0 : 28.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 25,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1120,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildPageHeader(),

                                const SizedBox(height: 28),

                                _buildProfileContent(
                                  constraints.maxWidth -
                                      horizontalPadding * 2,
                                ),

                                const SizedBox(height: 25),

                                const Center(
                                  child: Text(
                                    'SYNCORA  •  SMART INVENTORY & ORDER MANAGEMENT',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}