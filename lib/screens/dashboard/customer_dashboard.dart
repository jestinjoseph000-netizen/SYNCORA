import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../../widgets/profile_avatar.dart';
import '../../services/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../orders/customer_orders_screen.dart';
import '../customers/customer_catalogue_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  static const Color _background = Color(0xFF090B10);
  static const Color _card = Color(0xFF151922);
  static const Color _accent = Color(0xFF00D68F);

  Future<String> _getCustomerName() async {
    final user = AuthService().currentUser;

    if (user == null) return 'Customer';

    final response = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();

    return response?['full_name']?.toString() ?? 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _card,
        title: Row(
          children: [
            const Icon(Icons.all_inclusive, color: _accent, size: 28),
            const SizedBox(width: 9),
            const Text(
              'SYNCORA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'My Profile',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ProfileAvatar(
                radius: 16,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout, color: _accent),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getCustomerName(),
        builder: (context, snapshot) {
          final name = snapshot.data ?? 'Customer';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Text(
                  'CUSTOMER WORKSPACE',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Welcome, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Manage your shopping and keep track of your orders.',
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                ),

                const SizedBox(height: 35),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withValues(alpha: 0.25)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: _accent,
                        size: 35,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Your SYNCORA account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your customer account is ready. '
                        'Product browsing, ordering and order history '
                        'will be available here.',
                        style: TextStyle(color: Colors.white54, height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Browse Products button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _background,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerCatalogueScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text(
                      'Browse Products',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // My Orders button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerOrdersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text(
                      'My Orders',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
