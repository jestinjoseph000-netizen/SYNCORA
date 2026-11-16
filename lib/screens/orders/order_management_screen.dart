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

      try {
        invoice = await _invoiceService.getInvoiceForOrder(
          order['id'].toString(),
        );
      } catch (invoiceError) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to check invoice: $invoiceError')),
        );
      }

      if (!mounted) return;

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
                                    style: const TextStyle(color: Colors.white),
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
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close', style: TextStyle(color: _accent)),
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

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to load order: $e')));
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

// ============================================================
// CREATE ORDER SCREEN
// ============================================================

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
  static const Color _surface = Color(0xFF111923);
  static const Color _card = Color(0xFF151F2A);
  static const Color _raised = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _muted = Color(0xFF91A0AF);

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
        _selectedProductId = null;
        _isLoading = false;
        _error = null;
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

  int get _totalItems {
    return _cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }

  void _addToCart() {
    if (_selectedProductId == null) {
      _showMessage('Please select a product.');
      return;
    }

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

    _showMessage('Product added to order.');
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
        const SnackBar(
          content: Text('Order created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
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

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accent, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.3),
      ),
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(22),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }

  Widget _buildCustomerSection() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Customer Information',
            'Choose the customer for this order',
            Icons.person_outline_rounded,
          ),
          _fieldLabel('Select Customer'),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedCustomerId),
            initialValue: _selectedCustomerId,
            dropdownColor: _raised,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              hint: 'Choose a customer',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: _muted,
                size: 19,
              ),
            ),
            hint: const Text(
              'Choose a customer',
              style: TextStyle(color: Colors.white38),
            ),
            items: _customers.map((customer) {
              return DropdownMenuItem<String>(
                value: customer['id'].toString(),
                child: Text(
                  customer['name'] ?? 'Customer',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCustomerId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a customer.';
              }
              return null;
            },
          ),
          if (_selectedCustomerId != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: _accent,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _customers.firstWhere(
                            (customer) =>
                                customer['id'].toString() ==
                                _selectedCustomerId,
                          )['name'] ??
                          'Customer selected',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'SELECTED',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    final product = _selectedProduct;

    final stock = product == null
        ? 0
        : (product['stock_quantity'] as num).toInt();

    final price = product == null
        ? 0.0
        : (product['unit_price'] as num).toDouble();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Add Products',
            'Select products and specify quantities',
            Icons.inventory_2_outlined,
          ),
          _fieldLabel('Select Product'),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedProductId),
            initialValue: _selectedProductId,
            dropdownColor: _raised,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              hint: 'Choose a product',
              prefixIcon: const Icon(
                Icons.inventory_2_outlined,
                color: _muted,
                size: 19,
              ),
            ),
            hint: const Text(
              'Choose a product',
              style: TextStyle(color: Colors.white38),
            ),
            isExpanded: true,
            items: _products.map((product) {
              return DropdownMenuItem<String>(
                value: product['id'].toString(),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${product['name']} — ₹${product['unit_price']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProductId = value;
              });
            },
          ),
          if (product != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${price.toStringAsFixed(2)} per unit',
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$stock',
                        style: TextStyle(
                          color: stock > 0 ? _accent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'IN STOCK',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _fieldLabel('Quantity'),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter quantity',
              prefixIcon: const Icon(
                Icons.numbers_rounded,
                color: _muted,
                size: 19,
              ),
            ),
            validator: (value) {
              final quantity = int.tryParse(value?.trim() ?? '');

              if (quantity == null || quantity <= 0) {
                return 'Enter a valid quantity.';
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart, size: 19),
              label: const Text(
                'Add to Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(
                  'Order Items',
                  'Review products added to this order',
                  Icons.shopping_bag_outlined,
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
                  '${_cart.length} PRODUCTS',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (_cart.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 15),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white10,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 36,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your order is empty',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Select a product and add it to your order.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ..._cart.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final product = item['product'] as Map<String, dynamic>;
              final quantity = item['quantity'] as int;
              final price = (product['unit_price'] as num).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: _raised,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: _accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Product',
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
                            '$quantity × ₹${price.toStringAsFixed(2)}',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${(price * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        InkWell(
                          onTap: () => _removeFromCart(index),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 13,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (_cart.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            _summaryRow('Total products', '${_cart.length}'),
            const SizedBox(height: 10),
            _summaryRow('Total quantity', '$_totalItems units'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _accent.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER TOTAL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Final amount',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '₹${_total.toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _background,
          disabledBackgroundColor: _accent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 21,
                width: 21,
                child: CircularProgressIndicator(
                  color: _background,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 19),
                  SizedBox(width: 9),
                  Text(
                    'Place Order',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildCustomerSection(),
                const SizedBox(height: 18),
                _buildProductSection(),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildCartSection(),
                const SizedBox(height: 18),
                _buildOrderButton(),
                const SizedBox(height: 12),
                const Text(
                  'Stock will be adjusted automatically after order creation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCustomerSection(),
          const SizedBox(height: 16),
          _buildProductSection(),
          const SizedBox(height: 16),
          _buildCartSection(),
          const SizedBox(height: 18),
          _buildOrderButton(),
          const SizedBox(height: 12),
          const Text(
            'Stock will be adjusted automatically after order creation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Preparing your order form...',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load order form',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadFormData();
                },
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _background,
                ),
              ),
            ],
          ),
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create New Order',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 950;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 30 : 18,
                    vertical: 25,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(23),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF142B28), Color(0xFF111923)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ORDER CREATION',
                                        style: TextStyle(
                                          color: _accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Text(
                                        'Create a new order',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isDesktop ? 25 : 21,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      const Text(
                                        'Select a customer, add products, and review your order before placing it.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 15),
                                  Container(
                                    height: 65,
                                    width: 65,
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: _accent,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isDesktop)
                            _buildDesktopLayout()
                          else
                            _buildMobileLayout(),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
