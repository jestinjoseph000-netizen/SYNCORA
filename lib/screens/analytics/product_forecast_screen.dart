
import 'package:flutter/material.dart';

import '../../services/forecast_service.dart';

class ProductForecastScreen extends StatefulWidget {
  const ProductForecastScreen({super.key});

  @override
  State<ProductForecastScreen> createState() => _ProductForecastScreenState();
}

class _ProductForecastScreenState extends State<ProductForecastScreen> {
  final ForecastService _forecastService = ForecastService();

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111923);
  static const Color _raised = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _secondary = Color(0xFF91A0AF);
  static const Color _border = Color(0xFF263441);

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
      final products = await _forecastService.getProductPerformance(
        days: _selectedDays,
      );

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
      (a, b) => _toInt(b['units_sold']).compareTo(_toInt(a['units_sold'])),
    );

    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _topRevenue {
    final result = List<Map<String, dynamic>>.from(_products);

    result.sort(
      (a, b) => _toDouble(b['revenue']).compareTo(_toDouble(a['revenue'])),
    );

    return result.take(5).toList();
  }

  List<Map<String, dynamic>> get _increasingProducts {
    final result = _products.where((product) {
      final trend = product['trend_percent'];
      return trend != null && _toDouble(trend) > 0;
    }).toList();

    result.sort(
      (a, b) => _toDouble(b['trend_percent'])
          .compareTo(_toDouble(a['trend_percent'])),
    );

    return result;
  }

  List<Map<String, dynamic>> get _decliningProducts {
    final result = _products.where((product) {
      final trend = product['trend_percent'];
      return trend != null && _toDouble(trend) < 0;
    }).toList();

    result.sort(
      (a, b) => _toDouble(a['trend_percent'])
          .compareTo(_toDouble(b['trend_percent'])),
    );

    return result;
  }

  Widget _buildPageHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 17 : 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF15252B),
            Color(0xFF111923),
            Color(0xFF111923),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_rounded, color: _accent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'INTELLIGENCE CENTRE',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isMobile)
                const Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: _accent, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'DEMAND ANALYSIS',
                      style: TextStyle(
                        color: _secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 48 : 58,
                height: isMobile ? 48 : 58,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.query_stats_rounded,
                  color: _accent,
                  size: isMobile ? 25 : 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Forecast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Understand performance. Anticipate demand.',
                      style: TextStyle(
                        color: _secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _accent,
                  size: 20,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reporting period',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Choose the sales history to analyse',
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDays,
                    dropdownColor: _raised,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _accent,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                      DropdownMenuItem(value: 365, child: Text('365 days')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedDays = value;
                      });

                      _loadForecast();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
    required Color color,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: compact
          ? Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: color.withValues(alpha: 0.7),
                  size: 17,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: color.withValues(alpha: 0.65),
                      size: 17,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatistics(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 950
            ? 4
            : constraints.maxWidth > 560
                ? 2
                : 1;

        final compact = columns == 1;

        final stats = [
          {
            'title': 'Units Sold',
            'value': '$_totalUnits',
            'subtitle': 'Selected period',
            'icon': Icons.shopping_cart_outlined,
            'color': _accent,
          },
          {
            'title': 'Sales Revenue',
            'value': _money(_totalRevenue),
            'subtitle': 'Excluding cancelled orders',
            'icon': Icons.currency_rupee_rounded,
            'color': Colors.blueAccent,
          },
          {
            'title': 'Active Products',
            'value': '${_products.length}',
            'subtitle': 'Available products',
            'icon': Icons.inventory_2_outlined,
            'color': Colors.purpleAccent,
          },
          {
            'title': 'Low Stock',
            'value': '$_lowStockCount',
            'subtitle': 'At or below threshold',
            'icon': Icons.warning_amber_rounded,
            'color': Colors.orangeAccent,
          },
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: compact ? 96 : 153,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];

            return _buildStatCard(
              title: stat['title'] as String,
              value: stat['value'] as String,
              subtitle: stat['subtitle'] as String,
              icon: stat['icon'] as IconData,
              color: stat['color'] as Color,
              compact: compact,
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
    Color color = _accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(19),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.query_stats_rounded,
            color: Colors.white30,
            size: 27,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secondary, fontSize: 12),
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
        : products
            .map((p) => _toDouble(p[metricKey]))
            .reduce((a, b) => a > b ? a : b);

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'Performance ranking',
            title: title,
            subtitle: subtitle,
            icon: isRevenue
                ? Icons.payments_outlined
                : Icons.emoji_events_outlined,
          ),
          if (products.isEmpty)
            _buildEmptyMessage('No product data available.')
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final value = _toDouble(product[metricKey]);

              final progress = maximum <= 0
                  ? 0.0
                  : (value / maximum).clamp(0.0, 1.0).toDouble();

              final rankColor = index == 0
                  ? _accent
                  : index == 1
                      ? Colors.blueAccent
                      : index == 2
                          ? Colors.orangeAccent
                          : _secondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rankColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: rankColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['product_name']?.toString() ??
                                      'Unknown product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRevenue
                                    ? _money(value)
                                    : '${value.toInt()} $metricLabel',
                                style: TextStyle(
                                  color: rankColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rankColor,
                              ),
                            ),
                          ),
                        ],
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

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: increasing ? 'Positive movement' : 'Needs attention',
            title: title,
            subtitle: subtitle,
            icon: increasing
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: color,
          ),
          if (products.isEmpty)
            _buildEmptyMessage('No comparable sales history available.')
          else
            ...products.take(5).map((product) {
              final trend = _toDouble(product['trend_percent']);

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.045),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        increasing
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
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
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_toInt(product['units_sold'])} units sold',
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
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

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'Forward-looking insights',
            title: 'Estimated Product Demand',
            subtitle: 'Estimated units needed over the next 7 days',
            icon: Icons.inventory_rounded,
          ),
          if (products.isEmpty)
            _buildEmptyMessage(
              'Not enough sales history to estimate demand.',
            )
          else
            ...products.map((product) {
              final forecast = _toDouble(
                product['projected_units_next_7_days'],
              );

              final stock = _toInt(product['stock_quantity']);
              final shortfall = forecast.ceil() - stock;
              final hasShortage = shortfall > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _raised.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 390;

                    final productInfo = Row(
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: _accent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
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
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Current stock: $stock',
                                style: const TextStyle(
                                  color: _secondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final demandInfo = Column(
                      crossAxisAlignment: narrow
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${forecast.toStringAsFixed(1)} units',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: hasShortage
                                ? Colors.orangeAccent.withValues(alpha: 0.10)
                                : _accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            hasShortage
                                ? 'Potential shortage: $shortfall'
                                : 'Stock covers estimate',
                            style: TextStyle(
                              color: hasShortage
                                  ? Colors.orangeAccent
                                  : _accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          productInfo,
                          const SizedBox(height: 12),
                          demandInfo,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: productInfo),
                        const SizedBox(width: 12),
                        demandInfo,
                      ],
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMethodologyNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _accent,
            size: 19,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABOUT THIS FORECAST',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Estimated demand uses the average daily units sold '
                  'during the selected period, multiplied by seven. '
                  'It is a basic estimate, not a guaranteed prediction. '
                  'Products without sales history are excluded.',
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isMobile),
        const SizedBox(height: 19),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Performance Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: _accent, size: 7),
                  SizedBox(width: 6),
                  Text(
                    'ANALYTICS',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildStatistics(isMobile),

        const SizedBox(height: 27),

        _buildProductRanking(
          title: 'Best-Selling Products',
          subtitle: 'Ranked by units sold',
          products: _bestSelling,
          metricKey: 'units_sold',
          metricLabel: 'units',
          isRevenue: false,
        ),

        const SizedBox(height: 16),

        _buildProductRanking(
          title: 'Top Revenue Products',
          subtitle: 'Ranked by revenue generated',
          products: _topRevenue,
          metricKey: 'revenue',
          metricLabel: '',
          isRevenue: true,
        ),

        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  _buildTrendSection(
                    title: 'Increasing Sales',
                    subtitle: 'Compared with the previous equivalent period',
                    products: _increasingProducts,
                    increasing: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTrendSection(
                    title: 'Declining Sales',
                    subtitle: 'Products with a negative sales trend',
                    products: _decliningProducts,
                    increasing: false,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTrendSection(
                    title: 'Increasing Sales',
                    subtitle: 'Compared with the previous equivalent period',
                    products: _increasingProducts,
                    increasing: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTrendSection(
                    title: 'Declining Sales',
                    subtitle: 'Products with a negative sales trend',
                    products: _decliningProducts,
                    increasing: false,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        _buildForecastTable(),

        const SizedBox(height: 16),

        _buildMethodologyNote(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load forecast',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadForecast,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
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
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: _accent,
              size: 27,
            ),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'ANALYTICS',
              style: TextStyle(
                color: _secondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh forecast',
            onPressed: _isLoading ? null : _loadForecast,
            icon: const Icon(Icons.refresh_rounded, color: _accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _raised,
        onRefresh: _loadForecast,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final horizontalPadding = isMobile ? 14.0 : 24.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(75),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _accent,
                            ),
                          ),
                        )
                      : _error != null
                          ? _buildErrorState()
                          : _products.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(35),
                                  child: _buildEmptyMessage(
                                    'No active products found.',
                                  ),
                                )
                              : _buildDashboard(isMobile),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
