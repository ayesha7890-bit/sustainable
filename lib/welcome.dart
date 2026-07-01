import 'package:flutter/material.dart';
// Aapki login screen ka import statement
import 'package:sustainable/screen/loginpage.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. TOP IMAGE: Picture ko niche shift kiya hai
              Expanded(
                flex: 7,
                child: ClipPath(
                  clipper: _BottomCurveClipper(),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF7CB342), // Image ke piche ka green background color match kiya hai
                    child: Container(
                      margin: const EdgeInsets.only(top: 40), // Top se thoda niche push kiya taake text pura dikhe
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/img.png'),
                          fit: BoxFit.contain, // Isse aapki puri picture (earth + text) bina cut huay fit aayegi
                          alignment: Alignment.center, // Center ya bottomCenter par rakh kar check karein
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. BOTTOM DETAILS: Text aur Button area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Track Your Sustainable Living",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Manually add details or connect your smart home devices - we'll show how much carbon your home uses.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),

                      // Premium Rounded Green Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C8346),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // BACKGROUND DECORATION LINE
          Positioned(
            top: 260,
            left: -60,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0C8346), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);

    var controlPoint = Offset(size.width / 2, size.height + 40);
    var endPoint = Offset(size.width, size.height - 60);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}