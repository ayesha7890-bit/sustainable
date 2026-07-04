import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';

class ManageChallengesScreen extends StatefulWidget {
  const ManageChallengesScreen({super.key});

  @override
  State<ManageChallengesScreen> createState() => _ManageChallengesScreenState();
}

class _ManageChallengesScreenState extends State<ManageChallengesScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();
  final _pointsController = TextEditingController();

  List<Map<String, dynamic>> _challenges = [];
  late final AnimationController _entranceController;

  static const Color forest = Color(0xFF2F4A3E);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFCBBE9C);
  static const Color glassBg = Color(0xFF0D2318);

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  void _loadChallenges() async {
    final data = await DatabaseHelper.instance.fetchChallenges();
    setState(() {
      _challenges = data;
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _pointsController.dispose();
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

  void _saveChallenge() async {
    await DatabaseHelper.instance.insertChallenge({
      'title': _titleController.text,
      'description': _descController.text,
      'duration_days': int.parse(_durationController.text),
      'points': int.parse(_pointsController.text),
    });

    _titleController.clear();
    _descController.clear();
    _durationController.clear();
    _pointsController.clear();

    if (!mounted) return;
    Navigator.pop(context);
    _loadChallenges();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Naya Challenge kamyabi se add ho gaya!'),
        backgroundColor: sage,
      ),
    );
  }

  void _deleteChallenge(int id) async {
    await DatabaseHelper.instance.deleteChallenge(id);
    _loadChallenges();
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
                        Icon(Icons.emoji_events_rounded, color: sand, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Create Eco-Challenge',
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
                              _buildGlassField(
                                controller: _titleController,
                                label: 'Challenge Title (e.g. No Plastic Week)',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _durationController,
                                      label: 'Duration (Days)',
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _pointsController,
                                      label: 'Reward Points',
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _descController,
                                label: 'Challenge Rules & Instructions',
                                maxLines: 4,
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
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              _saveChallenge();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Launch Challenge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
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

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Field fill karna zaroori hai';
        if (isNumber && int.tryParse(v) == null) return 'Sirf numbers allow hain';
        return null;
      },
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eco-Challenges Hub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Manage gamified tasks and user rewards', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _challenges.isEmpty
                    ? _staggered(1, const Center(child: Text('Koi active challenges nahi hain!', style: TextStyle(color: Colors.white70))))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _challenges.length,
                  itemBuilder: (context, index) {
                    final item = _challenges[index];
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
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.workspace_premium_rounded, color: sand, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: sage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                                        child: Text('${item['duration_days']} Days', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text('+${item['points']} Pts', style: const TextStyle(color: sand, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A80)),
                              onPressed: () => _deleteChallenge(item['id']),
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