import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'product-images';
  static const int maxImageBytes = 5 * 1024 * 1024;
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final result = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('barcode', barcode.trim())
        .maybeSingle();

    if (result == null) return null;

    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>?> lookupElectronicsProduct(String barcode) async {
    final response = await _client.functions.invoke(
      'lookup-electronics',
      body: {'barcode': barcode.trim()},
    );

    final data = response.data;

    if (data is Map && data['found'] == true) {
      final product = data['product'];

      if (product is Map) {
        return Map<String, dynamic>.from(product);
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getProducts({
    String searchQuery = '',
  }) async {
    var query = _client.from('products').select('*, categories(name)');
    final search = searchQuery.trim().replaceAll(',', '');
    if (search.isNotEmpty) {
      query = query.or(
        'name.ilike.%$search%,sku.ilike.%$search%,barcode.ilike.%$search%',
      );
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.from('categories').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> uploadProductImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw Exception('Image must be 5 MB or smaller.');
    }
    final originalName = image.name;
    final extension = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : 'jpg';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(extension)) {
      throw Exception('Choose a JPG, PNG, or WEBP image.');
    }
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final path =
        '${DateTime.now().microsecondsSinceEpoch}_${_safeName(originalName)}';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return cleaned.isEmpty ? 'product_image.jpg' : cleaned;
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    required String description,
    required double unitPrice,
    required int stockQuantity,
    required int lowStockThreshold,
    String? categoryId,
    String? barcode,
    XFile? imageFile,
    String? imageUrl,
  }) async {
    String? uploadedImageUrl;

    if (imageFile != null) {
      uploadedImageUrl = await uploadProductImage(imageFile);
    }

    final finalImageUrl = uploadedImageUrl ?? imageUrl;

    try {
      await _client.from('products').insert({
        'name': name,
        'sku': sku,
        'description': description,
        'unit_price': unitPrice,
        'stock_quantity': stockQuantity,
        'low_stock_threshold': lowStockThreshold,
        'category_id': categoryId,
        'barcode': _cleanBarcode(barcode),
        'image_url': finalImageUrl,
      });
    } catch (_) {
      if (uploadedImageUrl != null) {
        await _deleteImageByUrl(uploadedImageUrl);
      }
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String sku,
    required String description,
    required double unitPrice,
    required int lowStockThreshold,
    String? categoryId,
    String? barcode,
    XFile? imageFile,
    bool removeImage = false,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'sku': sku,
      'description': description,
      'unit_price': unitPrice,
      'low_stock_threshold': lowStockThreshold,
      'category_id': categoryId,
      'barcode': _cleanBarcode(barcode),
    };
    String? newImageUrl;
    if (imageFile != null) {
      newImageUrl = await uploadProductImage(imageFile);
      updates['image_url'] = newImageUrl;
    } else if (removeImage) {
      updates['image_url'] = null;
    }
    try {
      await _client.from('products').update(updates).eq('id', id);
    } catch (_) {
      if (newImageUrl != null) await _deleteImageByUrl(newImageUrl);
      rethrow;
    }
  }

  String? _cleanBarcode(String? value) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _deleteImageByUrl(String url) async {
    final marker = '/storage/v1/object/public/$_bucket/';
    final index = url.indexOf(marker);
    if (index < 0) return;
    final path = Uri.decodeComponent(url.substring(index + marker.length));
    await _client.storage.from(_bucket).remove([path]);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
