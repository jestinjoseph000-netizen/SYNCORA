import '../../widgets/stock_movement_widget.dart';
import 'package:flutter/material.dart';
import '../../widgets/daily_sales_chart.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../products/product_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService _dashboardService = DashboardService();

  late Future<Map<String, dynamic>> _summaryFuture;
  late Future<List<Map<String, dynamic>>> _recentOrdersFuture;

  static const Color backgroundColor = Color(0xFF080B10);
  static const Color surfaceColor = Color(0xFF111821);
  static const Color accentColor = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _summaryFuture = _dashboardService.getDashboardSummary();
    _recentOrdersFuture = _dashboardService.getRecentOrders();
  }

  void _refreshDashboard() {
    setState(() {
      _loadDashboard();
    });
  }

  String _formatCurrency(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.all_inclusive,
              color: accentColor,
              size: 27,
            ),
            const SizedBox(width: 10),
            const Text(
              'SYNCORA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
  tooltip: 'Product Management',
  icon: const Icon(
    Icons.inventory_2_outlined,
    color: Color(0xFF00D68F),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductManagementScreen(),
      ),
    );
  },
),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 45,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Unable to load dashboard data.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _refreshDashboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data ?? {};

            final totalProducts =
                (data['total_products'] as num?)?.toInt() ?? 0;

            final totalOrders =
                (data['total_orders'] as num?)?.toInt() ?? 0;

            final totalSales = data['total_sales'];

            final lowStockProducts =
                (data['low_stock_products'] as num?)?.toInt() ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Monitor and manage your inventory operations.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // DASHBOARD STATISTICS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      final columns = width >= 1000
                          ? 4
                          : width >= 600
                              ? 2
                              : 1;

                      const spacing = 16.0;

                      final cardWidth =
                          (width - (spacing * (columns - 1))) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Total Products',
                              value: totalProducts.toString(),
                              icon: Icons.inventory_2_outlined,
                              color: const Color(0xFF4DA3FF),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Total Orders',
                              value: totalOrders.toString(),
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFFB388FF),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Total Sales',
                              value: _formatCurrency(totalSales),
                              icon: Icons.trending_up_rounded,
                              color: accentColor,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Low Stock Products',
                              value: lowStockProducts.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // INVENTORY OVERVIEW SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your dashboard is connected to the SYNCORA database. '
                          'Use the refresh button to retrieve the latest figures.',
                          style: TextStyle(
                            color: Colors.white54,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // RECENT ORDERS SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),
                        

                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _recentOrdersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Text(
                                'Unable to load orders: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                ),
                              );
                            }

                            final orders = snapshot.data ?? [];

                            if (orders.isEmpty) {
                              return const Text(
                                'No orders available yet.',
                                style: TextStyle(
                                  color: Colors.white54,
                                ),
                              );
                            }

                            return Column(
                              children: orders.map((order) {
                                final orderNumber =
                                    order['order_number']?.toString() ??
                                        'N/A';

                                final customerName =
                                    order['customer_name']?.toString() ??
                                        'Customer';

                                final status =
                                    order['status']?.toString() ??
                                        'pending';

                                final total =
                                    (order['total'] as num?)
                                            ?.toDouble() ??
                                        0;

                                final statusColor = status == 'completed'
                                    ? accentColor
                                    : status == 'cancelled'
                                        ? Colors.redAccent
                                        : Colors.orangeAccent;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF19222D),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: accentColor,
                                        ),
                                      ),

                                      const SizedBox(width: 13),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              orderNumber,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              customerName,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.7,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const DailySalesChart(),
                  
                  const SizedBox(height: 20),

                  const StockMovementWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// REUSABLE DASHBOARD STAT CARD
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
