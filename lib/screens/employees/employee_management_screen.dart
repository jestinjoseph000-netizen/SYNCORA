
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

  String _selectedRole = 'staff';

  bool _isLoading = false;
  bool _isDirectoryLoading = false;
  bool _obscurePassword = true;

  String? _directoryError;
  String? _deletingEmployeeId;

  List<Map<String, dynamic>> _employees = [];

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111923);
  static const Color _raised = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _secondaryText = Color(0xFF91A0AF);

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
        role: 'staff',
      );

      if (!mounted) return;

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();

      setState(() {
        _selectedRole = 'staff';
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

  Future<void> _deleteEmployee(
    Map<String, dynamic> employee,
  ) async {
    final employeeId = employee['id']?.toString();
    final employeeName =
        employee['full_name']?.toString() ?? 'this employee';

    if (employeeId == null || employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee ID is missing.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final role = employee['role']?.toString().toLowerCase();

    if (role != 'staff') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Staff accounts can be deleted here.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Staff Account?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $employeeName? '
            'This will remove their login account. '
            'This action cannot be undone.',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _secondaryText),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingEmployeeId = employeeId);

    try {
      await _service.deleteEmployee(employeeId: employeeId);

      if (!mounted) return;

      setState(() {
        _employees.removeWhere(
          (item) => item['id']?.toString() == employeeId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$employeeName was deleted successfully.'),
          backgroundColor: _accent,
        ),
      );
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
        setState(() => _deletingEmployeeId = null);
      }
    }
  }

  int _countRole(String role) {
    return _employees.where((employee) {
      return employee['role']?.toString().toLowerCase() == role;
    }).length;
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: _background,
      labelStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: _accent,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _accent,
            size: 21,
          ),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
Widget _buildRoleCard({
  required String role,
  required String description,
  required IconData icon,
}) {
  final selected = _selectedRole == role;

  return GestureDetector(
    onTap: () {
      setState(() => _selectedRole = role);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: selected
            ? _accent.withValues(alpha: 0.10)
            : _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _accent : Colors.white12,
          width: selected ? 1.3 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: selected
                  ? _accent.withValues(alpha: 0.14)
                  : _raised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? _accent : _secondaryText,
              size: 22,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: selected ? _accent : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: selected ? _accent : Colors.white24,
            size: 17,
          ),
        ],
      ),
    ),
  );
}


  Widget _buildEmployeeForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeading(
              title: 'Employee Information',
              subtitle: 'Enter the details for the new Staff account',
              icon: Icons.person_add_alt_1_rounded,
            ),

            const SizedBox(height: 25),

            const Text(
              'FULL NAME',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: _inputDecoration(
                'Enter full name',
                Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter employee name.';
                }
                return null;
              },
            ),

            const SizedBox(height: 19),

            const Text(
              'EMAIL ADDRESS',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: _inputDecoration(
                'Enter email address',
                Icons.alternate_email_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
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

            const SizedBox(height: 19),

            const Text(
              'TEMPORARY PASSWORD',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: _inputDecoration(
                'Create temporary password',
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _secondaryText,
                    size: 20,
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

            const SizedBox(height: 27),

            Row(
              children: [
                const Text(
                  'ACCOUNT ROLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                const Text(
                  'STAFF',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildRoleCard(
              role: 'staff',
              description: 'Handle daily tasks and operations',
              icon: Icons.badge_outlined,
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _accent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Staff accounts can access daily operational tasks.',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createEmployee,
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
                        Icons.person_add_alt_1_rounded,
                        size: 19,
                      ),
                label: Text(
                  _isLoading
                      ? 'Creating Account...'
                      : 'Create Staff Account',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _background,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.65),
                  disabledForegroundColor: _background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final name =
        employee['full_name']?.toString() ?? 'Unnamed Employee';
    final email =
        employee['email']?.toString() ?? 'No email available';
    final role = employee['role']?.toString() ?? 'unknown';

    final isStaff = role.toLowerCase() == 'staff';
    final roleColor = isStaff ? Colors.blueAccent : _accent;
    final employeeId = employee['id']?.toString();
    final isDeleting = employeeId != null &&
        employeeId == _deletingEmployeeId;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final avatar = Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isStaff
                  ? Icons.badge_outlined
                  : Icons.manage_accounts_outlined,
              color: roleColor,
              size: 23,
            ),
          );

          final employeeDetails = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          final roleBadge = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          );

          final deleteButton = isStaff
              ? IconButton(
                  tooltip: 'Delete Staff account',
                  onPressed: isDeleting
                      ? null
                      : () => _deleteEmployee(employee),
                  icon: isDeleting
                      ? const SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 21,
                        ),
                )
              : const SizedBox.shrink();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    employeeDetails,
                    deleteButton,
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    roleBadge,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 13),
              employeeDetails,
              const SizedBox(width: 8),
              roleBadge,
              if (isStaff) ...[
                const SizedBox(width: 5),
                deleteButton,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmployeeDirectory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeading(
                  title: 'Employee Directory',
                  subtitle: 'Your SYNCORA team accounts',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white10),
                ),
                child: IconButton(
                  tooltip: 'Refresh employees',
                  onPressed:
                      _isDirectoryLoading ? null : _loadEmployees,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 8.0;
              final itemWidth =
                  (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildOverviewStat(
                      label: 'Total',
                      value: _employees.length,
                      icon: Icons.people_alt_outlined,
                      color: _accent,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildOverviewStat(
                      label: 'Staff',
                      value: _countRole('staff'),
                      icon: Icons.badge_outlined,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              const Text(
                'TEAM MEMBERS',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_employees.length}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (_isDirectoryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_directoryError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _directoryError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loadEmployees,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: _accent,
                        size: 17,
                      ),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(color: _accent),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_employees.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 35,
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    color: Colors.white38,
                    size: 38,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No employees found',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'New Staff accounts will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._employees.map(_buildEmployeeCard),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.all_inclusive_rounded,
                color: _accent,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNCORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'TEAM ADMINISTRATION',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 25),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accent.withValues(alpha: 0.20),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: _accent,
                size: 14,
              ),
              SizedBox(width: 7),
              Text(
                'WORKFORCE CONTROL CENTRE',
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

        const SizedBox(height: 13),

        const Text(
          'Employee Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Create and manage the people who keep your operations running.',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Employee Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final horizontalPadding =
              viewportConstraints.maxWidth < 600 ? 16.0 : 28.0;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 25,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),

                    const SizedBox(height: 27),

                    if (viewportConstraints.maxWidth >= 1000)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildEmployeeForm(),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            flex: 6,
                            child: _buildEmployeeDirectory(),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildEmployeeForm(),
                          const SizedBox(height: 24),
                          _buildEmployeeDirectory(),
                        ],
                      ),

                    const SizedBox(height: 25),

                    const Center(
                      child: Text(
                        'SYNCORA  •  SMART INVENTORY & ORDER MANAGEMENT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
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
