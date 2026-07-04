import 'dart:io';
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
          content: Text('$_selectedType kamyabi se add ho gaya!'),
          backgroundColor: sage,
        ),
      );
    } catch (e) {
      // Ye catch block asal error dikhayega (e.g. "no such table: education")
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save fail hua: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  // 2. Iske foran baad aapka pehle se bana hua delete function hona chahiye:
  void _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteEducationItem(id);
    _loadHubItems();
  }




  void _showAddDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim.value,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Form(
                  key: _formKey, // Global key attached here
                  child: AlertDialog(
                    backgroundColor: glassBg.withValues(alpha: 0.98),
                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: sand, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Create Content',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                              // Custom Dropdown Box
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
                              const SizedBox(height: 14),

                              // Dynamic Image Picker Container
                              GestureDetector(
                                onTap: () async {
                                  final String? path = await _pickImage();
                                  if (path != null) {
                                    setDialogState(() {
                                      _selectedImagePath = path;
                                    });
                                    setState(() {
                                      _selectedImagePath = path;
                                    });
                                  }
                                },
                                child: Container(
                                  height: 90,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), style: BorderStyle.solid),
                                  ),
                                  child: _selectedImagePath != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                                  )
                                      : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, color: sand, size: 26),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload Header Image / Logo (Optional)',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                      ),
                      Material(
                        color: sage,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            FocusScope.of(context).unfocus(); // Keyboard hide hoga

                            // FIXED: Directly validating using _formKey state pointer
                            if (_formKey.currentState!.validate()) {
                              _saveItem(); // Ab bina kisi issue ke save handler chalega
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Save Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
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
      validator: (v) => required && (v == null || v.trim().isEmpty) ? 'Field fill karna zaroori hai' : null,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [forest, sage, sand], stops: [0.0, 0.55, 1.0])),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
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
                    ? _staggered(1, const Center(child: Text('Koi items nahi hain. Naya content add karein!', style: TextStyle(color: Colors.white70))))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _hubItems.length,
                  itemBuilder: (context, index) {
                    final item = _hubItems[index];
                    final imagePath = item['image_url'] as String?;
                    final isArticle = item['type'] == 'Article';

                    return _staggered(
                      index,
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: glassBg.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            imagePath != null && imagePath.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imagePath), width: 50, height: 50, fit: BoxFit.cover))
                                : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(isArticle ? Icons.menu_book_rounded : Icons.verified_rounded, color: isArticle ? sand : const Color(0xFFC5E1A5)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: isArticle ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Text(item['type'], style: TextStyle(color: isArticle ? sand : Colors.blue[200], fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  if (item['subtitle'] != null && item['subtitle'].toString().isNotEmpty)
                                    Text(item['subtitle'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A80)), onPressed: () => _deleteItem(item['id'])),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: sage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}