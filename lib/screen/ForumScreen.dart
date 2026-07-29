import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Import for dynamic user unique key
import '../database/database_helper.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  Set<String> _likedPostIds = {}; // Track unique liked post IDs locally
  bool _isLoading = true;

  // Premium Green Theme Configuration
  static const Color forest = Color(0xFF1E3A2F);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFF4EAE1);

  // 🔑 Get Dynamic Key Based on Logged-in Firebase User
  String get _userPrefKey {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return 'user_liked_posts_${user.uid}'; // Dynamic key for unique user account
    }
    return 'user_liked_posts_guest'; // Fallback for guest users
  }

  @override
  void initState() {
    super.initState();
    _loadPostsAndLikes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Load posts from database and unique like states from SharedPreferences
  Future<void> _loadPostsAndLikes() async {
    try {
      final list = await DatabaseHelper.instance.getForumPosts();
      final prefs = await SharedPreferences.getInstance();

      // Fetch list using the dynamic user-specific key
      final likedList = prefs.getStringList(_userPrefKey) ?? [];

      setState(() {
        _posts = list;
        _likedPostIds = likedList.toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || author.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required to submit a post."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await DatabaseHelper.instance.insertForumPost({
      'title': title,
      'author': author,
      'content': content,
      'likes': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    _titleController.clear();
    _authorController.clear();
    _contentController.clear();

    if (mounted) {
      Navigator.pop(context);
      _loadPostsAndLikes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Your green story has been shared!"),
          backgroundColor: forest,
        ),
      );
    }
  }

  // 🔥 Professional Toggle Like Feature (Dynamic per user account)
  Future<void> _toggleLikePost(int id, int currentLikes) async {
    final prefs = await SharedPreferences.getInstance();
    final String stringId = id.toString();

    int newLikesCount = currentLikes;

    if (_likedPostIds.contains(stringId)) {
      // 1. Agar pehle se liked hai -> To Unlike karo (-1)
      newLikesCount = (currentLikes > 0) ? currentLikes - 1 : 0;
      _likedPostIds.remove(stringId);
    } else {
      // 2. Agar liked nahi hai -> To Like karo (+1)
      newLikesCount = currentLikes + 1;
      _likedPostIds.add(stringId);
    }

    // Database mein update bhejein
    await DatabaseHelper.instance.likeForumPost(id, newLikesCount);

    // Dynamic key par states save karein, taaki dosre accounts mix up na hon
    await prefs.setStringList(_userPrefKey, _likedPostIds.toList());

    // UI reload karein seamlessly
    _loadPostsAndLikes();
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: forest.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Share Your Green Story!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: forest),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _authorController,
                  style: const TextStyle(color: forest),
                  decoration: InputDecoration(
                    labelText: "Your Name",
                    labelStyle: const TextStyle(color: sage),
                    prefixIcon: const Icon(Icons.person_outline, color: sage),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: forest),
                  decoration: InputDecoration(
                    labelText: "Post Title",
                    labelStyle: const TextStyle(color: sage),
                    prefixIcon: const Icon(Icons.title_outlined, color: sage),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  style: const TextStyle(color: forest),
                  decoration: InputDecoration(
                    labelText: "Describe your sustainability update...",
                    labelStyle: const TextStyle(color: sage),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Post to Community", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [forest, sage, sand],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Community Forum",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _posts.isEmpty
            ? const Center(
          child: Text(
            "No discussions posted yet.\nBe the first to create one!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            final String timeText = _formatDate(post['created_at']);
            final String firstLetter = post['author'] != null && post['author'].toString().isNotEmpty
                ? post['author'].substring(0, 1).toUpperCase()
                : "U";

            final int postId = post['id'] ?? 0;
            final bool isLikedByMe = _likedPostIds.contains(postId.toString());

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: forest.withOpacity(0.12),
                            child: Text(
                              firstLetter,
                              style: const TextStyle(color: forest, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            post['author'] ?? "Anonymous",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: forest),
                          ),
                        ],
                      ),
                      Text(
                        timeText,
                        style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.black12, thickness: 0.8),
                  ),
                  Text(
                    post['title'] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: forest),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['content'] ?? "",
                    style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          if (postId != 0) {
                            _toggleLikePost(postId, post['likes'] ?? 0);
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isLikedByMe ? Colors.red.withOpacity(0.15) : sage.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  isLikedByMe ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                                  color: isLikedByMe ? Colors.redAccent : forest,
                                  size: 16
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${post['likes'] ?? 0} Likes",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isLikedByMe ? Colors.redAccent : forest,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined, size: 16, color: forest.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          const Text("0 Comments", style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreatePostSheet(context),
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_comment_outlined, size: 20),
          label: const Text("Share Story", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "";
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return "";
    }
  }
}