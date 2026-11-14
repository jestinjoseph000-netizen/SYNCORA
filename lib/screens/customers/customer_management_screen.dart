import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/customer_service.dart';
import '../../services/auth_service.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final CustomerService _service = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  bool _canDeleteCustomers = false;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  static const Color _background = Color(0xFF080B10);
  static const Color _card = Color(0xFF151B24);
  static const Color _accent = Color(0xFF00D68F);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final role = await AuthService().getCurrentUserRole();

      if (!mounted) return;

      setState(() {
        _canDeleteCustomers = role == 'admin';
      });
    } catch (e) {
      debugPrint('Permission loading error: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers({String search = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await _service.getCustomers(searchQuery: search);

      if (!mounted) return;

      setState(() {
        _customers = customers;
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadCustomers(search: value),
    );
  }

  Future<void> _addCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
    );

    if (result == true && mounted) {
      _loadCustomers(search: _searchController.text);
    }
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    );

    if (result == true && mounted) {
      _loadCustomers(search: _searchController.text);
    }
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    if (!_canDeleteCustomers) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Delete Customer?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${customer['name']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _background,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCustomer(customer['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted successfully.')),
      );

      _loadCustomers(search: _searchController.text);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete customer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] ?? 'Unnamed Customer';
    final email = customer['email'] ?? 'No email provided';
    final phone = customer['phone'] ?? 'No phone provided';

    return Container(
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
              CircleAvatar(
                radius: 23,
                backgroundColor: _accent.withValues(alpha: 0.15),
                child: Text(
                  name.toString().isNotEmpty
                      ? name.toString()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _customerInfo(Icons.email_outlined, email.toString()),
          const SizedBox(height: 10),
          _customerInfo(Icons.phone_outlined, phone.toString()),
          const SizedBox(height: 10),
          _customerInfo(
            Icons.location_on_outlined,
            (customer['address'] ?? 'No address provided').toString(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editCustomer(customer),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_canDeleteCustomers)
                IconButton(
                  tooltip: 'Delete customer',
                  onPressed: () => _deleteCustomer(customer),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        backgroundColor: const Color(0xFF0D121A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Customer Management',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadCustomers(search: _searchController.text),
            icon: const Icon(Icons.refresh),
            color: Color(0xFF00D68F),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        backgroundColor: _accent,
        foregroundColor: _background,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Add Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search customers by name, email or phone...',
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
                            'Unable to load customers.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _background,
                            ),
                            onPressed: () =>
                                _loadCustomers(search: _searchController.text),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _customers.isEmpty
                ? const Center(
                    child: Text(
                      'No customers found.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        _loadCustomers(search: _searchController.text),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 950
                            ? 3
                            : constraints.maxWidth > 600
                            ? 2
                            : 1;

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                          itemCount: _customers.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 260,
                              ),
                          itemBuilder: (context, index) {
                            return _buildCustomerCard(_customers[index]);
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

// Add and edit customer form

class CustomerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final CustomerService _service = CustomerService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  static const Color _accent = Color(0xFF00D68F);
  static const Color _background = Color(0xFF080B10);

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.customer?['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.customer?['phone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?['address'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _service.updateCustomer(
          id: widget.customer!['id'].toString(),
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
      } else {
        await _service.addCustomer(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Customer updated successfully.'
                : 'Customer added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save customer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: _accent),
          filled: true,
          fillColor: const Color(0xFF151B24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required.';
                }
                return null;
              }
            : null,
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
        title: Text(
          _isEditing ? 'Edit Customer' : 'Add Customer',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    requiredField: true,
                  ),
                  _buildField(
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildField(
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildField(
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    controller: _addressController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _background,
                        disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _background,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update Customer' : 'Save Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
