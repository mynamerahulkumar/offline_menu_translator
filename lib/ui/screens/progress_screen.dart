import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  final ContentService _contentService = ContentService();

  bool _isLoading = true;
  int _totalStars = 0;
  int _streak = 0;
  List<String> _badges = [];
  Map<String, int> _activityTimes = {};

  late AnimationController _starController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    await _rewardsService.initialize();
    await _contentService.initialize();

    setState(() {
      _totalStars = _rewardsService.totalStars;
      _streak = _rewardsService.dailyStreak;
      _badges = _rewardsService.earnedBadges;
      _activityTimes = _contentService.activityTimes;
      _isLoading = false;
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade400,
              Colors.purple.shade500,
              Colors.pink.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          '📊 My Progress',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '⭐',
                          '$_totalStars',
                          'Stars',
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '🔥',
                          '$_streak',
                          'Day Streak',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '🏆',
                          '${_badges.length}',
                          'Badges',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Learning progress
                  _buildSectionTitle('📚 Learning Progress'),
                  const SizedBox(height: 12),
                  _buildProgressCard(),

                  const SizedBox(height: 24),

                  // Activity breakdown
                  _buildSectionTitle('⏱️ Time Spent'),
                  const SizedBox(height: 12),
                  _buildActivityBreakdown(),

                  const SizedBox(height: 24),

                  // Badges section
                  _buildSectionTitle('🎖️ My Badges'),
                  const SizedBox(height: 12),
                  _buildBadgesGrid(),

                  const SizedBox(height: 24),

                  // Growth visualization
                  _buildSectionTitle('🌱 Growth Journey'),
                  const SizedBox(height: 12),
                  _buildGrowthVisualization(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        final scale = emoji == '⭐' ? 1.0 + (_starController.value * 0.1) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final activities = [
      {
        'name': 'ABC',
        'emoji': '🔤',
        'progress': (_totalStars / 100).clamp(0.0, 1.0),
        'color': Colors.red,
      },
      {
        'name': 'Numbers',
        'emoji': '🔢',
        'progress': (_totalStars / 150).clamp(0.0, 1.0),
        'color': Colors.blue,
      },
      {
        'name': 'Tables',
        'emoji': '✖️',
        'progress': (_totalStars / 200).clamp(0.0, 1.0),
        'color': Colors.purple,
      },
      {
        'name': 'Animals',
        'emoji': '🦁',
        'progress': (_totalStars / 120).clamp(0.0, 1.0),
        'color': Colors.green,
      },
      {
        'name': 'Poems',
        'emoji': '🎵',
        'progress': (_totalStars / 80).clamp(0.0, 1.0),
        'color': Colors.orange,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  activity['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value:
                                  (activity['progress'] as double) *
                                  _progressController.value,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                activity['color'] as Color,
                              ),
                              minHeight: 10,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${((activity['progress'] as double) * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: activity['color'] as Color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityBreakdown() {
    final totalMinutes = _activityTimes.values.fold(0, (a, b) => a + b) ~/ 60;

    final activities = [
      {
        'name': 'ABC Learning',
        'key': 'abc',
        'emoji': '🔤',
        'color': Colors.red,
      },
      {
        'name': 'Numbers',
        'key': 'numbers',
        'emoji': '🔢',
        'color': Colors.blue,
      },
      {
        'name': 'Tables',
        'key': 'tables',
        'emoji': '✖️',
        'color': Colors.purple,
      },
      {
        'name': 'Animals',
        'key': 'animals',
        'emoji': '🦁',
        'color': Colors.green,
      },
      {'name': 'Poems', 'key': 'poems', 'emoji': '🎵', 'color': Colors.orange},
      {
        'name': 'Stories',
        'key': 'stories',
        'emoji': '📖',
        'color': Colors.pink,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Total time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, size: 28, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                '$totalMinutes minutes',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total learning time',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 24),

          // Activity breakdown
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: activities.map((activity) {
              final minutes = (_activityTimes[activity['key']] ?? 0) ~/ 60;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activity['emoji'] as String,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$minutes min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: activity['color'] as Color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final allBadges = [
      {
        'id': 'first_star',
        'emoji': '⭐',
        'name': 'First Star',
        'desc': 'Earn your first star',
      },
      {
        'id': 'math_beginner',
        'emoji': '🧮',
        'name': 'Math Beginner',
        'desc': '10 math stars',
      },
      {
        'id': 'math_wizard',
        'emoji': '🧙',
        'name': 'Math Wizard',
        'desc': '50 math stars',
      },
      {
        'id': 'spelling_bee',
        'emoji': '🐝',
        'name': 'Spelling Bee',
        'desc': '20 spelling stars',
      },
      {
        'id': 'word_master',
        'emoji': '📚',
        'name': 'Word Master',
        'desc': '100 word stars',
      },
      {
        'id': 'story_lover',
        'emoji': '📖',
        'name': 'Story Lover',
        'desc': '5 stories read',
      },
      {
        'id': 'super_learner',
        'emoji': '🦸',
        'name': 'Super Learner',
        'desc': '200 total stars',
      },
      {
        'id': 'streak_3',
        'emoji': '🔥',
        'name': '3 Day Streak',
        'desc': 'Learn 3 days in a row',
      },
      {
        'id': 'streak_7',
        'emoji': '🏆',
        'name': 'Week Champion',
        'desc': 'Learn 7 days in a row',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: allBadges.length,
        itemBuilder: (context, index) {
          final badge = allBadges[index];
          final isEarned = _badges.contains(badge['id']);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 100)),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEarned ? Colors.amber.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: isEarned
                    ? Border.all(color: Colors.amber, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge['emoji'] as String,
                    style: TextStyle(
                      fontSize: 32,
                      color: isEarned ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isEarned ? Colors.amber.shade800 : Colors.grey,
                    ),
                  ),
                  if (!isEarned)
                    const Icon(Icons.lock, size: 14, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrowthVisualization() {
    // Determine growth stage based on stars
    int stage;
    String stageEmoji;
    String stageName;
    String nextGoal;

    if (_totalStars < 10) {
      stage = 1;
      stageEmoji = '🌱';
      stageName = 'Seedling';
      nextGoal = '${10 - _totalStars} more stars to sprout!';
    } else if (_totalStars < 50) {
      stage = 2;
      stageEmoji = '🌿';
      stageName = 'Sprout';
      nextGoal = '${50 - _totalStars} more stars to bloom!';
    } else if (_totalStars < 100) {
      stage = 3;
      stageEmoji = '🌻';
      stageName = 'Flower';
      nextGoal = '${100 - _totalStars} more stars to grow!';
    } else if (_totalStars < 200) {
      stage = 4;
      stageEmoji = '🌳';
      stageName = 'Tree';
      nextGoal = '${200 - _totalStars} more stars to become magical!';
    } else {
      stage = 5;
      stageEmoji = '🌟';
      stageName = 'Superstar';
      nextGoal = 'You\'re amazing! Keep shining!';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Growth stage visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGrowthStage('🌱', 1, stage),
              _buildGrowthArrow(stage >= 2),
              _buildGrowthStage('🌿', 2, stage),
              _buildGrowthArrow(stage >= 3),
              _buildGrowthStage('🌻', 3, stage),
              _buildGrowthArrow(stage >= 4),
              _buildGrowthStage('🌳', 4, stage),
              _buildGrowthArrow(stage >= 5),
              _buildGrowthStage('🌟', 5, stage),
            ],
          ),
          const SizedBox(height: 20),

          // Current stage
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_starController.value * 0.1),
                child: child,
              );
            },
            child: Text(stageEmoji, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 8),
          Text(
            stageName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextGoal,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthStage(String emoji, int stageNum, int currentStage) {
    final isReached = currentStage >= stageNum;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isReached ? Colors.amber.shade100 : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: currentStage == stageNum
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: 18, color: isReached ? null : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildGrowthArrow(bool isActive) {
    return Icon(
      Icons.arrow_forward,
      size: 16,
      color: isActive ? Colors.amber : Colors.grey.shade300,
    );
  }
}
