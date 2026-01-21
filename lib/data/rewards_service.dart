import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage stars and rewards for kids
class RewardsService {
  // Singleton instance
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  static const String _starsKey = 'total_stars';
  static const String _streakKey = 'daily_streak';
  static const String _lastPlayKey = 'last_play_date';
  static const String _badgesKey = 'earned_badges';

  int _totalStars = 0;
  int _dailyStreak = 0;
  List<String> _earnedBadges = [];

  int get totalStars => _totalStars;
  int get dailyStreak => _dailyStreak;
  List<String> get earnedBadges => List.unmodifiable(_earnedBadges);

  /// Badge definitions
  static const Map<String, Map<String, dynamic>> badges = {
    'first_star': {'name': 'First Star!', 'icon': '⭐', 'requirement': 1},
    'math_beginner': {'name': 'Math Beginner', 'icon': '🧮', 'requirement': 10},
    'math_wizard': {'name': 'Math Wizard', 'icon': '🧙', 'requirement': 50},
    'spelling_bee': {'name': 'Spelling Bee', 'icon': '🐝', 'requirement': 20},
    'word_master': {'name': 'Word Master', 'icon': '📚', 'requirement': 100},
    'story_lover': {'name': 'Story Lover', 'icon': '📖', 'requirement': 5},
    'super_learner': {
      'name': 'Super Learner',
      'icon': '🦸',
      'requirement': 200,
    },
    'streak_3': {'name': '3 Day Streak', 'icon': '🔥', 'requirement': 3},
    'streak_7': {'name': 'Week Champion', 'icon': '🏆', 'requirement': 7},
  };

  /// Initialize rewards from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalStars = prefs.getInt(_starsKey) ?? 0;
      _dailyStreak = prefs.getInt(_streakKey) ?? 0;
      _earnedBadges = prefs.getStringList(_badgesKey) ?? [];

      // Check and update streak
      await _updateStreak(prefs);

      debugPrint(
        'RewardsService: Loaded $_totalStars stars, $_dailyStreak day streak',
      );
    } catch (e) {
      debugPrint('Error loading rewards: $e');
    }
  }

  /// Update daily streak
  Future<void> _updateStreak(SharedPreferences prefs) async {
    final lastPlayStr = prefs.getString(_lastPlayKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastPlayStr == null) {
      _dailyStreak = 1;
    } else if (lastPlayStr == todayStr) {
      // Already played today, keep streak
    } else {
      final lastPlay = DateTime.tryParse(lastPlayStr);
      if (lastPlay != null) {
        final difference = today.difference(lastPlay).inDays;
        if (difference == 1) {
          _dailyStreak++;
        } else if (difference > 1) {
          _dailyStreak = 1; // Reset streak
        }
      }
    }

    await prefs.setString(_lastPlayKey, todayStr);
    await prefs.setInt(_streakKey, _dailyStreak);

    // Check streak badges
    if (_dailyStreak >= 3) await _checkAndAwardBadge('streak_3');
    if (_dailyStreak >= 7) await _checkAndAwardBadge('streak_7');
  }

  /// Add stars and check for new badges
  Future<List<String>> addStars(int count, {String? category}) async {
    _totalStars += count;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_starsKey, _totalStars);

    // Check for new badges
    List<String> newBadges = [];

    if (_totalStars >= 1) {
      if (await _checkAndAwardBadge('first_star')) newBadges.add('first_star');
    }
    if (_totalStars >= 200) {
      if (await _checkAndAwardBadge('super_learner'))
        newBadges.add('super_learner');
    }

    // Category-specific badges
    if (category == 'math') {
      if (_totalStars >= 10 && await _checkAndAwardBadge('math_beginner')) {
        newBadges.add('math_beginner');
      }
      if (_totalStars >= 50 && await _checkAndAwardBadge('math_wizard')) {
        newBadges.add('math_wizard');
      }
    } else if (category == 'spelling') {
      if (_totalStars >= 20 && await _checkAndAwardBadge('spelling_bee')) {
        newBadges.add('spelling_bee');
      }
      if (_totalStars >= 100 && await _checkAndAwardBadge('word_master')) {
        newBadges.add('word_master');
      }
    } else if (category == 'story') {
      if (_totalStars >= 5 && await _checkAndAwardBadge('story_lover')) {
        newBadges.add('story_lover');
      }
    }

    return newBadges;
  }

  /// Check and award a badge if not already earned
  Future<bool> _checkAndAwardBadge(String badgeId) async {
    if (_earnedBadges.contains(badgeId)) return false;

    _earnedBadges.add(badgeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_badgesKey, _earnedBadges);

    debugPrint('New badge earned: $badgeId');
    return true;
  }

  /// Get badge info
  static Map<String, dynamic>? getBadgeInfo(String badgeId) {
    return badges[badgeId];
  }

  /// Check if badge is earned
  bool hasBadge(String badgeId) {
    return _earnedBadges.contains(badgeId);
  }
}
