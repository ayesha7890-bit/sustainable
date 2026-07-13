import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double carbonSavedKg;
  final String description;
  final String iconName;
  final List<String> benefits;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.carbonSavedKg,
    required this.description,
    required this.iconName,
    required this.benefits,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num? ?? 0.0).toDouble(),
      carbonSavedKg: (map['carbon_saved'] as num? ?? 25.0).toDouble(),
      description: map['description'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'eco',
      benefits: (map['benefits_csv'] as String? ?? 'Eco Friendly,Sustainable').split(','),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _allProducts = [];
  bool _isLoading = true;

  String _searchQuery = "";
  String _selectedCategory = "All";
  String _sortBy = "Rating";

  // Premium Green Theme Colors
  static const Color forest = Color(0xFF1E3A2F);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFF4EAE1);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await DatabaseHelper.instance.fetchProducts();
    setState(() {
      _allProducts = list.map((m) => Product.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  IconData _getIconData(String name) {
    switch (name) {
      case "water_drop": return Icons.water_drop_outlined;
      case "wrap_text": return Icons.wrap_text_outlined;
      case "lightbulb": return Icons.lightbulb_outline;
      case "brush": return Icons.brush_outlined;
      case "shopping_bag": return Icons.shopping_bag_outlined;
      case "solar_power": return Icons.solar_power_outlined;
      case "blur_circular": return Icons.blur_circular_outlined;
      case "delete_outline": return Icons.delete_outline;
      case "compost": return Icons.compost_outlined;
      default: return Icons.eco_outlined;
    }
  }

  List<Product> get _filteredProducts {
    List<Product> result = _allProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" || p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortBy == "Price: Low to High") {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == "Price: High to Low") {
      result.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == "Carbon Saved") {
      result.sort((a, b) => b.carbonSavedKg.compareTo(a.carbonSavedKg));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ["All", "Kitchen", "Bathroom", "Travel", "Energy", "Laundry"];

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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Sustainable Marketplace",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
          color: forest,
          onRefresh: _loadProducts,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  style: const TextStyle(color: forest),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search sustainable alternatives...",
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(Icons.search_outlined, color: sage),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: forest),
                      onPressed: () => setState(() => _searchQuery = ""),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Sort Dropdown (Fixed styling here)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sort products by:",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                    ),
                    DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: sand,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: forest, fontWeight: FontWeight.w600),
                      underline: Container(height: 1.5, color: Colors.white),
                      items: ["Rating", "Price: Low to High", "Price: High to Low", "Carbon Saved"].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(val, style: const TextStyle(fontSize: 13, color: forest)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortBy = val);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Scrollable Category Chips
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        disabledColor: Colors.transparent,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        checkmarkColor: forest,
                        labelStyle: TextStyle(
                          color: isSelected ? forest : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Main Grid View List
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(
                  child: Text(
                    "No products found in this category.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
                    : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(context, product);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 95,
                decoration: BoxDecoration(
                  color: sage.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _getIconData(product.iconName),
                  size: 38,
                  color: forest,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                product.category.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sage, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: forest, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Text(
                "Saves ${product.carbonSavedKg.toInt()} kg CO₂/yr",
                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              Text(
                "\$${product.price.toStringAsFixed(2)}",
                // Fixed: Changed FontWeight.black to FontWeight.w900
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: forest),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
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
                        child: Icon(_getIconData(product.iconName), size: 28, color: forest),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: forest),
                            ),
                            Text(
                              "Category: ${product.category}",
                              style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PRICE", style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
                          Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            // Fixed: Changed FontWeight.black to FontWeight.w900
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: forest),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("ANNUAL CO₂ SAVING", style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
                          Text(
                            "${product.carbonSavedKg.toInt()} kg",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Colors.black12),
                  ),
                  const Text("Alternative Swap Benefit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: forest)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(height: 1.4, fontSize: 13.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  const Text("Key Environmental Benefits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: forest)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.benefits.map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        // Fixed: Changed Border.line to Border.all
                        border: Border.all(color: sage.withOpacity(0.3), width: 1),
                      ),
                      child: Text(b.trim(), style: const TextStyle(fontSize: 11.5, color: forest, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Redirecting to purchase ${product.name}... (Sustainable Swap Logged!)"),
                            backgroundColor: forest,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Perform Sustainable Swap", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}