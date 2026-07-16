import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _GalleryImage {
  final String url;
  final String caption;
  final String category;
  const _GalleryImage({required this.url, required this.caption, required this.category});
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  String _activeCategory = 'All';

  // ── DUMMY DATA — replace with DatabaseHelper.instance.fetchGalleryImages() later ──
  final List<_GalleryImage> _images = const [
    _GalleryImage(url: 'https://picsum.photos/id/1015/500/500', caption: 'Riverside greenery', category: 'Nature'),
    _GalleryImage(url: 'https://picsum.photos/id/1018/500/500', caption: 'Mountain solar farm', category: 'Solar'),
    _GalleryImage(url: 'https://picsum.photos/id/1039/500/500', caption: 'Community recycling drive', category: 'Recycling'),
    _GalleryImage(url: 'https://picsum.photos/id/28/500/500', caption: 'Urban rooftop garden', category: 'Nature'),
    _GalleryImage(url: 'https://picsum.photos/id/48/500/500', caption: 'Wind turbines at sunset', category: 'Solar'),
    _GalleryImage(url: 'https://picsum.photos/id/106/500/500', caption: 'Zero-waste grocery haul', category: 'Zero Waste'),
    _GalleryImage(url: 'https://picsum.photos/id/110/500/500', caption: 'Reusable produce bags', category: 'Zero Waste'),
    _GalleryImage(url: 'https://picsum.photos/id/122/500/500', caption: 'Compost bin setup', category: 'Recycling'),
    _GalleryImage(url: 'https://picsum.photos/id/177/500/500', caption: 'Forest conservation area', category: 'Nature'),
  ];

  List<String> get _categories =>
      ['All', ..._images.map((e) => e.category).toSet()];

  List<_GalleryImage> get _filtered => _activeCategory == 'All'
      ? _images
      : _images.where((img) => img.category == _activeCategory).toList();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _switchCategory(String category) {
    setState(() => _activeCategory = category);
    _entranceController.forward(from: 0);
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.06).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return ScaleTransition(
      scale: anim,
      child: FadeTransition(opacity: anim, child: child),
    );
  }

  void _openFullscreen(_GalleryImage img) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, anim1, anim2) => FadeTransition(
          opacity: anim1,
          child: _FullscreenViewer(image: img),
        ),
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
                  'Image Gallery',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  'Moments of sustainable living, around the world',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),

              // ── Category filter chips ──────────────────────────
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final active = cat == _activeCategory;
                    return GestureDetector(
                      onTap: () => _switchCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.sand.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: active ? 0 : 0.16)),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: active ? AppColors.forest : Colors.white70,
                              fontSize: 12.5,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Grid ────────────────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                  child: Text('Is category mein koi image nahi.', style: TextStyle(color: Colors.white70)),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final img = _filtered[index];
                    return _staggered(
                      index,
                      GestureDetector(
                        onTap: () => _openFullscreen(img),
                        child: Hero(
                          tag: img.url,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  img.url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: AppColors.sand, strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    child: const Icon(Icons.image_not_supported_rounded, color: Colors.white38),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                                      ),
                                    ),
                                    child: Text(
                                      img.caption,
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}

class _FullscreenViewer extends StatelessWidget {
  final _GalleryImage image;
  const _FullscreenViewer({required this.image});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: image.url,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(image.url, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 24,
                right: 16,
                child: Text(
                  image.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}