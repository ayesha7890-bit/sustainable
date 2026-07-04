import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _searchController = TextEditingController();
  final _bulkAddController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _isLoading = true;
  bool _isImporting = false;
  int? _editingId;

  late AnimationController _headerController;
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  // ---- Design system ----
  static const Color _forest = Color(0xFF2F4A3E);
  static const Color _sage = Color(0xFF5E8570);
  static const Color _sand = Color(0xFFCBBE9C);

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
    _refreshCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _searchController.dispose();
    _bulkAddController.dispose();
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // DATA LAYER
  // ---------------------------------------------------------------

  Future<void> _refreshCategories({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchCategories();
    setState(() {
      _categories = data;
      _filtered = _applySearch(_categories, _searchController.text);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _applySearch(
      List<Map<String, dynamic>> source, String query) {
    if (query.trim().isEmpty) return List.from(source);
    return source
        .where((c) => c['name']
        .toString()
        .toLowerCase()
        .contains(query.trim().toLowerCase()))
        .toList();
  }

  void _onSearchChanged() {
    setState(() {
      _filtered = _applySearch(_categories, _searchController.text);
    });
  }

  Future<void> _saveCategory(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) return;
    final name = _categoryNameController.text.trim();
    final wasEditing = _editingId != null;

    try {
      if (!wasEditing) {
        await DatabaseHelper.instance.insertCategory(name);
      } else {
        await DatabaseHelper.instance.updateCategory(_editingId!, name);
      }

      _categoryNameController.clear();
      _editingId = null;

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      await _refreshCategories();
      _showSnack(wasEditing
          ? 'Category update ho gayi! ✏️'
          : 'Category add ho gayi! ✅');
    } catch (e) {
      debugPrint('Save category error: $e');
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

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirm = await _confirmDeleteDialog(category['name']);
    if (confirm != true) return;

    await DatabaseHelper.instance.deleteCategory(category['id']);
    _showSnack('Category delete ho gayi! 🗑️');
    _refreshCategories();
  }

  Future<void> _bulkAddCategories() async {
    final text = _bulkAddController.text;
    final rawNames = text
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (rawNames.isEmpty) {
      _showSnack('Koi valid category naam nahi mila.', isError: true);
      return;
    }

    setState(() => _isImporting = true);
    try {
      int added = 0;
      for (final name in rawNames) {
        final alreadyExists = _categories.any(
                (c) => c['name'].toString().toLowerCase() == name.toLowerCase());
        if (!alreadyExists) {
          await DatabaseHelper.instance.insertCategory(name);
          added++;
        }
      }

      await _refreshCategories();
      _bulkAddController.clear();
      if (mounted) Navigator.pop(context);
      setState(() => _isImporting = false);
      _showSnack('$added nayi categories add ho gayin! 📥');
    } catch (e) {
      setState(() => _isImporting = false);
      _showSnack('Bulk add fail ho gaya: $e', isError: true);
    }
  }

  // ---------------------------------------------------------------
  // DIALOGS
  // ---------------------------------------------------------------

  void _showBulkAddDialog() {
    _bulkAddController.clear();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) => _themedDialog(
              icon: Icons.playlist_add_rounded,
              title: 'Bulk Add Categories',
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multiple naam paste ya type karein — comma (,) ya '
                          'nayi line se separate karein.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _forest.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bulkAddController,
                      autofocus: true,
                      maxLines: 5,
                      decoration: _dialogFieldDecoration(
                          'Fruits, Vegetables, Dairy...'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: TextStyle(color: _forest.withValues(alpha: 0.6))),
                ),
                _gradientDialogButton(
                  label: 'Add All',
                  icon: _isImporting ? null : Icons.check_rounded,
                  isLoading: _isImporting,
                  onTap: _isImporting
                      ? null
                      : () async {
                    setDialogState(() {});
                    await _bulkAddCategories();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeleteDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _themedDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete Category?',
        content: Text(
          'Kya aap "$name" ko delete karna chahte hain?',
          style: TextStyle(color: _forest.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: _forest.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({Map<String, dynamic>? category}) {
    _editingId = category?['id'];
    _categoryNameController.text = category?['name'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
          ),
          child: _themedDialog(
            icon: category == null ? Icons.add_circle_rounded : Icons.edit_rounded,
            title: category == null ? 'Nayi Category' : 'Category Edit Karein',
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _categoryNameController,
                autofocus: true,
                decoration: _dialogFieldDecoration('Category Ka Naam',
                    icon: Icons.label_outline_rounded),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Naam likhna zaroori hai'
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _categoryNameController.clear();
                  _editingId = null;
                  Navigator.pop(dialogContext);
                },
                child: Text('Cancel',
                    style: TextStyle(color: _forest.withValues(alpha: 0.6))),
              ),
              _gradientDialogButton(
                label: category == null ? 'Save' : 'Update',
                icon: Icons.check_rounded,
                onTap: () => _saveCategory(dialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themedDialog({
    required IconData icon,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_forest, _sage]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _forest, fontSize: 17),
            ),
          ),
        ],
      ),
      content: content,
      actions: actions,
    );
  }

  InputDecoration _dialogFieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: _sage) : null,
      filled: true,
      fillColor: _sand.withValues(alpha: 0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _sage, width: 1.5),
      ),
    );
  }

  Widget _gradientDialogButton({
    required String label,
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_forest, _sage]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) => _fabController.reverse(),
        onTapCancel: () => _fabController.reverse(),
        onTap: () => _showFormDialog(),
        child: AnimatedBuilder(
          animation: _fabScale,
          builder: (context, child) =>
              Transform.scale(scale: _fabScale.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sage, _sand]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _forest.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Add Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    'Manage Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Add, edit ya delete karein',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            _glassIconButton(
              icon: _isImporting
                  ? Icons.hourglass_top_rounded
                  : Icons.playlist_add_rounded,
              onTap: _isImporting ? null : _showBulkAddDialog,
            ),
            const SizedBox(width: 10),
            _glassIconButton(
              icon: Icons.refresh_rounded,
              onTap: () => _refreshCategories(),
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
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Category dhoondhein...',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _forest,
      backgroundColor: Colors.white,
      onRefresh: () => _refreshCategories(showLoader: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final category = _filtered[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 400)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 24),
                  child: child,
                ),
              );
            },
            child: _buildCategoryCard(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name'].toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_sage, _sand]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
              ),
            ),
          ),
          _roundIconButton(
            icon: Icons.edit_outlined,
            onTap: () => _showFormDialog(category: category),
          ),
          const SizedBox(width: 6),
          _roundIconButton(
            icon: Icons.delete_outline_rounded,
            onTap: () => _deleteCategory(category),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDanger ? Colors.redAccent : Colors.white)
              .withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDanger ? Colors.redAccent.shade100 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Koi category nahi mili',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Neeche "Add Category" button se nayi category add karein\nya upar "Bulk Add" istemal karein.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}