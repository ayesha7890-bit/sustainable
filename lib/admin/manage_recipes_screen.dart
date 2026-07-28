import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';

class ManageRecipesScreen extends StatefulWidget {
  const ManageRecipesScreen({super.key});

  @override
  State<ManageRecipesScreen> createState() => _ManageRecipesScreenState();
}

class _ManageRecipesScreenState extends State<ManageRecipesScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _ecoBenefitController = TextEditingController();

  // Dropdown / toggle states
  bool _isPlantBased = true;
  String _selectedCategory = 'Lunch';
  String _selectedCarbonImpact = 'Low';
  String _selectedIcon = 'bowl_food';

  List<Map<String, dynamic>> _recipes = [];
  late final AnimationController _entranceController;

  // Track karne ke liye ke naya add ho raha hai ya edit
  int? _editingRecipeId;

  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner'];
  final List<String> _carbonImpacts = ['Low', 'Medium', 'High'];
  final Map<String, IconData> _icons = {
    'bowl_food': Icons.restaurant_rounded,
    'breakfast_dining': Icons.breakfast_dining_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,
    'pie_chart': Icons.pie_chart_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  void _loadRecipes() async {
    // NOTE: DatabaseHelper mein fetchRecipes() method add karna hoga (fetchChallenges ki tarah)
    final data = await DatabaseHelper.instance.fetchRecipes();
    setState(() {
      _recipes = data;
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
    _prepTimeController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _ecoBenefitController.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position:
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  // Combined Add aur Edit Logic
  Future<void> _saveRecipe() async {
    final recipeData = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'carbon_impact': _selectedCarbonImpact,
      'prep_time': _prepTimeController.text.trim().isEmpty
          ? '20 mins'
          : _prepTimeController.text.trim(),

      'ingredients_csv': _ingredientsController.text.trim(),
      'instructions_csv': _instructionsController.text.trim(),

      'eco_benefit': _ecoBenefitController.text.trim().isEmpty
          ? 'This organic, plant-based meal significantly lowers greenhouse emissions.'
          : _ecoBenefitController.text.trim(),
      'icon_name': _selectedIcon,
      'is_plant_based': _isPlantBased ? 1 : 0,
    };

    String successMessage = '';

    try {
      if (_editingRecipeId == null) {
        // Create New
        await DatabaseHelper.instance.insertRecipe(recipeData);
        successMessage = '🎉 Eco-Recipe Shared Successfully!';
      } else {
        // Update Existing
        // NOTE: DatabaseHelper mein updateRecipe() method add karna hoga (updateChallenge ki tarah)
        recipeData['id'] = _editingRecipeId!;
        await DatabaseHelper.instance.updateRecipe(recipeData);
        successMessage = 'Recipe updated successfully!';
      }

      _clearForm();

      if (!mounted) return;
      Navigator.pop(context);
      _loadRecipes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: sage),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _prepTimeController.clear();
    _ingredientsController.clear();
    _instructionsController.clear();
    _ecoBenefitController.clear();
    _isPlantBased = true;
    _selectedCategory = 'Lunch';
    _selectedCarbonImpact = 'Low';
    _selectedIcon = 'bowl_food';
    _editingRecipeId = null;
  }

  void _deleteRecipe(int id) async {
    // NOTE: DatabaseHelper mein deleteRecipe() method add karna hoga (deleteChallenge ki tarah)
    await DatabaseHelper.instance.deleteRecipe(id);
    _loadRecipes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe deleted'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Edit Mode On karke dialog kholne ka method
  void _editRecipe(Map<String, dynamic> item) {
    _editingRecipeId = item['id'];
    _titleController.text = (item['title'] ?? '').toString();
    _prepTimeController.text = (item['prep_time'] ?? '').toString();
    _ingredientsController.text =
        (item['ingredients_csv'] ?? item['ingredients'] ?? '').toString();
    _instructionsController.text =
        (item['instructions_csv'] ?? item['instructions'] ?? '').toString();
    _ecoBenefitController.text = (item['eco_benefit'] ?? '').toString();
    _selectedCategory = (item['category'] ?? 'Lunch').toString();
    _selectedCarbonImpact = (item['carbon_impact'] ?? 'Low').toString();
    _selectedIcon = (item['icon_name'] ?? 'bowl_food').toString();
    _isPlantBased = (item['is_plant_based'] ?? 1) == 1;

    _showRecipeDialog();
  }

  void _showRecipeDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim.value,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Form(
                  key: _formKey,
                  child: AlertDialog(
                    backgroundColor: glassBg.withValues(alpha: 0.98),
                    insetPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded,
                            color: sand, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _editingRecipeId == null
                              ? 'Add Eco-Recipe'
                              : 'Edit Eco-Recipe',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGlassField(
                                controller: _titleController,
                                label: 'Recipe Title (e.g. Avocado Green Salad)',
                              ),
                              const SizedBox(height: 12),
                              _buildGlassDropdown(
                                label: 'Category',
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (val) => setDialogState(
                                        () => _selectedCategory = val!),
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _prepTimeController,
                                label: 'Prep Time (e.g. 25 mins)',
                              ),
                              const SizedBox(height: 12),
                              // Plant Based Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                      Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Plant-Based / Organic',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Switch(
                                      value: _isPlantBased,
                                      activeColor: forest,
                                      activeTrackColor: sand,
                                      inactiveThumbColor:
                                      Colors.white.withValues(alpha: 0.5),
                                      inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.08),
                                      onChanged: (val) => setDialogState(
                                              () => _isPlantBased = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildGlassDropdown(
                                label: 'Carbon Impact',
                                value: _selectedCarbonImpact,
                                items: _carbonImpacts,
                                onChanged: (val) => setDialogState(
                                        () => _selectedCarbonImpact = val!),
                              ),
                              const SizedBox(height: 12),
                              _buildGlassDropdown(
                                label: 'App Icon',
                                value: _selectedIcon,
                                items: _icons.keys.toList(),
                                onChanged: (val) => setDialogState(
                                        () => _selectedIcon = val!),
                                iconMap: _icons,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _ingredientsController,
                                label:
                                'Ingredients (comma separated: Oats, Milk, Berries)',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _instructionsController,
                                label:
                                'Instructions (comma separated per step)',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _ecoBenefitController,
                                label: 'Eco-Benefit (why is this good for planet?)',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold)),
                      ),
                      Material(
                        color: sage,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              _saveRecipe();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _editingRecipeId == null
                                      ? 'Share Recipe'
                                      : 'Update Recipe',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _editingRecipeId == null
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.check_circle_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'This field is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: sand, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.4)),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    Map<String, IconData>? iconMap,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: glassBg,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: sand, width: 1.4)),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: iconMap == null
              ? Text(item)
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconMap[item], color: sand, size: 16),
              const SizedBox(width: 8),
              Text(item.replaceAll('_', ' ')),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [forest, sage, sand],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eco-Recipes Hub',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Manage sustainable meal plans',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _recipes.isEmpty
                    ? _staggered(
                  1,
                  const Center(
                    child: Text('No recipes added yet!',
                        style: TextStyle(color: Colors.white70)),
                  ),
                )
                    : ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final item = _recipes[index];
                    final iconKey =
                    (item['icon_name'] ?? 'bowl_food').toString();
                    return _staggered(
                      index,
                      GestureDetector(
                        onTap: () => _editRecipe(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: glassBg.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.amber
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _icons[iconKey] ??
                                      Icons.restaurant_rounded,
                                  color: sand,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: sage.withValues(
                                                  alpha: 0.3),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                          child: Text(
                                              '${item['category']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                          child: Text(
                                              '${item['carbon_impact']} Impact',
                                              style: const TextStyle(
                                                  color: sand,
                                                  fontSize: 10,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ),
                                        if ((item['is_plant_based'] ??
                                            0) ==
                                            1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withValues(
                                                    alpha: 0.25),
                                                borderRadius:
                                                BorderRadius.circular(
                                                    6)),
                                            child: const Text('Plant-Based',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                    FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('${item['title']}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Prep: ${item['prep_time'] ?? '-'}',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFFF8A80)),
                                onPressed: () =>
                                    _deleteRecipe(item['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showRecipeDialog();
        },
        backgroundColor: sage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}