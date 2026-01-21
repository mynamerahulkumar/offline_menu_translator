import 'dart:math';
import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class AnimalQuizScreen extends StatefulWidget {
  const AnimalQuizScreen({super.key});

  @override
  State<AnimalQuizScreen> createState() => _AnimalQuizScreenState();
}

class _AnimalQuizScreenState extends State<AnimalQuizScreen>
    with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  bool _isLoading = true;
  bool _isQuizMode = false;
  int _currentIndex = 0;
  int _score = 0;
  int _questionsAnswered = 0;
  String? _selectedAnswer;
  bool? _isCorrect;
  List<Map<String, String>> _animals = [];
  String _selectedCategory = 'all';

  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _contentService.initialize();
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() {
      _animals = _contentService.getAnimalsForAge();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getFilteredAnimals() {
    if (_selectedCategory == 'all') return _animals;
    return _animals.where((a) => a['category'] == _selectedCategory).toList();
  }

  void _speakAnimal(Map<String, String> animal) {
    final text = '${animal['name']}. ${animal['sound']}';
    _speechService.speak(text);
  }

  void _speakHindi(Map<String, String> animal) {
    _speechService.speak(
      'In Hindi, ${animal['name']} is called ${animal['hindi']}',
    );
  }

  void _startQuiz() {
    final filtered = _getFilteredAnimals();
    if (filtered.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 animals for quiz!')),
      );
      return;
    }
    setState(() {
      _isQuizMode = true;
      _score = 0;
      _questionsAnswered = 0;
    });
    _generateQuestion();
  }

  void _generateQuestion() {
    final filtered = _getFilteredAnimals();
    final random = Random();
    setState(() {
      _currentIndex = random.nextInt(filtered.length);
      _selectedAnswer = null;
      _isCorrect = null;
    });
  }

  List<String> _generateOptions() {
    final filtered = _getFilteredAnimals();
    final correct = filtered[_currentIndex]['name']!;
    final options = <String>{correct};
    final random = Random();

    while (options.length < 4) {
      final randomAnimal = filtered[random.nextInt(filtered.length)]['name']!;
      options.add(randomAnimal);
    }

    return options.toList()..shuffle();
  }

  void _checkAnswer(String answer) async {
    final filtered = _getFilteredAnimals();
    final correct = filtered[_currentIndex]['name']!;
    final isCorrect = answer == correct;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
      _questionsAnswered++;
      if (isCorrect) _score++;
    });

    if (isCorrect) {
      _speechService.speak('Correct! This is a $correct');
      await _rewardsService.addStars(2, category: 'animals');
    } else {
      _shakeController.forward(from: 0);
      _speechService.speak('Oops! This is a $correct');
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _questionsAnswered < 10) {
      _generateQuestion();
    } else if (mounted) {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _score >= 8
                  ? '🏆'
                  : _score >= 5
                  ? '🌟'
                  : '💪',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              '$_score / 10',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _score >= 8
                  ? 'Amazing!'
                  : _score >= 5
                  ? 'Good job!'
                  : 'Keep learning!',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isQuizMode = false);
            },
            child: const Text('Explore'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startQuiz();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
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
              Colors.green.shade400,
              Colors.teal.shade500,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '🦁 Animal World',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isQuizMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '⭐ $_score',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Category filter
              if (!_isQuizMode)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('all', '🌍 All'),
                      _buildCategoryChip('pet', '🏠 Pets'),
                      _buildCategoryChip('farm', '🌾 Farm'),
                      _buildCategoryChip('wild', '🌲 Wild'),
                      _buildCategoryChip('bird', '🐦 Birds'),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Main content
              Expanded(
                child: _isQuizMode ? _buildQuizMode() : _buildExploreMode(),
              ),

              // Start quiz button
              if (!_isQuizMode)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton.icon(
                    onPressed: _startQuiz,
                    icon: const Icon(Icons.quiz),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.teal : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildExploreMode() {
    final filtered = _getFilteredAnimals();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final animal = filtered[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: GestureDetector(
            onTap: () => _speakAnimal(animal),
            onLongPress: () => _speakHindi(animal),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(animal['emoji']!, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    animal['name']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    animal['hindi']!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      animal['sound']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizMode() {
    final filtered = _getFilteredAnimals();
    final animal = filtered[_currentIndex];
    final options = _generateOptions();

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_isCorrect == false ? _shakeAnimation.value : 0, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question ${_questionsAnswered + 1} of 10',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Who is this?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Animated animal emoji
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: child,
                );
              },
              child: Text(
                animal['emoji']!,
                style: const TextStyle(fontSize: 100),
              ),
            ),

            const SizedBox(height: 32),

            // Options
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = _selectedAnswer == option;
                final isCorrect = option == animal['name'];

                Color bgColor = Colors.blue.shade50;
                Color borderColor = Colors.blue.shade200;

                if (_selectedAnswer != null) {
                  if (isCorrect) {
                    bgColor = Colors.green.shade100;
                    borderColor = Colors.green;
                  } else if (isSelected) {
                    bgColor = Colors.red.shade100;
                    borderColor = Colors.red;
                  }
                }

                return GestureDetector(
                  onTap: _selectedAnswer == null
                      ? () => _checkAnswer(option)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
