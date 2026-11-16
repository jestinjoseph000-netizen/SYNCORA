
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

class _CustomerManagementScreenState
    extends State<CustomerManagementScreen> {
  final CustomerService _service = CustomerService();
  final TextEditingController _searchController =
      TextEditingController();

  bool _canDeleteCustomers = false;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _customers = [];

  Timer? _debounce;
  int _loadRequest = 0;

  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111923);
  static const Color _card = Color(0xFF1C2733);
  static const Color _accent = Color(0xFF00D68F);
  static const Color _secondary = Color(0xFF91A0AF);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadPermissions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadCustomers({String? search}) async {
    if (!mounted) return;

    final request = ++_loadRequest;
    final searchValue = search ?? _searchController.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await _service.getCustomers(
        searchQuery: searchValue,
      );

      if (!mounted || request != _loadRequest) return;

      setState(() {
        _customers = customers;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || request != _loadRequest) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCustomers() async {
    _debounce?.cancel();

    if (!mounted) return;

    await _loadCustomers(
      search: _searchController.text.trim(),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    setState(() {});

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadCustomers(search: value),
    );
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();

    setState(() {});

    _loadCustomers(search: '');
  }

  Future<void> _addCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerFormScreen(),
      ),
    );

    if (result == true && mounted) {
      await _refreshCustomers();
    }
  }

  Future<void> _editCustomer(
    Map<String, dynamic> customer,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerFormScreen(customer: customer),
      ),
    );

    if (result == true && mounted) {
      await _refreshCustomers();
    }
  }

  Future<void> _deleteCustomer(
    Map<String, dynamic> customer,
  ) async {
    if (!_canDeleteCustomers) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete Customer?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${customer['name']}?',
          style: const TextStyle(color: _secondary),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _background,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCustomer(
        customer['id'].toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer deleted successfully.'),
        ),
      );

      await _refreshCustomers();
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

  // HEADER

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172A2A),
            Color(0xFF14212B),
            Color(0xFF111923),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;

          final icon = Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _accent.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: _accent,
              size: 29,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CUSTOMER RELATIONSHIP',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Customer Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Manage customer profiles and keep contact information organized.',
                style: TextStyle(
                  color: _secondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 16),
                content,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 18),
              icon,
            ],
          );
        },
      ),
    );
  }

  // CUSTOMER SUMMARY

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: _accent,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL CUSTOMERS',
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_customers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 13,
                  color: _accent,
                ),
                SizedBox(width: 5),
                Text(
                  'Directory',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name, email or phone...',
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _accent,
            size: 21,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _secondary,
                    size: 18,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _accent,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // SECTION HEADING

  Widget _buildSectionHeading() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Directory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View and manage your registered customers.',
                style: TextStyle(
                  color: _secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_customers.length} records',
          style: const TextStyle(
            color: _accent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // CUSTOMER CARD

  Widget _buildCustomerCard(
    Map<String, dynamic> customer,
  ) {
    final name =
        (customer['name'] ?? 'Unnamed Customer').toString();
    final email =
        (customer['email'] ?? 'No email provided').toString();
    final phone =
        (customer['phone'] ?? 'No phone provided').toString();
    final address =
        (customer['address'] ?? 'No address provided').toString();

    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: _accent,
                          size: 12,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Customer',
                          style: TextStyle(
                            color: _secondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_canDeleteCustomers)
                PopupMenuButton<String>(
                  tooltip: 'Customer actions',
                  color: _card,
                  icon: const Icon(
                    Icons.more_vert,
                    color: _secondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCustomer(customer);
                    } else if (value == 'delete') {
                      _deleteCustomer(customer);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit customer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete customer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 15),
          _customerInfo(Icons.email_outlined, email),
          const SizedBox(height: 12),
          _customerInfo(Icons.phone_outlined, phone),
          const SizedBox(height: 12),
          _customerInfo(Icons.location_on_outlined, address),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _editCustomer(customer),
              icon: const Icon(
                Icons.edit_outlined,
                size: 15,
              ),
              label: const Text(
                'Edit Customer',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: BorderSide(
                  color: _accent.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerInfo(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: _accent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: _accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'No customers found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try another search term or clear your search.'
                  : 'Add your first customer to start building your directory.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear search'),
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.orangeAccent,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load customers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshCustomers,
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
    );
  }

  // MAIN SCREEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: _accent,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        backgroundColor: _accent,
        foregroundColor: _background,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, pageConstraints) {
            final width = pageConstraints.maxWidth;

            final horizontalPadding = width < 400
                ? 14.0
                : width < 700
                    ? 18.0
                    : 25.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1400,
                ),
                child: RefreshIndicator(
                  color: _accent,
                  backgroundColor: _card,
                  onRefresh: _refreshCustomers,
                  child: CustomScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // HEADER
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          14,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                      ),

                      // SUMMARY
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSummaryCard(),
                        ),
                      ),

                      // SEARCH
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          18,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSearchField(),
                        ),
                      ),

                      // DIRECTORY HEADING
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          15,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSectionHeading(),
                        ),
                      ),

                      // LOADING
                      if (_isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _accent,
                            ),
                          ),
                        )

                      // ERROR
                      else if (_error != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildErrorState(),
                        )

                      // EMPTY
                      else if (_customers.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )

                      // CUSTOMER GRID
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            110,
                          ),
                          sliver: SliverLayoutBuilder(
                            builder: (context, gridConstraints) {
                              final availableWidth =
                                  gridConstraints.crossAxisExtent;

                              final gridColumns =
                                  availableWidth >= 950
                                      ? 3
                                      : availableWidth >= 580
                                          ? 2
                                          : 1;

                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridColumns,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  mainAxisExtent: 285,
                                ),
                                delegate:
                                    SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _buildCustomerCard(
                                      _customers[index],
                                    );
                                  },
                                  childCount: _customers.length,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADD / EDIT CUSTOMER FORM
