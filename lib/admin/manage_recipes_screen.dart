import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AdminAddRecipeScreen extends StatefulWidget {
  const AdminAddRecipeScreen({super.key});

  @override
  State<AdminAddRecipeScreen> createState() => _AdminAddRecipeScreenState();
}

class _AdminAddRecipeScreenState extends State<AdminAddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _ecoBenefitController = TextEditingController();

  // Dropdown States
  bool _isPlantBased = true;
  String _selectedCategory = 'Lunch';
  String _selectedCarbonImpact = 'Low';
  String _selectedIcon = 'bowl_food';

  // Exact EcoWise Theme Palette Colors
  static const Color forest = Color(0xFF1E3027); // Dark premium forest green
  static const Color cardBg = Color(0xFF283B32); // Slightly lighter translucent green
  static const Color sand = Color(0xFFCBBE9C); // Signature accent gold/sand
  static const Color textLight = Color(0xFFE2EBE7);

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner'];
  final List<String> _carbonImpacts = ['Low', 'Medium', 'High'];
  final Map<String, IconData> _icons = {
    'bowl_food': Icons.restaurant_rounded,
    'breakfast_dining': Icons.breakfast_dining_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,
    'pie_chart': Icons.pie_chart_rounded,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _prepTimeController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _ecoBenefitController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipeToDb() async {
    if (!_formKey.currentState!.validate()) return;

    final newRecipe = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'carbon_impact': _selectedCarbonImpact,
      'prep_time': _prepTimeController.text.trim().isEmpty ? '20 mins' : _prepTimeController.text.trim(),

      // 💡 BACKWARD COMPATIBILITY FIX:
      // Purane columns ko bhi data de rahe hain taaki NOT NULL constraint failed na ho
      'ingredients': _ingredientsController.text.trim(),
      'instructions': _instructionsController.text.trim(),

      // Naye columns jo list splitting ke liye use hote hain
      'ingredients_csv': _ingredientsController.text.trim(),
      'instructions_csv': _instructionsController.text.trim(),

      'eco_benefit': _ecoBenefitController.text.trim().isEmpty
          ? 'This organic, plant-based meal significantly lowers greenhouse emissions.'
          : _ecoBenefitController.text.trim(),
      'icon_name': _selectedIcon,
      'is_plant_based': _isPlantBased ? 1 : 0,
    };

    try {
      await DatabaseHelper.instance.insertRecipe(newRecipe);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Eco-Recipe Shared Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Screen close karke piche chala jayega
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Common input styling matching your dark eco UI
  InputDecoration _inputStyle(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textLight.withOpacity(0.4), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: textLight.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: sand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sustainable Recipes",
              style: TextStyle(fontWeight: FontWeight.bold, color: textLight, fontSize: 18),
            ),
            Text(
              "Manage eco-friendly and organic meal plans",
              style: TextStyle(color: textLight.withOpacity(0.5), fontSize: 11),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: textLight.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Inside Form Card
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu_rounded, color: sand, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      "Add Eco-Recipe",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 1. Recipe Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Recipe Title (e.g., Avocado Green Salad)"),
                  validator: (v) => v!.isEmpty ? "Title cannot be empty" : null,
                ),
                const SizedBox(height: 16),

                // 2. Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: cardBg,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Category"),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 16),

                // 3. Prep Time
                TextFormField(
                  controller: _prepTimeController,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Prep Time (e.g., 25 mins)"),
                  validator: (v) => v!.isEmpty ? "Prep time is required" : null,
                ),
                const SizedBox(height: 16),

                // 4. Plant Based Toggle Widget
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textLight.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "100% Plant-Based / Organic",
                              style: TextStyle(fontWeight: FontWeight.bold, color: textLight, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Helps lower food carbon footprint",
                              style: TextStyle(color: textLight.withOpacity(0.4), fontSize: 11),
                            )
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPlantBased,
                        activeColor: forest,
                        activeTrackColor: sand,
                        inactiveThumbColor: textLight.withOpacity(0.4),
                        inactiveTrackColor: Colors.white.withOpacity(0.08),
                        onChanged: (val) => setState(() => _isPlantBased = val),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Carbon Impact Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCarbonImpact,
                  dropdownColor: cardBg,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Carbon Impact"),
                  items: _carbonImpacts.map((ci) {
                    return DropdownMenuItem(value: ci, child: Text("$ci Impact"));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCarbonImpact = val!),
                ),
                const SizedBox(height: 16),

                // 6. App Icon Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIcon,
                  dropdownColor: cardBg,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("App Icon"),
                  items: _icons.keys.map((iconKey) {
                    return DropdownMenuItem(
                      value: iconKey,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icons[iconKey], color: sand, size: 18),
                          const SizedBox(width: 8),
                          Text(iconKey.replaceAll('_', ' ')),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedIcon = val!),
                ),
                const SizedBox(height: 16),

                // 7. Ingredients (Comma Separated)
                TextFormField(
                  controller: _ingredientsController,
                  maxLines: 3,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Ingredients (Comma separated: Oats, Milk, Berries)"),
                  validator: (v) => v!.isEmpty ? "Please add ingredients" : null,
                ),
                const SizedBox(height: 16),

                // 8. Cooking Instructions (Comma Separated)
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 4,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Cooking Instructions (Comma separated per step)"),
                  validator: (v) => v!.isEmpty ? "Please add steps" : null,
                ),
                const SizedBox(height: 16),

                // 9. Eco Benefit Info Text Field
                TextFormField(
                  controller: _ecoBenefitController,
                  maxLines: 3,
                  style: const TextStyle(color: textLight),
                  decoration: _inputStyle("Eco-Benefit (Why this is good for planet?)"),
                  validator: (v) => v!.isEmpty ? "Please add sustainable details" : null,
                ),
                const SizedBox(height: 28),

                // Actions: Cancel & Share Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: textLight.withOpacity(0.8), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E8570), // Sage green accent button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _saveRecipeToDb,
                      icon: const Text(
                        "Share Recipe",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      label: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}