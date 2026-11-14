
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../products/product_management_screen.dart';
import '../inventory/inventory_management_screen.dart';
import '../orders/order_management_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _error;

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary =
          await _dashboardService.getDashboardSummary();

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 25),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: _accent,
              size: 15,
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
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.all_inclusive, color: _accent),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: _accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage daily inventory and order operations.',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 28),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          color: _accent,
                        ),
                      ),
                    )
                  else if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: _loadDashboard,
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: _accent),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700
                              ? 4
                              : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                      children: [
                        _buildStatCard(
                          'Total Products',
                          '${_summary['total_products'] ?? 0}',
                          Icons.inventory_2_outlined,
                        ),
                        _buildStatCard(
                          'Total Orders',
                          '${_summary['total_orders'] ?? 0}',
                          Icons.shopping_bag_outlined,
                        ),
                        _buildStatCard(
                          'Total Sales',
                          '₹${_summary['total_sales'] ?? 0}',
                          Icons.currency_rupee,
                        ),
                        _buildStatCard(
                          'Low Stock Items',
                          '${_summary['low_stock_products'] ?? 0}',
                          Icons.warning_amber_outlined,
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  const Text(
                    'Daily Operations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    title: 'Product Catalogue',
                    description: 'View and search available products',
                    icon: Icons.inventory_2_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProductManagementScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildActionCard(
                    title: 'Inventory Management',
                    description: 'View stock levels and movements',
                    icon: Icons.warehouse_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const InventoryManagementScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildActionCard(
                    title: 'Order Management',
                    description: 'View and process customer orders',
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrderManagementScreen(),
                        ),
                      );
                    },
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
