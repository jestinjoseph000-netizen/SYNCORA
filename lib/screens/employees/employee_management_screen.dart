
import 'package:flutter/material.dart';

import '../../services/employee_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState
    extends State<EmployeeManagementScreen> {
  final EmployeeService _service = EmployeeService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'manager';

  bool _isLoading = false;
  bool _isDirectoryLoading = false;
  bool _obscurePassword = true;

  String? _directoryError;

  List<Map<String, dynamic>> _employees = [];

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111821);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isDirectoryLoading = true;
      _directoryError = null;
    });

    try {
      final employees = await _service.getEmployees();

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isDirectoryLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _directoryError =
            error.toString().replaceFirst('Exception: ', '');
        _isDirectoryLoading = false;
      });
    }
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _service.createEmployee(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();

      setState(() {
        _selectedRole = 'manager';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['role']} account created successfully.',
          ),
          backgroundColor: _accent,
        ),
      );

      await _loadEmployees();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _accent),
      filled: true,
      fillColor: _surface,
      labelStyle: const TextStyle(color: Colors.white60),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String description,
    required IconData icon,
  }) {
    final selected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.12)
                : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? _accent : Colors.white54,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: selected ? _accent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final name = employee['full_name']?.toString() ?? 'Unnamed Employee';
    final email = employee['email']?.toString() ?? 'No email available';
    final role = employee['role']?.toString() ?? 'unknown';

    final isManager = role == 'manager';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _accent.withValues(alpha: 0.12),
            child: Icon(
              isManager
                  ? Icons.manage_accounts_outlined
                  : Icons.badge_outlined,
              color: _accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: _accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDirectory() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Employee Directory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh employees',
                onPressed:
                    _isDirectoryLoading ? null : _loadEmployees,
                icon: const Icon(
                  Icons.refresh,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_employees.length} employee accounts',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (_isDirectoryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: _accent,
                ),
              ),
            )
          else if (_directoryError != null)
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _directoryError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadEmployees,
                    icon: const Icon(
                      Icons.refresh,
                      color: _accent,
                    ),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(color: _accent),
                    ),
                  ),
                ],
              ),
            )
          else if (_employees.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.white38,
                      size: 38,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No employees found.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._employees.map(_buildEmployeeCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'Employee Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Employee Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create manager and staff accounts for your SYNCORA team.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Employee Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 22),

                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Full Name',
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter employee name.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Email Address',
                            Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter email address.';
                            }

                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value.trim())) {
                              return 'Enter a valid email address.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Temporary Password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _accent,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must contain at least 8 characters.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          'Select Employee Role',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            _buildRoleCard(
                              role: 'manager',
                              description: 'Manage operations',
                              icon: Icons.manage_accounts_outlined,
                            ),
                            const SizedBox(width: 12),
                            _buildRoleCard(
                              role: 'staff',
                              description: 'Handle daily tasks',
                              icon: Icons.badge_outlined,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _createEmployee,
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _background,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_alt_1,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Creating Account...'
                                  : 'Create Employee Account',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _background,
                              disabledBackgroundColor: _accent,
                              disabledForegroundColor: _background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _buildEmployeeDirectory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
