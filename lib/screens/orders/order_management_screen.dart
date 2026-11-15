import 'package:flutter/material.dart';
import '../../services/invoice_service.dart';
import '../invoices/invoice_preview_screen.dart';
import '../../services/order_service.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const Color _background = Color(0xFF080B10);
  static const Color _card = Color(0xFF151B24);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _changeOrderStatus(String orderId, String newStatus) async {
    // Ask for confirmation before cancelling an order.
    if (newStatus == 'cancelled') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Cancel Order?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will cancel the order and restore its products to inventory. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase()}.'),
        ),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to update order: $e')));
    }
  }

  List<String> _availableStatusActions(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['processing', 'cancelled'];
      case 'processing':
        return ['completed', 'cancelled'];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.getOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
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

  List<Map<String, dynamic>> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _orders;

    return _orders.where((order) {
      final orderNumber = (order['order_number'] ?? '')
          .toString()
          .toLowerCase();

      final customer = order['customers'];
      final customerName = customer is Map
          ? (customer['name'] ?? '').toString().toLowerCase()
          : '';

      return orderNumber.contains(query) || customerName.contains(query);
    }).toList();
  }

  Future<void> _openCreateOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
    );

    if (result == true && mounted) {
      _loadOrders();
    }
  }


Future<void> _showOrderDetails(Map<String, dynamic> order) async {
  try {
    final details = await _orderService.getOrderDetails(
      order['id'].toString(),
    );

    if (!mounted) return;

    Map<String, dynamic>? invoice;

    // Check whether an invoice has been generated for this order.
    try {
      invoice = await _invoiceService.getInvoiceForOrder(
        order['id'].toString(),
      );
    } catch (invoiceError) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to check invoice: $invoiceError'),
        ),
      );
    }

    if (!mounted) return;

    // Prepare invoice information for the dialog actions.
    final invoiceId = invoice?['id']?.toString();
    final invoiceNumber = invoice?['invoice_number']?.toString();
    final invoiceStatus = invoice?['status']?.toString();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final items = details['order_items'] as List? ?? [];
        final customer = details['customers'] as Map? ?? {};

        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Order ${details['order_number']}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CUSTOMER',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    customer['name'] ?? 'Unknown Customer',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    customer['email'] ?? '',
                    style: const TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'ORDER ITEMS',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...items.map((item) {
                    final product = item['products'] as Map? ?? {};

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'Product',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${item['quantity']} × ₹${item['unit_price']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item['line_total']}',
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(color: Colors.white24),

                  Row(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${details['total']}',
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  if (invoiceId != null) ...[
                    const SizedBox(height: 22),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    const Text(
                      'INVOICE',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      invoiceNumber ?? 'Invoice available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (invoiceStatus == 'cancelled')
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'This invoice has been cancelled.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 18),
                    const Text(
                      'The invoice will become available once this order is confirmed.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: _accent),
              ),
            ),

            if (invoiceId != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(
                        invoiceId: invoiceId,
                        invoiceNumber: invoiceNumber ?? 'SYNCORA-Invoice',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to load order: $e'),
      ),
    );
  }
}


  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return _accent;
      case 'cancelled':
        return Colors.redAccent;
      case 'processing':
        return Colors.blueAccent;
      case 'confirmed':
        return Colors.purpleAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map? ?? {};
    final status = (order['status'] ?? 'pending').toString();
    final color = _statusColor(status);

    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');

    final formattedDate = date == null
        ? 'Date unavailable'
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';

    return InkWell(
      onTap: () => _showOrderDetails(order),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: _accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order['order_number']?.toString() ?? 'Order',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Order status update menu
                if (_availableStatusActions(status).isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Update order status',
                    icon: const Icon(Icons.more_vert, color: _accent),
                    color: _card,
                    onSelected: (newStatus) {
                      _changeOrderStatus(order['id'].toString(), newStatus);
                    },
                    itemBuilder: (context) {
                      return _availableStatusActions(status).map((action) {
                        final isCancelled = action == 'cancelled';

                        return PopupMenuItem<String>(
                          value: action,
                          child: Row(
                            children: [
                              Icon(
                                isCancelled
                                    ? Icons.cancel_outlined
                                    : Icons.arrow_forward,
                                color: isCancelled ? Colors.redAccent : _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                action[0].toUpperCase() + action.substring(1),
                                style: TextStyle(
                                  color: isCancelled
                                      ? Colors.redAccent
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              customer['name'] ?? 'Unknown Customer',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 7),

            Text(
              formattedDate,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const Divider(height: 25, color: Colors.white10),

            Row(
              children: [
                const Text(
                  'Order Total',
                  style: TextStyle(color: Colors.white54),
                ),
                const Spacer(),
                Text(
                  '₹${order['total'] ?? 0}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View details →',
                style: TextStyle(color: _accent, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Order Management',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateOrder,
        backgroundColor: _accent,
        foregroundColor: _background,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text(
          'Create Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search order number or customer...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: _accent),
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
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Unable to load orders.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _background,
                            ),
                            onPressed: _loadOrders,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : RefreshIndicator(
                    color: _accent,
                    onRefresh: _loadOrders,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 950
                            ? 3
                            : constraints.maxWidth > 600
                            ? 2
                            : 1;

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                          itemCount: filteredOrders.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 235,
                              ),
                          itemBuilder: (context, index) {
                            return _buildOrderCard(filteredOrders[index]);
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

// CREATE ORDER SCREEN

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  final _formKey = GlobalKey<FormState>();

  static const Color _background = Color(0xFF080B10);
  static const Color _card = Color(0xFF151B24);
  static const Color _accent = Color(0xFF00D68F);

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  final List<Map<String, dynamic>> _cart = [];

  String? _selectedCustomerId;
  String? _selectedProductId;

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final results = await Future.wait([
        _customerService.getCustomers(),
        _productService.getProducts(),
      ]);

      if (!mounted) return;

      // Keep only active products and remove duplicate IDs.
      final uniqueProducts = <String, Map<String, dynamic>>{};

      for (final product in results[1]) {
        final id = product['id']?.toString();

        if (id != null && id.isNotEmpty && product['is_active'] == true) {
          uniqueProducts[id] = product;
        }
      }

      setState(() {
        _customers = results[0];

        _products = uniqueProducts.values.toList();

        // Reset selection after loading fresh data.
        _selectedProductId = null;

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

  Map<String, dynamic>? get _selectedProduct {
    for (final product in _products) {
      if (product['id'].toString() == _selectedProductId) {
        return product;
      }
    }
    return null;
  }

  double get _total {
    return _cart.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['product']['unit_price'] as num).toDouble() *
              (item['quantity'] as int)),
    );
  }

  void _addToCart() {
    if (_selectedProductId == null) return;

    final product = _selectedProduct;
    final quantity = int.tryParse(_quantityController.text.trim());

    if (product == null || quantity == null || quantity <= 0) {
      _showMessage('Enter a valid quantity.');
      return;
    }

    final stock = (product['stock_quantity'] as num).toInt();

    final existingIndex = _cart.indexWhere(
      (item) => item['product']['id'] == product['id'],
    );

    final alreadyAdded = existingIndex >= 0
        ? _cart[existingIndex]['quantity'] as int
        : 0;

    if (quantity + alreadyAdded > stock) {
      _showMessage('Quantity exceeds available stock.');
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity'] += quantity;
      } else {
        _cart.add({'product': product, 'quantity': quantity});
      }

      _selectedProductId = null;
      _quantityController.text = '1';
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      _showMessage('Please select a customer.');
      return;
    }

    if (_cart.isEmpty) {
      _showMessage('Please add at least one product.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _orderService.createOrder(
        customerId: _selectedCustomerId!,
        productIds: _cart
            .map<String>((item) => item['product']['id'].toString())
            .toList(),
        quantities: _cart.map<int>((item) => item['quantity'] as int).toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to create order: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, top: 18),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create New Order',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load order form.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      const Text(
                        'CUSTOMER INFORMATION',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      _buildLabel('Select Customer'),

                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedCustomerId),
                        initialValue: _selectedCustomerId,
                        dropdownColor: _card,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text(
                          'Choose a customer',
                          style: TextStyle(color: Colors.white54),
                        ),
                        items: _customers.map((customer) {
                          return DropdownMenuItem<String>(
                            value: customer['id'].toString(),
                            child: Text(customer['name'] ?? 'Customer'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomerId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'ADD PRODUCTS',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      _buildLabel('Select Product'),

                      DropdownButtonFormField<String>(
                        initialValue:
                            _products.any(
                              (product) =>
                                  product['id'].toString() ==
                                  _selectedProductId,
                            )
                            ? _selectedProductId
                            : null,
                        dropdownColor: _card,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text(
                          'Choose a product',
                          style: TextStyle(color: Colors.white54),
                        ),
                        items: _products.map((product) {
                          return DropdownMenuItem<String>(
                            value: product['id'].toString(),
                            child: Text(
                              '${product['name']} — ₹${product['unit_price']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                          });
                        },
                      ),

                      _buildLabel('Quantity'),

                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter quantity',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'ORDER ITEMS',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 15),

                      if (_cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No products added yet.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),

                      ..._cart.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final product = item['product'] as Map<String, dynamic>;
                        final quantity = item['quantity'] as int;
                        final price = (product['unit_price'] as num).toDouble();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Product',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '$quantity × ₹$price',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeFromCart(index),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'ORDER TOTAL',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _background,
                            disabledBackgroundColor: _accent.withValues(
                              alpha: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: _background,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Place Order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
