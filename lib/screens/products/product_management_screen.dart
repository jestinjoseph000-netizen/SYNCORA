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
  static const Color surfaceColor = Color(0xFF111923);
  static const Color cardColor = Color(0xFF1C2733);
  static const Color accentColor = Color(0xFF00D68F);
  static const Color mutedColor = Color(0xFF91A0AF);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadPermissions();
  }

  void _loadProducts({String search = ''}) {
    _productsFuture = _service.getProducts(searchQuery: search);
  }

  Future<void> _refreshProducts() async {
    if (!mounted) return;

    setState(() {
      _loadProducts(search: _searchController.text.trim());
    });

    try {
      await _productsFuture;
    } catch (_) {}
  }

  Future<void> _loadPermissions() async {
    try {
      final role = await AuthService().getCurrentUserRole();

      if (!mounted) return;

      setState(() {
        _canManageProducts = role == 'admin' || role == 'staff';
        _canDeleteProducts = role == 'admin';
      });
    } catch (error) {
      debugPrint('Permission loading error: $error');
    }
  }

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

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Product?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${product['name']}"?',
          style: const TextStyle(color: mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: mutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
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
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    final cleanBarcode = barcode.trim();

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

    if (existingProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product already exists. Opening product details.'),
        ),
      );

      await _editProduct(existingProduct);
      return;
    }

    Map<String, dynamic>? details;

    try {
      details = await _service.lookupElectronicsProduct(cleanBarcode);
    } catch (e) {
      debugPrint('External product lookup failed: $e');
    }

    if (!mounted) return;

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: RefreshIndicator(
                    color: accentColor,
                    onRefresh: _refreshProducts,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 28,
                        12,
                        isMobile ? 16 : 28,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageIntroduction(isMobile),
                          const SizedBox(height: 24),
                          _buildSearchSection(isMobile),
                          const SizedBox(height: 24),
                          _buildProductHeading(isMobile),
                          const SizedBox(height: 16),
                          _buildProductList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFF263442), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.all_inclusive_rounded,
              color: accentColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNCORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'INVENTORY MANAGEMENT',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          if (_canManageProducts)
            _headerAction(
              icon: Icons.qr_code_scanner_rounded,
              tooltip: 'Quick Add by Barcode',
              onPressed: _quickAddProduct,
            ),
          const SizedBox(width: 6),
          _headerAction(
            icon: Icons.add_rounded,
            tooltip: 'Add Product',
            onPressed: _addProduct,
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted ? accentColor : cardColor,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onPressed,
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(
              icon,
              color: highlighted ? backgroundColor : accentColor,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIntroduction(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 23 : 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Manage, organize and monitor your product catalogue.',
          style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accentColor.withValues(alpha: 0.18)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: accentColor, size: 7),
              SizedBox(width: 8),
              Text(
                'PRODUCT CATALOGUE',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 13 : 17),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find a product',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (value) {
              setState(() {
                _loadProducts(search: value.trim());
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, SKU or barcode...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: accentColor),
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
              filled: true,
              fillColor: backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF263442)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeading(bool isMobile) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 23,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Your Products',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.grid_view_rounded, color: mutedColor, size: 17),
        const SizedBox(width: 7),
        const Text(
          'CATALOGUE',
          style: TextStyle(
            color: mutedColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 75),
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load products',
            message: snapshot.error.toString(),
            action: ElevatedButton(
              onPressed: _refreshProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
              ),
              child: const Text('Try Again'),
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return _buildMessage(
            icon: Icons.inventory_2_outlined,
            title: _searchController.text.isEmpty
                ? 'No products added yet'
                : 'No matching products found',
            message: _searchController.text.isEmpty
                ? 'Your product catalogue is currently empty.'
                : 'Try searching with a different name, SKU or barcode.',
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 258,
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
        );
      },
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: mutedColor, size: 43),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ProductCard({required this.product, this.onDelete, this.onEdit});

  static const Color surfaceColor = Color(0xFF111923);
  static const Color cardColor = Color(0xFF1C2733);
  static const Color accentColor = Color(0xFF00D68F);
  static const Color mutedColor = Color(0xFF91A0AF);

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
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.inventory_2_outlined,
                          color: mutedColor,
                          size: 25,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: mutedColor,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: mutedColor,
                    size: 21,
                  ),
                  color: cardColor,
                  tooltip: 'Product actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: accentColor,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Edit product',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete product',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  color: mutedColor,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'SKU: $sku',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedColor, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (barcode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Barcode: $barcode',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: mutedColor, fontSize: 10),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '₹${price.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$stock in stock',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusLabel(
                text: isLowStock ? 'LOW STOCK' : 'HEALTHY',
                color: statusColor,
              ),
              const Spacer(),
              _StatusLabel(
                text: isActive ? 'ACTIVE' : 'INACTIVE',
                color: isActive ? Colors.blueAccent : mutedColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
