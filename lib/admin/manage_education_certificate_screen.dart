import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sustainable/database/database_helper.dart';

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

  // Colors map
  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);

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

  // --- SAVE OR UPDATE ACTION ---
  void _saveItem({int? editId}) async {
    try {
      final itemData = {
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'description': _descController.text.trim(),
        'image_url': _selectedImagePath ?? '',
      };

      if (editId != null) {
        // Edit mode: Database update call (Make sure updateEducationItem dynamic map accept kare)
        await DatabaseHelper.instance.updateEducationItem(editId, itemData);
      } else {
        // Create mode: Naya item insert karein
        await DatabaseHelper.instance.insertEducationItem(itemData);
      }

      _clearForm();

      if (!mounted) return;
      Navigator.pop(context);
      _loadHubItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editId != null ? 'Content updated successfully! 📝' : '$_selectedType added successfully! 🎉'),
          backgroundColor: sage,
        ),
      );
    } catch (e) {
      debugPrint('SAVE/UPDATE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation fail hua: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _subtitleController.clear();
    _descController.clear();
    setState(() {
      _selectedImagePath = null;
      _selectedType = 'Article';
    });
  }

  void _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteEducationItem(id);
    _loadHubItems();
  }

  // --- MODIFIED DIALOG FOR BOTH ADD AND EDIT ---
  void _showFormDialog({Map<String, dynamic>? existingItem}) {
    final isEditMode = existingItem != null;

    if (isEditMode) {
      _titleController.text = existingItem['title'] ?? '';
      _subtitleController.text = existingItem['subtitle'] ?? '';
      _descController.text = existingItem['description'] ?? '';
      _selectedType = existingItem['type'] ?? 'Article';
      _selectedImagePath = existingItem['image_url'];
    } else {
      _clearForm();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim.value,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Form(
                  key: _formKey,
                  child: AlertDialog(
                    backgroundColor: glassBg.withValues(alpha: 0.98),
                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    ),
                    title: Row(
                      children: [
                        Icon(isEditMode ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: sand, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          isEditMode ? 'Edit Content' : 'Create Content',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    dropdownColor: glassBg,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    items: ['Article', 'Certification'].map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Row(
                                          children: [
                                            Icon(
                                              type == 'Article' ? Icons.menu_book_rounded : Icons.verified_rounded,
                                              color: type == 'Article' ? sand : const Color(0xFFC5E1A5),
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
                              const SizedBox(height: 12),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                      ),
                      Material(
                        color: sage,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              _saveItem(editId: isEditMode ? existingItem['id'] : null);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(isEditMode ? 'Update' : 'Save Content', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: sand, width: 1.4)),
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
            colors: [forest, sage, sand],
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
                        // CARD TAPPING ACTION OPENS THE EDIT FORM DIALOG
                        onTap: () => _showFormDialog(existingItem: item),
                        scaleAmount: 0.985,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: glassBg.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                                      color: sand.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(isArticle ? Icons.menu_book_rounded : Icons.verified_rounded, color: sand),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isArticle ? sand : const Color(0xFFC5E1A5)).withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Text(
                                            item['type'] ?? '',
                                            style: TextStyle(
                                              color: isArticle ? sand : const Color(0xFFC5E1A5),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item['title'] ?? '',
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
                                          item['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action Icon for Editing Explicitly
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white60, size: 20),
                                    onPressed: () => _showFormDialog(existingItem: item),
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
          onTap: () => _showFormDialog(), // Call without arguments for fresh creation
          scaleAmount: 0.90,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: sage,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: sage.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 1),
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