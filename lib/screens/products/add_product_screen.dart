
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/product_service.dart';
import 'barcode_scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  final String? initialDescription;
  final String? initialImageUrl;

  const AddProductScreen({
    super.key,
    this.initialBarcode,
    this.initialName,
    this.initialDescription,
    this.initialImageUrl,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const accent = Color(0xFF00D68F);
  static const background = Color(0xFF080B10);
  static const card = Color(0xFF111923);
  static const fieldBackground = Color(0xFF0B1118);

  String _limitProductName(String value) {
    return String.fromCharCodes(value.runes.take(60));
  }

  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '5');
  final _picker = ImagePicker();

  List<Map<String, dynamic>> _categories = [];
  String _categoryId = '';
  XFile? _image;
  String? _externalImageUrl;

  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _name.text = _limitProductName(widget.initialName ?? '');
    _barcode.text = widget.initialBarcode ?? '';
    _description.text = widget.initialDescription ?? '';
    _externalImageUrl = widget.initialImageUrl;

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await _service.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = rows;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingCategories = false);
      _message('Could not load categories: $e', error: true);
    }
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : accent,
      ),
    );
  }

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

      setState(() => _image = picked);
    } catch (e) {
      _message('Could not select image: $e', error: true);
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (!mounted || result == null || result.isEmpty) return;

    setState(() {
      _barcode.text = result;
    });

    _message('Barcode scanned successfully!');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _service.addProduct(
        name: _limitProductName(_name.text.trim()),
        sku: _sku.text.trim(),
        barcode: _barcode.text,
        description: _description.text.trim(),
        unitPrice: double.parse(_price.text.trim()),
        stockQuantity: int.parse(_stock.text.trim()),
        lowStockThreshold: int.parse(_threshold.text.trim()),
        categoryId: _categoryId.isEmpty ? null : _categoryId,
        imageFile: _image,
        imageUrl: _image == null ? _externalImageUrl : null,
      );

      if (!mounted) return;

      _message('Product added successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _message('Failed to add product: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  String? _priceValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');

    return number == null || !number.isFinite || number < 0
        ? 'Enter a valid non-negative price'
        : null;
  }

  String? _intValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');

    return number == null || number < 0
        ? 'Enter a valid non-negative whole number'
        : null;
  }

  Widget _sectionHeading(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int lines = 1,
    int? maxLength,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: lines,
          maxLength: maxLength,
          keyboardType: keyboard,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: _decoration(label, icon),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white30,
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: accent, size: 19),
      filled: true,
      fillColor: fieldBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
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
        borderSide: const BorderSide(color: accent, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _imagePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          if (_image != null)
            FutureBuilder<Uint8List>(
              future: _image!.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: accent),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    snapshot.data!,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                );
              },
            )
          else if (_externalImageUrl != null &&
              _externalImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _externalImageUrl!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 45,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 125,
              width: double.infinity,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white10,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: accent,
                    size: 38,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No product image selected',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(
              _image == null &&
                      (_externalImageUrl == null ||
                          _externalImageUrl!.isEmpty)
                  ? 'Choose Product Image'
                  : 'Change Image',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: const BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'JPG, PNG or WEBP • Maximum 5 MB',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barcodeField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanButton = SizedBox(
          height: 53,
          child: ElevatedButton.icon(
            onPressed: _scanBarcode,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text(
              'Scan Barcode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

        final input = TextFormField(
          controller: _barcode,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _decoration(
            'Enter or scan barcode',
            Icons.qr_code_scanner,
          ),
        );

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              input,
              const SizedBox(height: 10),
              scanButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: input),
            const SizedBox(width: 10),
            scanButton,
          ],
        );
      },
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _categoryId,
      dropdownColor: card,
      isExpanded: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration(
        'Select a category',
        Icons.category_outlined,
      ),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('No category'),
        ),
        ..._categories.map(
          (category) => DropdownMenuItem<String>(
            value: category['id'].toString(),
            child: Text(
              category['name'].toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _loadingCategories
          ? null
          : (value) => setState(() => _categoryId = value ?? ''),
    );
  }

  Widget _formSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(title, subtitle, icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _sku,
      _barcode,
      _description,
      _price,
      _stock,
      _threshold,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 18,
        title: const Row(
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              color: accent,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'SYNCORA',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth < 500 ? 14.0 : 24.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    30,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.15),
                                const Color(0xFF111923),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRODUCT MANAGEMENT',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 9),
                                    Text(
                                      'Add New Product',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 7),
                                    Text(
                                      'Create a product record and add it to your inventory.',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.inventory_2_outlined,
                                color: accent,
                                size: 43,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _formSection(
                          title: 'Product Image',
                          subtitle: 'Upload an image to identify your product.',
                          icon: Icons.image_outlined,
                          children: [_imagePicker()],
                        ),

                        const SizedBox(height: 16),

                        _formSection(
                          title: 'Basic Information',
                          subtitle: 'Enter the product details and identification.',
                          icon: Icons.info_outline_rounded,
                          children: [
                            _field(
                              'Product Name',
                              _name,
                              Icons.label_outline,
                              validator: _required,
                              maxLength: 60,
                            ),
                            const SizedBox(height: 17),
                            _field(
                              'SKU',
                              _sku,
                              Icons.qr_code,
                              validator: _required,
                            ),
                            const SizedBox(height: 17),
                            const Text(
                              'Barcode (optional)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _barcodeField(),
                            const SizedBox(height: 17),
                            _field(
                              'Description',
                              _description,
                              Icons.description_outlined,
                              lines: 3,
                            ),
                            const SizedBox(height: 17),
                            const Text(
                              'Category',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _categoryDropdown(),
                            if (_loadingCategories)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Loading categories...',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _formSection(
                          title: 'Pricing & Stock',
                          subtitle: 'Set the selling price and inventory quantities.',
                          icon: Icons.analytics_outlined,
                          children: [
                            _field(
                              'Unit Price',
                              _price,
                              Icons.currency_rupee,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _priceValidator,
                            ),
                            const SizedBox(height: 17),
                            _field(
                              'Initial Stock Quantity',
                              _stock,
                              Icons.inventory_outlined,
                              keyboard: TextInputType.number,
                              validator: _intValidator,
                            ),
                            const SizedBox(height: 17),
                            _field(
                              'Low Stock Threshold',
                              _threshold,
                              Icons.warning_amber_outlined,
                              keyboard: TextInputType.number,
                              validator: _intValidator,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: background,
                              disabledBackgroundColor:
                                  accent.withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: background,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded),
                            label: Text(
                              _saving ? 'Saving Product...' : 'Add Product',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'SYNCORA • SMART INVENTORY MANAGEMENT',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
