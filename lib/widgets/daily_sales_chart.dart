import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';

class DailySalesChart extends StatefulWidget {
  final int refreshToken;

  const DailySalesChart({super.key, this.refreshToken = 0});

  @override
  State<DailySalesChart> createState() => _DailySalesChartState();
}

class _DailySalesChartState extends State<DailySalesChart> {
  final DashboardService _service = DashboardService();

  late Future<List<Map<String, dynamic>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void didUpdateWidget(covariant DailySalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadSales();
    }
  }

  void _loadSales() {
    _salesFuture = _service.getDailySales();
  }

  Future<void> _refresh() async {
    setState(_loadSales);
    await _salesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                      'Daily Sales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Sales performance · Last 7 days',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, color: Color(0xFF00D68F)),
              ),
            ],
          ),
          const SizedBox(height: 25),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _salesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00D68F)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Unable to load sales data: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              final sales = snapshot.data ?? [];

              if (sales.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 42,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No sales data available yet',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Your sales chart will appear here.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...sales.map((item) {
                    final amount = (item['total_sales'] as num).toDouble();

                    final date = DateTime.parse(item['sale_date'].toString());

                    final orders = item['total_orders'];

                    final maxSales = sales
                        .map((e) => (e['total_sales'] as num).toDouble())
                        .reduce((a, b) => a > b ? a : b);

                    final percentage = maxSales > 0 ? amount / maxSales : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '₹${amount.toStringAsFixed(2)} · $orders orders',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 11,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF00D68F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
