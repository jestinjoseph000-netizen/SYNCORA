
import 'package:flutter/material.dart';

import '../../services/reorder_service.dart';

class SmartReorderScreen extends StatefulWidget {
  const SmartReorderScreen({super.key});

  @override
  State<SmartReorderScreen> createState() => _SmartReorderScreenState();
}

class _SmartReorderScreenState extends State<SmartReorderScreen> {
  final ReorderService _service = ReorderService();

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _warning = Color(0xFFFFB74D);
  static const Color _danger = Color(0xFFFF6B6B);

  int _selectedDays = 30;
  int _coverDays = 14;

  late Future<List<Map<String, dynamic>>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  void _loadSuggestions() {
    _suggestionsFuture = _service.getReorderSuggestions(
      days: _selectedDays,
      coverDays: _coverDays,
    );
  }

  void _refresh() {
    setState(() {
      _loadSuggestions();
    });
  }

  String _formatNumber(dynamic value) {
    return _service.toInt(value).toString();
  }

  String _formatDecimal(dynamic value) {
    return _service.toDouble(value).toStringAsFixed(1);
  }

  Color _stockColor(Map<String, dynamic> item) {
    final stock = _service.toInt(item['stock_quantity']);

    if (stock == 0) return _danger;

    return _warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'Smart Reorder Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          IconButton(
            tooltip: 'Refresh recommendations',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _suggestionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _accent),
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
                        Icons.error_outline,
                        color: _danger,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Unable to load reorder recommendations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _refresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _background,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final suggestions = snapshot.data ?? [];

            final totalUnits =
                _service.getTotalSuggestedUnits(suggestions);

            final outOfStock =
                _service.getOutOfStockCount(suggestions);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory Reorder Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review inventory risks and estimated replenishment needs.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildFilters(),

                  const SizedBox(height: 20),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 850
                          ? 3
                          : constraints.maxWidth >= 500
                              ? 2
                              : 1;

                      const spacing = 12.0;
                      final cardWidth =
                          (constraints.maxWidth -
                                  spacing * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              title: 'Products to Reorder',
                              value: suggestions.length.toString(),
                              icon: Icons.inventory_2_outlined,
                              color: _accent,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              title: 'Suggested Units',
                              value: totalUnits.toString(),
                              icon: Icons.shopping_cart_outlined,
                              color: const Color(0xFF4DA3FF),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              title: 'Out of Stock',
                              value: outOfStock.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: _danger,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'REORDER RECOMMENDATIONS',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        '${suggestions.length} products',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (suggestions.isEmpty)
                    _buildEmptyState()
                  else
                    ...suggestions.map(_buildProductCard),

                  const SizedBox(height: 22),

                  _buildInformationCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forecast Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Sales reporting period',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: _selectedDays,
            dropdownColor: _surface,
            style: const TextStyle(color: Colors.white),
            decoration: _dropdownDecoration(),
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
                _loadSuggestions();
              });
            },
          ),

          const SizedBox(height: 16),

          const Text(
            'Target stock coverage',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: _coverDays,
            dropdownColor: _surface,
            style: const TextStyle(color: Colors.white),
            decoration: _dropdownDecoration(),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 14, child: Text('14 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 60, child: Text('60 days')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _coverDays = value;
                _loadSuggestions();
              });
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 15),
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
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final stock = _service.toInt(item['stock_quantity']);
    final threshold =
        _service.toInt(item['low_stock_threshold']);
    final reorder =
        _service.toInt(item['suggested_reorder_quantity']);

    final stockColor = _stockColor(item);
    final stockDays = item['days_of_stock'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: stockColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name']?.toString() ?? 'Unnamed product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'SKU: ${item['sku'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['category_name']?.toString() ??
                          'Uncategorized',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stock == 0 ? 'OUT OF STOCK' : 'LOW STOCK',
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Current stock',
                  stock.toString(),
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Low-stock level',
                  threshold.toString(),
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Units sold',
                  _formatNumber(item['units_sold']),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Estimated stock days',
                  stockDays == null
                      ? 'N/A'
                      : '${_formatDecimal(stockDays)} days',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Projected demand',
                  _formatDecimal(item['projected_demand']),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: _accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Suggested reorder quantity',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$reorder units',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            item['recommendation_reason']?.toString() ??
                'Replenishment recommended',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: _accent,
            size: 45,
          ),
          SizedBox(height: 14),
          Text(
            'No Reorders Recommended',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No products currently meet the reorder conditions for these settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _accent,
                size: 20,
              ),
              SizedBox(width: 9),
              Text(
                'How recommendations work',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Recommendations use historical sales, current stock and each product’s low-stock threshold to estimate replenishment quantities.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'These are planning estimates, not purchase orders. Review supplier availability and actual demand before reordering.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
