import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart'; // forest, sage, sand automatically picked from here

class AboutContactScreen extends StatefulWidget {
  const AboutContactScreen({super.key});

  @override
  State<AboutContactScreen> createState() => _AboutContactScreenState();
}

class _AboutContactScreenState extends State<AboutContactScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _entranceController;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Premium hatane ke baad ab sirf 2 tabs hain
    _tabController = TabController(length: 2, vsync: this);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _entranceController.reset();
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.5);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.forest.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.sand, size: 28),
              SizedBox(width: 10),
              Text("Submitted!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: Text(
            "Thank you, ${_nameController.text}.\n\nOur eco support team has received your query and will reply back to ${_emailController.text} within 24 hours.",
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _formKey.currentState!.reset();
                _nameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _messageController.clear();
              },
              child: const Text("Done", style: TextStyle(color: AppColors.sand, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.sage, AppColors.sand],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          // title: const Text("EcoWise Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sand,
            indicatorWeight: 3,
            labelColor: AppColors.sand,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: "About Us", icon: Icon(Icons.info_outline_rounded)),
              Tab(text: "Contact Us", icon: Icon(Icons.support_agent_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── TAB 1: ABOUT US ───────────────────────────────────────
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _staggered(0, Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.spa_rounded, size: 60, color: AppColors.sand),
                        ),
                        const SizedBox(height: 14),
                        const Text("Sustainable Living Guide", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sand.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Version 2.0 (Clean Build)", style: TextStyle(color: AppColors.sand, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 30),
                  _staggered(1, _buildGlassCard(
                    title: "Our Mission",
                    child: const Text(
                      "EcoWise is a state-of-the-art interactive ecosystem engineered to help individuals measure, adapt, and dramatically lower their ecological footprint. We replace guesswork with dynamic data analytics, custom trackers, and carbon auditation to pave your path toward absolute zero-waste living.",
                      style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                    ),
                  )),
                  const SizedBox(height: 20),
                  _staggered(2, _buildGlassCard(
                    title: "Core Ecosystem Features",
                    child: Column(
                      children: [
                        _buildBulletPoint("📊 Carbon Footprint Auditing & Analytics"),
                        _buildBulletPoint("🗑️ Intelligent Waste Logging Systems"),
                        _buildBulletPoint("🛍️ Eco-Friendly Verified Alternatives"),
                        _buildBulletPoint("🚀 Real-Time Green Travel Computations"),
                        _buildBulletPoint("📅 Custom Sustainable Meal Formulations"),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // ── TAB 2: CONTACT US ─────────────────────────────────────
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _staggered(0, const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Get in Touch", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text("Drop us a query or report system bugs effortlessly.", style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    )),
                    _staggered(1, TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration("Full Name", Icons.person_outline_rounded),
                      validator: (val) => val == null || val.trim().isEmpty ? "Name required" : null,
                    )),
                    const SizedBox(height: 16),
                    _staggered(2, TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration("Email Address", Icons.email_outlined),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Email required";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val)) return "Invalid email format";
                        return null;
                      },
                    )),
                    const SizedBox(height: 16),
                    _staggered(3, TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration("Phone Number", Icons.phone_android_rounded),
                      validator: (val) => val == null || val.length < 7 ? "Invalid phone number" : null,
                    )),
                    const SizedBox(height: 16),
                    _staggered(4, TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration("Write Message Detail...", null),
                      validator: (val) => val == null || val.isEmpty ? "Details required" : null,
                    )),
                    const SizedBox(height: 24),
                    _staggered(5, SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _submitFeedback,
                        icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.sand),
                        label: const Text("Send Encrypted Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sand)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.sand, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3))),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.sand) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      alignLabelWithHint: true,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.sand, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
    );
  }
}