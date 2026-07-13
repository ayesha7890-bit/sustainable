import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';
import 'package:sustainable/utils/app_colors.dart';


class EducationHubScreen extends StatefulWidget {
  final String initialFilter;

  const EducationHubScreen({super.key, this.initialFilter = 'Certification'});

  @override
  State<EducationHubScreen> createState() => _EducationHubScreenState();
}

class _EducationHubScreenState extends State<EducationHubScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  late String _activeTab; // 'Article' | 'Certification'

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialFilter;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadItems();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final data = await DatabaseHelper.instance.fetchEducationItems();
    setState(() {
      _allItems = data;
      _loading = false;
    });
    _applyFilter();
    _entranceController.forward(from: 0);
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allItems.where((item) {
        final matchesTab = item['type'] == _activeTab;
        final title = (item['title'] ?? '').toString().toLowerCase();
        final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
        final matchesSearch = _searchQuery.isEmpty ||
            title.contains(_searchQuery.toLowerCase()) ||
            subtitle.contains(_searchQuery.toLowerCase());
        return matchesTab && matchesSearch;
      }).toList();
    });
  }

  void _switchTab(String tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
    _applyFilter();
    _entranceController.forward(from: 0);
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

  void _showDetail(Map<String, dynamic> item) {
    final bool isArticle = item['type'] == 'Article';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isArticle ? Icons.menu_book_rounded : Icons.verified_rounded,
                      color: AppColors.sand,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if ((item['subtitle'] ?? '').toString().isNotEmpty)
                          Text(item['subtitle'], style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isArticle ? 'Content' : 'What it means',
                style: const TextStyle(color: AppColors.sand, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                item['description'] ?? '',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
            colors: [AppColors.forest, AppColors.sage, AppColors.sand],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Education Hub',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  'Learn, and know what eco-labels really mean',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),

              // ── Tab toggle (Articles / Certifications) ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton('Certification', 'Certifications', Icons.verified_rounded)),
                      Expanded(child: _buildTabButton('Article', 'Articles', Icons.menu_book_rounded)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Search ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: TextField(
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilter();
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _activeTab == 'Certification'
                          ? 'Search certifications (e.g. Fair Trade)'
                          : 'Search articles',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── List ──────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.sand))
                    : _filtered.isEmpty
                    ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'There is nothing in this category yet.\nAdd from the admin panel.'
                        : 'No matches found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    final isArticle = item['type'] == 'Article';
                    return _staggered(
                      index,
                      GestureDetector(
                        onTap: () => _showDetail(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.sand.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isArticle ? Icons.menu_book_rounded : Icons.verified_rounded,
                                  color: AppColors.sand,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((item['subtitle'] ?? '').toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          item['subtitle'],
                                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                            ],
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
    );
  }

  Widget _buildTabButton(String value, String label, IconData icon) {
    final bool active = _activeTab == value;
    return GestureDetector(
      onTap: () => _switchTab(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.sand.withValues(alpha: 0.9) : Colors.transparent,
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
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}