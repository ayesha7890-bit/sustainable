
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sustainable/welcome.dart';

void main() {
runApp(const EZApp());
}

class EZApp extends StatelessWidget {
const EZApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
home: const SplashScreen(),
);
}
}

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});

@override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
with SingleTickerProviderStateMixin {
late final AnimationController _controller;

// Orbit size ko desktop aur mobile dono ke liye safe (340) rakha hai
final double orbitSize = 340.0;

@override
void initState() {
super.initState();
_controller = AnimationController(
vsync: this,
duration: const Duration(seconds: 12),
)..repeat();

Future.delayed(const Duration(seconds: 4), () {
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => WelcomeScreen()),
);
}
});
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF173B2A),
body: Container(
width: double.infinity,
height: double.infinity,
decoration: const BoxDecoration(
gradient: RadialGradient(
center: Alignment(0, 0),
radius: 1.2,
colors: [
Color(0xFF1F4632),
Color(0xFF173B2A),
Color(0xFF0F2C1F),
],
stops: [0.0, 0.55, 1.0],
),
),
child: Center(
child: Stack(
alignment: Alignment.center,
children: [
// 1. Dashed orbit circle, slowly rotating
AnimatedBuilder(
animation: _controller,
builder: (context, child) {
return Transform.rotate(
angle: _controller.value * 2 * math.pi,
child: child,
);
},
child: CustomPaint(
size: Size(orbitSize, orbitSize),
painter: _DashedCirclePainter(),
),
),

// 2. Inner thin solid circle
Container(
width: 200,
height: 200,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(
color: const Color(0xFF5A8A6F).withOpacity(0.3),
width: 1,
),
),
),

// 3. Orbit badges (Ab size bada kar diya hai taake boundary se cut na ho)
  AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      return Transform.rotate(
        angle: _controller.value * 2 * math.pi,
        child: child,
      );
    },
    child: SizedBox(
      // Orbit size se 40 padding badha di taake icons safe rahein
      width: orbitSize + 40,
      height: orbitSize + 40,
      child: Stack(
        children: [
          // PANI / WATER DROP ICON
          _orbitBadge(
            angleDeg: 0,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.water_drop, color: Color(0xFF5EC8F2)),
          ),
          // HOME / ECO BUILDINGS
          _orbitBadge(
            angleDeg: 60,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.home_work_rounded, color: Color(0xFFFFB84D)),
          ),
          // ENERGY / BOLT ICON
          _orbitBadge(
            angleDeg: 120,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.bolt, color: Color(0xFFFFD166)),
          ),
          // ECO LEAF
          _orbitBadge(
            angleDeg: 180,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.eco, color: Color(0xFF8FE3A3)),
          ),
          // RECYCLE ICON
          _orbitBadge(
            angleDeg: 240,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.recycling, color: Color(0xFF4DB6AC)),
          ),
          // SPARKS / STARS
          _orbitBadge(
            angleDeg: 300,
            radius: orbitSize / 2,
            child: const _AppIconBadge(icon: Icons.auto_awesome, color: Color(0xFF7EE3B0)),
          ),
        ],
      ),
    ),
  ),

// 4. CENTER LOGO: Sustainable Living Guide (SLG)
Column(
mainAxisSize: MainAxisSize.min,
children: [
// Upper Leaves Pattern
CustomPaint(
size: const Size(80, 24),
painter: _LeafPainter(),
),
const SizedBox(height: 8),

// Main Acronym Brand Name
const Text(
'SLG',
style: TextStyle(
fontFamily: 'Georgia',
fontSize: 52,
fontWeight: FontWeight.w800,
color: Colors.white,
letterSpacing: 2,
),
),

// Elegant Divider Line
Container(
margin: const EdgeInsets.symmetric(vertical: 8),
width: 120,
height: 1.5,
color: Colors.white.withOpacity(0.5),
),

// Full Subtitle Name
const Text(
'Sustainable Living Guide',
textAlign: TextAlign.center,
style: TextStyle(
fontFamily: 'Roboto',
fontSize: 12,
fontWeight: FontWeight.w500,
color: Colors.white,
letterSpacing: 0.8,
),
),
],
),
],
),
),
),
);
}

// FIXED MATH LOGIC FOR ORBIT BADGES WITH EXTRA BOX SPACE
  Widget _orbitBadge({
    required double angleDeg,
    required double radius,
    required Widget child,
  }) {
    final angle = angleDeg * math.pi / 180;

    // Naye container ka center point nikalne ke liye extra padding (+ 20) shamil ki hai
    final centerFactor = (orbitSize + 40) / 2;

    // Badge size ka half (19) minus karne se perfect spacing aayegi
    final dx = radius * math.cos(angle) + centerFactor - 19;
    final dy = radius * math.sin(angle) + centerFactor - 19;

    return Positioned(
      left: dx,
      top: dy,
      child: child,
    );
  }
}

// DASHED CIRCLE PAINTER
class _DashedCirclePainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = const Color(0xFF4D7D63).withOpacity(0.6)
..style = PaintingStyle.stroke
..strokeWidth = 1.2;

final center = Offset(size.width / 2, size.height / 2);
final radius = size.width / 2;
const dashWidth = 5.0;
const dashSpace = 8.0;
final circumference = 2 * math.pi * radius;
final dashCount = (circumference / (dashWidth + dashSpace)).floor();
final angleStep = (2 * math.pi) / dashCount;

for (int i = 0; i < dashCount; i++) {
final startAngle = i * angleStep;
final endAngle = startAngle + (dashWidth / radius);
canvas.drawArc(
Rect.fromCircle(center: center, radius: radius),
startAngle,
endAngle - startAngle,
false,
paint,
);
}
}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// LEAF PAINTER FOR LOGO
class _LeafPainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()..color = Colors.white.withOpacity(0.95);
final center = Offset(size.width / 2, size.height - 4);

final leftLeaf = Path()
..moveTo(center.dx, center.dy)
..cubicTo(center.dx - 12, center.dy - 16, center.dx - 32, center.dy - 16, center.dx - 38, center.dy)
..cubicTo(center.dx - 26, center.dy + 8, center.dx - 10, center.dy + 6, center.dx, center.dy)
..close();

final rightLeaf = Path()
..moveTo(center.dx, center.dy)
..cubicTo(center.dx + 12, center.dy - 16, center.dx + 32, center.dy - 16, center.dx + 38, center.dy)
..cubicTo(center.dx + 26, center.dy + 8, center.dx + 10, center.dy + 6, center.dx, center.dy)
..close();

canvas.drawPath(leftLeaf, paint);
canvas.drawPath(rightLeaf, paint);
}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// UI BADGE CONTAINER (Shell for Icons)
class _AppIconBadge extends StatelessWidget {
final IconData icon;
final Color color;

const _AppIconBadge({required this.icon, required this.color});

@override
Widget build(BuildContext context) {
return Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: const Color(0xFF173B2A),
shape: BoxShape.circle,
border: Border.all(color: color.withOpacity(0.6), width: 1.5),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.3),
blurRadius: 4,
offset: const Offset(0, 2),
),
],
),
alignment: Alignment.center,
child: Icon(
icon,
color: color,
size: 18,
),
);
}
}
