
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
  static const Color _surface = Color(0xFF111923);
  static const Color _raised = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _warning = Color(0xFFFFB74D);
  static const Color _danger = Color(0xFFFF6B6B);
  static const Color _blue = Color(0xFF4DA3FF);
  static const Color _muted = Color(0xFF91A0AF);

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
    setState(_loadSuggestions);
  }

  String _formatNumber(dynamic value) {
    return _service.toInt(value).toString();
  }

  String _formatDecimal(dynamic value) {
    return _service.toDouble(value).toStringAsFixed(1);
  }

  Color _stockColor(Map<String, dynamic> item) {
    final stock = _service.toInt(item['stock_quantity']);
    return stock == 0 ? _danger : _warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
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
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          IconButton(
            tooltip: 'Refresh recommendations',
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _accent,
            ),
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
              return _buildErrorState(snapshot.error);
            }

            final suggestions = snapshot.data ?? [];

            final totalUnits =
                _service.getTotalSuggestedUnits(suggestions);

            final outOfStock =
                _service.getOutOfStockCount(suggestions);

            return LayoutBuilder(
              builder: (context, pageConstraints) {
                final isMobile = pageConstraints.maxWidth < 600;
                final horizontalPadding =
                    pageConstraints.maxWidth > 1200
                        ? 36.0
                        : isMobile
                            ? 16.0
                            : 24.0;

                return RefreshIndicator(
                  color: _accent,
                  backgroundColor: _raised,
                  onRefresh: () async {
                    _refresh();
                    await _suggestionsFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1450,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageHeader(isMobile),

                            const SizedBox(height: 24),

                            _buildFilters(isMobile),

                            const SizedBox(height: 20),

                            _buildStatistics(
                              suggestions: suggestions,
                              totalUnits: totalUnits,
                              outOfStock: outOfStock,
                            ),

                            const SizedBox(height: 30),

                            _buildSectionHeading(
                              title: 'Reorder recommendations',
                              subtitle:
                                  'Products that may need replenishment',
                              count: suggestions.length,
                            ),

                            const SizedBox(height: 16),

                            if (suggestions.isEmpty)
                              _buildEmptyState()
                            else
                              ...suggestions.map(_buildProductCard),

                            const SizedBox(height: 22),

                            _buildInformationCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF12352D),
            _surface,
            _surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _accent.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _accent,
                  size: 14,
                ),
                SizedBox(width: 7),
                Text(
                  'INTELLIGENT INVENTORY',
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
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 48 : 58,
                height: isMobile ? 48 : 58,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: _accent,
                  size: isMobile ? 25 : 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reorder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Plan replenishment before stock runs out.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: _accent,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sales trends  •  Current stock  •  Suggested quantities',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: _blue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forecast settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Adjust the period used for recommendations',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 500;
              final fieldWidth = stacked
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 14) / 2;

              return Wrap(
                spacing: 14,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _buildDropdownField(
                      label: 'Sales reporting period',
                      icon: Icons.calendar_month_rounded,
                      value: _selectedDays,
                      items: const [
                        DropdownMenuItem(
                          value: 7,
                          child: Text('Last 7 days'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('Last 30 days'),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('Last 90 days'),
                        ),
                        DropdownMenuItem(
                          value: 365,
                          child: Text('Last 365 days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedDays = value;
                          _loadSuggestions();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildDropdownField(
                      label: 'Target stock coverage',
                      icon: Icons.timelapse_rounded,
                      value: _coverDays,
                      items: const [
                        DropdownMenuItem(
                          value: 7,
                          child: Text('7 days'),
                        ),
                        DropdownMenuItem(
                          value: 14,
                          child: Text('14 days'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 days'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('60 days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _coverDays = value;
                          _loadSuggestions();
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _muted, size: 15),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: _raised,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _accent,
          ),
          decoration: _dropdownDecoration(),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: _accent,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatistics({
    required List<Map<String, dynamic>> suggestions,
    required int totalUnits,
    required int outOfStock,
  }) {
    final stats = [
      {
        'title': 'Products to Reorder',
        'value': suggestions.length.toString(),
        'subtitle': 'Need replenishment',
        'icon': Icons.inventory_2_outlined,
        'color': _accent,
      },
      {
        'title': 'Suggested Units',
        'value': totalUnits.toString(),
        'subtitle': 'Estimated order quantity',
        'icon': Icons.shopping_bag_outlined,
        'color': _blue,
      },
      {
        'title': 'Out of Stock',
        'value': outOfStock.toString(),
        'subtitle': 'Currently unavailable',
        'icon': Icons.warning_amber_rounded,
        'color': _danger,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        const spacing = 13.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                subtitle: stat['subtitle'] as String,
                icon: stat['icon'] as IconData,
                color: stat['color'] as Color,
                compact: columns == 1,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool compact,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 105 : 158,
      ),
      padding: EdgeInsets.all(compact ? 16 : 19),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: compact
          ? Row(
              children: [
                _statIcon(icon, color, 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _statIcon(icon, color, 42),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      color: color.withValues(alpha: 0.6),
                      size: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
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
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statIcon(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(5),
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
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count products',
            style: const TextStyle(
              color: _accent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final stock = _service.toInt(item['stock_quantity']);
    final threshold = _service.toInt(item['low_stock_threshold']);
    final reorder =
        _service.toInt(item['suggested_reorder_quantity']);

    final stockColor = _stockColor(item);
    final stockDays = item['days_of_stock'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: stockColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stock == 0
                      ? Icons.remove_shopping_cart_rounded
                      : Icons.inventory_2_outlined,
                  color: stockColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name']?.toString() ??
                          'Unnamed product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'SKU: ${item['sku'] ?? 'N/A'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['category_name']?.toString() ??
                          'Uncategorized',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStockBadge(stock, stockColor),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 360 ? 2 : 3;
                final metrics = [
                  ('Current stock', stock.toString()),
                  ('Low-stock level', threshold.toString()),
                  ('Units sold', _formatNumber(item['units_sold'])),
                ];

                return Wrap(
                  spacing: 8,
                  runSpacing: 14,
                  children: metrics.map((metric) {
                    final width = columns == 2
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 16) / 3;

                    return SizedBox(
                      width: width,
                      child: _buildMetric(
                        metric.$1,
                        metric.$2,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 13),

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
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  'Projected demand',
                  _formatDecimal(item['projected_demand']),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _accent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Suggested reorder quantity',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$reorder',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'UNITS',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: _warning.withValues(alpha: 0.9),
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['recommendation_reason']?.toString() ??
                      'Replenishment recommended',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int stock, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        stock == 0 ? 'OUT OF STOCK' : 'LOW STOCK',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _accent,
            size: 48,
          ),
          SizedBox(height: 15),
          Text(
            'No Reorders Recommended',
            textAlign: TextAlign.center,
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
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _accent,
                size: 20,
              ),
              SizedBox(width: 9),
              Text(
                'How recommendations work',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Recommendations use historical sales, current stock and each product’s low-stock threshold to estimate replenishment quantities.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: _warning,
                  size: 17,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'These are planning estimates, not purchase orders. Review supplier availability and actual demand before reordering.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _danger,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load reorder recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
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
}
