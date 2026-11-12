
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _backgroundController;

  bool isLogin = true;
  bool obscurePassword = true;
  bool isLoading = false;

  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF111821);
  static const Color accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
Future<void> handleAuth() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    if (isLogin) {
      // ADMIN / CUSTOMER / STAFF / MANAGER LOGIN
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Close the authentication screen.
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);

    } else {
      // CUSTOMER REGISTRATION
      final response = await _authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        // Email confirmation is required.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Please confirm your email before signing in.',
            ),
            backgroundColor: Color(0xFF137B58),
          ),
        );

        setState(() {
          isLogin = true;
          isLoading = false;
        });

        return;
      }

      // Registration created an active session.
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }
  } on Exception catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.redAccent,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool password = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: TextFormField(
        controller: controller,
        obscureText: password && obscurePassword,
        keyboardType: keyboard,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        cursorColor: accent,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }

          if (label == 'Email' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                  .hasMatch(value.trim())) {
            return 'Enter a valid email address';
          }

          if (label == 'Password' && value.length < 6) {
            return 'Password must contain at least 6 characters';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: accent.withValues(alpha: 0.85),
            size: 20,
          ),
          suffixIcon: password
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white54,
                    size: 19,
                  ),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF0B1119),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 19,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: accent,
              width: 1.3,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.redAccent,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LoginBackgroundPainter(
                    _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 35,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 460,
                        ),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ),

                _buildBottomText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TOP NAVIGATION

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 18,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.all_inclusive,
            color: accent,
            size: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'SYNCORA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 17,
              color: accent,
            ),
            label: const Text(
              'Back to Home',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // LOGIN CARD

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 45,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.all_inclusive,
                  color: accent,
                  size: 36,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              isLogin ? 'Welcome Back' : 'Create Your Account',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isLogin
                  ? 'Sign in to continue to your SYNCORA workspace.'
                  : 'Register to start managing your orders.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 35),

            if (!isLogin)
              buildInput(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
              ),

            buildInput(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
            ),

            if (!isLogin)
              buildInput(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone,
              ),

            buildInput(
              label: 'Password',
              controller: _passwordController,
              icon: Icons.lock_outline,
              password: true,
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor:
                      accent.withValues(alpha: 0.5),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    isLogin
                        ? "Don't have an account? "
                        : 'Already have an account? ',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                            _formKey.currentState?.reset();
                          },
                    child: Text(
                      isLogin ? 'Register' : 'Sign In',
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FOOTER

  Widget _buildBottomText() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        '© 2026 SYNCORA. All rights reserved.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white30,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ANIMATED BACKGROUND

class _LoginBackgroundPainter extends CustomPainter {
  final double animationValue;

  _LoginBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final time = animationValue * math.pi * 2;

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        65,
      );

    final firstCenter = Offset(
      size.width * (0.2 + 0.08 * math.sin(time)),
      size.height * 0.25,
    );

    glowPaint.color = const Color(0xFF00D68F)
        .withValues(alpha: 0.10);

    canvas.drawCircle(
      firstCenter,
      size.width * 0.22,
      glowPaint,
    );

    final secondCenter = Offset(
      size.width * (0.8 + 0.06 * math.cos(time)),
      size.height * 0.75,
    );

    glowPaint.color = const Color(0xFF008F75)
        .withValues(alpha: 0.09);

    canvas.drawCircle(
      secondCenter,
      size.width * 0.18,
      glowPaint,
    );

    final particlePaint = Paint()
      ..color = const Color(0xFF00D68F)
          .withValues(alpha: 0.22);

    for (int i = 0; i < 35; i++) {
      final x = (i * 97.0) % size.width;
      final y = (i * 61.0 +
              animationValue * size.height * 0.35) %
          size.height;

      canvas.drawCircle(
        Offset(x, y),
        1.2,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _LoginBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.animationValue != animationValue;
  }
}
