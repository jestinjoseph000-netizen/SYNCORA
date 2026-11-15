
import 'package:flutter/material.dart';

import '../../services/forecast_service.dart';

class ProductForecastScreen extends StatefulWidget {
  const ProductForecastScreen({super.key});

  @override
  State<ProductForecastScreen> createState() =>
      _ProductForecastScreenState();
}

class _ProductForecastScreenState
    extends State<ProductForecastScreen> {
  final ForecastService _forecastService = ForecastService();

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);

  int _selectedDays = 30;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return '₹${_toDouble(value).toStringAsFixed(2)}';
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _forecastService
          .getProductPerformance(days: _selectedDays);

      if (!mounted) return;

      setState(() {
        _products = products;
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

  int get _totalUnits {
    return _products.fold(
      0,
      (sum, product) => sum + _toInt(product['units_sold']),
    );
  }

  double get _totalRevenue {
    return _products.fold(
      0,
      (sum, product) => sum + _toDouble(product['revenue']),
    );
  }

  int get _lowStockCount {
    return _products.where((product) {
      return _toInt(product['stock_quantity']) <=
          _toInt(product['low_stock_threshold']);
    }).length;
  }

  List<Map<String, dynamic>> get _bestSelling {
    final result = List<Map<String, dynamic>>.from(_products);

    result.sort(
      (a, b) => _toInt(b['units_sold']).compareTo(
        _toInt(a['units_sold']),
      ),
    );

    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _topRevenue {
    final result = List<Map<String, dynamic>>.from(_products);

    result.sort(
      (a, b) => _toDouble(b['revenue']).compareTo(
        _toDouble(a['revenue']),
      ),
    );

    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _increasingProducts {
    final result = _products.where((product) {
      final trend = product['trend_percent'];

      return trend != null && _toDouble(trend) > 0;
    }).toList();

    result.sort(
      (a, b) => _toDouble(b['trend_percent']).compareTo(
        _toDouble(a['trend_percent']),
      ),
    );

    return result;
  }

  List<Map<String, dynamic>> get _decliningProducts {
    final result = _products.where((product) {
      final trend = product['trend_percent'];

      return trend != null && _toDouble(trend) < 0;
    }).toList();

    result.sort(
      (a, b) => _toDouble(a['trend_percent']).compareTo(
        _toDouble(b['trend_percent']),
      ),
    );

    return result;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
  }) {
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
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRanking({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> products,
    required String metricKey,
    required String metricLabel,
    required bool isRevenue,
  }) {
    final maximum = products.isEmpty
        ? 1.0
        : products.map((p) => isRevenue
            ? _toDouble(p[metricKey])
            : _toDouble(p[metricKey])).reduce(
                (a, b) => a > b ? a : b,
              );

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
          _buildSectionTitle(title, subtitle),

          if (products.isEmpty)
            const Text(
              'No product data available.',
              style: TextStyle(color: Colors.white54),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;

              final value = _toDouble(product[metricKey]);

              final progress = maximum <= 0
                  ? 0.0
                  : (value / maximum).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            product['product_name']?.toString() ??
                                'Unknown product',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          isRevenue
                              ? _money(value)
                              : '${value.toInt()} $metricLabel',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white10,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTrendSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> products,
    required bool increasing,
  }) {
    final color = increasing ? _accent : Colors.orangeAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, subtitle),

          if (products.isEmpty)
            const Text(
              'No comparable sales history available.',
              style: TextStyle(color: Colors.white54),
            )
          else
            ...products.take(5).map((product) {
              final trend = _toDouble(product['trend_percent']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Icon(
                      increasing
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name']?.toString() ??
                                'Unknown product',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_toInt(product['units_sold'])} units sold',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildForecastTable() {
    final forecastProducts = List<Map<String, dynamic>>.from(_products);

    forecastProducts.sort(
      (a, b) => _toDouble(b['projected_units_next_7_days'])
          .compareTo(_toDouble(a['projected_units_next_7_days'])),
    );

    final products = forecastProducts
        .where((product) => _toInt(product['units_sold']) > 0)
        .take(10)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Estimated Product Demand',
            'Estimated units needed over the next 7 days',
          ),

          if (products.isEmpty)
            const Text(
              'Not enough sales history to estimate demand.',
              style: TextStyle(color: Colors.white54),
            )
          else
            ...products.map((product) {
              final forecast =
                  _toDouble(product['projected_units_next_7_days']);

              final stock = _toInt(product['stock_quantity']);

              final shortfall = forecast.ceil() - stock;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: _accent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name']?.toString() ??
                                'Unknown product',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Current stock: $stock',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${forecast.toStringAsFixed(1)} units',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortfall > 0
                              ? 'Potential shortage: $shortfall'
                              : 'Stock covers estimate',
                          style: TextStyle(
                            color: shortfall > 0
                                ? Colors.orangeAccent
                                : Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Understand sales performance and estimate future demand.',
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 22),

        DropdownButtonFormField<int>(
          initialValue: _selectedDays,
          dropdownColor: _surface,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Reporting Period',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 7, child: Text('Last 7 days')),
            DropdownMenuItem(value: 30, child: Text('Last 30 days')),
            DropdownMenuItem(value: 90, child: Text('Last 90 days')),
            DropdownMenuItem(value: 365, child: Text('Last 365 days')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedDays = value;
            });

            _loadForecast();
          },
        ),

        const SizedBox(height: 22),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 750 ? 4 : 2;

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.25 : 1.45,
              children: [
                _buildStatCard(
                  title: 'Units Sold',
                  value: '$_totalUnits',
                  icon: Icons.shopping_cart_outlined,
                  subtitle: 'Selected period',
                ),
                _buildStatCard(
                  title: 'Sales Revenue',
                  value: _money(_totalRevenue),
                  icon: Icons.currency_rupee,
                  subtitle: 'Excluding cancelled orders',
                ),
                _buildStatCard(
                  title: 'Active Products',
                  value: '${_products.length}',
                  icon: Icons.inventory_2_outlined,
                  subtitle: 'Available products',
                ),
                _buildStatCard(
                  title: 'Low Stock',
                  value: '$_lowStockCount',
                  icon: Icons.warning_amber_outlined,
                  subtitle: 'At or below threshold',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        _buildProductRanking(
          title: 'Best-Selling Products',
          subtitle: 'Ranked by units sold',
          products: _bestSelling,
          metricKey: 'units_sold',
          metricLabel: 'units',
          isRevenue: false,
        ),

        const SizedBox(height: 18),

        _buildProductRanking(
          title: 'Top Revenue Products',
          subtitle: 'Ranked by revenue generated',
          products: _topRevenue,
          metricKey: 'revenue',
          metricLabel: '',
          isRevenue: true,
        ),

        const SizedBox(height: 18),

        _buildTrendSection(
          title: 'Increasing Sales',
          subtitle: 'Compared with the previous equivalent period',
          products: _increasingProducts,
          increasing: true,
        ),

        const SizedBox(height: 18),

        _buildTrendSection(
          title: 'Declining Sales',
          subtitle: 'Products with a negative sales trend',
          products: _decliningProducts,
          increasing: false,
        ),

        const SizedBox(height: 18),

        _buildForecastTable(),

        const SizedBox(height: 20),

        const Text(
          'Forecast methodology: estimated demand uses the average '
          'daily units sold during the selected period, multiplied '
          'by seven. It is a basic estimate, not a guaranteed prediction. '
          'Products without sales history are excluded.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'SYNCORA Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadForecast,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _loadForecast,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(70),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _accent,
                        ),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 35,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadForecast,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _products.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No active products found.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          : _buildDashboard(),
            ),
          ),
        ),
      ),
    );
  }
}
