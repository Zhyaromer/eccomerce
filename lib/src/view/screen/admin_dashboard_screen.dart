import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/model/numerical.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/model/product_category.dart';
import 'package:e_commerce_flutter/src/model/product_size_type.dart';
import 'package:e_commerce_flutter/src/view/screen/auth_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productSearchController =
      TextEditingController();

  DateTime? _ordersDateFilter;
  String _productSearchQuery = '';

  @override
  void dispose() {
    _productSearchController.dispose();
    super.dispose();
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  dynamic _field(Map<String, dynamic>? data, String key) {
    return data == null ? null : data[key];
  }

  String _dateLabel(dynamic value) {
    if (value is! Timestamp) return 'Not set';

    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _productDocumentId(String name) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return normalizedName.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : normalizedName;
  }

  String _friendlyLabel(String value) {
    if (value.isEmpty) return 'Category';
    return value
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _categoryDocumentId(String name) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return normalizedName.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : normalizedName;
  }

  ProductType _legacyTypeForCategory(String category) {
    return ProductType.values.firstWhere(
      (type) => type.name == category,
      orElse: () => ProductType.mobile,
    );
  }

  Future<List<ProductCategory>> _loadAdminCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    final categories = snapshot.docs
        .map((doc) => ProductCategory.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return categories;
  }

  String _selectedDayLabel() {
    final date = _ordersDateFilter;
    if (date == null) return 'All';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
        content: Text(message),
      ),
    );
  }

  String _bestProductImage(Map<String, dynamic> data) {
    final images = _productImages(data);
    if (images.isNotEmpty) return images.first;

    return '';
  }

  List<String> _productImages(Map<String, dynamic> data) {
    final images = (data['images'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();

    for (final key in ['imageUrl', 'image', 'photoUrl', 'thumbnail']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && !images.contains(value)) {
        images.add(value);
      }
    }

    return images;
  }

  List<Map<String, dynamic>> _sizeRowsFromData(Map<String, dynamic>? data) {
    final rows = <Map<String, dynamic>>[];
    final sizes = _field(data, 'sizes');
    if (sizes is! Map) return rows;

    final numerical = sizes['numerical'];
    if (numerical is List) {
      for (final item in numerical) {
        if (item is Map) {
          rows.add({
            'label': item['value']?.toString() ?? '',
            'price': item['price']?.toString() ?? '',
            'stock': item['stock']?.toString() ?? '',
          });
        }
      }
    }

    final categorical = sizes['categorical'];
    if (categorical is List) {
      for (final item in categorical) {
        if (item is Map) {
          rows.add({
            'label': item['value']?.toString() ?? '',
            'price': item['price']?.toString() ?? '',
            'stock': item['stock']?.toString() ?? '',
          });
        }
      }
    }

    return rows;
  }

  ProductSizeType? _sizesFromRows(List<Map<String, TextEditingController>> rows) {
    final sizes = rows
        .map((row) {
          final label = row['label']!.text.trim();
          if (label.isEmpty) return null;

          return Numerical(
            label,
            false,
            price: row['price']!.text.trim().isEmpty
                ? null
                : _readInt(row['price']!.text),
            stock: row['stock']!.text.trim().isEmpty
                ? null
                : _readInt(row['stock']!.text),
          );
        })
        .whereType<Numerical>()
        .toList();

    return sizes.isEmpty ? null : ProductSizeType(numerical: sizes);
  }

  Widget _missingImage({required double size}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }

  Widget _productImage(String path, {double size = 58}) {
    if (path.trim().isEmpty) {
      return _missingImage(size: size);
    }

    final isNetworkImage =
        path.startsWith('http://') || path.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isNetworkImage
          ? Image.network(
              path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _missingImage(size: size);
              },
              errorBuilder: (_, __, ___) => _missingImage(size: size),
            )
          : Image.asset(
              path,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _missingImage(size: size),
            ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(initialMode: AuthMode.signIn),
      ),
      (_) => false,
    );
  }

  Future<void> _deleteDocument(
    DocumentReference<Map<String, dynamic>> reference,
    String label,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete $label',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await reference.delete();
      _showSnackBar('$label deleted');
    } on FirebaseException catch (error) {
      _showSnackBar(error.message ?? 'Could not delete $label', isError: true);
    }
  }

  Future<void> _deleteUser(
    DocumentReference<Map<String, dynamic>> userRef,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete user profile',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'This deletes the Firestore profile plus its favorites and purchases. It does not delete the Firebase Auth account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final batch = _firestore.batch();
      final favorites = await userRef.collection('favorites').get();
      final purchases = await userRef.collection('purchases').get();

      for (final doc in favorites.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in purchases.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(userRef);

      await batch.commit();
      _showSnackBar('User profile deleted');
    } on FirebaseException catch (error) {
      _showSnackBar(
        error.message ?? 'Could not delete user profile',
        isError: true,
      );
    }
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColor.darkOrange, size: 52),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColor.darkOrange),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: _panel(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.lightOrange.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColor.darkOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _compactAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: color ?? AppColor.darkOrange,
      icon: Icon(icon),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Future<void> _openProductEditor([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    final isEditing = document != null;
    final data = document?.data();
    final nameController = TextEditingController(
      text: _field(data, 'name')?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: _field(data, 'price')?.toString() ?? '',
    );
    final offController = TextEditingController(
      text: _field(data, 'off')?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: _field(data, 'stock')?.toString() ?? '',
    );
    final ratingController = TextEditingController(
      text: _field(data, 'rating')?.toString() ?? '0',
    );
    final aboutController = TextEditingController(
      text: isEditing ? _field(data, 'about')?.toString() ?? '' : '',
    );
    final categoryOptions = await _loadAdminCategories();
    final existingCategory =
        (_field(data, 'category') ?? _field(data, 'type') ?? '').toString();
    if (existingCategory.isNotEmpty &&
        categoryOptions.every((category) => category.id != existingCategory)) {
      categoryOptions.add(
        ProductCategory(
          id: existingCategory,
          name: _friendlyLabel(existingCategory),
        ),
      );
    }
    if (categoryOptions.isEmpty) {
      categoryOptions.add(
        ProductCategory(
          id: 'uncategorized',
          name: 'Uncategorized',
        ),
      );
    }
    var categoryId = categoryOptions.any(
      (category) => category.id == existingCategory,
    )
        ? existingCategory
        : categoryOptions.first.id;
    var isAvailable = _field(data, 'isAvailable') as bool? ?? true;
    final imageRows = _productImages(data ?? <String, dynamic>{})
        .map((image) => TextEditingController(text: image))
        .toList();
    if (imageRows.isEmpty) {
      imageRows.add(TextEditingController());
    }
    final formKey = GlobalKey<FormState>();
    final sizeRows = _sizeRowsFromData(data)
        .map(
          (row) => {
            'label': TextEditingController(text: row['label']?.toString()),
            'price': TextEditingController(text: row['price']?.toString()),
            'stock': TextEditingController(text: row['stock']?.toString()),
          },
        )
        .toList();

    void addSizeRow() {
      sizeRows.add({
        'label': TextEditingController(),
        'price': TextEditingController(),
        'stock': TextEditingController(),
      });
    }

    void addImageRow() {
      imageRows.add(TextEditingController());
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit product' : 'New product',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _simpleInput(
                          controller: nameController,
                          label: 'Name',
                          icon: Icons.inventory_2_outlined,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: categoryOptions
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => categoryId = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _simpleInput(
                                controller: priceController,
                                label: 'Price',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_readInt(value) <= 0) {
                                    return 'Enter a price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _simpleInput(
                                controller: offController,
                                label: 'Discount',
                                icon: Icons.percent,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _simpleInput(
                                controller: stockController,
                                label: 'Stock',
                                icon: Icons.storefront,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_readInt(value, fallback: -1) < 0) {
                                    return 'Enter stock';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _simpleInput(
                                controller: ratingController,
                                label: 'Rating',
                                icon: Icons.star_border,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _simpleInput(
                          controller: aboutController,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          minLines: 3,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Image URLs',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(addImageRow);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add image'),
                            ),
                          ],
                        ),
                        ...imageRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _productImage(
                                    controller.text.trim(),
                                    size: 54,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      labelText: 'Image URL',
                                      hintText: 'https://example.com/photo.png',
                                      prefixIcon: Icon(Icons.link),
                                    ),
                                    onChanged: (_) {
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove image',
                                  onPressed: imageRows.length == 1
                                      ? null
                                      : () {
                                          final removed =
                                              imageRows.removeAt(index);
                                          removed.dispose();
                                          setDialogState(() {});
                                        },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sizes',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(addSizeRow);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add size'),
                            ),
                          ],
                        ),
                        if (sizeRows.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No sizes. The product will use one default stock.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ...sizeRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: row['label'],
                                    decoration: const InputDecoration(
                                      labelText: 'Label',
                                      hintText: '41, 45, small...',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: row['price'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: row['stock'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Stock',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove size',
                                  onPressed: () {
                                    final removed = sizeRows.removeAt(index);
                                    for (final controller in removed.values) {
                                      controller.dispose();
                                    }
                                    setDialogState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isAvailable,
                          onChanged: (value) {
                            setDialogState(() => isAvailable = value);
                          },
                          title: const Text('Available'),
                          activeColor: AppColor.darkOrange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final product = Product(
                      name: nameController.text.trim(),
                      price: _readInt(priceController.text),
                      isAvailable: isAvailable,
                      stock: _readInt(stockController.text),
                      off: offController.text.trim().isEmpty
                          ? null
                          : _readInt(offController.text),
                      quantity: 0,
                      images: imageRows
                          .map((controller) => controller.text.trim())
                          .where((image) => image.isNotEmpty)
                          .toList(),
                      isFavorite: false,
                      rating: _readDouble(ratingController.text),
                      about: aboutController.text.trim(),
                      sizes: _sizesFromRows(sizeRows),
                      type: _legacyTypeForCategory(categoryId),
                      category: categoryId,
                    );

                    final data = product.toMap();
                    data['updatedAt'] = FieldValue.serverTimestamp();
                    if (!isEditing) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                    }

                    final docId = isEditing
                        ? document!.id
                        : _productDocumentId(product.name);

                    try {
                      await _firestore
                          .collection('products')
                          .doc(docId)
                          .set(data, SetOptions(merge: isEditing));
                      if (context.mounted) Navigator.pop(context, true);
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            error.message ?? 'Could not save product',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      nameController,
      priceController,
      offController,
      stockController,
      ratingController,
      aboutController,
    ]) {
      controller.dispose();
    }
    for (final controller in imageRows) {
      controller.dispose();
    }
    for (final row in sizeRows) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }

    if (saved == true) {
      _showSnackBar(isEditing ? 'Product updated' : 'Product created');
    }
  }

  void _showProductDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final images = _productImages(data);
    final sizes = _sizeRowsFromData(data);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            data['name']?.toString() ?? document.id,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return _productImage(images[index], size: 108);
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: images.length,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow('ID', document.id),
                  _detailRow(
                    'Category',
                    (data['category'] ?? data['type'] ?? '').toString(),
                  ),
                  _detailRow('Price', '\$${_readInt(data['price'])}'),
                  _detailRow(
                    'Discount',
                    data['off'] == null ? 'None' : '\$${_readInt(data['off'])}',
                  ),
                  _detailRow('Stock', '${_readInt(data['stock'])}'),
                  _detailRow('Rating', '${_readDouble(data['rating'])}'),
                  _detailRow(
                    'Available',
                    data['isAvailable'] == true ? 'Yes' : 'No',
                  ),
                  _detailRow('Description', data['about']?.toString() ?? ''),
                  if (sizes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Sizes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sizes.map((size) {
                        final label = size['label']?.toString() ?? '';
                        final price = size['price']?.toString() ?? '';
                        final stock = size['stock']?.toString() ?? '';
                        final details = [
                          if (price.isNotEmpty) '\$$price',
                          if (stock.isNotEmpty) 'stock $stock',
                        ].join(' - ');

                        return Chip(
                          label: Text(details.isEmpty ? label : '$label ($details)'),
                          backgroundColor: AppColor.lightGrey,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openProductEditor(document);
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUserEditor([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    final isEditing = document != null;
    final data = document?.data();
    final uidController = TextEditingController(
      text: _field(data, 'uid')?.toString() ?? '',
    );
    final nameController = TextEditingController(
      text: _field(data, 'fullName')?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: _field(data, 'email')?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: _field(data, 'phone')?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: _field(data, 'address')?.toString() ?? '',
    );
    var role =
        _field(data, 'role')?.toString() == 'admin' ? 'admin' : 'customer';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit user' : 'New user profile',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: uidController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'UID / document ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Enter a uid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _simpleInput(
                          controller: nameController,
                          label: 'Full name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _simpleInput(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _simpleInput(
                          controller: phoneController,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _simpleInput(
                          controller: addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'customer',
                              child: Text('customer'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admin'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => role = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final uid = isEditing ? document!.id : uidController.text.trim();
                    final data = <String, dynamic>{
                      'uid': uid,
                      'fullName': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'role': role,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (!isEditing) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                    }

                    try {
                      await _firestore
                          .collection('users')
                          .doc(uid)
                          .set(data, SetOptions(merge: isEditing));
                      if (context.mounted) Navigator.pop(context, true);
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                          content: Text(error.message ?? 'Could not save user'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      uidController,
      nameController,
      emailController,
      phoneController,
      addressController,
    ]) {
      controller.dispose();
    }

    if (saved == true) {
      _showSnackBar(isEditing ? 'User updated' : 'User profile created');
    }
  }

  Future<void> _openCategoryEditor([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    final isEditing = document != null;
    final data = document?.data();
    final nameController = TextEditingController(
      text: _field(data, 'name')?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit category' : 'New category',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a category name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final name = nameController.text.trim();
                    final categoryData = <String, dynamic>{
                      'name': name,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (!isEditing) {
                      categoryData['createdAt'] = FieldValue.serverTimestamp();
                    }

                    final docId =
                        isEditing ? document!.id : _categoryDocumentId(name);

                    try {
                      await _firestore
                          .collection('categories')
                          .doc(docId)
                          .set(categoryData, SetOptions(merge: isEditing));
                      if (context.mounted) Navigator.pop(context, true);
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            error.message ?? 'Could not save category',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (saved == true) {
      _showSnackBar(isEditing ? 'Category updated' : 'Category created');
    }
  }

  void _showOrderDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> purchase,
  ) {
    final data = purchase.data();
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final userId = purchase.reference.parent.parent?.id ?? 'Unknown user';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            data['customerName']?.toString() ?? 'Order',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Order ID', purchase.id),
                  _detailRow('User UID', userId),
                  _detailRow('Date', _dateLabel(data['createdAt'])),
                  _detailRow('Status', data['status']?.toString() ?? ''),
                  _detailRow('Total', '\$${_readInt(data['total'])}'),
                  _detailRow(
                    'Email',
                    data['customerEmail']?.toString() ?? '',
                  ),
                  _detailRow(
                    'Phone',
                    data['customerPhone']?.toString() ?? '',
                  ),
                  _detailRow(
                    'Address',
                    data['deliveryAddress']?.toString() ?? '',
                  ),
                  _detailRow(
                    'Card holder',
                    data['cardHolder']?.toString() ?? '',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Text(
                      'No item details saved for this order.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...items.map((item) {
                      final name = item['productName']?.toString() ?? 'Item';
                      final quantity = _readInt(item['quantity'], fallback: 1);
                      final size = item['sizeLabel']?.toString() ?? 'Default';
                      final unitPrice = _readInt(item['unitPrice']);
                      final lineTotal = _readInt(item['lineTotal']);
                      final image = item['imagePath']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _productImage(image ?? '', size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$quantity x $size - \$$unitPrice each',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$$lineTotal',
                              style: const TextStyle(
                                color: AppColor.darkOrange,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDocument(purchase.reference, 'purchase');
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin dashboard',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage products, users, and customer orders.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('products').snapshots(),
            builder: (context, productsSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, usersSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore.collectionGroup('purchases').snapshots(),
                    builder: (context, purchasesSnapshot) {
                      final productCount =
                          productsSnapshot.data?.docs.length ?? 0;
                      final userCount = usersSnapshot.data?.docs.length ?? 0;
                      final purchases = purchasesSnapshot.data?.docs ?? [];
                      final revenue = purchases.fold<int>(
                        0,
                        (sum, doc) => sum + _readInt(doc.data()['total']),
                      );

                      return Column(
                        children: [
                          Row(
                            children: [
                              _metricCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Products',
                                value: '$productCount',
                                color: AppColor.darkOrange,
                              ),
                              const SizedBox(width: 12),
                              _metricCard(
                                icon: Icons.people_outline,
                                label: 'Users',
                                value: '$userCount',
                                color: const Color(0xFF3081E1),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _metricCard(
                                icon: Icons.receipt_long_outlined,
                                label: 'Orders',
                                value: '${purchases.length}',
                                color: const Color(0xFF23814D),
                              ),
                              const SizedBox(width: 12),
                              _metricCard(
                                icon: Icons.attach_money,
                                label: 'Revenue',
                                value: '\$$revenue',
                                color: const Color(0xFF9C46FF),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 4),
          _panel(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Set a user document field role to admin to send that user here after login. New sign-ups are created as customers.',
                  style: TextStyle(color: Colors.grey, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsTab() {
    return Column(
      children: [
        _sectionHeader(
          title: 'Products',
          subtitle: 'Search, view, create, and edit store items.',
          icon: Icons.inventory_2_outlined,
          trailing: IconButton.filled(
            tooltip: 'Add product',
            onPressed: () => _openProductEditor(),
            icon: const Icon(Icons.add),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            controller: _productSearchController,
            onChanged: (value) {
              setState(() => _productSearchQuery = value.trim().toLowerCase());
            },
            decoration: InputDecoration(
              labelText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _productSearchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _productSearchController.clear();
                        setState(() => _productSearchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snapshot.hasError) {
                return _errorState('Could not load products.');
              }

              final products = snapshot.data?.docs.toList() ?? [];
              products.sort((a, b) {
                return (a.data()['name'] ?? a.id)
                    .toString()
                    .compareTo((b.data()['name'] ?? b.id).toString());
              });

              final filteredProducts = products.where((product) {
                if (_productSearchQuery.isEmpty) return true;
                final name = product.data()['name']?.toString().toLowerCase();
                return name?.contains(_productSearchQuery) == true;
              }).toList();

              if (filteredProducts.isEmpty) {
                return _emptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products found',
                  subtitle: 'Try another search or add a new product.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final data = product.data();
                  final available = data['isAvailable'] as bool? ?? false;

                  return InkWell(
                    onTap: () => _showProductDetails(product),
                    borderRadius: BorderRadius.circular(14),
                    child: _panel(
                      child: Row(
                        children: [
                          _productImage(_bestProductImage(data)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name']?.toString() ?? product.id,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['category'] ?? data['type'] ?? 'item'} - \$${_readInt(data['price'])} - stock ${_readInt(data['stock'])}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: available
                                  ? const Color(0xFFEAF7EF)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              available ? 'Live' : 'Hidden',
                              style: TextStyle(
                                color: available
                                    ? const Color(0xFF23814D)
                                    : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _compactAction(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit product',
                            onPressed: () => _openProductEditor(product),
                          ),
                          _compactAction(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete product',
                            color: Colors.redAccent,
                            onPressed: () => _deleteDocument(
                              product.reference,
                              'product',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _usersTab() {
    return Column(
      children: [
        _sectionHeader(
          title: 'Users',
          subtitle: 'Manage profiles and roles.',
          icon: Icons.people_outline,
          trailing: IconButton.filled(
            tooltip: 'Add user profile',
            onPressed: () => _openUserEditor(),
            icon: const Icon(Icons.add),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snapshot.hasError) {
                return _errorState('Could not load users.');
              }

              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty) {
                return _emptyState(
                  icon: Icons.people_outline,
                  title: 'No users',
                  subtitle: 'Registered customer profiles will appear here.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data();
                  final role = data['role']?.toString() ?? 'customer';
                  final isAdmin = role == 'admin';

                  return _panel(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColor.lightOrange.withValues(alpha: 0.35)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person_outline,
                            color: isAdmin
                                ? AppColor.darkOrange
                                : const Color(0xFF3081E1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['fullName']?.toString().isNotEmpty == true
                                    ? data['fullName'].toString()
                                    : user.id,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['email'] ?? 'No email'} - $role',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _compactAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit user',
                          onPressed: () => _openUserEditor(user),
                        ),
                        _compactAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete user profile',
                          color: Colors.redAccent,
                          onPressed: () => _deleteUser(user.reference),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoriesTab() {
    return Column(
      children: [
        _sectionHeader(
          title: 'Categories',
          subtitle: 'Create, edit, and remove shop categories.',
          icon: Icons.list_alt,
          trailing: IconButton.filled(
            tooltip: 'Add category',
            onPressed: () => _openCategoryEditor(),
            icon: const Icon(Icons.add),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('categories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snapshot.hasError) {
                return _errorState('Could not load categories.');
              }

              final categories = snapshot.data?.docs.toList() ?? [];
              categories.sort((a, b) {
                final aName = a.data()['name']?.toString() ?? a.id;
                final bName = b.data()['name']?.toString() ?? b.id;
                return aName.compareTo(bName);
              });

              if (categories.isEmpty) {
                return _emptyState(
                  icon: Icons.list_alt,
                  title: 'No categories',
                  subtitle: 'Add categories here, then choose them on products.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final data = category.data();
                  final name = data['name']?.toString() ?? category.id;

                  return _panel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.id,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _compactAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit category',
                          onPressed: () => _openCategoryEditor(category),
                        ),
                        _compactAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete category',
                          color: Colors.redAccent,
                          onPressed: () => _deleteDocument(
                            category.reference,
                            'category',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _ordersTab() {
    return Column(
      children: [
        _sectionHeader(
          title: 'Orders',
          subtitle: 'Tap an order to see full details and items.',
          icon: Icons.receipt_long_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _ordersDateFilter ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (selected != null) {
                      setState(() => _ordersDateFilter = selected);
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Date: ${_selectedDayLabel()}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.darkOrange,
                    side: const BorderSide(color: AppColor.darkOrange),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Show all orders',
                onPressed: _ordersDateFilter == null
                    ? null
                    : () => setState(() => _ordersDateFilter = null),
                icon: const Icon(Icons.all_inclusive),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collectionGroup('purchases').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingState();
              }
              if (snapshot.hasError) {
                return _errorState('Could not load purchases.');
              }

              final purchases = snapshot.data?.docs.toList() ?? [];
              purchases.sort((a, b) {
                final aDate = a.data()['createdAt'] as Timestamp?;
                final bDate = b.data()['createdAt'] as Timestamp?;

                return (bDate?.toDate().millisecondsSinceEpoch ?? 0)
                    .compareTo(aDate?.toDate().millisecondsSinceEpoch ?? 0);
              });

              final filteredPurchases = purchases.where((purchase) {
                final selectedDate = _ordersDateFilter;
                if (selectedDate == null) return true;

                final createdAt = purchase.data()['createdAt'];
                if (createdAt is! Timestamp) return false;

                return _sameDay(createdAt.toDate(), selectedDate);
              }).toList();

              if (filteredPurchases.isEmpty) {
                return _emptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders',
                  subtitle: _ordersDateFilter == null
                      ? 'Customer orders will appear here.'
                      : 'No orders were placed on this day.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = filteredPurchases[index];
                  final data = purchase.data();
                  final items = (data['items'] as List<dynamic>? ?? [])
                      .whereType<Map>()
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();
                  final status = data['status']?.toString() ?? 'Purchased';
                  final customerName =
                      data['customerName']?.toString() ?? 'Customer';
                  final userId =
                      purchase.reference.parent.parent?.id ?? 'Unknown user';

                  return InkWell(
                    onTap: () => _showOrderDetails(purchase),
                    borderRadius: BorderRadius.circular(14),
                    child: _panel(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF23814D),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$userId - ${_dateLabel(data['createdAt'])}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${items.length} item${items.length == 1 ? '' : 's'} - $status',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${_readInt(data['total'])}',
                            style: const TextStyle(
                              color: AppColor.darkOrange,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          _compactAction(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete purchase',
                            color: Colors.redAccent,
                            onPressed: () => _deleteDocument(
                              purchase.reference,
                              'purchase',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F8F8),
            appBar: AppBar(
              title: Text(
                'Admin',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                labelColor: AppColor.darkOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColor.darkOrange,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
                  Tab(text: 'Categories'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
                ],
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                children: [
                  _dashboardTab(),
                  _productsTab(),
                  _categoriesTab(),
                  _usersTab(),
                  _ordersTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
