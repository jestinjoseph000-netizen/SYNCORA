
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../landing/landing_page.dart';
import '../dashboard/admin_dashboard.dart';
import '../dashboard/staff_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.currentAuthStateChanges,
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

          case 'staff':
            return const StaffDashboard();

          case 'manager':
          case 'customer':
            return const Scaffold(
              backgroundColor: Color(0xFF090B10),
              body: Center(
                child: Text(
                  'Your account does not have dashboard access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );

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
