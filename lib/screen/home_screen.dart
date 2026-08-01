import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import '../utils/app_colors.dart';
import 'package:sustainable/database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child, {int totalSteps = 8}) {
    final start = (index * (0.6 / totalSteps)).clamp(0.0, 0.7);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  // 📊 Dono local tables se aik sath data load karne ka combine future function
  Future<Map<String, dynamic>> _loadDashboardData() async {
    final carbonLogs = await DatabaseHelper.instance.getCarbonLogs();
    final completedChallenges = await DatabaseHelper.instance.fetchCompletedChallenges();

    // Custom logic: Yahan fetchTravelTips database helper se fetch karein
    final tips = await DatabaseHelper.instance.fetchTravelTips();

    double totalCarbon = 0.0;
    if (carbonLogs.isNotEmpty) {
      totalCarbon = (carbonLogs.first['total_co2'] ?? 0.0).toDouble();
    }

    // Sirf Travel aur Energy wali tips filter karna
    final travelEnergyTips = tips.where((tip) {
      final cat = tip['category']?.toString().toLowerCase() ?? '';
      return cat == 'travel' || cat == 'energy';
    }).toList();

    return {
      'carbonScore': totalCarbon,
      'completedCount': completedChallenges.length,
      'tipsList': travelEnergyTips.isEmpty ? tips : travelEnergyTips, // Fallback agar filtered na milein
    };
  }

  IconData _getTipIcon(String? cat) {
    final category = cat?.toLowerCase() ?? '';
    if (category == 'travel') return Icons.commute_rounded;
    if (category == 'energy') return Icons.bolt_rounded;
    return Icons.tips_and_updates_rounded;
  }

  Color _getTipColor(String? cat) {
    final category = cat?.toLowerCase() ?? '';
    if (category == 'travel') return Colors.cyanAccent;
    if (category == 'energy') return Colors.amberAccent;
    return AppColors.sand;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadDashboardData(),
        builder: (context, snapshot) {
          double carbonFootprint = 0.0;
          int completedTasks = 0;
          List<Map<String, dynamic>> tipsList = [];

          if (snapshot.hasData) {
            carbonFootprint = snapshot.data!['carbonScore'];
            completedTasks = snapshot.data!['completedCount'];
            tipsList = snapshot.data!['tipsList'];
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                _staggered(
                  0,
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.spa_rounded, color: AppColors.sand, size: 28),
                        const SizedBox(width: 6),
                        const Text(
                          "Sustainable Lifestyle",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Carbon Card ───────────────────────
                _staggered(
                  1,
                  _HoverScale(
                    onTap: () => widget.onNavigate(1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Your Carbon", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: AppColors.sand.withOpacity(0.22), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        "${carbonFootprint.toStringAsFixed(1)} kg CO2e",
                                        style: const TextStyle(color: AppColors.sand, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text("Lower your score by completing green tasks.", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                                const SizedBox(height: 16),
                                CustomPaint(size: const Size(double.infinity, 60), painter: SplineGraphPainter(color: AppColors.sand)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Activities ────────────────────────────────────────
                _staggered(2, const Text("Your Activities", style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _staggered(3, _buildActivityCard("Green Tasks", "$completedTasks completed", Icons.emoji_events_rounded, const Color(0xFF8BC98E), () => widget.onNavigate(2))),
                    _staggered(4, _buildActivityCard("Community", "join top forums", Icons.groups_rounded, const Color(0xFF7FCDCD), () => widget.onNavigate(3))),
                    _staggered(5, _buildActivityCard("Green Travel", "calculate tips", Icons.electric_car_rounded, const Color(0xFFAED581), () => widget.onNavigate(8))),
                    _staggered(6, _buildActivityCard("Alternatives", "eco alternatives", Icons.shopping_bag_outlined, AppColors.sand, () => widget.onNavigate(4))),
                  ],
                ),
                const SizedBox(height: 28),

                // ── 📊 UNCOMMENTED DYNAMIC SQLITE CAROUSEL SLIDER ──────────────────────
                _staggered(
                  7,
                  tipsList.isEmpty
                      ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Center(
                      child: Text("No eco tips available for Travel or Energy!", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                        child: Text(
                          "💡 Featured Guidelines",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 115,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          enlargeCenterPage: true,
                          viewportFraction: 1.0,
                        ),
                        items: tipsList.map((tip) {
                          final String title = tip['title'] ?? 'Eco Tip';
                          final String desc = tip['description'] ?? '';
                          final String? cat = tip['category'];

                          return Builder(
                            builder: (BuildContext context) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                                color: _getTipColor(cat).withOpacity(0.2),
                                                shape: BoxShape.circle
                                            ),
                                            child: Icon(_getTipIcon(cat), color: _getTipColor(cat)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    title,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    desc,
                                                    style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.72), height: 1.35),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(String title, String subtitle, IconData icon, Color accentColor, VoidCallback onTap) {
    return _HoverScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.16))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: accentColor.withOpacity(0.20), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accentColor, size: 24)),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverScale({required this.child, required this.onTap});
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 140), curve: Curves.easeOut, child: widget.child),
    );
  }
}

class SplineGraphPainter extends CustomPainter {
  final Color color;
  SplineGraphPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    final paintGradient = Paint()..shader = LinearGradient(colors: [color.withOpacity(0.25), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.8, size.width * 0.75, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.4);
    final fillPath = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fillPath, paintGradient);
    canvas.drawPath(path, paintLine);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}