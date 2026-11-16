
import 'package:flutter/material.dart';

import '../../widgets/profile_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

import '../products/product_management_screen.dart';
import '../inventory/inventory_management_screen.dart';
import '../orders/order_management_screen.dart';
import '../profile/profile_screen.dart';
import '../analytics/product_forecast_screen.dart';
import '../analytics/smart_reorder_screen.dart';

// ------------------------------------------------------------
// SYNCORA STAFF DASHBOARD
// ------------------------------------------------------------

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();

  late Future<Map<String, dynamic>> _summaryFuture;

  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF111923);
  static const Color raised = Color(0xFF1C2733);
  static const Color emerald = Color(0xFF00D68F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF8A98A8);

  @override
  void initState() {
    super.initState();
    _summaryFuture = _dashboardService.getDashboardSummary();
  }

  Future<void> _refreshDashboard() async {
    final future = _dashboardService.getDashboardSummary();

    setState(() {
      _summaryFuture = future;
    });

    await future;
  }

  Future<void> _logout() async {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: background,
          drawer: compact
              ? Drawer(
                  backgroundColor: surface,
                  child: SafeArea(
                    child: _navigationPanel(),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact) _navigationPanel(),

              Expanded(
                child: Column(
                  children: [
                    _topBar(compact),

                    Expanded(
                      child: RefreshIndicator(
                        color: emerald,
                        backgroundColor: raised,
                        onRefresh: _refreshDashboard,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 600 ? 16 : 28,
                          ),
                          child: _dashboardContent(
                            constraints.maxWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // NAVIGATION PANEL
  // ------------------------------------------------------------

  Widget _navigationPanel() {
    return Container(
      width: 238,
      color: const Color(0xFF0C121A),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: emerald,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.all_inclusive_rounded,
                    color: background,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 11),
                const Text(
                  'SYNCORA',
                  style: TextStyle(
                    color: white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 42),

            _navLabel('WORKSPACE'),
            const SizedBox(height: 12),

            _navItem(
              Icons.dashboard_rounded,
              'Overview',
              selected: true,
            ),

            _navItem(
              Icons.inventory_2_outlined,
              'Products',
              onTap: () => _openPage(
                const ProductManagementScreen(),
              ),
            ),

            _navItem(
              Icons.swap_vert_circle_outlined,
              'Inventory',
              onTap: () => _openPage(
                const InventoryManagementScreen(),
              ),
            ),

            _navItem(
              Icons.shopping_bag_outlined,
              'Orders',
              onTap: () => _openPage(
                const OrderManagementScreen(),
              ),
            ),

            const SizedBox(height: 28),

            _navLabel('INTELLIGENCE'),
            const SizedBox(height: 12),

            _navItem(
              Icons.insights_rounded,
              'Product Forecast',
              onTap: () => _openPage(
                const ProductForecastScreen(),
              ),
            ),

            _navItem(
              Icons.auto_awesome_outlined,
              'Smart Reorder',
              onTap: () => _openPage(
                const SmartReorderScreen(),
              ),
            ),

            const SizedBox(height: 24),

            const Divider(color: Color(0xFF273340)),

            _navItem(
              Icons.account_circle_outlined,
              'My Profile',
              onTap: () => _openPage(
                const ProfileScreen(),
              ),
            ),

            _navItem(
              Icons.logout_rounded,
              'Sign Out',
              onTap: _logout,
            ),

            const SizedBox(height: 12),

            const Text(
              'SYNCORA  •  OPERATIONS',
              style: TextStyle(
                color: white,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? emerald.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: selected
                  ? Border.all(
                      color: emerald.withValues(alpha: 0.25),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? emerald : white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _topBar(bool compact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;

        return Container(
          height: 76,
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 8 : 22,
          ),
          decoration: const BoxDecoration(
            color: background,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF202B36),
              ),
            ),
          ),
          child: Row(
            children: [
              if (compact)
                Builder(
                  builder: (context) => IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: white,
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations Centre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: white,
                        fontSize: narrow ? 13 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'SYNCORA / STAFF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: narrow ? 8 : 9,
                        letterSpacing: narrow ? 0.7 : 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 7 : 13,
                  vertical: narrow ? 8 : 9,
                ),
                decoration: BoxDecoration(
                  color: emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: emerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      color: emerald,
                      size: 8,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'SYSTEM ONLINE',
                      style: TextStyle(
                        color: white,
                        fontSize: narrow ? 8 : 10,
                        letterSpacing: narrow ? 0.2 : 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              ProfileAvatar(
                radius: narrow ? 19 : 27,
                onTap: () => _openPage(
                  const ProfileScreen(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DASHBOARD CONTENT
  // ------------------------------------------------------------

  Widget _dashboardContent(double screenWidth) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 500,
            child: Center(
              child: CircularProgressIndicator(
                color: emerald,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorPanel(
            'Dashboard data could not be loaded.',
            snapshot.error.toString(),
          );
        }

        final data = snapshot.data ?? {};

        final totalProducts =
            int.tryParse(data['total_products'].toString()) ?? 0;

        final totalOrders =
            int.tryParse(data['total_orders'].toString()) ?? 0;

        final lowStock =
            int.tryParse(data['low_stock_products'].toString()) ?? 0;

        final outOfStock =
            int.tryParse(data['out_of_stock_products'].toString()) ?? 0;

        final totalSales = data['total_sales'] ?? 0;

        final healthyProducts =
            (totalProducts - lowStock - outOfStock)
                .clamp(0, totalProducts);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeading(screenWidth),

            const SizedBox(height: 27),

            _metricGrid(
              screenWidth,
              totalProducts,
              totalOrders,
              totalSales,
              lowStock,
            ),

            const SizedBox(height: 28),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return Column(
                    children: [
                      _inventorySnapshot(
                        totalProducts,
                        healthyProducts,
                        lowStock,
                        outOfStock,
                      ),
                      const SizedBox(height: 18),
                      _operationsPanel(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _inventorySnapshot(
                        totalProducts,
                        healthyProducts,
                        lowStock,
                        outOfStock,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 7,
                      child: _operationsPanel(),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            _quickAccessPanel(),

            const SizedBox(height: 35),

            const Center(
              child: Text(
                'SYNCORA  •  INVENTORY INTELLIGENCE SYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pageHeading(double width) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your operations, in control.',
                style: TextStyle(
                  color: white,
                  fontSize: width < 600 ? 22 : 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage daily inventory and order operations.',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.all_inclusive_rounded,
          color: emerald,
          size: 27,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // KEY METRICS
  // ------------------------------------------------------------

  Widget _metricGrid(
    double width,
    int products,
    int orders,
    dynamic sales,
    int lowStock,
  ) {
    final columns = width >= 1000 ? 4 : 2;

    final metrics = [
      _MetricData(
        label: 'TOTAL PRODUCTS',
        value: products.toString(),
        icon: Icons.inventory_2_outlined,
        detail: 'Registered in catalogue',
      ),
      _MetricData(
        label: 'TOTAL ORDERS',
        value: orders.toString(),
        icon: Icons.shopping_bag_outlined,
        detail: 'Orders recorded',
      ),
      _MetricData(
        label: 'TOTAL SALES',
        value: _money(sales),
        icon: Icons.account_balance_wallet_outlined,
        detail: 'Recorded order sales',
      ),
      _MetricData(
        label: 'LOW STOCK',
        value: lowStock.toString(),
        icon: Icons.warning_amber_rounded,
        detail: 'Products at or below threshold',
        warning: lowStock > 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        mainAxisExtent: 132,
      ),
      itemBuilder: (context, index) {
        return _metricCard(metrics[index]);
      },
    );
  }

  Widget _metricCard(_MetricData metric) {
    final accent = metric.warning
        ? const Color(0xFFFFB547)
        : emerald;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: accent, size: 19),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const Spacer(),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: const TextStyle(
                color: white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INVENTORY SNAPSHOT
  // ------------------------------------------------------------

  Widget _inventorySnapshot(
    int total,
    int healthy,
    int lowStock,
    int outOfStock,
  ) {
    final healthyRatio = total == 0
        ? 0.0
        : (healthy / total).clamp(0.0, 1.0);

    final lowRatio = total == 0
        ? 0.0
        : (lowStock / total).clamp(0.0, 1.0);

    final outRatio = total == 0
        ? 0.0
        : (outOfStock / total).clamp(0.0, 1.0);

    return _panel(
      title: 'Inventory Snapshot',
      subtitle: 'Current product stock health',
      trailing: const _LiveIndicator(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 9,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),

                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: healthyRatio,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    color: emerald,
                  ),
                ),

                SizedBox(
                  width: 136,
                  height: 136,
                  child: CircularProgressIndicator(
                    value: lowRatio,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    color: const Color(0xFFFFB547),
                  ),
                ),

                SizedBox(
                  width: 102,
                  height: 102,
                  child: CircularProgressIndicator(
                    value: outRatio,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    color: const Color(0xFFFF4D5E),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'HEALTHY',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(healthyRatio * 100).round()}%',
                      style: const TextStyle(
                        color: white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'PRODUCTS',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 8,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _snapshotRow('Healthy stock', healthy, emerald),
          const SizedBox(height: 13),

          _snapshotRow(
            'Low stock',
            lowStock,
            const Color(0xFFFFB547),
          ),
          const SizedBox(height: 13),

          _snapshotRow(
            'Out of stock',
            outOfStock,
            const Color(0xFFFF4D5E),
          ),
          const SizedBox(height: 13),

          _snapshotRow('Total products', total, white),

          const SizedBox(height: 17),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: raised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Monitor product availability and identify stock risks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: white,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            color: white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // OPERATIONS PANEL
  // ------------------------------------------------------------

  Widget _operationsPanel() {
    return _panel(
      title: 'Daily Operations',
      subtitle: 'Your available operational tools',
      child: Column(
        children: [
          _operationButton(
            Icons.inventory_2_outlined,
            'Product Catalogue',
            'View and search available products',
            () => _openPage(
              const ProductManagementScreen(),
            ),
          ),

          const SizedBox(height: 10),

          _operationButton(
            Icons.swap_vert_circle_outlined,
            'Inventory Management',
            'View stock levels and movements',
            () => _openPage(
              const InventoryManagementScreen(),
            ),
          ),

          const SizedBox(height: 10),

          _operationButton(
            Icons.shopping_bag_outlined,
            'Order Management',
            'View and process customer orders',
            () => _openPage(
              const OrderManagementScreen(),
            ),
          ),

          const SizedBox(height: 10),

          _operationButton(
            Icons.insights_rounded,
            'Product Performance',
            'Analyse sales trends and product demand',
            () => _openPage(
              const ProductForecastScreen(),
            ),
          ),

          const SizedBox(height: 10),

          _operationButton(
            Icons.auto_awesome_outlined,
            'Smart Reorder Assistant',
            'Review stock risks and reorder recommendations',
            () => _openPage(
              const SmartReorderScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationButton(
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Material(
      color: raised,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: emerald.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: emerald,
                  size: 19,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_rounded,
                color: emerald,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACCESS
  // ------------------------------------------------------------

  Widget _quickAccessPanel() {
    return _panel(
      title: 'Quick Access',
      subtitle: 'Navigate directly to your daily tools',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 420 ? 2 : 3;

          final items = [
            _QuickAccessData(
              'Products',
              Icons.inventory_2_outlined,
              () => _openPage(const ProductManagementScreen()),
            ),
            _QuickAccessData(
              'Inventory',
              Icons.warehouse_outlined,
              () => _openPage(const InventoryManagementScreen()),
            ),
            _QuickAccessData(
              'Orders',
              Icons.receipt_long_outlined,
              () => _openPage(const OrderManagementScreen()),
            ),
            _QuickAccessData(
              'Forecast',
              Icons.insights_rounded,
              () => _openPage(const ProductForecastScreen()),
            ),
            _QuickAccessData(
              'Smart Reorder',
              Icons.auto_awesome_outlined,
              () => _openPage(const SmartReorderScreen()),
            ),
            _QuickAccessData(
              'My Profile',
              Icons.account_circle_outlined,
              () => _openPage(const ProfileScreen()),
            ),
          ];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return Material(
                color: raised,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: emerald,
                          size: 21,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // REUSABLE PANELS AND STATES
  // ------------------------------------------------------------

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),

          const SizedBox(height: 22),

          child,
        ],
      ),
    );
  }

  Widget _errorPanel(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFF7777).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF7777),
            size: 32,
          ),
          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: emerald,
              foregroundColor: background,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// REUSABLE DATA CLASSES
// ------------------------------------------------------------

class _MetricData {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final bool warning;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.detail,
    this.warning = false,
  });
}

class _QuickAccessData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccessData(
    this.title,
    this.icon,
    this.onTap,
  );
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF00D68F),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'LIVE DATA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