// -----------------------------------------------------------------------------

class CustomerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;

  const CustomerFormScreen({
    super.key,
    this.customer,
  });

  @override
  State<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState
    extends State<CustomerFormScreen> {
  final CustomerService _service = CustomerService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  static const Color _accent = Color(0xFF00D68F);
  static const Color _background = Color(0xFF080B10);
  static const Color _surface = Color(0xFF111923);
  static const Color _secondary = Color(0xFF91A0AF);

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
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
              prefixIcon: Icon(
                icon,
                color: _accent,
                size: 19,
              ),
              alignLabelWithHint: maxLines > 1,
              filled: true,
              fillColor: const Color(0xFF151F2A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _accent,
                  width: 1.2,
                ),
              ),
            ),
            validator: requiredField
                ? (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return '$label is required.';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172A2A),
            Color(0xFF111923),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _accent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_note_rounded
                  : Icons.person_add_alt_1_rounded,
              color: _accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'UPDATE CUSTOMER'
                      : 'NEW CUSTOMER',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isEditing
                      ? 'Edit Customer Details'
                      : 'Add a New Customer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Keep customer information accurate and up to date.',
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.contact_page_outlined,
                color: _accent,
                size: 19,
              ),
              SizedBox(width: 10),
              Text(
                'Personal Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Enter the customer contact details below.',
            style: TextStyle(
              color: _secondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 22),
          _buildField(
            label: 'Full Name *',
            hint: 'Enter customer full name',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            requiredField: true,
          ),
          _buildField(
            label: 'Email Address',
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildField(
            label: 'Phone Number',
            hint: 'Enter phone number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          _buildField(
            label: 'Address',
            hint: 'Enter customer address',
            icon: Icons.location_on_outlined,
            controller: _addressController,
            maxLines: 3,
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving ? null : _saveCustomer,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _background,
                      ),
                    )
                  : Icon(
                      _isEditing
                          ? Icons.save_outlined
                          : Icons.person_add_alt_1_rounded,
                      size: 19,
                    ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : _isEditing
                        ? 'Update Customer'
                        : 'Save Customer',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                disabledBackgroundColor:
                    _accent.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: _accent,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 400 ? 14 : 18,
                    18,
                    constraints.maxWidth < 400 ? 14 : 18,
                    35,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _buildFormHeader(),
                        const SizedBox(height: 20),
                        _buildFormSection(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
