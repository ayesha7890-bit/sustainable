import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sustainable/database/database_helper.dart';
import 'package:sustainable/screen/About_contactscreen.dart';
import 'package:sustainable/screen/contactus.dart';
// import 'package:sustainable/utils/app_colors.dart';

class ManageEducationScreen extends StatefulWidget {
  const ManageEducationScreen({super.key});

  @override
  State<ManageEducationScreen> createState() => _ManageEducationScreenState();
}

class _ManageEducationScreenState extends State<ManageEducationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedType = 'Article';
  String? _selectedImagePath;
  List<Map<String, dynamic>> _hubItems = [];
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _entranceController;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _loadHubItems();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  void _loadHubItems() async {
    final data = await DatabaseHelper.instance.fetchEducationItems();
    setState(() {
      _hubItems = data;
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fabController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  Future<String?> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  void _saveItem() async {
    try {
      await DatabaseHelper.instance.insertEducationItem({
        'type': _selectedType,
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'description': _descController.text,
        'image_url': _selectedImagePath ?? '',
      });

      _titleController.clear();
      _subtitleController.clear();
      _descController.clear();
      setState(() {
        _selectedImagePath = null;
      });

      if (!mounted) return;
      Navigator.pop(context);
      _loadHubItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedType added successfully!'),
          backgroundColor:AppColors.sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save fail hua: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteEducationItem(id);
    _loadHubItems();
  }

  void _showAddDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
          child: Transform.scale(
            scale: curvedValue,
            child: Opacity(
              opacity: anim.value.clamp(0.0, 1.0),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Form(
                    key: _formKey,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.forest.withValues(alpha: 0.85),
                                  AppColors.sage.withValues(alpha: 0.55),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sand.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(22),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.sand.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.sand, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Create Content',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Glass dropdown
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedType,
                                          dropdownColor: AppColors.forest,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          items: ['Article', 'Certification'].map((type) {
                                            return DropdownMenuItem(
                                              value: type,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    type == 'Article' ? Icons.menu_book_rounded : Icons.verified_rounded,
                                                    color: type == 'Article' ? AppColors.sand : const Color(0xFFC5E1A5),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(type),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              _selectedType = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Image picker with hover-style scale on tap
                                    _HoverScale(
                                      onTap: () async {
                                        final String? path = await _pickImage();
                                        if (path != null) {
                                          setDialogState(() => _selectedImagePath = path);
                                          setState(() => _selectedImagePath = path);
                                        }
                                      },
                                      child: Container(
                                        height: 92,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                        ),
                                        child: _selectedImagePath != null
                                            ? ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover, width: double.infinity),
                                        )
                                            : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cloud_upload_outlined, color: AppColors.sand, size: 26),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Upload Header Image / Logo (Optional)',
                                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    _buildGlassField(
                                      controller: _titleController,
                                      label: _selectedType == 'Article' ? 'Article Title' : 'Certification Name (e.g. Energy Star)',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGlassField(
                                      controller: _subtitleController,
                                      label: _selectedType == 'Article' ? 'Author / Topic' : 'Issuing Organization',
                                      required: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGlassField(
                                      controller: _descController,
                                      label: _selectedType == 'Article' ? 'Article Content' : 'Meaning & Guidelines',
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 20),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        _HoverScale(
                                          onTap: () {
                                            FocusScope.of(context).unfocus();
                                            if (_formKey.currentState!.validate()) {
                                              _saveItem();
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [AppColors.sage, AppColors.sand]),
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(color: AppColors.sage.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 5)),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Save Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                                SizedBox(width: 6),
                                                Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassField({required TextEditingController controller, required String label, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) => required && (v == null || v.trim().isEmpty) ? 'This field is required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.sand, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.forest, AppColors.sage, AppColors.sand],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _HoverScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Education & Certifications', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Articles and Eco-Labels directory', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _hubItems.isEmpty
                    ? _staggered(1, const Center(child: Text('No items found. Add new content!', style: TextStyle(color: Colors.white70))))
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                  itemCount: _hubItems.length,
                  itemBuilder: (context, index) {
                    final item = _hubItems[index];
                    final imagePath = item['image_url'] as String?;
                    final isArticle = item['type'] == 'Article';

                    return _staggered(
                      index,
                      _HoverScale(
                        onTap: () {}, // reserved for future detail/edit view
                        scaleAmount: 0.985,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                boxShadow: [
                                  BoxShadow(color: AppColors.forest.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  imagePath != null && imagePath.isNotEmpty
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.file(File(imagePath), width: 52, height: 52, fit: BoxFit.cover),
                                  )
                                      : Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.sand.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(isArticle ? Icons.menu_book_rounded : Icons.verified_rounded, color: AppColors.sand),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isArticle ? AppColors.sand : const Color(0xFFC5E1A5)).withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Text(
                                            item['type'],
                                            style: TextStyle(
                                              color: isArticle ? AppColors.sand : const Color(0xFFC5E1A5),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item['title'],
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item['subtitle'] != null && item['subtitle'].toString().isNotEmpty)
                                          Text(
                                            item['subtitle'],
                                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _HoverScale(
                                    onTap: () => _deleteItem(item['id']),
                                    scaleAmount: 0.85,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8A80).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A80), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
        child: _HoverScale(
          onTap: _showAddDialog,
          scaleAmount: 0.90,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.sage, AppColors.sand]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.sage.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 1),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

/// Reusable press-scale wrapper — the mobile equivalent of a "hover" effect,
/// giving instant tactile feedback on tap-down with a smooth spring back.
class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;

  const _HoverScale({
    required this.child,
    required this.onTap,
    this.scaleAmount = 0.94,
  });

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = widget.scaleAmount),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}