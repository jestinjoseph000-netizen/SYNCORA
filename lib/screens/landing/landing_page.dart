
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _backgroundController;

  static const Color backgroundColor = Color(0xFF080B10);
  static const Color accentColor = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  math.sin(_backgroundController.value * math.pi * 2) * 0.5,
                  -0.5,
                ),
                radius: 1.4,
                colors: const [
                  Color(0xFF102C29),
                  backgroundColor,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildNavigation(),
                _buildHero(),
                _buildFeatures(),
                _buildAbout(),
                _buildCallToAction(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NAVIGATION

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 22,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.all_inclusive,
            color: accentColor,
            size: 32,
          ),
          const SizedBox(width: 10),
          const Text(
            'SYNCORA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 650) ...[
            _navText('Home'),
            _navText('Features'),
            _navText('About Us'),
            const SizedBox(width: 20),
          ],
          ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 15,
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _navText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  // HERO SECTION

  Widget _buildHero() {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: AnimatedHeroBackground(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 90,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMARTER INVENTORY.\nBETTER BUSINESS.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Manage products, track stock, handle orders, '
                    'and understand your business with one connected system.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _openLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 18,
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: content),
                    const SizedBox(width: 40),
                    const Expanded(
                      flex: 2,
                      child: _DashboardPreview(),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 45),
                  const _DashboardPreview(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // FEATURES SECTION

  Widget _buildFeatures() {
    final features = [
      (
        Icons.dashboard_outlined,
        'Smart Dashboard',
        'Monitor your business activities from one place.'
      ),
      (
        Icons.inventory_2_outlined,
        'Product Management',
        'Organize products, categories and pricing.'
      ),
      (
        Icons.swap_vert,
        'Stock Management',
        'Track stock movements and low-stock alerts.'
      ),
      (
        Icons.shopping_cart_outlined,
        'Order Management',
        'Create orders and automatically update inventory.'
      ),
      (
        Icons.people_outline,
        'Customer Management',
        'Maintain customer information and order history.'
      ),
      (
        Icons.analytics_outlined,
        'Reports & Analytics',
        'Understand sales and inventory performance.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 35,
        vertical: 75,
      ),
      child: Column(
        children: [
          const Text(
            'POWERFUL FEATURES',
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Everything Your Business Needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 45),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 850
                  ? 3
                  : constraints.maxWidth > 550
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: 190,
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];

                  return _FeatureCard(
                    icon: feature.$1,
                    title: feature.$2,
                    description: feature.$3,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ABOUT SECTION

  Widget _buildAbout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 75,
      ),
      color: const Color(0xFF0D141C),
      child: Column(
        children: [
          const Text(
            'ABOUT SYNCORA',
            style: TextStyle(
              color: accentColor,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connecting Every Part of Your Business',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 750,
            child: Text(
              'SYNCORA is designed to simplify inventory and order '
              'management through a connected digital platform. '
              'Our goal is to help businesses organize their operations, '
              'make informed decisions and manage everyday activities '
              'more efficiently.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CALL TO ACTION

  Widget _buildCallToAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 80,
      ),
      child: Column(
        children: [
          const Text(
            'READY TO GET STARTED?',
            style: TextStyle(
              color: accentColor,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Take Control of Your Inventory',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 17,
              ),
            ),
            child: const Text('Sign In Now'),
          ),
        ],
      ),
    );
  }

  // FOOTER

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: const Color(0xFF05080C),
      child: const Column(
        children: [
          Text(
            'SYNCORA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Smart Inventory & Order Management System',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          SizedBox(height: 15),
          Text(
            '© 2026 SYNCORA. All rights reserved.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// DASHBOARD PREVIEW

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF111821).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D68F).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D68F).withValues(alpha: 0.08),
            blurRadius: 35,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUSINESS OVERVIEW',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
          const _PreviewCard(
            title: 'Total Products',
            value: '1,240',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 15),
          const _PreviewCard(
            title: 'Total Orders',
            value: '356',
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 15),
          const _PreviewCard(
            title: 'Revenue',
            value: '₹82.5K',
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _PreviewCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D68F), size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// FEATURE CARD

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF00D68F),
            size: 32,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ANIMATED HERO BACKGROUND

class AnimatedHeroBackground extends StatefulWidget {
  const AnimatedHeroBackground({super.key});

  @override
  State<AnimatedHeroBackground> createState() =>
      _AnimatedHeroBackgroundState();
}

class _AnimatedHeroBackgroundState
    extends State<AnimatedHeroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: HeroBackgroundPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

// ANIMATION PAINTER

class HeroBackgroundPainter extends CustomPainter {
  final double animationValue;

  HeroBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    final time = animationValue * math.pi * 2;

    // Moving green light effects

    final firstCenter = Offset(
      size.width * (0.75 + 0.08 * math.sin(time)),
      size.height * 0.25,
    );

    paint.color = const Color(0xFF00D68F).withValues(alpha: 0.12);

    canvas.drawCircle(
      firstCenter,
      size.width * 0.18,
      paint,
    );

    final secondCenter = Offset(
      size.width * (0.25 + 0.06 * math.cos(time)),
      size.height * 0.75,
    );

    paint.color = const Color(0xFF008F75).withValues(alpha: 0.10);

    canvas.drawCircle(
      secondCenter,
      size.width * 0.15,
      paint,
    );

    // Floating particles

    final particlePaint = Paint()
      ..color = const Color(0xFF00D68F).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 83.0) % size.width;

      final y = (i * 47.0 +
              animationValue * size.height * 0.5) %
          size.height;

      final radius = 1.0 + (i % 3) * 0.6;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        particlePaint,
      );
    }

    // Connecting lines

    final linePaint = Paint()
      ..color = const Color(0xFF00D68F).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 8);

      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + 50 * math.sin(time + i),
          size.height,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeroBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
