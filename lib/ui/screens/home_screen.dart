import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:srp_ai_app/data/rewards_service.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/ui/screens/chat_screen.dart';
import 'package:srp_ai_app/ui/screens/math_quiz_screen.dart';
import 'package:srp_ai_app/ui/screens/spelling_screen.dart';
import 'package:srp_ai_app/ui/screens/story_screen.dart';
import 'package:srp_ai_app/ui/screens/abc_learning_screen.dart';
import 'package:srp_ai_app/ui/screens/number_learning_screen.dart';
import 'package:srp_ai_app/ui/screens/tables_screen.dart';
import 'package:srp_ai_app/ui/screens/animal_quiz_screen.dart';
import 'package:srp_ai_app/ui/screens/places_screen.dart';
import 'package:srp_ai_app/ui/screens/poem_screen.dart';
import 'package:srp_ai_app/ui/screens/progress_screen.dart';
import 'package:srp_ai_app/ui/screens/parent_dashboard_screen.dart';
import 'package:srp_ai_app/ui/screens/age_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  final ContentService _contentService = ContentService();
  int _totalStars = 0;
  List<String> _badges = [];
  int _streak = 0;
  bool _isLoading = true;
  AgeGroup _ageGroup = AgeGroup.toddler;

  late AnimationController _starController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    await _rewardsService.initialize();
    await _contentService.initialize();

    setState(() {
      _totalStars = _rewardsService.totalStars;
      _badges = _rewardsService.earnedBadges;
      _streak = _rewardsService.dailyStreak;
      _ageGroup = _contentService.ageGroup;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _bounceController.dispose();
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
              Colors.blue.shade400,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with rewards
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Streak and badges
                  _buildStreakCard(),

                  const SizedBox(height: 20),

                  // Learning Section
                  _buildSectionTitle('📚 Learning'),
                  const SizedBox(height: 12),
                  _buildLearningGrid(),

                  const SizedBox(height: 20),

                  // Practice Section
                  _buildSectionTitle('✏️ Practice'),
                  const SizedBox(height: 12),
                  _buildPracticeGrid(),

                  const SizedBox(height: 20),

                  // Fun Section
                  _buildSectionTitle('🎉 Fun'),
                  const SizedBox(height: 12),
                  _buildFunGrid(),

                  const SizedBox(height: 20),

                  // More Section
                  _buildSectionTitle('⭐ More'),
                  const SizedBox(height: 12),
                  _buildMoreGrid(),

                  const SizedBox(height: 24),

                  // Badges display
                  if (_badges.isNotEmpty) _buildBadgesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLearningGrid() {
    final activities = [
      {
        'title': 'ABC',
        'emoji': '🔤',
        'subtitle': 'Learn Alphabet',
        'color': Colors.red,
        'screen': const ABCLearningScreen(),
      },
      {
        'title': 'Numbers',
        'emoji': '🔢',
        'subtitle': 'Count 1-20',
        'color': Colors.orange,
        'screen': const NumberLearningScreen(),
      },
      {
        'title': 'Tables',
        'emoji': '✖️',
        'subtitle': 'Multiplication',
        'color': Colors.green,
        'screen': const TablesScreen(),
      },
      {
        'title': 'Animals',
        'emoji': '🦁',
        'subtitle': 'Explore animals',
        'color': Colors.amber,
        'screen': const AnimalQuizScreen(),
      },
    ];

    return _buildGridFromActivities(activities);
  }

  Widget _buildPracticeGrid() {
    final activities = [
      {
        'title': 'Math Quiz',
        'emoji': '🧮',
        'subtitle': 'Practice math',
        'color': Colors.indigo,
        'screen': const MathQuizScreen(),
      },
      {
        'title': 'Spelling',
        'emoji': '🐝',
        'subtitle': 'Learn words',
        'color': Colors.teal,
        'screen': const SpellingPracticeScreen(),
      },
    ];

    return _buildGridFromActivities(activities);
  }

  Widget _buildFunGrid() {
    final activities = [
      {
        'title': 'Stories',
        'emoji': '📖',
        'subtitle': 'Hindi & English',
        'color': Colors.purple,
        'screen': const StoryScreen(),
      },
      {
        'title': 'Poems',
        'emoji': '🎵',
        'subtitle': 'Nursery rhymes',
        'color': Colors.pink,
        'screen': const PoemScreen(),
      },
      {
        'title': 'Places',
        'emoji': '🏛️',
        'subtitle': 'Famous India',
        'color': Colors.brown,
        'screen': const PlacesScreen(),
      },
      {
        'title': 'Ask AI',
        'emoji': '🤖',
        'subtitle': 'Chat with AI',
        'color': Colors.blue,
        'screen': const ChatScreen(),
      },
    ];

    return _buildGridFromActivities(activities);
  }

  Widget _buildMoreGrid() {
    final activities = [
      {
        'title': 'Progress',
        'emoji': '📊',
        'subtitle': 'My learning',
        'color': Colors.cyan,
        'screen': const ProgressScreen(),
      },
      {
        'title': 'Age',
        'emoji': _ageGroup.emoji,
        'subtitle': _ageGroup.label,
        'color': Colors.deepPurple,
        'screen': const AgeSelectionScreen(),
      },
      {
        'title': 'Parents',
        'emoji': '👨‍👩‍👧',
        'subtitle': 'Dashboard',
        'color': Colors.blueGrey,
        'screen': const ParentDashboardScreen(),
      },
    ];

    return _buildGridFromActivities(activities, crossAxisCount: 3);
  }

  Widget _buildGridFromActivities(
    List<Map<String, dynamic>> activities, {
    int crossAxisCount = 2,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: crossAxisCount == 3 ? 0.85 : 1.0,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity, compact: crossAxisCount == 3);
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar/Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: const Center(
            child: Text('🌟', style: TextStyle(fontSize: 32)),
          ),
        ),

        const SizedBox(width: 16),

        // Welcome text
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Super Learner!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'What shall we learn today?',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Stars counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade400,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                  controller: _starController,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$_totalStars',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🔥', '$_streak', 'Day Streak'),
          _buildStatItem('⭐', '$_totalStars', 'Total Stars'),
          _buildStatItem('🏆', '${_badges.length}', 'Badges'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    Map<String, dynamic> activity, {
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => activity['screen'] as Widget),
        ).then((_) => _loadRewards()); // Refresh rewards on return
      },
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_bounceController.value * 0.02),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: (activity['color'] as Color).withOpacity(0.3),
                blurRadius: compact ? 8 : 15,
                offset: Offset(0, compact ? 4 : 8),
              ),
            ],
          ),
          child: compact
              ? _buildCompactContent(activity)
              : _buildFullContent(activity),
        ),
      ),
    );
  }

  Widget _buildCompactContent(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                activity['emoji'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activity['title'],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: activity['color'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            activity['subtitle'],
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullContent(Map<String, dynamic> activity) {
    return Stack(
      children: [
        // Background decoration
        Positioned(
          right: -10,
          top: -10,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    activity['emoji'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),

              const Spacer(),

              // Title
              Text(
                activity['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: activity['color'],
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                activity['subtitle'],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Play button
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity['color'],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final badgeInfo = {
      'first_star': {'emoji': '⭐', 'name': 'First Star'},
      'math_beginner': {'emoji': '🔢', 'name': 'Math Beginner'},
      'math_wizard': {'emoji': '🧙', 'name': 'Math Wizard'},
      'spelling_bee': {'emoji': '🐝', 'name': 'Spelling Bee'},
      'word_master': {'emoji': '📚', 'name': 'Word Master'},
      'story_lover': {'emoji': '📖', 'name': 'Story Lover'},
      'super_learner': {'emoji': '🦸', 'name': 'Super Learner'},
      'streak_3': {'emoji': '🔥', 'name': '3 Day Streak'},
      'streak_7': {'emoji': '💪', 'name': 'Week Warrior'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Badges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _badges.map((badge) {
              final info = badgeInfo[badge] ?? {'emoji': '🏅', 'name': badge};
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      info['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
