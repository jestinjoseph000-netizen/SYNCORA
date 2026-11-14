
import 'package:flutter/material.dart';
import '../dashboard/customer_dashboard.dart';
import '../dashboard/admin_dashboard.dart';
import '../../services/auth_service.dart';
import '../landing/landing_page.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.currentAuthStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data?.session?.user ??
            authService.currentUser;

        if (user == null) {
          return const LandingPage();
        }

        return RoleRedirect(
          key: ValueKey(user.id),
        );
      },
    );
  }
}

class RoleRedirect extends StatelessWidget {
  const RoleRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF090B10),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D68F),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF090B10),
            body: Center(
              child: Text(
                'Unable to load your account role.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        switch (snapshot.data) {
          case 'admin':
          return const AdminDashboard();

          case 'manager':
            return const RolePlaceholder(
              role: 'Manager Dashboard',
            );

          case 'staff':
            return const RolePlaceholder(
              role: 'Staff Dashboard',
            );

          case 'customer':
             return const CustomerDashboard();

          default:
            return const Scaffold(
              backgroundColor: Color(0xFF090B10),
              body: Center(
                child: Text(
                  'Invalid user role.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
        }
      },
    );
  }
}

class RolePlaceholder extends StatelessWidget {
  final String role;

  const RolePlaceholder({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151922),
        title: const Text('SYNCORA'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          role,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
