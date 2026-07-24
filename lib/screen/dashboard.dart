import 'package:flutter/material.dart';
import 'dart:ui'; // Used for premium ImageFilter blur effects
import 'package:firebase_auth/firebase_auth.dart'; // 1. Firebase Auth Import Kiya

// Your Exact Project Path Imports
import 'package:sustainable/screen/home_screen.dart';
import 'package:sustainable/screen/About_contactscreen.dart';
import 'package:sustainable/screen/ChallengesScreen.dart';
import 'package:sustainable/screen/EducationalScreen.dart';
import 'package:sustainable/screen/ForumScreen.dart';
import 'package:sustainable/screen/ImageGalleryScreen.dart';
import 'package:sustainable/screen/ProductsScreen.dart';
import 'package:sustainable/screen/RecipesScreen.dart';
import 'package:sustainable/screen/TipsScreen.dart';
import 'package:sustainable/screen/WasteTrackerScreen.dart';
import 'package:sustainable/screen/carbon_tracker_screen.dart';
import 'package:sustainable/screen/certifications_screen.dart';
import 'package:sustainable/screen/loginpage.dart'; // 2. Login Screen Import Kiya redirect karne ke liye

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> with SingleTickerProviderStateMixin {
  int currentindex = 0;
  late AnimationController _fadeController;

  // Exact Color Palette matching your defined theme
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);

  late final List<Widget> pages;

  // Document Modules Professional Titles corresponding to indices
  final List<String> titles = [
    "EcoWise Home",              // Index 0
    "Carbon Footprint Tracker",  // Index 1
    "Sustainable Challenges",    // Index 2
    "Community Forum",           // Index 3
    "Eco Product Suggestions",   // Index 4
    "Green Certifications Guide",// Index 5
    "Analytics & Waste Tracker", // Index 6
    "Meal & Recipe Planner",     // Index 7
    "Energy & Travel Hub",       // Index 8
    "Educational Content",       // Index 9
    "Eco Image Gallery",         // Index 10
    "About & Support Desk",      // Index 11
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    pages = [
      HomeScreen(onNavigate: (index) => _onPageChanged(index)), // Index 0: Home Page
      carban(),                 // Index 1: Carbon Tracker
      ChallengesScreen(),       // Index 2: Sustainable Challenges
      ForumScreen(),            // Index 3: Community Forum
      ProductsScreen(),         // Index 4: Eco Alternatives
      EducationHubScreen(),     // Index 5: Eco Labels Guide
      WasteTrackerScreen(),     // Index 6: Analytics & Waste Logs
      RecipesScreen(),         // Index 7: Meal Planner
      EcoTipsUserScreen(),// Index 8: Energy & Travel Hub
      EducationalScreen(),      // Index 9: Learning Hub
      ImageGalleryScreen(),     // Index 10: Photo Gallery
      AboutContactScreen(), // Index 11: About & Support Form
    ];

    _fadeController.forward(); // Triggers first screen animation
  }

  void _onPageChanged(int index) {
    if (currentindex == index) return;
    _fadeController.reset();
    setState(() {
      currentindex = index;
    });
    _fadeController.forward(); // Dynamic screen fluid switch trigger
  }

  // 3. Logout function jo account sign out karega aur wapas login par bhejega
  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase Sign Out

      if (!mounted) return;

      // Pop Drawer and clear stack to go back to Login Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully!"),
          backgroundColor: forest,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: ${e.toString()}"),
          backgroundColor: const Color(0xFFE57373),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current user's email dynamic check
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userEmail = currentUser?.email ?? 'citizen@ecowise.com';
    final String userName = currentUser?.displayName ?? 'Eco Citizen';

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
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              titles[currentindex],
              key: ValueKey<int>(currentindex),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: forest.withOpacity(0.82),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),

        drawer: Drawer(
          backgroundColor: Colors.white.withOpacity(0.92),
          elevation: 16,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Premium Profile Card Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [forest, sage],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.eco_rounded, size: 36, color: forest),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: sand,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Level 5: Green Guard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Menu Tiles
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerTile(0, Icons.home_rounded, 'Eco Home'),
                    _buildDrawerTile(1, Icons.co2_rounded, 'Carbon Tracker'),
                    _buildDrawerTile(2, Icons.workspace_premium_outlined, 'Eco Challenges'),
                    _buildDrawerTile(3, Icons.forum_outlined, 'Community Forum'),
                    _buildDrawerTile(4, Icons.shopping_bag_outlined, 'Product Alternatives'),
                    _buildDrawerTile(5, Icons.gavel_rounded, 'Certifications Guide'),
                    _buildDrawerTile(6, Icons.bar_chart_outlined, 'Analytics & Waste'),
                    _buildDrawerTile(7, Icons.restaurant_menu_outlined, 'Recipe & Meal Planner'),
                    _buildDrawerTile(8, Icons.bolt_outlined, 'Energy & Travel Hub'),
                    _buildDrawerTile(9, Icons.menu_book_rounded, 'Educational Hub'),
                    _buildDrawerTile(10, Icons.collections_rounded, 'Inspirational Gallery'),
                    _buildDrawerTile(11, Icons.contact_support_outlined, 'About & Contact Us'),

                    const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),

                    // 4. Premium Design Red Colored Logout Tile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          _handleLogout(); // Trigger Logout Function
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Log out",
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        body: FadeTransition(
          opacity: _fadeController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
              ),
              child: pages[currentindex],
            ),
          ),
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: forest.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / 4;
                      final bool isBottomTabActive = currentindex >= 0 && currentindex <= 3;
                      final int displayIndex = isBottomTabActive ? currentindex : 0;

                      return Stack(
                        children: [
                          if (isBottomTabActive)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutBack,
                              left: displayIndex * tabWidth + 8,
                              top: 8,
                              bottom: 8,
                              width: tabWidth - 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [forest, sage],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: forest.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(child: _buildBottomTab(0, Icons.home_rounded, 'Home')),
                              Expanded(child: _buildBottomTab(1, Icons.analytics_rounded, 'Tracker')),
                              Expanded(child: _buildBottomTab(2, Icons.emoji_events_rounded, 'Challenges')),
                              Expanded(child: _buildBottomTab(3, Icons.forum_rounded, 'Forum')),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, IconData icon, String title) {
    return HoverableDrawerTile(
      index: index,
      currentIndex: currentindex,
      icon: icon,
      title: title,
      onTap: () {
        _onPageChanged(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBottomTab(int index, IconData icon, String label) {
    final bool isSelected = currentindex == index;
    return HoverableBottomTab(
      index: index,
      isSelected: isSelected,
      icon: icon,
      label: label,
      activeColor: Colors.white,
      inactiveColor: Colors.grey.shade600,
      onTap: () => _onPageChanged(index),
    );
  }
}

// Custom interactive Hoverable Drawer Tile
class HoverableDrawerTile extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const HoverableDrawerTile({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<HoverableDrawerTile> createState() => _HoverableDrawerTileState();
}

class _HoverableDrawerTileState extends State<HoverableDrawerTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.currentIndex == widget.index;
    const Color forest = Color(0xFF2F4A3E);
    const Color sage = Color(0xFF5E8570);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? forest.withOpacity(0.12)
              : (_isHovered ? sage.withOpacity(0.08) : Colors.transparent),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 4,
                  height: isSelected ? 24 : (_isHovered ? 12 : 0),
                  decoration: BoxDecoration(
                    color: isSelected ? forest : sage,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected || _isHovered ? 10 : 0,
                ),
                AnimatedScale(
                  scale: isSelected ? 1.15 : (_isHovered ? 1.08 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    color: isSelected ? forest : (_isHovered ? forest : Colors.black54),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? forest : (_isHovered ? forest : Colors.black87),
                    ),
                    child: Text(widget.title),
                  ),
                ),
                AnimatedOpacity(
                  opacity: isSelected || _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: forest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom interactive Hoverable Bottom Navigation Tab
class HoverableBottomTab extends StatefulWidget {
  final int index;
  final bool isSelected;
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const HoverableBottomTab({
    super.key,
    required this.index,
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<HoverableBottomTab> createState() => _HoverableBottomTabState();
}

class _HoverableBottomTabState extends State<HoverableBottomTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedScale(
            scale: widget.isSelected ? 1.02 : (_isHovered ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: !widget.isSelected && _isHovered
                    ? Colors.black.withOpacity(0.04)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isSelected ? widget.activeColor : widget.inactiveColor,
                    size: 19,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: widget.isSelected
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.activeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                      ],
                    )
                        : (_isHovered
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.inactiveColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    )
                        : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}