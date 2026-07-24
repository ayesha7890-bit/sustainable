import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sustainable/database/database_helper.dart';

class EcoTipsUserScreen extends StatefulWidget {
  const EcoTipsUserScreen({super.key});

  @override
  State<EcoTipsUserScreen> createState() => _EcoTipsUserScreenState();
}

class _EcoTipsUserScreenState extends State<EcoTipsUserScreen> {
  List<Map<String, dynamic>> _allTips = [];
  List<Map<String, dynamic>> _filteredTips = [];
  bool _isLoading = true;
  String _selectedTab = 'All';
  int _activeCarouselIndex = 0;
  int? _hoveredCardIndex;

  // Premium Green/Nature Theme Colors
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);
  static const Color mintGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _fetchUserTips();
  }

  // Database se dynamic data load karna[cite: 1]
  void _fetchUserTips() async {
    final data = await DatabaseHelper.instance.fetchTravelTips();
    setState(() {
      _allTips = data;
      _filteredTips = data; // Initially all tips visible
      _isLoading = false;
    });
  }

  // Tab change filter logic
  void _filterTips(String category) {
    setState(() {
      _selectedTab = category;
      if (category == 'All') {
        _filteredTips = _allTips;
      } else {
        _filteredTips = _allTips.where((tip) => tip['category'] == category).toList();
      }
    });
  }

  IconData _getCategoryIcon(String? cat) {
    if (cat == 'Travel') return Icons.commute_rounded;
    if (cat == 'Energy') return Icons.bolt_rounded;
    return Icons.delete_sweep_rounded;
  }

  Color _getCategoryColor(String? cat) {
    if (cat == 'Travel') return Colors.cyanAccent;
    if (cat == 'Energy') return Colors.amberAccent;
    return Colors.lightGreenAccent;
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: sand))
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eco-Life Hub', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Live sustainably, reduce your footprint', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.eco_rounded, color: Colors.lightGreenAccent, size: 24),
                      )
                    ],
                  ),
                ),

                // --- 🎡 DYNAMIC HERO CAROUSEL ---
                if (_allTips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  CarouselSlider.builder(
                    itemCount: _allTips.take(5).length, // Top 5 tips dynamically featured
                    options: CarouselOptions(
                      height: 190,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.88,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _activeCarouselIndex = index;
                        });
                      },
                    ),
                    itemBuilder: (context, index, realIndex) {
                      final item = _allTips[index];
                      final cat = item['category'] ?? 'General';
                      bool isActive = index == _activeCarouselIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.symmetric(vertical: isActive ? 6 : 18, horizontal: 4),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: glassBg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _getCategoryColor(cat).withValues(alpha: 0.3), width: isActive ? 1.5 : 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isActive ? 0.3 : 0.1),
                              blurRadius: isActive ? 12 : 4,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getCategoryIcon(cat), color: _getCategoryColor(cat), size: 20),
                                    const SizedBox(width: 8),
                                    Text(cat.toUpperCase(), style: TextStyle(color: _getCategoryColor(cat), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('FEATURED', style: TextStyle(color: sand, fontSize: 9, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item['title'] ?? 'Eco Suggestion', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(item['description'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // --- FILTER TABS ---
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['All', 'Travel', 'Energy', 'Waste'].map((tabName) {
                        bool isSelected = _selectedTab == tabName;
                        return GestureDetector(
                          onTap: () => _filterTips(tabName),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? sand : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Text(
                              tabName == 'All' ? '🌐 All Guides' : tabName,
                              style: TextStyle(color: isSelected ? forest : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Actionable Eco Guidelines', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                // --- LIST VIEW WITH ANIMATED HOVER EFFECT ---
                _filteredTips.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text('No tips available for $_selectedTab', style: const TextStyle(color: Colors.white60))),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTips.length,
                  itemBuilder: (context, index) {
                    final item = _filteredTips[index];
                    final cat = item['category'] ?? 'Travel';
                    bool isHovered = _hoveredCardIndex == index;

                    return GestureDetector(
                      onPanDown: (_) => setState(() => _hoveredCardIndex = index),
                      onPanCancel: () => setState(() => _hoveredCardIndex = null),
                      onTapDown: (_) => setState(() => _hoveredCardIndex = index),
                      onTapUp: (_) => setState(() => _hoveredCardIndex = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        // ✨ HOVER LIFT EFFECT: Card upar ko lift karega touch hone par
                        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isHovered ? glassBg.withValues(alpha: 0.7) : glassBg.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isHovered ? _getCategoryColor(cat) : Colors.white.withValues(alpha: 0.15),
                            width: isHovered ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isHovered ? 0.2 : 0.05),
                              blurRadius: isHovered ? 12 : 4,
                              offset: Offset(0, isHovered ? 6 : 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedScale(
                              scale: isHovered ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(cat).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_getCategoryIcon(cat), color: _getCategoryColor(cat), size: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(
                                    item['description'] ?? 'No description logic added.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}