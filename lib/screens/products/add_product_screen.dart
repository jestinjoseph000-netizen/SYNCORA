
import 'package:flutter/material.dart';

import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');

  List<Map<String, dynamic>> _categories = [];
  String _selectedCategoryId = '';

  bool _isLoadingCategories = true;
  bool _isSaving = false;

  static const Color accentColor = Color(0xFF00D68F);
  static const Color cardColor = Color(0xFF111820);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoadingCategories = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load categories: $error')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _productService.addProduct(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        description: _descriptionController.text.trim(),
        unitPrice: double.parse(_priceController.text.trim()),
        stockQuantity: int.parse(_stockController.text.trim()),
        lowStockThreshold: int.parse(_thresholdController.text.trim()),
        categoryId:
            _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: accentColor,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the product price';
    }

    final price = double.tryParse(value.trim());

    if (price == null || !price.isFinite || price < 0) {
      return 'Enter a valid non-negative price';
    }

    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final number = int.tryParse(value.trim());

    if (number == null || number < 0) {
      return 'Enter a valid non-negative whole number';
    }

    return null;
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            filled: true,
            fillColor: const Color(0xFF0B1118),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: accentColor,
                      size: 36,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the details below to add a product to your inventory.',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 28),

                    _buildField(
                      label: 'Product Name',
                      controller: _nameController,
                      icon: Icons.label_outline,
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'SKU',
                      controller: _skuController,
                      icon: Icons.qr_code,
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Description',
                      controller: _descriptionController,
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: accentColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0B1118),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('No category'),
                        ),
                        ..._categories.map(
                          (category) => DropdownMenuItem<String>(
                            value: category['id'].toString(),
                            child: Text(category['name'].toString()),
                          ),
                        ),
                      ],
                      onChanged: _isLoadingCategories
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCategoryId = value ?? '';
                              });
                            },
                    ),

                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Loading categories...',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),

                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Unit Price',
                      controller: _priceController,
                      icon: Icons.currency_rupee,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePrice,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Initial Stock Quantity',
                      controller: _stockController,
                      icon: Icons.inventory_outlined,
                      keyboardType: TextInputType.number,
                      validator: _validateInteger,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Low Stock Threshold',
                      controller: _thresholdController,
                      icon: Icons.warning_amber_outlined,
                      keyboardType: TextInputType.number,
                      validator: _validateInteger,
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: accentColor.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          _isSaving ? 'Saving Product...' : 'Add Product',
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
      ),
    );
  }
}
