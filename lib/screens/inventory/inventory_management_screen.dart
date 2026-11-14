
import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends State<InventoryManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _movements = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
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
          backgroundColor: Colors.red,
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
              backgroundColor: const Color(0xFF151B24),
              title: Text(
                'Adjust Stock',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product',
                      style: const TextStyle(
                        color: Color(0xFF00D68F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current stock: ${product['stock_quantity']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: movementType,
                      dropdownColor: const Color(0xFF202936),
                      decoration: const InputDecoration(
                        labelText: 'Movement Type',
                        border: OutlineInputBorder(),
                      ),
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

                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm'),
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    final int stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;
    final int threshold =
        (product['low_stock_threshold'] as num?)?.toInt() ?? 5;

    final bool isLowStock = stock <= threshold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['name'] ?? 'Unnamed Product',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                isLowStock
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: isLowStock
                    ? Colors.orangeAccent
                    : const Color(0xFF00D68F),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SKU: ${product['sku'] ?? '-'}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Available stock',
                style: TextStyle(color: Colors.white60),
              ),
              const Spacer(),
              Text(
                '$stock units',
                style: TextStyle(
                  color: isLowStock
                      ? Colors.orangeAccent
                      : const Color(0xFF00D68F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Low-stock threshold: $threshold',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showStockDialog(product),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Adjust Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D68F),
                foregroundColor: const Color(0xFF080B10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementHistory() {
    if (_movements.isEmpty) {
      return const Text(
        'No inventory movements recorded yet.',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      children: _movements.take(20).map((movement) {
        final bool isStockIn =
            movement['movement_type'] == 'STOCK_IN';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151B24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isStockIn
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: isStockIn
                    ? const Color(0xFF00D68F)
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement['product_name'] ?? 'Product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movement['movement_type'] ?? '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    if (movement['note'] != null)
                      Text(
                        movement['note'].toString(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${isStockIn ? '+' : '-'}${movement['quantity']}',
                style: TextStyle(
                  color: isStockIn
                      ? const Color(0xFF00D68F)
                      : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121A),
        title: const Text(
          'Inventory Management',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadInventory,
            icon: const Icon(Icons.refresh),
             color: Color(0xFF00D68F),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unable to load inventory.\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInventory,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInventory,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSectionTitle(
                        'Stock Overview',
                        'Monitor and manage your product quantities.',
                      ),

                      if (_products.isEmpty)
                        const Text(
                          'No products found. Add products first.',
                          style: TextStyle(color: Colors.white54),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth > 850 ? 3 : 2;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: _products.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 220,
                              ),
                              itemBuilder: (context, index) {
                                return _buildProductCard(
                                  _products[index],
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 30),

                      _buildSectionTitle(
                        'Low Stock Alerts',
                        'Products at or below their stock threshold.',
                      ),

                      if (_lowStockProducts.isEmpty)
                        const Text(
                          'All products have sufficient stock.',
                          style: TextStyle(
                            color: Color(0xFF00D68F),
                          ),
                        )
                      else
                        ..._lowStockProducts.map(
                          (product) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF241B15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orangeAccent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    product['name'] ?? 'Product',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${product['stock_quantity']} left',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      _buildSectionTitle(
                        'Recent Stock Movements',
                        'Latest inventory transactions.',
                      ),

                      _buildMovementHistory(),
                    ],
                  ),
                ),
    );
  }
}
