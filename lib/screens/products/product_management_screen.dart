import 'package:flutter/material.dart';

import 'barcode_scanner_screen.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _service = ProductService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _productsFuture;

  bool _canManageProducts = false;
  bool _canDeleteProducts = false;

  static const Color backgroundColor = Color(0xFF080B10);
  static const Color surfaceColor = Color(0xFF111821);
  static const Color accentColor = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadPermissions();
  }

  // Load products from Supabase.
  void _loadProducts({String search = ''}) {
    _productsFuture = _service.getProducts(searchQuery: search);
  }

  // Refresh product list.
  Future<void> _refreshProducts() async {
    if (!mounted) return;

    setState(() {
      _loadProducts(search: _searchController.text.trim());
    });

    try {
      await _productsFuture;
    } catch (_) {
      // FutureBuilder displays loading errors.
    }
  }

  // Load permissions based on logged-in user's role.
  Future<void> _loadPermissions() async {
    try {
      final role = await AuthService().getCurrentUserRole();

      if (!mounted) return;

      setState(() {
        _canManageProducts = role == 'admin' || role == 'manager';

        _canDeleteProducts = role == 'admin';
      });
    } catch (error) {
      debugPrint('Permission loading error: $error');
    }
  }

  // Navigate to edit product screen.
  Future<void> _editProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );

    if (result == true && mounted) {
      await _refreshProducts();
    }
  }

  // Delete product after confirmation.
  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text(
          'Delete Product?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${product['name']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteProduct(product['id'].toString());

      if (!mounted) return;

      await _refreshProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete product: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Navigate to add product screen.
  Future<void> _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );

    if (result == true && mounted) {
      await _refreshProducts();
    }
  }

  Future<void> _quickAddProduct() async {
    // Open barcode scanner.
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    final cleanBarcode = barcode.trim();

    // First, check SYNCORA's own database.
    Map<String, dynamic>? existingProduct;

    try {
      existingProduct = await _service.getProductByBarcode(cleanBarcode);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check existing products: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    if (!mounted) return;

    // If already registered, open its Edit Product screen.
    if (existingProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product already exists. Opening product details.'),
        ),
      );

      await _editProduct(existingProduct);
      return;
    }

    // Otherwise, try the external product database.
    Map<String, dynamic>? details;

    try {
      details = await _service.lookupElectronicsProduct(cleanBarcode);
    } catch (e) {
      debugPrint('External product lookup failed: $e');
    }

    if (!mounted) return;

    // Open Add Product with any available details.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          initialBarcode: cleanBarcode,
          initialName: details?['name']?.toString(),
          initialDescription: details?['description']?.toString(),
          initialImageUrl: details?['image_url']?.toString(),
        ),
      ),
    );

    if (result == true && mounted) {
      await _refreshProducts();
    } else if (mounted && details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No product details found online. You can enter them manually.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Product Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_canManageProducts)
            if (_canManageProducts)
              IconButton(
                tooltip: 'Quick Add by Barcode',
                onPressed: _quickAddProduct,
                icon: const Icon(Icons.qr_code_scanner, color: accentColor),
              ),
          IconButton(
            tooltip: 'Add Product',
            onPressed: _addProduct,
            icon: const Icon(Icons.add_circle_outline, color: accentColor),
          ),
          IconButton(
            onPressed: _refreshProducts,
            icon: const Icon(Icons.refresh, color: accentColor),
            tooltip: 'Refresh products',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage your inventory',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // Product search.
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _loadProducts(search: value.trim());
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU or barcode...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: accentColor),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _loadProducts();
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.white54),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // Product list.
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: accentColor),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load products:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: backgroundColor,
                              ),
                              onPressed: _refreshProducts,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    final products = snapshot.data ?? [];

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 55,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No products added yet'
                                  : 'No matching products found',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: accentColor,
                      onRefresh: _refreshProducts,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 1000
                              ? 3
                              : constraints.maxWidth > 650
                              ? 2
                              : 1;

                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 250,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];

                              return _ProductCard(
                                product: product,
                                onEdit: _canManageProducts
                                    ? () => _editProduct(product)
                                    : null,
                                onDelete: _canDeleteProducts
                                    ? () => _deleteProduct(product)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Individual product card.
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ProductCard({required this.product, this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Unnamed Product';

    final sku = product['sku']?.toString() ?? 'No SKU';

    final barcode = product['barcode']?.toString() ?? '';
    final imageUrl = product['image_url']?.toString() ?? '';

    final price = (product['unit_price'] as num?)?.toDouble() ?? 0;

    final stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;

    final threshold = (product['low_stock_threshold'] as num?)?.toInt() ?? 5;

    final category = product['categories'];

    final categoryName = category is Map
        ? category['name']?.toString() ?? 'Uncategorized'
        : 'Uncategorized';

    final isLowStock = stock <= threshold;
    final isActive = product['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1118),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white30,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white30,
                      ),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF00D68F),
                    size: 20,
                  ),
                  tooltip: 'Edit product',
                ),

              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white54,
                    size: 20,
                  ),
                  tooltip: 'Delete product',
                ),
            ],
          ),

          Text(
            'SKU: $sku',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (barcode.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Barcode: $barcode',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],

          const SizedBox(height: 8),

          Text(
            categoryName,
            style: const TextStyle(color: Color(0xFF00D68F), fontSize: 12),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$stock in stock',
                style: TextStyle(
                  color: isLowStock
                      ? Colors.orangeAccent
                      : const Color(0xFF00D68F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _StatusLabel(
                text: isLowStock ? 'Low Stock' : 'Stock Healthy',
                color: isLowStock
                    ? Colors.orangeAccent
                    : const Color(0xFF00D68F),
              ),
              const Spacer(),
              _StatusLabel(
                text: isActive ? 'Active' : 'Inactive',
                color: isActive ? Colors.blueAccent : Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Product status label.
class _StatusLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
