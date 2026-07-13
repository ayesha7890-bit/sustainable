import 'dart:math';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Database logic removed: Using clean static mock values
  final int _completedChallengesCount = 4;
  final double _latestCarbonFootprint = 12.4;
  String _tipOfTheDay = "Avoid single-use plastics. Switch to a reusable bag and a steel water bottle!";

  final List<String> _tips = [
    "Avoid single-use plastics. Switch to a reusable bag and a steel water bottle!",
    "Unplug electronics when not in use. Standby power accounts for 5-10% of home energy use.",
    "A plant-based meal once a week saves water, land use, and greenhouse gases.",
    "Wash clothes in cold water to save up to 90% of the energy used by washing machines.",
    "Carpool, use public transit, or ride a bicycle to reduce transportation footprint.",
    "Compost organic waste. Food waste in landfills produces harmful methane gas.",
    "Lower your thermostat by 1-2 degrees in winter and raise it in summer to save energy bills.",
    "Choose products with minimal packaging or buy in bulk to reduce waste.",
  ];

  @override
  void initState() {
    super.initState();
    _getRandomTip();
  }

  void _getRandomTip() {
    setState(() {
      _tipOfTheDay = _tips[Random().nextInt(_tips.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the dashboard gradient fluid
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EcoWise Header logo and banner
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        "EcoWise",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Sustainable Lifestyle",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Carbon Card Link
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.08), width: 1.5),
                    ),
                    child: InkWell(
                      onTap: () => widget.onNavigate(1), // Index 1: Carbon Tracker Screen
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Your Carbon",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${_latestCarbonFootprint.toStringAsFixed(1)} kg CO2e",
                                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Weekly average of CO2 emissions generated. Lower your score by completing green tasks.",
                              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            CustomPaint(
                              size: const Size(double.infinity, 60),
                              painter: SplineGraphPainter(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title "Your Activities"
            Text(
              "Your Activities",
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Mapped Activities Grid according to your DashboardShell Index Rules
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: [
                _buildActivityCard(
                  context,
                  "Green Tasks",
                  "$_completedChallengesCount completed",
                  Icons.emoji_events,
                  Colors.green.shade600,
                      () => widget.onNavigate(2), // Correct Shell Index 2: Challenges
                ),
                _buildActivityCard(
                  context,
                  "Community",
                  "join top forums",
                  Icons.groups,
                  Colors.teal.shade600,
                      () => widget.onNavigate(3), // Correct Shell Index 3: Forum
                ),
                _buildActivityCard(
                  context,
                  "Green Travel",
                  "calculate tips",
                  Icons.electric_car,
                  Colors.lightGreen.shade700,
                      () => widget.onNavigate(8), // Correct Shell Index 8: Energy & Travel Hub
                ),
                _buildActivityCard(
                  context,
                  "Alternatives",
                  "eco alternatives",
                  Icons.shopping_bag_outlined,
                  Colors.orange.shade600,
                      () => widget.onNavigate(4), // Correct Shell Index 4: Products Screen
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tips Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.08), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.tips_and_updates, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Eco Tip of the Day",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tipOfTheDay,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Colors.black45),
                      onPressed: _getRandomTip,
                      tooltip: "New Tip",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            color: Colors.white,
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.08), width: 1.5),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplineGraphPainter extends CustomPainter {
  final Color color;
  SplineGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final paintGradient = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.8, size.width * 0.75, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.4);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintGradient);
    canvas.drawPath(path, paintLine);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.1), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}