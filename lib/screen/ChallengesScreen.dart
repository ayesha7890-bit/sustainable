import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class Challenge {
  final int id; // Database Helper matching ID integer
  final String title;
  final String description;
  final int durationDays;
  final int points;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.points,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      durationDays: map['duration_days'] as int? ?? 7,
      points: map['points'] as int? ?? 50,
    );
  }
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Challenge> _allChallenges = [];
  List<int> _completedChallengeIds = []; // Mapped with integer IDs from DB helper
  bool _isLoading = true;

  // Carbon Theme Configuration Matching layout design
  static const Color forest = Color(0xFF1E3A2F);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFF4EAE1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallengesAndCompletions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallengesAndCompletions() async {
    final db = DatabaseHelper.instance;

    // DB helper calls
    final list = await db.fetchChallenges();
    final completedData = await db.fetchCompletedChallenges();

    // Mapping rows cleanly
    final completedIds = completedData.map((m) => m['challenge_id'] as int).toList();

    setState(() {
      _allChallenges = list.map((m) => Challenge.fromMap(m)).toList();
      _completedChallengeIds = completedIds;
      _isLoading = false;
    });
  }

  Future<void> _completeChallenge(Challenge challenge) async {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final result = await DatabaseHelper.instance.completeChallenge(challenge.id, todayStr);
    if (result > 0) {
      _showCelebrationDialog(challenge);
      _loadChallengesAndCompletions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: forest,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final double progressPercent = _allChallenges.isEmpty
        ? 0
        : _completedChallengeIds.length / _allChallenges.length;

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
            "Eco Challenges",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Active", icon: Icon(Icons.run_circle_outlined)),
              Tab(text: "Badges Earned", icon: Icon(Icons.stars_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(progressPercent),
            _buildBadgesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(double progressPercent) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      children: [
        // Premium Progress Card matching original style structure
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "YOUR PROGRESS",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black45),
                  ),
                  Text(
                    "${_completedChallengeIds.length} / ${_allChallenges.length} Done",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: forest, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressPercent,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: sage,
                backgroundColor: forest.withOpacity(0.15),
              ),
              const SizedBox(height: 8),
              const Text(
                "Keep completing tasks to unlock eco points and sustainability badges!",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        const Text(
          "Weekly Challenges",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        _allChallenges.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: Text("No challenges uploaded by Admin yet.", style: TextStyle(color: Colors.white70)),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allChallenges.length,
          itemBuilder: (context, index) {
            final challenge = _allChallenges[index];
            final isCompleted = _completedChallengeIds.contains(challenge.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withOpacity(0.15) : sage.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.workspace_premium_outlined,
                      color: isCompleted ? Colors.green : forest,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: forest,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Text(
                              "${challenge.points} pts",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: sage, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Duration: ${challenge.durationDays} Days",
                          style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          challenge.description,
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        isCompleted
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Completed Successfully ✓",
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                            : SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: () => _completeChallenge(challenge),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: forest,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("I Completed This!", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildBadgesTab() {
    final completedChallenges = _allChallenges.where((c) => _completedChallengeIds.contains(c.id)).toList();

    if (completedChallenges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_outlined, size: 80, color: Colors.white60),
            SizedBox(height: 16),
            Text("No badges unlocked yet.", style: TextStyle(color: Colors.white70, fontSize: 16)),
            Text("Complete challenges to win badges!", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: completedChallenges.length,
      itemBuilder: (context, index) {
        final challenge = completedChallenges[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                "${challenge.title} Badge",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: forest),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                "🌟 Unlocked",
                style: TextStyle(fontSize: 11, color: sage, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCelebrationDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: sand,
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events, size: 72, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                "Challenge Cleared!",
                style: TextStyle(fontWeight: FontWeight.bold, color: forest),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Congratulations! You completed", style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "\"${challenge.title}\"",
              style: const TextStyle(fontWeight: FontWeight.bold, color: forest, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: forest.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "+${challenge.points} Eco Points Earned",
                style: const TextStyle(color: forest, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Awesome!", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: forest)),
            ),
          )
        ],
      ),
    );
  }
}