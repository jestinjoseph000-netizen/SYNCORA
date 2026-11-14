
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/product_service.dart';
import '../../services/order_service.dart';

class CustomerCatalogueScreen extends StatefulWidget {
  const CustomerCatalogueScreen({super.key});

  @override
  State<CustomerCatalogueScreen> createState() =>
      _CustomerCatalogueScreenState();
}

class _CustomerCatalogueScreenState
    extends State<CustomerCatalogueScreen> {
  static const Color _background = Color(0xFF090B10);
  static const Color _card = Color(0xFF151922);
  static const Color _accent = Color(0xFF00D68F);

  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _products = [];
  final Map<String, Map<String, dynamic>> _cart = {};

  bool _isLoading = true;
  bool _isPlacingOrder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _productService.getProducts(
        searchQuery: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _products = products
            .where((product) => product['is_active'] == true)
            .toList();
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

  void _addToCart(Map<String, dynamic> product) {
    final id = product['id'].toString();
    final stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;

    if (stock <= 0) {
      _showMessage('This product is out of stock.');
      return;
    }

    final currentQuantity =
        (_cart[id]?['quantity'] as int?) ?? 0;

    if (currentQuantity >= stock) {
      _showMessage('You have reached the available stock limit.');
      return;
    }

    setState(() {
      _cart[id] = {
        'product': product,
        'quantity': currentQuantity + 1,
      };
    });

    _showMessage('Added to cart.');
  }

  void _changeQuantity(String id, int change) {
    final item = _cart[id];
    if (item == null) return;

    final product = item['product'] as Map<String, dynamic>;
    final currentQuantity = item['quantity'] as int;
    final stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;

    final newQuantity = currentQuantity + change;

    if (newQuantity <= 0) {
      setState(() => _cart.remove(id));
      return;
    }

    if (newQuantity > stock) {
      _showMessage('Not enough stock available.');
      return;
    }

    setState(() {
      _cart[id]!['quantity'] = newQuantity;
    });
  }

  int get _cartCount {
    return _cart.values.fold<int>(
      0,
      (total, item) => total + (item['quantity'] as int),
    );
  }

  double get _cartTotal {
    return _cart.values.fold<double>(
      0,
      (total, item) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = item['quantity'] as int;
        final price =
            (product['unit_price'] as num?)?.toDouble() ?? 0;

        return total + (price * quantity);
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _card,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty || _isPlacingOrder) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Confirm Order',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Place your order for ₹${_cartTotal.toStringAsFixed(2)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _background,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPlacingOrder = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in again.');
      }

      // Find the customer record linked to this account.
      final customer = await _supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      final customerId = customer['id'].toString();

      final productIds = <String>[];
      final quantities = <int>[];

      for (final entry in _cart.entries) {
        productIds.add(entry.key);
        quantities.add(entry.value['quantity'] as int);
      }

      await _orderService.createOrder(
        customerId: customerId,
        productIds: productIds,
        quantities: quantities,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _isPlacingOrder = false;
      });

      await _loadProducts();

      if (!mounted) return;

      _showMessage('Order placed successfully!');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isPlacingOrder = false);

      _showMessage('Unable to place order: $e');
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock =
        (product['stock_quantity'] as num?)?.toInt() ?? 0;

    final price =
        (product['unit_price'] as num?)?.toDouble() ?? 0;

    final category = product['categories'] as Map? ?? {};
    final id = product['id'].toString();
    final cartQuantity =
        (_cart[id]?['quantity'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: _accent,
                size: 27,
              ),
              const Spacer(),
              if (stock <= 0)
                const Text(
                  'OUT OF STOCK',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  '$stock available',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            product['name']?.toString() ?? 'Product',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category['name']?.toString() ?? 'General',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SKU: ${product['sku'] ?? '-'}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: stock <= 0
                    ? null
                    : () => _addToCart(product),
                child: Text(
                  cartQuantity > 0
                      ? 'Add more ($cartQuantity)'
                      : 'Add to cart',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Shopping Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_cart.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(25),
                        child: Center(
                          child: Text(
                            'Your cart is empty.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: _cart.entries.map((entry) {
                            final product =
                                entry.value['product']
                                    as Map<String, dynamic>;
                            final quantity =
                                entry.value['quantity'] as int;
                            final price =
                                (product['unit_price'] as num?)
                                        ?.toDouble() ??
                                    0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                product['name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '₹${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: _accent,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _changeQuantity(entry.key, -1);
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: _accent,
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _changeQuantity(entry.key, 1);
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: _accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const Divider(color: Colors.white12),
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Text(
                          '₹${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _background,
                          padding: const EdgeInsets.all(15),
                        ),
                        onPressed: _cart.isEmpty || _isPlacingOrder
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _placeOrder();
                              },
                        child: _isPlacingOrder
                            ? const CircularProgressIndicator(
                                color: _background,
                              )
                            : const Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text(
          'Shop Products',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Shopping cart',
            onPressed: _showCart,
            icon: Badge(
              label: Text('$_cartCount'),
              isLabelVisible: _cartCount > 0,
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: _accent,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProducts,
            icon: const Icon(
              Icons.refresh,
              color: _accent,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadProducts(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products or SKU...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _accent,
                ),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unable to load products.\n$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: _loadProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(
                            child: Text(
                              'No products available.',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: _accent,
                            onRefresh: _loadProducts,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth > 950
                                        ? 3
                                        : constraints.maxWidth > 600
                                            ? 2
                                            : 1;

                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 25,
                                  ),
                                  itemCount: _products.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    mainAxisExtent: 235,
                                  ),
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(
                                      _products[index],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
