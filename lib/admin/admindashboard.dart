import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sustainable/admin/manage_challenges_screen.dart';
import 'package:sustainable/admin/manage_education_certificate_screen.dart';
import 'package:sustainable/admin/manage_recipes_screen.dart';
import 'package:sustainable/admin/manage_tips_screen.dart';
import 'package:sustainable/admin/manage_travel_screen.dart';
import 'package:sustainable/welcome.dart';

import 'manage_categories_screen.dart';
import 'manage_products_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;

  final List<_AdminModule> _modules = [
    _AdminModule(
      title: 'Categories',
      icon: Icons.category_rounded,
      screenBuilder: () => const ManageCategoriesScreen(),
    ),
    _AdminModule(
      title: 'Products',
      icon: Icons.eco_rounded,
      screenBuilder: () => const ManageProductsScreen(),
    ),
    _AdminModule(
      title: 'Challenges',
      icon: Icons.flag_rounded,
      screenBuilder: () => const ManageChallengesScreen(),
    ),
    _AdminModule(
      title: 'Certifications',
      icon: Icons.verified_rounded,
      screenBuilder: () => const ManageEducationScreen(),
    ),
    _AdminModule(
      title: 'Recipes',
      icon: Icons.restaurant_menu_rounded,
      screenBuilder: () => const AdminAddRecipeScreen(),
    ),
    _AdminModule(
      title: 'Energy Tips',
      icon: Icons.bolt_rounded,
      screenBuilder: () => const ManageTipsScreen(),

    ),
    _AdminModule(
      title: 'Eco-Travel',
      icon: Icons.travel_explore_rounded,
      screenBuilder: () => const ManageTravelScreen(),
    ),
    _AdminModule(
      title: 'Education',
      icon: Icons.menu_book_rounded,
      screenBuilder: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _onModuleTap(_AdminModule module) {
    if (module.screenBuilder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${module.title} is being developed...'),
          backgroundColor: const Color(0xFF2F4A3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => module.screenBuilder!()),
    );
  }

  // ─── ✨ LOGOUT LOGIC (PURE & CLEAN) ───────────────────────────────────
  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false, // Yeh poore navigation stack ko clear kar dega
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2F4A3E),
              Color(0xFF5E8570),
              Color(0xFFCBBE9C),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sustainable Living Guide',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Glassmorphic Rounded Logout Button
                    _LogoutButton(onTap: _logout),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _modules.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    final start = (index * 0.08).clamp(0.0, 0.7);
                    final end = (start + 0.4).clamp(0.0, 1.0);
                    final animation = CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(start, end, curve: Curves.easeOutCubic),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: animation.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - animation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: _ModuleCard(
                        module: module,
                        onTap: () => _onModuleTap(module),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminModule {
  final String title;
  final IconData icon;
  final Widget Function()? screenBuilder;

  _AdminModule({
    required this.title,
    required this.icon,
    required this.screenBuilder,
  });
}

class _ModuleCard extends StatefulWidget {
  final _AdminModule module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.module.icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.module.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 🔘 ROUNDED LOGOUT BUTTON WIDGET ──────────────────────────────────
class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.logout_rounded, // Pure rounded logout icon
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}