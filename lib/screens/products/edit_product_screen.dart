import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditProductScreen({super.key, required this.product});
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();
  final _picker = ImagePicker();
  late final TextEditingController _name,
      _sku,
      _barcode,
      _description,
      _price,
      _threshold;
  List<Map<String, dynamic>> _categories = [];
  String _categoryId = '';
  XFile? _newImage;
  bool _removeImage = false, _loadingCategories = true, _saving = false;
  static const accent = Color(0xFF00D68F);
  static const card = Color(0xFF111820);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final category = p['categories'];
    _name = TextEditingController(text: p['name']?.toString() ?? '');
    _sku = TextEditingController(text: p['sku']?.toString() ?? '');
    _barcode = TextEditingController(text: p['barcode']?.toString() ?? '');
    _description = TextEditingController(
      text: p['description']?.toString() ?? '',
    );
    _price = TextEditingController(text: p['unit_price']?.toString() ?? '0');
    _threshold = TextEditingController(
      text: p['low_stock_threshold']?.toString() ?? '5',
    );
    if (category is Map && category['id'] != null) {
      _categoryId = category['id'].toString();
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await _service.getCategories();
      if (!mounted) return;
      final current = widget.product['category_id']?.toString() ?? '';
      setState(() {
        _categories = rows;
        _categoryId = rows.any((c) => c['id'].toString() == current)
            ? current
            : '';
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      _message('Could not load categories: $e', error: true);
    }
  }

  void _message(String value, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value),
          backgroundColor: error ? Colors.redAccent : accent,
        ),
      );

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > ProductService.maxImageBytes) {
        _message('Choose an image smaller than 5 MB.', error: true);
        return;
      }
      setState(() {
        _newImage = picked;
        _removeImage = false;
      });
    } catch (e) {
      _message('Could not select image: $e', error: true);
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updateProduct(
        id: widget.product['id'].toString(),
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        barcode: _barcode.text,
        description: _description.text.trim(),
        unitPrice: double.parse(_price.text.trim()),
        lowStockThreshold: int.parse(_threshold.text.trim()),
        categoryId: _categoryId.isEmpty ? null : _categoryId,
        imageFile: _newImage,
        removeImage: _removeImage,
      );
      if (!mounted) return;
      _message('Product updated successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message('Failed to update product: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'This field is required' : null;
  String? _priceValidator(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    return n == null || !n.isFinite || n < 0
        ? 'Enter a valid non-negative price'
        : null;
  }

  String? _intValidator(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return n == null || n < 0
        ? 'Enter a valid non-negative whole number'
        : null;
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white30),
    prefixIcon: Icon(icon, color: accent, size: 20),
    filled: true,
    fillColor: const Color(0xFF0B1118),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
      borderSide: const BorderSide(color: accent),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int lines = 1,
  }) => Column(
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
        maxLines: lines,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label, icon),
      ),
    ],
  );

  Widget _imagePicker() {
    final existingUrl = widget.product['image_url']?.toString();
    final hasExisting =
        existingUrl != null &&
        existingUrl.isNotEmpty &&
        !_removeImage &&
        _newImage == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1118),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              if (_newImage != null)
                FutureBuilder<Uint8List>(
                  future: _newImage!.readAsBytes(),
                  builder: (context, snap) => snap.hasData
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            snap.data!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        ),
                )
              else if (hasExisting)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    existingUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 50,
                    ),
                  ),
                )
              else
                const SizedBox(
                  height: 90,
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white38,
                      size: 42,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      hasExisting || _newImage != null
                          ? 'Change Image'
                          : 'Choose Image',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: const BorderSide(color: accent),
                    ),
                  ),
                  if (hasExisting || _newImage != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _newImage = null;
                        _removeImage = true;
                      }),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  if (_removeImage)
                    TextButton(
                      onPressed: () => setState(() => _removeImage = false),
                      child: const Text(
                        'Undo remove',
                        style: TextStyle(color: accent),
                      ),
                    ),
                ],
              ),
              const Text(
                'JPG, PNG or WEBP • Maximum 5 MB',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _barcode, _description, _price, _threshold]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080B10),
    appBar: AppBar(
      backgroundColor: const Color(0xFF080B10),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Edit Product',
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
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_note, color: accent, size: 36),
                  const SizedBox(height: 14),
                  const Text(
                    'Update Product Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Modify the product details below.',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 25),
                  _imagePicker(),
                  const SizedBox(height: 22),
                  _field(
                    'Product Name',
                    _name,
                    Icons.label_outline,
                    validator: _required,
                  ),
                  const SizedBox(height: 18),
                  _field('SKU', _sku, Icons.qr_code, validator: _required),
                  const SizedBox(height: 18),
                  _field('Barcode (optional)', _barcode, Icons.qr_code_scanner),
                  const SizedBox(height: 18),
                  _field(
                    'Description',
                    _description,
                    Icons.description_outlined,
                    lines: 3,
                  ),
                  const SizedBox(height: 18),
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
                    initialValue: _categoryId,
                    dropdownColor: card,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'Category',
                      Icons.category_outlined,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('No category'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: _loadingCategories
                        ? null
                        : (v) => setState(() => _categoryId = v ?? ''),
                  ),
                  if (_loadingCategories)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Loading categories...',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _field(
                    'Unit Price',
                    _price,
                    Icons.currency_rupee,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _priceValidator,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    'Low Stock Threshold',
                    _threshold,
                    Icons.warning_amber_outlined,
                    keyboard: TextInputType.number,
                    validator: _intValidator,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Stock quantity is managed separately through Stock In and Stock Out.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving || _loadingCategories ? null : _update,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF080B10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Updating Product...' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
