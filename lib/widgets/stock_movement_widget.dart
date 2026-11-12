
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class StockMovementWidget extends StatefulWidget {
  const StockMovementWidget({super.key});

  @override
  State<StockMovementWidget> createState() =>
      _StockMovementWidgetState();
}

class _StockMovementWidgetState extends State<StockMovementWidget> {
  final DashboardService _service = DashboardService();

  late Future<List<Map<String, dynamic>>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  void _loadMovements() {
    _movementsFuture = _service.getStockMovements();
  }

  Future<void> _refresh() async {
    setState(_loadMovements);
    await _movementsFuture;
  }

  Color _movementColor(String type) {
    switch (type.toUpperCase()) {
      case 'STOCK_IN':
        return const Color(0xFF00D68F);
      case 'STOCK_OUT':
        return Colors.orangeAccent;
      case 'ORDER_DEDUCTION':
        return Colors.blueAccent;
      case 'ORDER_RESTOCK':
        return Colors.purpleAccent;
      default:
        return Colors.white70;
    }
  }

  String _movementLabel(String type) {
    switch (type.toUpperCase()) {
      case 'STOCK_IN':
        return 'Stock In';
      case 'STOCK_OUT':
        return 'Stock Out';
      case 'ORDER_DEDUCTION':
        return 'Order Deduction';
      case 'ORDER_RESTOCK':
        return 'Order Restock';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  IconData _movementIcon(String type) {
    switch (type.toUpperCase()) {
      case 'STOCK_IN':
        return Icons.add_circle_outline;
      case 'STOCK_OUT':
        return Icons.remove_circle_outline;
      case 'ORDER_DEDUCTION':
        return Icons.shopping_cart_outlined;
      case 'ORDER_RESTOCK':
        return Icons.inventory_2_outlined;
      default:
        return Icons.swap_horiz;
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Unknown date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Movement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Recent inventory activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF00D68F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _movementsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D68F),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'Unable to load stock movements:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                );
              }

              final movements = snapshot.data ?? [];

              if (movements.isEmpty) {
                return const SizedBox(
                  height: 170,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 42,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No stock movements yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Inventory activity will appear here.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: movements.map((item) {
                  final type =
                      item['movement_type'].toString();

                  final color = _movementColor(type);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _movementIcon(type),
                            color: color,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product_name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                _movementLabel(type),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Text(
                                'Stock: ${item['stock_before']} → ${item['stock_after']}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),

                              if (item['note'] != null &&
                                  item['note'].toString().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  item['note'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 5),

                              Text(
                                _formatDate(item['created_at']),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          '${type == 'STOCK_IN' || type == 'ORDER_RESTOCK' ? '+' : '-'}${item['quantity']}',
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
