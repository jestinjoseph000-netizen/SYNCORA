import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.radius = 21, this.onTap});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final ProfileService _profileService = ProfileService();

  String? _avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final profile = await _profileService.getMyProfile();

      final url = await _profileService.getAvatarSignedUrl(
        profile['avatar_url'] as String?,
      );

      if (!mounted) return;

      setState(() {
        _avatarUrl = url;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151B23),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00D68F), width: 1.5),
          ),
          child: ClipOval(
            child: SizedBox(
              width: widget.radius * 2,
              height: widget.radius * 2,
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00D68F),
                        ),
                      ),
                    )
                  : _avatarUrl != null
                  ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return const ColoredBox(
                          color: Color(0xFF202833),
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00D68F),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFF202833),
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF00D68F),
                          ),
                        );
                      },
                    )
                  : const ColoredBox(
                      color: Color(0xFF202833),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF00D68F),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
