import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/app_colors.dart';

class WasteTrackerScreen extends StatefulWidget {
  const WasteTrackerScreen({super.key});

  @override
  State<WasteTrackerScreen> createState() => _WasteTrackerScreenState();
}

class _WasteTrackerScreenState extends State<WasteTrackerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final AnimationController _entranceController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _recycleController = TextEditingController(text: "0.0");
  final TextEditingController _compostController = TextEditingController(text: "0.0");
  final TextEditingController _trashController = TextEditingController(text: "0.0");

  List<Map<String, dynamic>> _wasteLogs = [];
  double _recyclingTotal = 0.0;
  double _compostTotal = 0.0;
  double _trashTotal = 0.0;
  int _activeTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index != _activeTab) {
        setState(() => _activeTab = _tabController.index);
        _entranceController.forward(from: 0);
      }
    });
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadWasteLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
    _recycleController.dispose();
    _compostController.dispose();
    _trashController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // BACKEND / DATABASE LAYER INTERACTION
  // ---------------------------------------------------------------
  Future<void> _loadWasteLogs() async {
    try {
      final logs = await DatabaseHelper.instance.getWasteLogs();
      double recycling = 0;
      double compost = 0;
      double trash = 0;

      for (var log in logs) {
        recycling += (double.tryParse(log['recycling_kg']?.toString() ?? '0') ?? 0.0);
        compost += (double.tryParse(log['compost_kg']?.toString() ?? '0') ?? 0.0);
        trash += (double.tryParse(log['trash_kg']?.toString() ?? '0') ?? 0.0);
      }

      if (mounted) {
        setState(() {
          _wasteLogs = logs;
          _recyclingTotal = recycling;
          _compostTotal = compost;
          _trashTotal = trash;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Data load error: $e", Colors.redAccent);
    }
  }

  Future<void> _saveWasteLog() async {
    if (!_formKey.currentState!.validate()) return;

    final double? recycling = double.tryParse(_recycleController.text.trim());
    final double? compost = double.tryParse(_compostController.text.trim());
    final double? trash = double.tryParse(_trashController.text.trim());

    if (recycling == null || compost == null || trash == null) {
      _showSnackBar("Please enter valid numbers.", Colors.redAccent);
      return;
    }

    if (recycling < 0 || compost < 0 || trash < 0) {
      _showSnackBar("Weights cannot be negative.", Colors.redAccent);
      return;
    }

    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      await DatabaseHelper.instance.insertWasteLog({
        'date': formattedDate,
        'recycling_kg': recycling,
        'compost_kg': compost,
        'trash_kg': trash,
      });

      _showSnackBar("Waste log saved successfully! 🌿", AppColors.sage);

      _recycleController.text = "0.0";
      _compostController.text = "0.0";
      _trashController.text = "0.0";

      await _loadWasteLogs();

      // Smooth navigation to stats history tab
      _tabController.animateTo(1);
      setState(() => _activeTab = 1);
    } catch (e) {
      _showSnackBar("Failed to save entry: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  double get _ecoRatio {
    double totalEco = _recyclingTotal + _compostTotal;
    double grandTotal = totalEco + _trashTotal;
    if (grandTotal == 0) return 0.0;
    return (totalEco / grandTotal) * 100;
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.06).clamp(0.0, 0.5);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------
  // UI BUILD METHODS
  // ---------------------------------------------------------------
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
            colors: [AppColors.forest, AppColors.sage, AppColors.sand],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _HoverScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Waste Reduction Tracker',
                              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          Text('Log it, track it, reduce it',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Animated Pill Tabs ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton(0, 'Log Waste', Icons.add_task_rounded)),
                      Expanded(child: _buildTabButton(1, 'Stats & History', Icons.bar_chart_rounded)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogTab(),
                    _buildStatsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final bool active = _activeTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.sand.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: active ? AppColors.forest : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.forest : Colors.white70,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: Log Waste ───────────────────────────────────────────
  Widget _buildLogTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staggered(0, _glassInfoCard()),
            const SizedBox(height: 24),

            const Text("Enter Weights in Kilograms (kg)",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),

            _staggered(1, _buildGlassInput("Recyclable Waste (Paper, Metal, Plastic)", _recycleController, Icons.recycling_rounded, Colors.tealAccent)),
            const SizedBox(height: 14),
            _staggered(2, _buildGlassInput("Organic Compostable Waste (Food scraps, Peels)", _compostController, Icons.compost_rounded, const Color(0xFFA5D6A7))),
            const SizedBox(height: 14),
            _staggered(3, _buildGlassInput("Landfill Trash (Non-recyclable bags)", _trashController, Icons.delete_outline_rounded, const Color(0xFFFF8A80))),

            const SizedBox(height: 26),

            _staggered(
              4,
              _HoverScale(
                onTap: _saveWasteLog,
                scaleAmount: 0.97,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sage, AppColors.sand]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.sage.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.forest, size: 19),
                      SizedBox(width: 8),
                      Text("Save Waste Entry", style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.forest)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text("Composting Guidelines",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            _staggered(5, _buildCompostTips()),
          ],
        ),
      ),
    );
  }

  Widget _glassInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sand.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.sand),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Why track waste?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        "Diverting compost and recyclables keeps organic trash from creating methane at municipal landfills.",
                        style: TextStyle(fontSize: 12, height: 1.35, color: Colors.white70),
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
  }

  Widget _buildGlassInput(String label, TextEditingController controller, IconData icon, Color accentColor) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter numeric values' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor.withOpacity(0.8), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildCompostTips() {
    final tips = [
      "🟢 YES: Veg scraps, coffee grounds, eggshells, tea bags, dried leaves.",
      "🔴 NO: Meat, bones, cheese, oils, dog waste, plastic, foil.",
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sand.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sand.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips
                  .map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  tip,
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── TAB 2: Stats & History ─────────────────────────────────────
  Widget _buildStatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sand));
    }

    if (_wasteLogs.isEmpty) {
      return const Center(
        child: Text("No logs saved yet.", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500)),
      );
    }

    return RefreshIndicator(
      color: AppColors.forest,
      backgroundColor: AppColors.sand,
      onRefresh: _loadWasteLogs,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staggered(0, _buildStatsCard()),
            const SizedBox(height: 24),
            const Text("Logged History",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wasteLogs.length,
              itemBuilder: (context, index) {
                final log = _wasteLogs[index];
                return _staggered(index + 1, _buildHistoryTile(log));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final bool healthy = _ecoRatio > 50;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(color: AppColors.forest.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("LIFETIME RECOVERY STATS",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.sand, letterSpacing: 0.8)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAnimatedStat("Recycled", _recyclingTotal, Colors.tealAccent),
                    _buildAnimatedStat("Composted", _compostTotal, const Color(0xFFA5D6A7)),
                    _buildAnimatedStat("Landfill", _trashTotal, const Color(0xFFFF8A80)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Divider(color: Colors.white.withOpacity(0.14), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Eco Recovery Ratio:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (healthy ? Colors.greenAccent : Colors.amberAccent).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _ecoRatio),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Text(
                          "${value.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: healthy ? Colors.greenAccent : Colors.amberAccent,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (_ecoRatio / 100).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(healthy ? Colors.greenAccent : Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  healthy
                      ? "Excellent! More than half of your waste is diverted from landfills."
                      : "Compost more organic trash to increase your ratio.",
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStat(String label, double value, Color color) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Text(
            "${v.toStringAsFixed(1)} kg",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> log) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.sage.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: AppColors.sand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recycled: ${log['recycling_kg']}kg • Compost: ${log['compost_kg']}kg",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Trash: ${log['trash_kg']}kg  |  Date: ${log['date']}",
                      style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
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
    this.scaleAmount = 0.95,
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