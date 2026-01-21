import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final RewardsService _rewardsService = RewardsService();
  final ContentService _contentService = ContentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _pinController = TextEditingController();

  bool _isLocked = true;
  bool _isLoading = true;
  bool _hasPin = false;
  String? _errorMessage;

  int _totalStars = 0;
  int _streak = 0;
  List<String> _badges = [];
  Map<String, int> _activityTimes = {};
  AgeGroup _ageGroup = AgeGroup.toddler;

  static const String _pinKey = 'parent_dashboard_pin';

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final existingPin = await _storage.read(key: _pinKey);
    setState(() {
      _hasPin = existingPin != null;
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    await _rewardsService.initialize();
    await _contentService.initialize();

    setState(() {
      _totalStars = _rewardsService.totalStars;
      _streak = _rewardsService.dailyStreak;
      _badges = _rewardsService.earnedBadges;
      _activityTimes = _contentService.activityTimes;
      _ageGroup = _contentService.ageGroup;
    });
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length != 4) {
      setState(() => _errorMessage = 'PIN must be 4 digits');
      return;
    }

    if (!_hasPin) {
      // Setting new PIN
      await _storage.write(key: _pinKey, value: _pinController.text);
      setState(() {
        _isLocked = false;
        _hasPin = true;
      });
      _loadData();
      return;
    }

    // Verify existing PIN
    final storedPin = await _storage.read(key: _pinKey);
    if (_pinController.text == storedPin) {
      setState(() => _isLocked = false);
      _loadData();
    } else {
      setState(() => _errorMessage = 'Incorrect PIN');
    }
  }

  Future<void> _resetPin() async {
    await _storage.delete(key: _pinKey);
    setState(() {
      _hasPin = false;
      _pinController.clear();
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLocked) {
      return _buildPinScreen();
    }

    return _buildDashboard();
  }

  Widget _buildPinScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    _hasPin ? 'Enter Parent PIN' : 'Set Parent PIN',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasPin
                        ? 'Enter your 4-digit PIN to access the dashboard'
                        : 'Create a 4-digit PIN to protect this section',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: '• • • •',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blueGrey,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _verifyPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _hasPin ? 'Unlock' : 'Set PIN',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to App',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final totalMinutes = _activityTimes.values.fold(0, (a, b) => a + b) ~/ 60;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
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
                          '👨‍👩‍👧 Parent Dashboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAgeGroupPicker(),
                        icon: const Icon(Icons.settings, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Child info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('👶', style: TextStyle(fontSize: 32)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Little Learner',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Age Group: ${_ageGroup.label}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Key stats
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
                          'Streak',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '⏱️',
                          '$totalMinutes',
                          'Minutes',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Activity breakdown
                  _buildSectionTitle('📊 Activity Summary'),
                  const SizedBox(height: 12),
                  _buildActivitySummary(),

                  const SizedBox(height: 20),

                  // Recommendations
                  _buildSectionTitle('💡 Recommendations'),
                  const SizedBox(height: 12),
                  _buildRecommendations(),

                  const SizedBox(height: 20),

                  // Badges earned
                  _buildSectionTitle('🏆 Badges Earned'),
                  const SizedBox(height: 12),
                  _buildBadgesList(),

                  const SizedBox(height: 20),

                  // Settings
                  _buildSectionTitle('⚙️ Settings'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(),

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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary() {
    final activities = [
      {'name': 'ABC Learning', 'key': 'abc', 'emoji': '🔤'},
      {'name': 'Numbers', 'key': 'numbers', 'emoji': '🔢'},
      {'name': 'Tables', 'key': 'tables', 'emoji': '✖️'},
      {'name': 'Animals', 'key': 'animals', 'emoji': '🦁'},
      {'name': 'Places', 'key': 'places', 'emoji': '🏛️'},
      {'name': 'Poems', 'key': 'poems', 'emoji': '🎵'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: activities.map((activity) {
          final minutes = (_activityTimes[activity['key']] ?? 0) ~/ 60;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  activity['emoji'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '$minutes min',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendations() {
    List<Map<String, String>> recommendations = [];

    if (_streak == 0) {
      recommendations.add({
        'emoji': '🔥',
        'text': 'Encourage daily practice to build a learning streak!',
      });
    }
    if (_totalStars < 50) {
      recommendations.add({
        'emoji': '⭐',
        'text': 'Try spending more time on ABC and Number activities.',
      });
    }
    if (_activityTimes['poems'] == null || _activityTimes['poems']! < 300) {
      recommendations.add({
        'emoji': '🎵',
        'text': 'Poems help with language skills. Try reading together!',
      });
    }
    if (recommendations.isEmpty) {
      recommendations.add({
        'emoji': '🌟',
        'text': 'Great progress! Keep up the excellent work!',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec['emoji']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec['text']!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadgesList() {
    if (_badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No badges earned yet. Keep learning! 💪',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final badgeInfo = {
      'first_star': '⭐ First Star',
      'math_beginner': '🧮 Math Beginner',
      'math_wizard': '🧙 Math Wizard',
      'spelling_bee': '🐝 Spelling Bee',
      'word_master': '📚 Word Master',
      'story_lover': '📖 Story Lover',
      'super_learner': '🦸 Super Learner',
      'streak_3': '🔥 3 Day Streak',
      'streak_7': '🏆 Week Champion',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _badges.map((badge) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              badgeInfo[badge] ?? badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.child_care, color: Colors.blue),
            title: const Text('Change Age Group'),
            subtitle: Text('Current: ${_ageGroup.label}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAgeGroupPicker,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.orange),
            title: const Text('Reset PIN'),
            subtitle: const Text('Change your parent PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showResetPinDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Reset Progress'),
            subtitle: const Text('Clear all stars and badges'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showResetProgressDialog,
          ),
        ],
      ),
    );
  }

  void _showAgeGroupPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Age Group',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...AgeGroup.values.map((group) {
              return ListTile(
                leading: Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(group.label),
                trailing: _ageGroup == group
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _contentService.setAgeGroup(group);
                  setState(() => _ageGroup = group);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showResetPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text(
          'You will need to set a new PIN to access the parent dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPin();
              Navigator.pop(context); // Go back to locked state
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will delete all stars, badges, and learning history. This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Reset all progress data
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('total_stars');
              await prefs.remove('daily_streak');
              await prefs.remove('earned_badges');
              for (final activity in [
                'abc',
                'numbers',
                'tables',
                'animals',
                'places',
                'poems',
                'stories',
                'math',
                'spelling',
              ]) {
                await prefs.remove('activity_time_$activity');
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress reset successfully')),
                );
                // Reinitialize services to reflect reset
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
