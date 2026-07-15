import 'package:flutter/material.dart';
import 'dart:ui'; // Used for dynamic premium blur effects
import '../database/database_helper.dart';

class Recipe {
  final int id;
  final String title;
  final String category;
  final String carbonImpact; // "Low", "Medium", "High"
  final String preparationTime;
  final List<String> ingredients;
  final List<String> instructions;
  final String ecoBenefit;
  final String iconName;

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.carbonImpact,
    required this.preparationTime,
    required this.ingredients,
    required this.instructions,
    required this.ecoBenefit,
    required this.iconName,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      carbonImpact: map['carbon_impact'] as String,
      preparationTime: map['prep_time'] as String,
      ingredients: (map['ingredients_csv'] as String).split(','),
      instructions: (map['instructions_csv'] as String).split(','),
      ecoBenefit: map['eco_benefit'] as String,
      iconName: map['icon_name'] as String,
    );
  }
}

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  String _searchQuery = "";
  String _selectedCategory = "All";

  // Exact EcoWise Theme Palette Colors
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);

  // Meal Planner State
  final Map<String, String> _weeklyPlan = {
    "Monday": "Spiced Lentil Shepherd's Pie",
    "Tuesday": "Creamy Coconut Chickpea Curry",
    "Wednesday": "Not Planned",
    "Thursday": "Not Planned",
    "Friday": "Not Planned",
    "Saturday": "Not Planned",
    "Sunday": "Not Planned",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Future<void> _loadRecipes() async {
  //   final list = await DatabaseHelper.instance.getRecipes();
  //   setState(() {
  //     _recipes = list.map((m) => Recipe.fromMap(m)).toList();
  //     _isLoading = false;
  //   });
  // }
  Future<void> _loadRecipes() async {
    final list = await DatabaseHelper.instance.fetchRecipes(); // 'getRecipes' ki jagah 'fetchRecipes' kiya
    setState(() {
      _recipes = list.map((m) => Recipe.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  IconData _getIconData(String name) {
    switch (name) {
      case "pie_chart": return Icons.pie_chart;
      case "soup_kitchen": return Icons.soup_kitchen;
      case "breakfast_dining": return Icons.breakfast_dining;
      case "bowl_food": return Icons.restaurant;
      default: return Icons.restaurant;
    }
  }

  List<Recipe> get _filteredRecipes {
    return _recipes.where((r) {
      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.ecoBenefit.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showRecipeDetails(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Keeps gradient/blur styling beautiful
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: forest.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: forest.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: sage.withOpacity(0.15),
                          child: Icon(_getIconData(recipe.iconName), color: forest, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: forest,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Category: ${recipe.category} • Prep: ${recipe.preparationTime}",
                                style: TextStyle(color: forest.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 36, thickness: 1),

                    // Carbon footprint detail card with Premium Eco Colors
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sage.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sage.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.co2_rounded, color: forest, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Carbon Footprint: ${recipe.carbonImpact} Impact",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: forest, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.ecoBenefit,
                                  style: TextStyle(fontSize: 12.5, color: forest.withOpacity(0.8), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ingredients
                    const Text(
                      "Ingredients",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: forest, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_rounded, size: 14, color: sage),
                          const SizedBox(width: 10),
                          Text(
                            ing.trim(),
                            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Instructions
                    const Text(
                      "Preparation Steps",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: forest, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.instructions.asMap().entries.map((entry) {
                      final stepNumber = entry.key + 1;
                      final stepText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: sage,
                              child: Text(
                                "$stepNumber",
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stepText.trim(),
                                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Premium Theme Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: forest,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddToPlannerDialog(recipe);
                        },
                        child: const Text(
                          "Add to Weekly Meal Plan",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddToPlannerDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Select Day",
          style: TextStyle(color: forest, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _weeklyPlan.keys.map((day) {
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sage),
                onTap: () {
                  setState(() {
                    _weeklyPlan[day] = recipe.title;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Added ${recipe.title} to $day's menu!"),
                      backgroundColor: forest,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ["All", "Breakfast", "Lunch", "Dinner"];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [forest, sage, sand],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background transparent kiya gradients ke liye
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            "Sustainable Meal Planner",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 19),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: sand,
            indicatorWeight: 3.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: "Recipes", icon: Icon(Icons.menu_book_rounded, size: 20)),
              Tab(text: "Schedule", icon: Icon(Icons.calendar_month_rounded, size: 20)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Recipes
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search plant-based recipes...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => setState(() => _searchQuery = ""),
                      )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Categories chips in Custom Sand Highlighting style
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: sand,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: isSelected
                              ? BorderSide(color: sand, width: 1.5)

                              : BorderSide(
                            color: isSelected ? sand : Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? forest : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Glassmorphic Recipes list
                Expanded(
                  child: _filteredRecipes.isEmpty
                      ? const Center(child: Text("No recipes found.", style: TextStyle(color: Colors.white60, fontSize: 15)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _filteredRecipes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: sage.withOpacity(0.15),
                            child: Icon(_getIconData(recipe.iconName), color: forest),
                          ),
                          title: Text(
                            recipe.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: forest, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Category: ${recipe.category} • Prep: ${recipe.preparationTime}",
                              style: TextStyle(color: forest.withOpacity(0.7), fontSize: 12),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: sage.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${recipe.carbonImpact} CO₂",
                              style: const TextStyle(color: forest, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () => _showRecipeDetails(context, recipe),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // TAB 2: Weekly Schedule (Sleek Theme Matched List)
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _weeklyPlan.length,
              itemBuilder: (context, index) {
                final day = _weeklyPlan.keys.elementAt(index);
                final plannedRecipeName = _weeklyPlan[day]!;
                final isPlanned = plannedRecipeName != "Not Planned";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isPlanned ? Colors.white.withOpacity(0.92) : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlanned ? sand : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 85,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: forest, fontSize: 15),
                      ),
                    ),
                    title: Text(
                      plannedRecipeName,
                      style: TextStyle(
                        fontWeight: isPlanned ? FontWeight.bold : FontWeight.w500,
                        color: isPlanned ? forest : Colors.black38,
                        fontSize: 14.5,
                      ),
                    ),
                    trailing: isPlanned
                        ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
                      onPressed: () {
                        setState(() {
                          _weeklyPlan[day] = "Not Planned";
                        });
                      },
                    )
                        : const Icon(Icons.add_circle_outline_rounded, size: 22, color: sage),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}