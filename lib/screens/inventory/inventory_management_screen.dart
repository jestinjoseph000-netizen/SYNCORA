
import 'package:flutter/material.dart';

import '../../services/inventory_service.dart';
import '../../services/product_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _movements = [];

  bool _isLoading = true;
  String? _error;

  static const Color backgroundColor = Color(0xFF080B10);
  static const Color surfaceColor = Color(0xFF111923);
  static const Color cardColor = Color(0xFF1C2733);
  static const Color accentColor = Color(0xFF00D68F);
  static const Color mutedColor = Color(0xFF91A0AF);

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _inventoryService.getLowStockProducts(),
        _inventoryService.getStockMovements(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0];
        _lowStockProducts = results[1];
        _movements = results[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _adjustStock({
    required Map<String, dynamic> product,
    required String movementType,
    required int quantity,
    String? note,
  }) async {
    try {
      await _inventoryService.adjustStock(
        productId: product['id'].toString(),
        movementType: movementType,
        quantity: quantity,
        note: note,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cardColor,
          content: Text(
            movementType == 'STOCK_IN'
                ? 'Stock added successfully.'
                : 'Stock removed successfully.',
          ),
        ),
      );

      await _loadInventory();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock adjustment failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showStockDialog(Map<String, dynamic> product) {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    String movementType = 'STOCK_IN';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF263442)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: accentColor, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Adjust Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']?.toString() ?? 'Product',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Current stock: ${product['stock_quantity']} units',
                            style: const TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _dialogLabel('MOVEMENT TYPE'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: movementType,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogDecoration('Select movement'),
                      items: const [
                        DropdownMenuItem(
                          value: 'STOCK_IN',
                          child: Text('Stock IN'),
                        ),
                        DropdownMenuItem(
                          value: 'STOCK_OUT',
                          child: Text('Stock OUT'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            movementType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _dialogLabel('QUANTITY'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogDecoration('Enter quantity'),
                    ),
                    const SizedBox(height: 16),
                    _dialogLabel('NOTE (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogDecoration('Add a note'),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: mutedColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final quantity = int.tryParse(
                            quantityController.text.trim(),
                          );

                          if (quantity == null || quantity <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid positive quantity.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          await _adjustStock(
                            product: product,
                            movementType: movementType,
                            quantity: quantity,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: backgroundColor,
                          ),
                        )
                      : const Text(
                          'Confirm Adjustment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      quantityController.dispose();
      noteController.dispose();
    });
  }

  InputDecoration _dialogDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF263442)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: accentColor),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: mutedColor,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  int get _totalUnits {
    return _products.fold<int>(
      0,
      (total, product) =>
          total + ((product['stock_quantity'] as num?)?.toInt() ?? 0),
    );
  }

  int get _healthyProducts {
    return (_products.length - _lowStockProducts.length)
        .clamp(0, _products.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 8,
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: accentColor,
              size: 27,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNCORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'INVENTORY MANAGEMENT',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadInventory,
            icon: const Icon(Icons.refresh_rounded, color: accentColor),
            tooltip: 'Refresh inventory',
          ),
          const SizedBox(width: 5),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Color(0xFF263442)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentColor),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: accentColor,
                  onRefresh: _loadInventory,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 28,
                          23,
                          isMobile ? 16 : 28,
                          35,
                        ),
                        children: [
                          _buildIntroduction(isMobile),
                          const SizedBox(height: 23),
                          _buildStatistics(isMobile),
                          const SizedBox(height: 30),
                          _buildSectionHeading(
                            'Stock Overview',
                            'Monitor and manage your product quantities.',
                            Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildProductGrid(),
                          const SizedBox(height: 32),
                          _buildSectionHeading(
                            'Low Stock Alerts',
                            'Products at or below their stock threshold.',
                            Icons.warning_amber_rounded,
                            alert: _lowStockProducts.isNotEmpty,
                          ),
                          const SizedBox(height: 15),
                          _buildLowStockSection(),
                          const SizedBox(height: 32),
                          _buildSectionHeading(
                            'Recent Stock Movements',
                            'Your latest inventory transactions.',
                            Icons.swap_vert_rounded,
                          ),
                          const SizedBox(height: 15),
                          _buildMovementHistory(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildIntroduction(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 23 : 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Track stock levels, manage quantities and monitor inventory activity.',
          style: TextStyle(
            color: mutedColor,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: accentColor, size: 7),
              SizedBox(width: 8),
              Text(
                'INVENTORY CONTROL CENTRE',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 850
            ? 3
            : constraints.maxWidth > 430
                ? 3
                : 1;

        final stats = [
          {
            'title': 'Total Products',
            'value': '${_products.length}',
            'subtitle': 'Registered products',
            'icon': Icons.inventory_2_outlined,
            'color': accentColor,
          },
          {
            'title': 'Total Units',
            'value': '$_totalUnits',
            'subtitle': 'Units in inventory',
            'icon': Icons.stacked_bar_chart_rounded,
            'color': Colors.blueAccent,
          },
          {
            'title': 'Low Stock Items',
            'value': '${_lowStockProducts.length}',
            'subtitle': 'Require attention',
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
            mainAxisExtent: columns == 1 ? 105 : 136,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];

            return _StatCard(
              title: stat['title'] as String,
              value: stat['value'] as String,
              subtitle: stat['subtitle'] as String,
              icon: stat['icon'] as IconData,
              color: stat['color'] as Color,
              compact: columns == 1,
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeading(
    String title,
    String subtitle,
    IconData icon, {
    bool alert = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (alert ? Colors.orangeAccent : accentColor)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: alert ? Colors.orangeAccent : accentColor,
            size: 20,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return _emptyState(
        Icons.inventory_2_outlined,
        'No products found',
        'Add products to start managing inventory.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050
            ? 3
            : constraints.maxWidth > 620
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 235,
          ),
          itemBuilder: (context, index) {
            return _buildProductCard(_products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;
    final threshold =
        (product['low_stock_threshold'] as num?)?.toInt() ?? 5;

    final isLowStock = stock <= threshold;
    final statusColor = isLowStock ? Colors.orangeAccent : accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['name']?.toString() ?? 'Unnamed Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'SKU: ${product['sku'] ?? '-'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available stock',
                style: TextStyle(color: mutedColor, fontSize: 11),
              ),
              Text(
                '$stock units',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Low-stock threshold: $threshold',
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _showStockDialog(product),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text(
                'Adjust Stock',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockSection() {
    if (_lowStockProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: accentColor, size: 21),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'All products have sufficient stock.',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _lowStockProducts.map((product) {
        final stock =
            (product['stock_quantity'] as num?)?.toInt() ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.orangeAccent.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product['name']?.toString() ?? 'Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$stock left',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMovementHistory() {
    if (_movements.isEmpty) {
      return _emptyState(
        Icons.swap_vert_rounded,
        'No stock movements yet',
        'Your inventory transactions will appear here.',
      );
    }

    return Column(
      children: _movements.take(20).map((movement) {
        final isStockIn = movement['movement_type'] == 'STOCK_IN';
        final movementColor = isStockIn ? accentColor : Colors.orangeAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: movementColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isStockIn
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: movementColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement['product_name']?.toString() ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      movement['movement_type']?.toString() ?? '',
                      style: TextStyle(
                        color: movementColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (movement['note'] != null &&
                        movement['note'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        movement['note'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isStockIn ? '+' : '-'}${movement['quantity']}',
                style: TextStyle(
                  color: movementColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(IconData icon, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: mutedColor, size: 37),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load inventory',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadInventory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  static const Color surfaceColor = Color(0xFF111923);
  static const Color mutedColor = Color(0xFF91A0AF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: compact
          ? Row(
              children: [
                _iconBox(),
                const SizedBox(width: 13),
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
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 9,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconBox(),
                    Icon(
                      Icons.trending_up_rounded,
                      color: color.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}
