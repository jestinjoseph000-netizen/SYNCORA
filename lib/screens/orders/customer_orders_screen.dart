
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';
import '../invoices/invoice_preview_screen.dart';
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  final InvoiceService _invoiceService = InvoiceService();

  late Future<List<Map<String, dynamic>>> _ordersFuture;

  static const Color _background = Color(0xFF090B10);
  static const Color _card = Color(0xFF151922);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = _orderService.getCustomerOrders();
  }

  void _refreshOrders() {
    setState(() {
      _loadOrders();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF00D68F);
      case 'processing':
        return Colors.blueAccent;
      case 'confirmed':
        return Colors.orangeAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.amber;
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return 'Date unavailable';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }


Future<void> _showOrderDetails(
  Map<String, dynamic> order,
) async {
  Map<String, dynamic>? invoice;

  try {
    invoice = await _invoiceService.getInvoiceForOrder(
      order['id'].toString(),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to check invoice: $error'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  if (!mounted) return;

  final items = List<Map<String, dynamic>>.from(
    order['order_items'] ?? [],
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  order['order_number']?.toString() ?? 'Order',
                  style: const TextStyle(color: Colors.white54),
                ),

                const Divider(height: 28, color: Colors.white12),

                ...items.map((item) {
                  final product =
                      item['products'] as Map<String, dynamic>? ?? {};

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name']?.toString() ??
                                    'Product unavailable',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quantity: ${item['quantity']}',
                                style: const TextStyle(
                                  color: Colors.white54,
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

                const Divider(color: Colors.white12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${order['total']}',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (invoice != null) ...[
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFF080B10),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'View / Download Invoice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoicePreviewScreen(
                              invoiceId: invoice!['id'].toString(),
                              invoiceNumber:
                                  invoice['invoice_number'].toString(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (invoice['status'] == 'cancelled')
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
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
                    'Your invoice will become available once your order is confirmed.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString();
    final color = _statusColor(status);

    final items = List<Map<String, dynamic>>.from(
      order['order_items'] ?? [],
    );

    return Card(
      color: _card,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: _accent,
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
                      horizontal: 11,
                      vertical: 6,
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
                ],
              ),
              const SizedBox(height: 16),

              Text(
                '${items.length} product(s)',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 7),

              Text(
                'Placed on ${_formatDate(order['created_at'])}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${order['total']}',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: _accent,
                        size: 12,
                      ),
                    ],
                  ),
                ],
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
        backgroundColor: _card,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh, color: _accent),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
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
                child: Text(
                  'Unable to load orders.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white38,
                    size: 55,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Your orders will appear here.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _accent,
            onRefresh: () async {
              _refreshOrders();
              await _ordersFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'YOUR ORDER HISTORY',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ...orders.map(_buildOrderCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
