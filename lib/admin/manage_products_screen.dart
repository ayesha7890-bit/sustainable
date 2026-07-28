import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sustainable/database/database_helper.dart';
import '../utils/app_colors.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  final _priceController = TextEditingController();
  final _carbonController = TextEditingController();
  final _benefitsController = TextEditingController();

  String? _selectedCategory;
  String? _selectedImagePath;
  int? _editingId;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _categories = [];

  String _categoryFilter = 'All';
  bool _isLoading = true;
  bool _isSaving = false;

  late AnimationController _headerController;
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  static const Color _forest = AppColors.forest;
  static const Color _sage = AppColors.sage;
  static const Color _sand = AppColors.sand;

  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_forest, _sage, _sand],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    _priceController.dispose();
    _carbonController.dispose();
    _benefitsController.dispose();
    _headerController.dispose();
    _fabController.dispose();
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
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        String pickedPath = result.files.single.path!;
        setDialogState(() {
          _selectedImagePath = pickedPath;
        });
      } else {
        _showSnack('Image selection cancelled.');
      }
    } catch (e) {
      _showSnack('Select Image Error: $e', isError: true);
    }
  }

  // 🔥 FIXED: Is function ke save flow aur state variables ki hierarchy ko sahi kiya hai
  Future<void> _saveProduct(BuildContext dialogContext, void Function(void Function()) setDialogState) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Kindly Select Category!', isError: true);
      return;
    }

    // Modal Sheet aur Main page dono ke loading spinners ko true karein
    setDialogState(() => _isSaving = true);
    setState(() => _isSaving = true);

    final wasEditing = _editingId != null;

    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'description': _descController.text.trim(),
      'image_url': _selectedImagePath ?? '',
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'carbon_saved': double.tryParse(_carbonController.text.trim()) ?? 25.0,
      'icon_name': _selectedCategory?.toLowerCase() == 'bathroom' ? 'brush' : 'shopping_bag',
      'benefits_csv': _benefitsController.text.isNotEmpty ? _benefitsController.text.trim() : 'Eco Friendly',
    };

    try {
      if (!wasEditing) {
        await DatabaseHelper.instance.insertProduct(data);
      } else {
        await DatabaseHelper.instance.updateProduct(_editingId!, data);
      }

      // Pehle loading bands karein taake pop safe ho ske
      setDialogState(() => _isSaving = false);
      if (mounted) setState(() => _isSaving = false);

      _resetForm();
      if (dialogContext.mounted) Navigator.pop(dialogContext);

      await _loadData(showLoader: false);
      _showSnack(wasEditing ? 'Product updated! ✏️' : 'Product saved successfully! ✅');
    } catch (e) {
      setDialogState(() => _isSaving = false);
      if (mounted) setState(() => _isSaving = false);

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
      builder: (context) => _themedDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete Product?',
        content: Text(
          'Are you sure you want to delete "${product['name']}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
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
      _showSnack('Product deleted successfully! 🗑️');
    } catch (e) {
      _showSnack('Delete fail: $e', isError: true);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _carbonController.clear();
    _benefitsController.clear();
    _selectedCategory = null;
    _selectedImagePath = null;
    _editingId = null;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _forest.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ---------------------------------------------------------------
  // GLASSMORPHIC BOTTOM SHEET FORM
  // ---------------------------------------------------------------

  void _showProductDialog({Map<String, dynamic>? product}) {
    if (_categories.isEmpty) {
      _showSnack('Select one Category', isError: true);
      return;
    }

    _editingId = product?['id'];
    _nameController.text = product?['name'] ?? '';
    _descController.text = product?['description'] ?? '';
    _priceController.text = (product?['price'] ?? '').toString();
    _carbonController.text = (product?['carbon_saved'] ?? '').toString();
    _benefitsController.text = product?['benefits_csv'] ?? '';
    _selectedCategory = product?['category'];
    _selectedImagePath =
    (product?['image_url'] as String?)?.isNotEmpty == true
        ? product!['image_url']
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: _forest.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            product == null
                                ? Icons.add_shopping_cart_rounded
                                : Icons.edit_rounded,
                            color: _sand,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          product == null ? 'New Product' : 'Edit Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () => _pickImage(setDialogState),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: _selectedImagePath != null ? _sand : Colors.white.withOpacity(0.2),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: _selectedImagePath != null && File(_selectedImagePath!).existsSync()
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(21),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                                        Positioned(
                                          right: 6,
                                          bottom: 6,
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.black.withOpacity(0.6),
                                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_rounded, color: _sand, size: 18),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text('PC Explorer Pic',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _dialogFieldDecoration('Product Name', icon: Icons.shopping_bag_outlined),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: _forest,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _dialogFieldDecoration('Category', icon: Icons.category_outlined),
                              hint: const Text('Select Category', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    decoration: _dialogFieldDecoration('Price (\$)', icon: Icons.attach_money_rounded),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _carbonController,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    decoration: _dialogFieldDecoration('Saves CO2 (kg)', icon: Icons.co2_rounded),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _benefitsController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _dialogFieldDecoration('Benefits (comma separated)', icon: Icons.star_border_rounded),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descController,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _dialogFieldDecoration('Description (optional)', icon: Icons.notes_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          child: _glassDialogButton(
                            label: product == null ? 'Save' : 'Update',
                            icon: _isSaving ? null : Icons.check,
                            isLoading: _isSaving,
                            onTap: _isSaving
                                ? null
                                : () {
                              _saveProduct(dialogContext, setDialogState);
                            },
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
    );
  }

  Widget _themedDialog({
    required IconData icon,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: _forest.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _sand, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: content,
        actions: actions,
      ),
    );
  }

  InputDecoration _dialogFieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: _sand, size: 20) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _sand, width: 1.5),
      ),
    );
  }

  Widget _glassDialogButton({
    required String label,
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else if (icon != null)
              Icon(icon, color: _sand, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD SCREEN BUILDERS
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) => _fabController.reverse(),
        onTapCancel: () => _fabController.reverse(),
        onTap: () => _showProductDialog(),
        child: AnimatedBuilder(
          animation: _fabScale,
          builder: (context, child) => Transform.scale(scale: _fabScale.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: _sand.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: _forest),
                SizedBox(width: 6),
                Text('Add Product', style: TextStyle(color: _forest, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Row(
          children: [
            _glassIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Products',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Organize and update system inventory',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear_rounded, color: Colors.white70),
              onPressed: () => _searchController.clear(),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chipNames = ['All', ..._categories.map((c) => c['name'].toString())];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chipNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = chipNames[index];
          final selected = _categoryFilter == name;
          return ChoiceChip(
            label: Text(name),
            selected: selected,
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.14),
            checkmarkColor: _forest,
            labelStyle: TextStyle(
              color: selected ? _forest : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: selected ? Colors.transparent : Colors.white.withOpacity(0.15)),
            ),
            onSelected: (_) {
              setState(() => _categoryFilter = name);
              _applyFilters();
            },
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _forest,
      backgroundColor: Colors.white,
      onRefresh: () => _loadData(showLoader: false),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.74,
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
    final hasImage = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () => _showProductDialog(product: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_${product['id']}',
                      child: hasImage
                          ? Image.file(File(imagePath), fit: BoxFit.cover)
                          : Container(
                        color: _sage.withOpacity(0.2),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white54, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showProductDialog(product: product),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: const Icon(Icons.edit_rounded, size: 14, color: _forest),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _deleteProduct(product),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.redAccent.withOpacity(0.9),
                              child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product['category'] ?? '',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${product['price']?.toString() ?? '0.0'}',
                            style: const TextStyle(color: _sand, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${product['carbon_saved']?.toString() ?? '0'} kg',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}