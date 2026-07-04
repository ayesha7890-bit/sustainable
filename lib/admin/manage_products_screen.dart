import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sustainable/database/database_helper.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedCategory;
  String? _selectedImagePath;
  int? _editingId; // null = Add mode, warna Edit mode

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _categories = [];

  String _categoryFilter = 'Sab'; // grid filter chip
  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  static const Color _primary = Color(0xFF2F4A3E);
  static const Color _secondary = Color(0xFF5E8570);
  static const Color _bg = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // DATA LAYER
  // ---------------------------------------------------------------

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    try {
      final prodData = await DatabaseHelper.instance.fetchProducts();
      final catData = await DatabaseHelper.instance.fetchCategories();
      setState(() {
        _products = prodData;
        _categories = catData;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Data load Error: $e', isError: true);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchesSearch =
            query.isEmpty || p['name'].toString().toLowerCase().contains(query);
        final matchesCategory =
            _categoryFilter == 'All' || p['category'] == _categoryFilter;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _pickImage(void Function(void Function()) setDialogState) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setDialogState(() => _selectedImagePath = image.path);
      }
    } catch (e) {
      _showSnack('Select Image Error: $e', isError: true);
    }
  }

  // Stylish bottom sheet: Camera ya Gallery choose karne ke liye
  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 40, end: 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => Transform.translate(
            offset: Offset(0, offset),
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Select Product Image',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _sourceOptionTile(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        onTap: () =>
                            Navigator.pop(sheetContext, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _sourceOptionTile(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () =>
                            Navigator.pop(sheetContext, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Kindly Select Category!', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final wasEditing = _editingId != null;

    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'description': _descController.text.trim(),
      'image_url': _selectedImagePath ?? '',
    };

    try {
      if (!wasEditing) {
        await DatabaseHelper.instance.insertProduct(data);
      } else {
        await DatabaseHelper.instance.updateProduct(_editingId!, data);
      }

      _resetForm();
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      await _loadData(showLoader: false);
      setState(() => _isSaving = false);
      _showSnack(wasEditing
          ? 'Product updated! ✏️'
          : 'Product save Sucsessfuly! ✅');
    } catch (e) {
      setState(() => _isSaving = false);
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Product?'),
        content: Text('Are you "${product['name']}" want to delte product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await DatabaseHelper.instance.deleteProduct(product['id']);
      await _loadData(showLoader: false);
      _showSnack('Product delete Sucsessfuly! 🗑️');
    } catch (e) {
      _showSnack('Delete fail: $e', isError: true);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descController.clear();
    _selectedCategory = null;
    _selectedImagePath = null;
    _editingId = null;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ---------------------------------------------------------------
  // ADD / EDIT DIALOG
  // ---------------------------------------------------------------

  void _showProductDialog({Map<String, dynamic>? product}) {
    if (_categories.isEmpty) {
      _showSnack('Select one Category', isError: true);
      return;
    }

    _editingId = product?['id'];
    _nameController.text = product?['name'] ?? '';
    _descController.text = product?['description'] ?? '';
    _selectedCategory = product?['category'];
    _selectedImagePath =
    (product?['image_url'] as String?)?.isNotEmpty == true
        ? product!['image_url']
        : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Gradient Header ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              product == null
                                  ? Icons.add_shopping_cart_rounded
                                  : Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            product == null ? 'New Product' : 'Eidit Product',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- Form Body ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- Animated Image Preview ---
                              Center(
                                child: GestureDetector(
                                  onTap: () => _pickImage(setDialogState),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    height: 130,
                                    width: 130,
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _selectedImagePath != null
                                            ? _secondary
                                            : _primary.withOpacity(0.25),
                                        width: 1.6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primary.withOpacity(0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _selectedImagePath != null
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(19),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(File(_selectedImagePath!),
                                              fit: BoxFit.cover),
                                          Positioned(
                                            right: 6,
                                            bottom: 6,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                              Colors.black.withOpacity(0.55),
                                              child: const Icon(Icons.edit,
                                                  size: 15, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _primary.withOpacity(0.85),
                                                _secondary.withOpacity(0.85),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.add_a_photo_rounded,
                                              color: Colors.white,
                                              size: 22),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Pic Upload',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Product Name',
                                  prefixIcon: Icon(Icons.shopping_bag_outlined,
                                      color: _primary),
                                  filled: true,
                                  fillColor: _primary.withOpacity(0.04),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Name required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon:
                                  Icon(Icons.category_outlined, color: _primary),
                                  filled: true,
                                  fillColor: _primary.withOpacity(0.04),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Select Category'),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat['name'].toString(),
                                    child: Text(cat['name'].toString()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() => _selectedCategory = value);
                                },
                                validator: (v) => v == null ? 'Select Category' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _descController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'Description (optional)',
                                  prefixIcon:
                                  Icon(Icons.notes_outlined, color: _primary),
                                  filled: true,
                                  fillColor: _primary.withOpacity(0.04),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // --- Actions ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: BorderSide(color: _primary.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _resetForm();
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                setDialogState(() {});
                                _saveProduct(dialogContext);
                              },
                              icon: _isSaving
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                                  : const Icon(Icons.check, size: 18),
                              label: Text(product == null ? 'Save' : 'Update'),
                            ),
                          ),
                        ],
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

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Manage Products', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Product dhoondhein...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chipNames = ['Sab', ..._categories.map((c) => c['name'].toString())];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chipNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = chipNames[index];
          final selected = _categoryFilter == name;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(name),
              selected: selected,
              selectedColor: _secondary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: selected ? _secondary : Colors.black12),
              ),
              onSelected: (_) {
                setState(() => _categoryFilter = name);
                _applyFilters();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _secondary));
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _secondary,
      onRefresh: () => _loadData(showLoader: false),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final product = _filtered[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + (index * 35).clamp(0, 350)),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            ),
            child: _buildProductCard(product),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imagePath = product['image_url'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showProductDialog(product: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image ---
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_${product['id']}',
                      child: hasImage
                          ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _imagePlaceholder(),
                      )
                          : _imagePlaceholder(),
                    ),
                    // Subtle gradient for legibility + delete button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _deleteProduct(product),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black.withOpacity(0.45),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- Info ---
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product['category'].toString(),
                        style: const TextStyle(
                            fontSize: 11, color: _primary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _primary.withOpacity(0.08),
      child: Icon(Icons.eco_rounded, color: _primary.withOpacity(0.5), size: 36),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: _primary.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text('Koi product nahi mila',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Neeche "Add Product" button se naya product add karein.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}