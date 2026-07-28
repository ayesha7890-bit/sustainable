import 'package:flutter/material.dart';

class ImageGalleryScreen extends StatelessWidget {
  const ImageGalleryScreen({super.key});

  // 🖼️ Clean & Fast Loading Sustainable Living Images Array (Copyright-free)
  final List<Map<String, String>> _galleryItems = const [
    {
      'image': 'https://images.pexels.com/photos/356036/pexels-photo-356036.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Solar Energy Panels',
      'desc': 'Clean and renewable energy harvested directly from the sun to power eco-homes.'
    },
    {
      'image': 'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Waste Recycling',
      'desc': 'Sorting and recycling plastic, glass, and paper to create a zero-waste lifestyle.'
    },
    {
      'image': 'https://images.pexels.com/photos/9875682/pexels-photo-9875682.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Eco-Friendly Transport',
      'desc': 'Reducing carbon emissions by using bicycles and electric public commuting options.'
    },
    {
      'image': 'https://images.pexels.com/photos/414837/pexels-photo-414837.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Wind Power Turbines',
      'desc': 'Utilizing natural wind streams to generate massive amounts of green grid electricity.'
    },
    {
      'image': 'https://images.pexels.com/photos/3075988/pexels-photo-3075988.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Home Composting',
      'desc': 'Converting organic food scraps into nutrient-rich soil to grow home gardens.'
    },
    {
      'image': 'https://images.pexels.com/photos/1072824/pexels-photo-1072824.jpeg?auto=compress&cs=tinysrgb&w=600',
      'title': 'Sustainable Reforestation',
      'desc': 'Planting indigenous trees to increase oxygen production and fight global warming.'
    },
  ];

  // 📑 Tap karne par image aur detailed info ka bottom sheet open karne ke liye function
  void _showImagePreview(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Image.network(
                item['image']!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                // Fast Loading Indicator
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFCBBE9C))),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['desc']!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCBBE9C),
                        foregroundColor: const Color(0xFF2F4A3E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F4A3E), Color(0xFF5E8570), Color(0xFFCBBE9C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    //   onPressed: () => Navigator.pop(context),
                    // ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sustainable Gallery',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Responsive 2-Column Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items par row
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8, // Card proportional look ke liye
                  ),
                  itemCount: _galleryItems.length,
                  itemBuilder: (context, index) {
                    final item = _galleryItems[index];
                    return GestureDetector(
                      onTap: () => _showImagePreview(context, item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.network(
                                  item['image']!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator(color: Color(0xFFCBBE9C), strokeWidth: 2));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  item['title']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
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
}