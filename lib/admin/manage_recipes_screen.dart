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
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isPlantBased = true; // Default plant-based select hoga

  List<Map<String, dynamic>> _recipes = [];
  late final AnimationController _entranceController;

  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);

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
    // DatabaseHelper ke naye function se data load hoga
    final data = await DatabaseHelper.instance.fetchRecipes();
    setState(() {
      _recipes = data;
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
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
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  void _saveRecipe() async {
    // Database mein entry insert ho rahi hai
    await DatabaseHelper.instance.insertRecipe({
      'title': _titleController.text,
      'ingredients': _ingredientsController.text,
      'instructions': _instructionsController.text,
      'is_plant_based': _isPlantBased ? 1 : 0,
    });

    _titleController.clear();
    _ingredientsController.clear();
    _instructionsController.clear();
    setState(() {
      _isPlantBased = true;
    });

    if (!mounted) return;
    Navigator.pop(context); // Dialog band ho jayega
    _loadRecipes(); // List live update ho jayegi

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sustainable Recipe kamyabi se publish ho gayi!'),
        backgroundColor: sage,
      ),
    );
  }

  void _deleteRecipe(int id) async {
    await DatabaseHelper.instance.deleteRecipe(id);
    _loadRecipes();
  }

  void _showAddDialog() {
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
                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.restaurant_menu_rounded, color: sand, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Add Eco-Recipe',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGlassField(
                                controller: _titleController,
                                label: 'Recipe Title (e.g., Avocado Green Salad)',
                              ),
                              const SizedBox(height: 12),

                              // Switch for Plant-Based status
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: SwitchListTile(
                                  title: const Text(
                                    '100% Plant-Based / Organic',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Helps lower food carbon footprint',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                  ),
                                  activeColor: sand,
                                  value: _isPlantBased,
                                  onChanged: (bool value) {
                                    setDialogState(() {
                                      _isPlantBased = value;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildGlassField(
                                controller: _ingredientsController,
                                label: 'Ingredients (Comma separated)',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _instructionsController,
                                label: 'Cooking Instructions & Eco Tips',
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Share Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
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
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Field fill karna zaroori hai' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: sand, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.4)),
      ),
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sustainable Recipes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Manage eco-friendly and organic meal plans', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _recipes.isEmpty
                    ? _staggered(1, const Center(child: Text('Koi recipes add nahi hain. Nayi dish launch karein!', style: TextStyle(color: Colors.white70))))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final item = _recipes[index];
                    final plantBased = item['is_plant_based'] == 1;

                    return _staggered(
                      index,
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: glassBg.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: plantBased
                                    ? const Color(0xFFC5E1A5).withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: plantBased ? const Color(0xFFC5E1A5) : Colors.orange[300],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: plantBased
                                          ? const Color(0xFFC5E1A5).withValues(alpha: 0.2)
                                          : Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      plantBased ? 'PLANT-BASED' : 'ORGANIC / LOCAL',
                                      style: TextStyle(
                                        color: plantBased ? const Color(0xFFC5E1A5) : Colors.orange[200],
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ingredients: ${item['ingredients']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['instructions'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A80)),
                              onPressed: () => _deleteRecipe(item['id']),
                            ),
                          ],
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
        onPressed: _showAddDialog,
        backgroundColor: sage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}