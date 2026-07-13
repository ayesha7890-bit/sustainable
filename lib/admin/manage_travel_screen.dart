import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';

class ManageTravelScreen extends StatefulWidget {
  const ManageTravelScreen({super.key});

  @override
  State<ManageTravelScreen> createState() => _ManageTravelScreenState();
}

class _ManageTravelScreenState extends State<ManageTravelScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Travel'; // Default Category

  List<Map<String, dynamic>> _tips = [];
  late final AnimationController _entranceController;

  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);

  @override
  void initState() {
    super.initState();
    _loadTips();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  void _loadTips() async {
    final data = await DatabaseHelper.instance.fetchTravelTips();
    setState(() {
      _tips = data;
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
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

  void _saveTip() async {
    await DatabaseHelper.instance.insertTravelTip({
      'category': _selectedCategory,
      'title': _titleController.text,
      'description': _descController.text,
    });

    _titleController.clear();
    _descController.clear();

    if (!mounted) return;
    Navigator.pop(context);
    _loadTips();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedCategory tip completed '),
        backgroundColor: sage,
      ),
    );
  }

  void _deleteTip(int id) async {
    await DatabaseHelper.instance.deleteTravelTip(id);
    _loadTips();
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
                  key: _formKey,
                  child: AlertDialog(
                    backgroundColor: glassBg.withValues(alpha: 0.98),
                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.wb_incandescent_rounded, color: sand, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Add Eco Guide/Tip',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dropdown for Category Selection
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  dropdownColor: glassBg,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  items: ['Travel', 'Energy', 'Waste'].map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text('$cat Guide'),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _selectedCategory = v!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildGlassField(
                              controller: _titleController,
                              label: 'Guide Title (e.g., Carpooling Perks)',
                            ),
                            const SizedBox(height: 12),
                            _buildGlassField(
                              controller: _descController,
                              label: 'Detailed Recommendation/Tip',
                              maxLines: 4,
                            ),
                          ],
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
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              _saveTip();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.send_rounded, size: 16, color: Colors.white),
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

  Widget _buildGlassField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
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

  IconData _getIcon(String cat) {
    if (cat == 'Travel') return Icons.commute_rounded;
    if (cat == 'Energy') return Icons.bolt_rounded;
    return Icons.delete_sweep_rounded;
  }

  Color _getColor(String cat) {
    if (cat == 'Travel') return Colors.cyanAccent;
    if (cat == 'Energy') return Colors.amberAccent;
    return Colors.lightGreenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [forest, sage, sand], stops: [0.0, 0.55, 1.0]),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eco Travel & Lifestyle Guides', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                        Text('Manage smart energy, waste, and travel logs', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _tips.isEmpty
                    ? _staggered(1, const Center(child: Text('No suggestions found!', style: TextStyle(color: Colors.white70))))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _tips.length,
                  itemBuilder: (context, index) {
                    final item = _tips[index];
                    final cat = item['category'];
                    return _staggered(
                      index,
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: glassBg.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: _getColor(cat).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Icon(_getIcon(cat), color: _getColor(cat), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                    child: Text(cat.toUpperCase(), style: TextStyle(color: _getColor(cat), fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(item['description'], maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A80)),
                              onPressed: () => _deleteTip(item['id']),
                            ),
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