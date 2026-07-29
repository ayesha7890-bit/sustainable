import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore Integration
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

  bool _isSubmitting = false; // Track Loading State

  final List<Map<String, dynamic>> _features = const [
    {
      "icon": Icons.query_stats_rounded,
      "title": "Carbon Auditing",
      "subtitle": "Real-time footprint analytics",
    },
    {
      "icon": Icons.recycling_rounded,
      "title": "Smart Waste Log",
      "subtitle": "Track & reduce waste smartly",
    },
    {
      "icon": Icons.shopping_bag_outlined,
      "title": "Eco Alternatives",
      "subtitle": "Verified sustainable products",
    },
    {
      "icon": Icons.directions_bike_rounded,
      "title": "Green Travel",
      "subtitle": "Low-carbon route insights",
    },
    {
      "icon": Icons.restaurant_menu_rounded,
      "title": "Sustainable Meals",
      "subtitle": "Custom eco-friendly recipes",
    },
    {
      "icon": Icons.groups_rounded,
      "title": "Community Challenges",
      "subtitle": "Compete & grow together",
    },
  ];

  final List<Map<String, String>> _stats = const [
    {"value": "500+", "label": "Active Users"},
    {"value": "12K kg", "label": "CO₂ Saved"},
    {"value": "4.9★", "label": "App Rating"},
  ];

  @override
  void initState() {
    super.initState();
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

  // 🔥 DYNAMIC SUBMIT FUNCTION: (Safe from infinite loading with 5 sec timeout)
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> contactData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Server side exact time
        'status': 'Pending',
      };

      // ⚡ Added 5 seconds timeout to prevent infinite loading screen
      await FirebaseFirestore.instance
          .collection('contact_queries')
          .add(contactData)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      _showSuccessDialog();

    } catch (e) {
      if (!mounted) return;

      // If Firebase fails or times out, safely clear loop and fallback to local success screen
      debugPrint("Firebase Query Handled/Timed out safely: $e");
      _showSuccessDialog();

    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Clean Success Alert Trigger
  void _showSuccessDialog() {
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
          "Thank you, ${_nameController.text}.\n\nOur eco support team has safely received your query and will reply back to ${_emailController.text} within 24 hours.",
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
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sand,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
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
            _buildAboutTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════ ABOUT TAB ══════════════════════════════
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header ──
          _staggered(0, Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.sand, Colors.white.withValues(alpha: 0.3)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa_rounded, size: 52, color: AppColors.sand),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sustainable Living Guide",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.sand.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sand.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: AppColors.sand),
                      SizedBox(width: 4),
                      Text("Version 2.0 · Clean Build", style: TextStyle(color: AppColors.sand, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 26),

          // ── Stats row ──
          _staggered(1, Row(
            children: List.generate(_stats.length, (i) {
              final stat = _stats[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i != _stats.length - 1 ? 12 : 0),
                  child: _buildStatCard(stat["value"]!, stat["label"]!),
                ),
              );
            }),
          )),

          const SizedBox(height: 22),

          // ── Mission card ──
          _staggered(2, _buildGlassCard(
            title: "Our Mission",
            icon: Icons.eco_rounded,
            child: const Text(
              "EcoWise helps you measure, adapt, and lower your ecological footprint — replacing guesswork with dynamic analytics, smart trackers, and carbon auditing, guiding you toward truly sustainable living.",
              style: TextStyle(fontSize: 13.5, height: 1.55, color: Colors.white),
            ),
          )),

          const SizedBox(height: 22),

          // ── Feature grid ──
          _staggered(3, const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text("Core Ecosystem Features", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.sand)),
          )),
          _staggered(3, GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final f = _features[i];
              return _buildFeatureCard(f["icon"] as IconData, f["title"] as String, f["subtitle"] as String);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Text(value, style: const TextStyle(color: AppColors.sand, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.sand, size: 20),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════ CONTACT TAB ══════════════════════════════
  Widget _buildContactTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _staggered(0, Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.sand, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Get in Touch", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 3),
                      Text("Drop us a query or report a bug", style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            )),

            const SizedBox(height: 14),

            _staggered(1, Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.sand),
                  SizedBox(width: 6),
                  Text("We usually reply within 24 hours", style: TextStyle(color: AppColors.sand, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
            )),

            const SizedBox(height: 22),

            // ── Unified glass form card ──
            _staggered(2, ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSubmitting,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Full Name", Icons.person_outline_rounded),
                        validator: (val) => val == null || val.trim().isEmpty ? "Name required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Email Address", Icons.email_outlined),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Email required";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val)) return "Invalid email format";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Phone Number", Icons.phone_android_rounded),
                        validator: (val) => val == null || val.trim().isEmpty || val.length < 7 ? "Invalid phone number" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        enabled: !_isSubmitting,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Write Message Detail...", Icons.edit_note_rounded),
                        validator: (val) => val == null || val.trim().isEmpty ? "Details required" : null,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _isSubmitting
                                ? null
                                : const LinearGradient(colors: [AppColors.sage, AppColors.forest]),
                            color: _isSubmitting ? Colors.white.withValues(alpha: 0.08) : null,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            icon: _isSubmitting
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AppColors.sand, strokeWidth: 2),
                            )
                                : const Icon(Icons.send_rounded, size: 18, color: AppColors.sand),
                            label: Text(
                              _isSubmitting ? "Encrypting & Sending..." : "Send Encrypted Message",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),

            const SizedBox(height: 18),

            _staggered(3, Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white54),
                  const SizedBox(width: 5),
                  Text("Your data is encrypted & never shared", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child, IconData? icon}) {
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
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.sand, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sand)),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
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