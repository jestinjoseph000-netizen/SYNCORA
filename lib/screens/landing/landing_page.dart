import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  static const Color backgroundColor = Color(0xFF080B10);
  static const Color accentColor = Color(0xFF00D68F);
  static const Color secondaryColor = Color(0xFF91A0AF);

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final targetContext = key.currentContext;

    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1100) return 65;
    if (width >= 650) return 40;
    return 22;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [Color(0xFF102C29), backgroundColor],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavigation(width),
                    _buildHero(width),
                    _buildFeatures(width),
                    _buildHowItWorks(width),
                    _buildAbout(width),
                    _buildCallToAction(width),
                    _buildFooter(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // NAVIGATION

  Widget _buildNavigation(double width) {
    final isMobile = width < 650;
    final horizontalPadding = _horizontalPadding(width);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
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
              if (!isMobile) ...[
                _navText('Home', _homeKey),
                _navText('Features', _featuresKey),
                _navText('About Us', _aboutKey),
                const SizedBox(width: 18),
              ],
              ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 18 : 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _mobileNavText('Home', _homeKey),
                _mobileNavText('Features', _featuresKey),
                _mobileNavText('About Us', _aboutKey),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _navText(String text, GlobalKey key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: InkWell(
        onTap: () => _scrollTo(key),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _mobileNavText(String text, GlobalKey key) {
    return Expanded(
      child: InkWell(
        onTap: () => _scrollTo(key),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // HERO SECTION

  Widget _buildHero(double width) {
    final isWide = width >= 850;
    final horizontalPadding = _horizontalPadding(width);
    final titleSize = width < 400
        ? 34.0
        : width < 650
        ? 39.0
        : 48.0;

    return SizedBox(
      key: _homeKey,
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: SizedBox.expand())),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: width < 650 ? 55 : 95,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1350),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: accentColor,
                              size: 15,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SMART BUSINESS MANAGEMENT',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'SMARTER INVENTORY.\n'),
                            TextSpan(
                              text: 'BETTER BUSINESS.',
                              style: TextStyle(color: accentColor),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Take control of your business operations with SYNCORA. '
                        'Manage products, monitor stock levels, process customer '
                        'orders and explore useful business insights — all from '
                        'one connected platform.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openLogin,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Get Started'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 17,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _scrollTo(_featuresKey),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 17,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Explore Features'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          _HeroPoint(text: 'Inventory Tracking'),
                          _HeroPoint(text: 'Order Management'),
                          _HeroPoint(text: 'Business Insights'),
                        ],
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 3, child: content),
                        const SizedBox(width: 55),
                        const Expanded(flex: 2, child: _DashboardPreview()),
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
          ),
        ],
      ),
    );
  }

  // FEATURES SECTION

  Widget _buildFeatures(double width) {
    final features = [
      (
        Icons.dashboard_outlined,
        'Smart Dashboard',
        'Get a clear overview of your business with key figures, recent orders, '
            'inventory activity and important updates in one place.',
      ),
      (
        Icons.inventory_2_outlined,
        'Product Management',
        'Add, update, search and organize products. Keep product details, '
            'categories, pricing and stock information easy to manage.',
      ),
      (
        Icons.swap_vert_rounded,
        'Stock Management',
        'Record stock movements, monitor available quantities and identify '
            'products that need attention with low-stock alerts.',
      ),
      (
        Icons.shopping_cart_outlined,
        'Order Management',
        'Create and manage customer orders while keeping inventory quantities '
            'updated through the order process.',
      ),
      (
        Icons.people_outline_rounded,
        'Customer Management',
        'Maintain customer records and access useful customer information '
            'to keep your business operations organized.',
      ),
      (
        Icons.analytics_outlined,
        'Reports & Analytics',
        'Review sales and inventory performance through reports and useful '
            'insights that support better business decisions.',
      ),
      (
        Icons.insights_rounded,
        'Product Forecasting',
        'Explore product performance and estimated demand to understand '
            'which items may need more attention.',
      ),
      (
        Icons.auto_awesome_rounded,
        'Smart Reordering',
        'Use stock and demand information to review suggested reorder '
            'quantities and plan inventory replenishment.',
      ),
      (
        Icons.groups_outlined,
        'Employee Management',
        'Organize employee accounts and role-based access to help manage '
            'who can access different areas of the system.',
      ),
    ];

    final horizontalPadding = _horizontalPadding(width);

    return Container(
      key: _featuresKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: width < 650 ? 65 : 90,
      ),
      child: Column(
        children: [
          const _SectionLabel(text: 'POWERFUL FEATURES'),
          const SizedBox(height: 15),
          Text(
            'Everything Your Business Needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: width < 400 ? 25 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: const Text(
              'From everyday inventory tasks to business performance insights, '
              'SYNCORA brings essential management tools together in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 42),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1000
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;

              final cardHeight = columns == 1 ? 205.0 : 220.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  mainAxisExtent: cardHeight,
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

  // HOW IT WORKS SECTION

  Widget _buildHowItWorks(double width) {
    final steps = [
      (
        '01',
        Icons.add_box_outlined,
        'Organize Products',
        'Set up your product catalogue with the details your business needs.',
      ),
      (
        '02',
        Icons.inventory_outlined,
        'Track Inventory',
        'Monitor stock levels and record incoming and outgoing stock.',
      ),
      (
        '03',
        Icons.receipt_long_outlined,
        'Manage Orders',
        'Handle customer orders and keep inventory information updated.',
      ),
      (
        '04',
        Icons.query_stats_rounded,
        'Review Performance',
        'Use reports and forecasts to understand business activity.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(width),
        vertical: width < 650 ? 60 : 80,
      ),
      decoration: const BoxDecoration(color: Color(0xFF0D141C)),
      child: Column(
        children: [
          const _SectionLabel(text: 'A SIMPLE WORKFLOW'),
          const SizedBox(height: 15),
          Text(
            'One Connected Business Process',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: width < 400 ? 24 : 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Bring everyday operations together with a clear and organized workflow.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryColor, fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 850
                  ? 4
                  : constraints.maxWidth > 550
                  ? 2
                  : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 205,
                ),
                itemBuilder: (context, index) {
                  final step = steps[index];

                  return _StepCard(
                    number: step.$1,
                    icon: step.$2,
                    title: step.$3,
                    description: step.$4,
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

  Widget _buildAbout(double width) {
    return Container(
      key: _aboutKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(width),
        vertical: width < 650 ? 65 : 90,
      ),
      child: Column(
        children: [
          const _SectionLabel(text: 'ABOUT SYNCORA'),
          const SizedBox(height: 18),
          Text(
            'Connecting Every Part of Your Business',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: width < 400 ? 24 : 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: const Text(
              'SYNCORA is a Smart Inventory & Order Management System designed '
              'to simplify the way businesses organize their daily operations. '
              'It brings product management, inventory tracking, customer records, '
              'order processing and business reporting into one connected digital '
              'platform.\n\n'
              'By keeping essential business information organized and accessible, '
              'SYNCORA aims to reduce manual effort, improve visibility over stock '
              'and help users make more informed operational decisions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.9,
              ),
            ),
          ),
          const SizedBox(height: 42),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                (
                  Icons.track_changes_rounded,
                  'Our Focus',
                  'Making inventory and order activities easier to organize.',
                ),
                (
                  Icons.hub_outlined,
                  'Our Approach',
                  'Connecting important business operations in one platform.',
                ),
                (
                  Icons.trending_up_rounded,
                  'Our Goal',
                  'Supporting clearer decisions through organized information.',
                ),
              ];

              final columns = constraints.maxWidth > 850 ? 3 : 1;

              if (columns == 1) {
                return Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AboutCard(
                        icon: item.$1,
                        title: item.$2,
                        description: item.$3,
                      ),
                    );
                  }).toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _AboutCard(
                        icon: item.$1,
                        title: item.$2,
                        description: item.$3,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // CALL TO ACTION

  Widget _buildCallToAction(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(width),
        vertical: width < 650 ? 55 : 80,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: width < 500 ? 22 : 35,
          vertical: width < 500 ? 38 : 50,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF102C29), Color(0xFF111923), Color(0xFF14251F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            const _SectionLabel(text: 'READY TO GET STARTED?'),
            const SizedBox(height: 18),
            Text(
              'Take Control of Your Inventory',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: width < 400 ? 24 : 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: const Text(
                'Bring your products, stock, orders and business information '
                'together with SYNCORA. Sign in to access your workspace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openLogin,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Sign In Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FOOTER

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
      color: const Color(0xFF05080C),
      child: const Column(
        children: [
          Icon(Icons.all_inclusive_rounded, color: accentColor, size: 30),
          SizedBox(height: 10),
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
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          SizedBox(height: 18),
          Text(
            'Organize better. Manage smarter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 20),
          Divider(color: Color(0xFF202A34)),
          SizedBox(height: 15),
          Text(
            '© 2026 SYNCORA. All rights reserved.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// SECTION LABEL

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF00D68F),
        fontSize: 12,
        letterSpacing: 2.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// HERO POINT

class _HeroPoint extends StatelessWidget {
  final String text;

  const _HeroPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF00D68F),
          size: 16,
        ),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

// DASHBOARD PREVIEW

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFF00D68F),
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'BUSINESS OVERVIEW',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 22),
          const _PreviewCard(
            title: 'Total Products',
            value: '1,240',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 13),
          const _PreviewCard(
            title: 'Total Orders',
            value: '356',
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 13),
          const _PreviewCard(
            title: 'Revenue',
            value: '₹82.5K',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2632),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF00D68F), size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Your business at a glance',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF00D68F),
                  size: 17,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '* Illustrative dashboard preview',
            style: TextStyle(color: Colors.white38, fontSize: 10),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00D68F).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00D68F), size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: const Color(0xFF00D68F).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00D68F), size: 25),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white60,
                height: 1.55,
                fontSize: 12,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// HOW IT WORKS CARD

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D68F), size: 25),
              const Spacer(),
              Text(
                number,
                style: TextStyle(
                  color: const Color(0xFF00D68F).withValues(alpha: 0.65),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ABOUT CARD

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D68F), size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.6,
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
  State<AnimatedHeroBackground> createState() => _AnimatedHeroBackgroundState();
}

class _AnimatedHeroBackgroundState extends State<AnimatedHeroBackground>
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
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    final time = animationValue * math.pi * 2;

    final firstCenter = Offset(
      size.width * (0.75 + 0.08 * math.sin(time)),
      size.height * 0.25,
    );

    paint.color = const Color(0xFF00D68F).withValues(alpha: 0.12);

    canvas.drawCircle(firstCenter, size.width * 0.18, paint);

    final secondCenter = Offset(
      size.width * (0.25 + 0.06 * math.cos(time)),
      size.height * 0.75,
    );

    paint.color = const Color(0xFF008F75).withValues(alpha: 0.10);

    canvas.drawCircle(secondCenter, size.width * 0.15, paint);

    final particlePaint = Paint()
      ..color = const Color(0xFF00D68F).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 83.0) % size.width;

      final y = (i * 47.0 + animationValue * size.height * 0.5) % size.height;

      final radius = 1.0 + (i % 3) * 0.6;

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00D68F).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 8);

      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 50 * math.sin(time + i), size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeroBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
