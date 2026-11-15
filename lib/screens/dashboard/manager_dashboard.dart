import 'package:flutter/material.dart';

import '../../widgets/stat_card.dart';
import '../analytics/product_forecast_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/profile_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../products/product_management_screen.dart';
import '../inventory/inventory_management_screen.dart';
import '../customers/customer_management_screen.dart';
import '../orders/order_management_screen.dart';
import '../../widgets/daily_sales_chart.dart';
import '../../widgets/stock_movement_widget.dart';
import '../analytics/smart_reorder_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final DashboardService _dashboardService = DashboardService();

  late Future<Map<String, dynamic>> _summaryFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _summaryFuture = _dashboardService.getDashboardSummary();
    _ordersFuture = _dashboardService.getRecentOrders();
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

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.all_inclusive, color: _accent, size: 27),
            SizedBox(width: 10),
            Text(
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
          Tooltip(
            message: 'My Profile',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ProfileAvatar(
                radius: 16,
                onTap: () => _openScreen(const ProfileScreen()),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout, color: _accent),
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
                child: CircularProgressIndicator(color: _accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load dashboard.',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshDashboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _background,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data ?? {};

            final totalProducts =
                (data['total_products'] as num?)?.toInt() ?? 0;

            final totalOrders = (data['total_orders'] as num?)?.toInt() ?? 0;

            final totalSales = data['total_sales'];

            final lowStock = (data['low_stock_products'] as num?)?.toInt() ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manager Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor inventory, customers and daily operations.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),

                  const SizedBox(height: 28),

                  // Dashboard statistics
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
                          (width - spacing * (columns - 1)) / columns;

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
                              icon: Icons.trending_up,
                              color: _accent,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: StatCard(
                              title: 'Low Stock Products',
                              value: lowStock.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Manager shortcuts
                  const Text(
                    'MANAGEMENT',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildManagementButton(
                    icon: Icons.inventory_2_outlined,
                    title: 'Product Management',
                    subtitle: 'View, add and update products',
                    onTap: () => _openScreen(const ProductManagementScreen()),
                  ),

                  _buildManagementButton(
                    icon: Icons.warehouse_outlined,
                    title: 'Inventory Management',
                    subtitle: 'Adjust stock and view movements',
                    onTap: () => _openScreen(const InventoryManagementScreen()),
                  ),

                  _buildManagementButton(
                    icon: Icons.people_outline,
                    title: 'Customer Management',
                    subtitle: 'View and manage customer records',
                    onTap: () => _openScreen(const CustomerManagementScreen()),
                  ),

                  _buildManagementButton(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Order Management',
                    subtitle: 'Review orders and update their status',
                    onTap: () => _openScreen(const OrderManagementScreen()),
                  ),
                  _buildManagementButton(
                    icon: Icons.analytics_outlined,
                    title: 'Product Performance & Forecasting',
                    subtitle:
                        'Analyse sales trends and estimate product demand',
                    onTap: () => _openScreen(const ProductForecastScreen()),
                  ),
                  _buildManagementButton(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Smart Reorder Assistant',
                    subtitle:
                        'View stock risks and suggested reorder quantities',
                    onTap: () => _openScreen(const SmartReorderScreen()),
                  ),

                  const SizedBox(height: 25),

                  // Recent orders
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
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
                        const SizedBox(height: 18),

                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _ordersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Text(
                                'Unable to load recent orders.',
                                style: TextStyle(color: Colors.white54),
                              );
                            }

                            final orders = snapshot.data ?? [];

                            if (orders.isEmpty) {
                              return const Text(
                                'No orders available yet.',
                                style: TextStyle(color: Colors.white54),
                              );
                            }

                            return Column(
                              children: orders.map((order) {
                                final customer =
                                    order['customer_name'] ?? 'Customer';

                                final number = order['order_number'] ?? 'N/A';

                                final status = order['status'] ?? 'pending';

                                final total =
                                    (order['total'] as num?)?.toDouble() ?? 0;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.receipt_long,
                                    color: _accent,
                                  ),
                                  title: Text(
                                    number.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    customer.toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(total),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        status.toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: _accent,
                                          fontSize: 10,
                                        ),
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

                  const SizedBox(height: 22),
                  const DailySalesChart(),
                  const SizedBox(height: 22),
                  const StockMovementWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildManagementButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
        leading: Icon(icon, color: _accent, size: 27),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, color: _accent, size: 15),
      ),
    );
  }
}
