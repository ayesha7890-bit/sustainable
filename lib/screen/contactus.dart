import 'dart:ui';
import 'package:flutter/material.dart';

// پچھلی اسکرین والے سیم کلرز
class AppColors {
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
}

class ContactUsScreen extends StatefulWidget {
  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _formAnimationController;

  // ان پٹ کنٹرولرز
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    // اسکرین کھلتے ہی اینیمیشن شروع ہو جائے گی
    _formAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // سیم وہی خوبصورت گریڈینٹ بیک گراؤنڈ
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.forest,
              Color(0xFF4a6b5c),
              Color(0xFF6d8b7b),
              Color(0xFF9bab99),
              AppColors.sand,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildNavBar(),
                _buildHeaderSection(),
                _buildContactFormCard(),
                _buildSocialIconsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نیویگیشن بار
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
            'Get In Touch',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  // ہیڈر سیکشن
  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.mail_outline_rounded, size: 64, color: AppColors.sand),
          SizedBox(height: 16),
          Text(
            'We\'d Love to Hear From You',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Have a question or feedback? Drop us a message!',
            // textAlign: Center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // گلاس مورفزم کارڈ (فارم کے لیے)
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // مکمل اینیمیٹڈ فارم کارڈ
  Widget _buildContactFormCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: _buildGlassCard(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedField(
                  index: 0,
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
                  ),
                ),
                SizedBox(height: 20),
                _buildAnimatedField(
                  index: 1,
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val!.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                _buildAnimatedField(
                  index: 2,
                  child: _buildTextField(
                    controller: _messageController,
                    label: 'Your Message',
                    icon: Icons.chat_bubble_outline,
                    maxLines: 4,
                    validator: (val) => val!.isEmpty ? 'Please write something' : null,
                  ),
                ),
                SizedBox(height: 32),
                _buildAnimatedField(
                  index: 3,
                  child: _buildSubmitButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ان پٹ فیلڈز کو اینیمیٹ کرنے والا ہیلپر وجیٹ
  Widget _buildAnimatedField({required int index, required Widget child}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _formAnimationController,
          curve: Interval(0.2 + (index * 0.15), 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _formAnimationController,
          curve: Interval(0.2 + (index * 0.15), 1.0, curve: Curves.linear),
        ),
        child: child,
      ),
    );
  }

  // کسٹم ٹیکسٹ فیلڈ ڈیزائن
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.forest, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.sage, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.sage),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.sage.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // اینیمیٹڈ سبمٹ بٹن
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // یہاں فارم سبمٹ ہونے پر کوئی بھی ایکشن لگا سکتے ہیں
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Message sent successfully! 🚀'),
                backgroundColor: AppColors.forest,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            // فیلڈز کو خالی کرنا
            _nameController.clear();
            _emailController.clear();
            _messageController.clear();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppColors.forest.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Send Message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            SizedBox(width: 8),
            Icon(Icons.send_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  // سوشل میڈیا آئیکنز سیکشن
  Widget _buildSocialIconsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Or connect with us via',
            style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(Icons.language_rounded), // Website
              SizedBox(width: 20),
              _buildSocialButton(Icons.phone_rounded),    // Phone
              SizedBox(width: 20),
              _buildSocialButton(Icons.location_on_outlined), // Location
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () {},
      ),
    );
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}