import 'dart:ui'; // Fixes: Undefined name 'ImageFilter'
import 'package:flutter/material.dart';

// colors.dart
class AppColors {
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
}

// about_us_screen.dart
class AboutUsScreen extends StatefulWidget {
  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Beautiful gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.forest,           // #2F4A3E
              Color(0xFF4a6b5c),         // Transition 1
              Color(0xFF6d8b7b),         // Transition 2
              Color(0xFF9bab99),         // Transition 3
              AppColors.sand,             // #CBBE9C
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable Content
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavBar(),
                    _buildHeroSection(),
                    _buildMissionCard(),
                    _buildServicesGrid(),
                    _buildStatsSection(),
                    _buildValuesSection(),
                    _buildCTASection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation Bar
  Widget _buildNavBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'About Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 48), // Balancing spacer
        ],
      ),
    );
  }

  // Hero Section
  Widget _buildHeroSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.eco_rounded, size: 72, color: AppColors.sand),
          SizedBox(height: 16),
          Text(
            'Nature Conscious',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Making the world greener, step by step.',
            // textAlign: Center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Glass Card Widget
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: _buildGlassCard(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.forest, AppColors.sage],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'We empower you to track environmental impact and implement sustainable habits in your everyday life seamlessly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Services Grid
  Widget _buildServicesGrid() {
    final List<Map> services = [
      {'icon': '🌱', 'title': 'Eco Tracking', 'description': 'Monitor your carbon footprint daily.'},
      {'icon': '🔄', 'title': 'Recycling Guides', 'description': 'Learn how to recycle efficiently.'},
      {'icon': '☀️', 'title': 'Green Energy', 'description': 'Tips on shifting to clean energy solutions.'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(
          services.length,
              (index) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildServiceCard(index, services[index]),
          ),
        ),
      ),
    );
  }

  // Service Card with Animation
  Widget _buildServiceCard(int index, Map service) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(0.3 + (index * 0.08), 1, curve: Curves.easeOutBack),
        ),
      ),
      child: _buildGlassCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Text(service['icon'], style: TextStyle(fontSize: 24)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      service['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stats Section
  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('10K+', 'Active Users'),
          _buildStatItem('50 Tons', 'CO2 Saved'),
          _buildStatItem('100K+', 'Trees Planted'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forest),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  // Values Section
  Widget _buildValuesSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: _buildGlassCard(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Core Values',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forest),
              ),
              SizedBox(height: 12),
              Text('• Integrity & Transparency\n• Innovation for Sustainability\n• Community-driven Impact',
                style: TextStyle(fontSize: 14, color: Colors.black, height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Call to Action (CTA) Section
  Widget _buildCTASection() {
    return Padding(
      padding: EdgeInsets.all(32),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        child: Text(
          'Join the Movement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}