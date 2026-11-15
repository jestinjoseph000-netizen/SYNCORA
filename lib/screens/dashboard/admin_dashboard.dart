import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../../widgets/profile_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

import 'package:flutter/gestures.dart';

import '../products/product_management_screen.dart';
import '../inventory/inventory_management_screen.dart';
import '../customers/customer_management_screen.dart';
import '../orders/order_management_screen.dart';
import '../employees/employee_management_screen.dart';
import '../profile/profile_screen.dart';
import '../analytics/product_forecast_screen.dart';
import '../analytics/smart_reorder_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/daily_sales_chart.dart';

// ------------------------------------------------------------
// SYNCORA ADMIN DASHBOARD
// ------------------------------------------------------------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();
  final ScrollController _flowScrollController = ScrollController();

  late Future<Map<String, dynamic>> _summaryFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  late Future<List<Map<String, dynamic>>> _movementsFuture;
  RealtimeChannel? _dashboardChannel;

  int _salesRefreshToken = 0;
  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF111923);
  static const Color raised = Color(0xFF1C2733);
  static const Color emerald = Color(0xFF00D68F);
  static const Color white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    _loadDashboard();
    _subscribeToDashboardChanges();
  }

  void _loadDashboard() {
    _summaryFuture = _dashboardService.getDashboardSummary();
    _ordersFuture = _dashboardService.getRecentOrders();
    _movementsFuture = _dashboardService.getStockMovements();
  }

  void _subscribeToDashboardChanges() {
    _dashboardChannel = Supabase.instance.client
        .channel('syncora-admin-dashboard')
        // Listen for order creation and status changes.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (!mounted) return;

            setState(() {
              _summaryFuture = _dashboardService.getDashboardSummary();
              _ordersFuture = _dashboardService.getRecentOrders();
              _salesRefreshToken++;
            });
          },
        )
        // Listen for inventory movement changes.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_movements',
          callback: (payload) {
            if (!mounted) return;

            setState(() {
              _movementsFuture = _dashboardService.getStockMovements();
            });
          },
        )
        .subscribe();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _loadDashboard();
      _salesRefreshToken++;
    });

    await Future.wait([_summaryFuture, _ordersFuture, _movementsFuture]);
  }

  @override
  void dispose() {
    _flowScrollController.dispose();
    if (_dashboardChannel != null) {
      Supabase.instance.client.removeChannel(_dashboardChannel!);
    }

    super.dispose();
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _shortDate(dynamic value) {
    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Date unavailable';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
                  child: SafeArea(child: _navigationPanel()),
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
                          child: _dashboardContent(constraints.maxWidth),
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

            _navItem(Icons.dashboard_rounded, 'Overview', selected: true),
            _navItem(
              Icons.inventory_2_outlined,
              'Products',
              onTap: () => _openPage(const ProductManagementScreen()),
            ),
            _navItem(
              Icons.swap_vert_circle_outlined,
              'Inventory',
              onTap: () => _openPage(const InventoryManagementScreen()),
            ),
            _navItem(
              Icons.shopping_bag_outlined,
              'Orders',
              onTap: () => _openPage(const OrderManagementScreen()),
            ),
            _navItem(
              Icons.people_outline_rounded,
              'Customers',
              onTap: () => _openPage(const CustomerManagementScreen()),
            ),

            const SizedBox(height: 28),

            _navLabel('INTELLIGENCE'),

            const SizedBox(height: 12),

            _navItem(
              Icons.groups_outlined,
              'Employees',
              onTap: () => _openPage(const EmployeeManagementScreen()),
            ),
            _navItem(
              Icons.insights_rounded,
              'Product Forecast',
              onTap: () => _openPage(const ProductForecastScreen()),
            ),
            _navItem(
              Icons.auto_awesome_outlined,
              'Smart Reorder',
              onTap: () => _openPage(const SmartReorderScreen()),
            ),

            const SizedBox(height: 24),

            const Divider(color: Color(0xFF273340)),

            _navItem(
              Icons.account_circle_outlined,
              'My Profile',
              onTap: () => _openPage(const ProfileScreen()),
            ),
            _navItem(Icons.logout_rounded, 'Sign Out', onTap: _logout),

            const SizedBox(height: 12),

            const Text(
              'SYNCORA  •  OPERATIONS',
              style: TextStyle(color: white, fontSize: 9, letterSpacing: 1.5),
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
        color: selected ? emerald.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: selected
                  ? Border.all(color: emerald.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: selected ? emerald : white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
          padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 22),
          decoration: const BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: Color(0xFF202B36))),
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
                    icon: const Icon(Icons.menu_rounded, color: white),
                  ),
                ),

              Expanded(
                flex: 2,
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
                      'SYNCORA / ADMINISTRATOR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: white,
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
                  border: Border.all(color: emerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: emerald, size: 8),
                    const SizedBox(width: 8),
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

              Padding(
                padding: EdgeInsets.only(left: narrow ? 2 : 8),
                child: ProfileAvatar(
                  radius: narrow ? 19 : 27,
                  onTap: () => _openPage(const ProfileScreen()),
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
            child: Center(child: CircularProgressIndicator(color: emerald)),
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

        final totalOrders = int.tryParse(data['total_orders'].toString()) ?? 0;

        final lowStock =
            int.tryParse(data['low_stock_products'].toString()) ?? 0;

        final outOfStockProducts =
            int.tryParse(data['out_of_stock_products'].toString()) ?? 0;

        final totalSales = data['total_sales'] ?? 0;

        final healthyProducts = (totalProducts - lowStock - outOfStockProducts)
            .clamp(0, totalProducts);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeading(),

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
                      _dynamicFlow(),
                      const SizedBox(height: 18),
                      _systemPulse(
                        totalProducts,
                        healthyProducts,
                        lowStock,
                        outOfStockProducts,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _dynamicFlow()),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _systemPulse(
                        totalProducts,
                        healthyProducts,
                        lowStock,
                        outOfStockProducts,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return Column(
                    children: [
                      _fastOps(),
                      const SizedBox(height: 18),
                      _liveStream(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _fastOps()),
                    const SizedBox(width: 18),
                    Expanded(flex: 7, child: _liveStream()),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            _salesSection(),

            const SizedBox(height: 35),

            const Center(
              child: Text(
                'SYNCORA  •  INVENTORY INTELLIGENCE SYSTEM',
                style: TextStyle(color: white, fontSize: 9, letterSpacing: 1.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pageHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Command your inventory.',
                style: TextStyle(
                  color: white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your business operations, connected in one place.',
                style: TextStyle(color: white, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.all_inclusive_rounded, color: emerald, size: 27),
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
    final columns = width >= 1250
        ? 4
        : width >= 650
        ? 2
        : 1;

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
    final accent = metric.warning ? const Color(0xFFFFB547) : emerald;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
            style: const TextStyle(
              color: white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.detail,
            style: const TextStyle(color: white, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DYNAMIC FLOW - REAL STOCK MOVEMENTS
  // ------------------------------------------------------------

  Widget _dynamicFlow() {
    return _panel(
      title: 'Dynamic Flow',
      subtitle: 'Inventory movement timeline',
      trailing: const _LiveIndicator(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _movementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingContent();
          }

          if (snapshot.hasError) {
            return _inlineError(snapshot.error.toString());
          }

          final movements = List<Map<String, dynamic>>.from(
            snapshot.data ?? [],
          );

          movements.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');

            final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');

            return (dateA ?? DateTime(2000)).compareTo(dateB ?? DateTime(2000));
          });

          if (movements.isEmpty) {
            return _emptyContent(
              Icons.timeline_rounded,
              'No inventory activity yet',
              'Stock movements will appear here when recorded.',
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_flowScrollController.hasClients) return;

            final position = _flowScrollController.position;

            _flowScrollController.jumpTo(position.maxScrollExtent);
          });

          // Latest operations first.
          // With reverse: true, the newest bar appears on the right.
          final maxQuantity = movements.fold<double>(1, (currentMax, item) {
            final quantity = (num.tryParse(item['quantity'].toString()) ?? 0)
                .abs()
                .toDouble();

            return quantity > currentMax ? quantity : currentMax;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _flowLegend(emerald, 'Stock In'),
                  const SizedBox(width: 18),
                  _flowLegend(const Color(0xFFFFB547), 'Stock Out'),
                  const Spacer(),
                  Text(
                    '${movements.length} operations',
                    style: const TextStyle(
                      color: white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 155,
                child: Scrollbar(
                  controller: _flowScrollController,
                  thumbVisibility: true,
                  trackVisibility: false,
                  thickness: 3,
                  radius: const Radius.circular(10),
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _flowScrollController,
                    scrollDirection: Axis.horizontal,
                    reverse: false,
                    physics: const ClampingScrollPhysics(),
                    dragStartBehavior: DragStartBehavior.start,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: movements.map((item) {
                        final type = item['movement_type']
                            .toString()
                            .toUpperCase();

                        final incoming =
                            type == 'STOCK_IN' || type == 'ORDER_RESTOCK';

                        final color = incoming
                            ? emerald
                            : const Color(0xFFFFB547);

                        final quantity =
                            (num.tryParse(item['quantity'].toString()) ?? 0)
                                .abs()
                                .toDouble();

                        final barHeight = (quantity / maxQuantity * 85)
                            .clamp(12.0, 85.0)
                            .toDouble();

                        return SizedBox(
                          width: 64,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${incoming ? '+' : '-'}${quantity.toInt()}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Container(
                                  width: 25,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.85),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _shortDate(item['created_at']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  incoming ? 'IN' : 'OUT',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Divider(color: Color(0xFF34404B), height: 1),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.swipe_rounded, color: Color(0xFF8A98A8), size: 14),
                  SizedBox(width: 7),
                  Text(
                    'Swipe to explore inventory history',
                    style: TextStyle(
                      color: Color(0xFF8A98A8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _flowLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // String _movementName(String type) {
  //   switch (type) {
  //     case 'STOCK_IN':
  //       return 'STOCK RECEIVED';
  //     case 'STOCK_OUT':
  //       return 'STOCK REMOVED';
  //     case 'ORDER_DEDUCTION':
  //       return 'ORDER FULFILMENT';
  //     case 'ORDER_RESTOCK':
  //       return 'ORDER RESTOCK';
  //     default:
  //       return type.replaceAll('_', ' ');
  //   }
  // }

  // ------------------------------------------------------------
  // SYSTEM PULSE - REAL PRODUCT HEALTH COUNTS
  // ------------------------------------------------------------

  Widget _systemPulse(int total, int healthy, int lowStock, int outOfStock) {
    final ratio = total == 0 ? 0.0 : (healthy / total).clamp(0.0, 1.0);

    final lowStockRatio = total == 0 ? 0.0 : (lowStock / total).clamp(0.0, 1.0);

    final outOfStockRatio = total == 0
        ? 0.0
        : (outOfStock / total).clamp(0.0, 1.0);

    return _panel(
      title: 'System Pulse',
      subtitle: 'Current product stock health',
      child: Column(
        children: [
          const SizedBox(height: 10),

          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // OUTER GREEN RING - HEALTHY
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),

                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    color: emerald,
                  ),
                ),

                // MIDDLE AMBER RING - LOW STOCK
                SizedBox(
                  width: 142,
                  height: 142,
                  child: CircularProgressIndicator(
                    value: lowStockRatio,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    color: const Color(0xFFFFB547),
                  ),
                ),

                // INNER RED RING - OUT OF STOCK
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: outOfStockRatio,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    color: const Color(0xFFFF4D5E),
                  ),
                ),

                // CENTRE CONTENT
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'HEALTHY',
                      style: TextStyle(
                        color: white,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: const TextStyle(
                        color: white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'PRODUCTS',
                      style: TextStyle(
                        color: white,
                        fontSize: 8,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          _pulseRow('Healthy stock', healthy, emerald),

          const SizedBox(height: 13),

          _pulseRow('Low stock', lowStock, const Color(0xFFFFB547)),

          const SizedBox(height: 13),

          _pulseRow('Out of stock', outOfStock, const Color(0xFFFF4D5E)),

          const SizedBox(height: 13),

          _pulseRow('Total products', total, white),

          const SizedBox(height: 17),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: raised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Stock health is calculated from the available product and low-stock counts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: white, fontSize: 9, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: white, fontSize: 11),
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
  // FAST OPS
  // ------------------------------------------------------------

  Widget _fastOps() {
    return _panel(
      title: 'Fast Ops',
      subtitle: 'Shortcuts to daily operations',
      child: Column(
        children: [
          _operationButton(
            Icons.add_box_outlined,
            'Manage Products',
            'Catalogue and product records',
            () => _openPage(const ProductManagementScreen()),
          ),
          const SizedBox(height: 10),
          _operationButton(
            Icons.swap_vert_circle_outlined,
            'Manage Inventory',
            'Stock-in and stock-out operations',
            () => _openPage(const InventoryManagementScreen()),
          ),
          const SizedBox(height: 10),
          _operationButton(
            Icons.shopping_bag_outlined,
            'Manage Orders',
            'Review and process orders',
            () => _openPage(const OrderManagementScreen()),
          ),
          const SizedBox(height: 10),
          _operationButton(
            Icons.people_outline_rounded,
            'Manage Customers',
            'Customer records and details',
            () => _openPage(const CustomerManagementScreen()),
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
            border: Border.all(color: emerald.withValues(alpha: 0.16)),
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
                child: Icon(icon, color: emerald, size: 19),
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
                      style: const TextStyle(color: white, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: emerald, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LIVE STREAM - REAL RECENT ORDERS
  // ------------------------------------------------------------

  Widget _liveStream() {
    const completedColor = Color(0xFF00D68F);
    const processingColor = Color(0xFFFFB547);
    const cancelledColor = Color(0xFFFF4D5E);

    return _panel(
      title: 'Live Stream',
      subtitle: 'Latest order activity overview',
      trailing: const _LiveIndicator(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingContent();
          }

          if (snapshot.hasError) {
            return _inlineError(snapshot.error.toString());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _emptyContent(
              Icons.receipt_long_outlined,
              'No orders recorded',
              'New order records will appear here.',
            );
          }

          final completed = orders
              .where(
                (order) =>
                    order['status']?.toString().toLowerCase() == 'completed',
              )
              .length;

          final cancelled = orders
              .where(
                (order) =>
                    order['status']?.toString().toLowerCase() == 'cancelled',
              )
              .length;

          final processing = orders.length - completed - cancelled;

          final recentOrders = orders.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ORDER STATUS CHART
              Row(
                children: [
                  SizedBox(
                    width: 105,
                    height: 105,
                    child: CustomPaint(
                      painter: _OrderStatusPainter(
                        completed: completed,
                        processing: processing,
                        cancelled: cancelled,
                        total: orders.length,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${orders.length}',
                              style: const TextStyle(
                                color: white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'ORDERS',
                              style: TextStyle(
                                color: Color(0xFF8A98A8),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _orderLegendItem(
                          completedColor,
                          'Completed',
                          completed,
                        ),
                        const SizedBox(height: 13),
                        _orderLegendItem(
                          processingColor,
                          'Processing',
                          processing,
                        ),
                        const SizedBox(height: 13),
                        _orderLegendItem(
                          cancelledColor,
                          'Cancelled',
                          cancelled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(color: Color(0xFF34404B), height: 1),

              const SizedBox(height: 13),

              // RECENT ORDER PREVIEW
              const Text(
                'RECENT ORDERS',
                style: TextStyle(
                  color: Color(0xFF8A98A8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              ...recentOrders.map((order) {
                final status = order['status']?.toString() ?? 'unknown';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['order_number']?.toString() ?? 'Order',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order['customer_name'] ?? 'Customer'}'
                              ' • ${_shortDate(order['created_at'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A98A8),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      _statusTag(status),

                      const SizedBox(width: 8),

                      SizedBox(
                        width: 65,
                        child: Text(
                          _money(order['total']),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _orderLegendItem(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _statusTag(String status) {
    final normalized = status.toLowerCase();

    final color = normalized == 'completed'
        ? emerald
        : normalized == 'cancelled'
        ? const Color(0xFFFF7777)
        : const Color(0xFFFFB547);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SALES SECTION
  // ------------------------------------------------------------

  Widget _salesSection() {
    return _panel(
      title: 'Sales Intelligence',
      subtitle: 'Daily sales performance',
      child: DailySalesChart(refreshToken: _salesRefreshToken),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                      style: const TextStyle(color: white, fontSize: 10),
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

  Widget _loadingContent() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: CircularProgressIndicator(color: emerald, strokeWidth: 2),
      ),
    );
  }

  Widget _inlineError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Text(
        'Unable to load data: $message',
        style: const TextStyle(color: white, fontSize: 11),
      ),
    );
  }

  Widget _emptyContent(IconData icon, String title, String description) {
    return SizedBox(
      height: 145,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: white, fontSize: 10),
            ),
          ],
        ),
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
            style: const TextStyle(color: white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: white, fontSize: 11),
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
// SMALL REUSABLE COMPONENTS
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

class _OrderStatusPainter extends CustomPainter {
  final int completed;
  final int processing;
  final int cancelled;
  final int total;

  _OrderStatusPainter({
    required this.completed,
    required this.processing,
    required this.cancelled,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const completedColor = Color(0xFF00D68F);
    const processingColor = Color(0xFFFFB547);
    const cancelledColor = Color(0xFFFF4D5E);

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 8;

    const strokeWidth = 11.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF34404B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    final segments = [
      (completed, completedColor),
      (processing, processingColor),
      (cancelled, cancelledColor),
    ];

    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final count = segment.$1;
      final color = segment.$2;

      if (count <= 0) continue;

      final sweepAngle = (count / total) * 2 * math.pi;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        math.max(0.0, sweepAngle - 0.035),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _OrderStatusPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.processing != processing ||
        oldDelegate.cancelled != cancelled ||
        oldDelegate.total != total;
  }
}
