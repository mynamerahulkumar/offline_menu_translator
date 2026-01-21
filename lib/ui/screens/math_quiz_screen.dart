import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:srp_ai_app/data/rewards_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';

class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({super.key});

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();
  final Random _random = Random();

  int _score = 0;
  int _questionsAnswered = 0;
  int _currentAnswer = 0;
  String _currentQuestion = '';
  List<int> _options = [];
  bool _isCorrect = false;
  bool _showResult = false;
  bool _isLoading = true;
  String _difficulty = 'easy'; // easy, medium, hard

  late AnimationController _celebrationController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() => _isLoading = false);
    _generateQuestion();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _shakeController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    int num1, num2;
    String operator;

    switch (_difficulty) {
      case 'easy':
        num1 = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        operator = ['+', '-'][_random.nextInt(2)];
        break;
      case 'medium':
        num1 = _random.nextInt(20) + 1;
        num2 = _random.nextInt(20) + 1;
        operator = ['+', '-', '×'][_random.nextInt(3)];
        break;
      case 'hard':
        num1 = _random.nextInt(50) + 1;
        num2 = _random.nextInt(20) + 1;
        operator = ['+', '-', '×', '÷'][_random.nextInt(4)];
        // For division, ensure clean result
        if (operator == '÷') {
          num1 = num2 * (_random.nextInt(10) + 1);
        }
        break;
      default:
        num1 = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        operator = '+';
    }

    // Ensure subtraction doesn't go negative for kids
    if (operator == '-' && num2 > num1) {
      final temp = num1;
      num1 = num2;
      num2 = temp;
    }

    // Calculate answer
    switch (operator) {
      case '+':
        _currentAnswer = num1 + num2;
        break;
      case '-':
        _currentAnswer = num1 - num2;
        break;
      case '×':
        _currentAnswer = num1 * num2;
        break;
      case '÷':
        _currentAnswer = num1 ~/ num2;
        break;
    }

    _currentQuestion = '$num1 $operator $num2 = ?';

    // Generate options (one correct, three wrong)
    _options = [_currentAnswer];
    while (_options.length < 4) {
      int wrongAnswer = _currentAnswer + _random.nextInt(11) - 5;
      if (wrongAnswer != _currentAnswer &&
          wrongAnswer >= 0 &&
          !_options.contains(wrongAnswer)) {
        _options.add(wrongAnswer);
      }
    }
    _options.shuffle();

    setState(() {
      _showResult = false;
    });

    // Speak the question
    final spokenQuestion = _currentQuestion.replaceAll('?', '');
    _speechService.speak('What is $spokenQuestion');
  }

  Future<void> _checkAnswer(int selectedAnswer) async {
    if (_showResult) return;

    final correct = selectedAnswer == _currentAnswer;

    setState(() {
      _isCorrect = correct;
      _showResult = true;
      _questionsAnswered++;
      if (correct) _score++;
    });

    if (correct) {
      _celebrationController.forward(from: 0);
      await _speechService.speak('Correct! Great job! 🎉');
      await _rewardsService.addStars(1, category: 'math');
    } else {
      _shakeController.forward(from: 0);
      await _speechService.speak(
        'Oops! The answer is $_currentAnswer. Try again!',
      );
    }

    // Wait and show next question
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _generateQuestion();
    }
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
              Colors.blue.shade300,
              Colors.purple.shade300,
              Colors.pink.shade200,
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        '🧮 Math Quiz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            '$_score',
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
                ),
              ),

              // Difficulty selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDifficultyChip('easy', '🌱 Easy'),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('medium', '🌿 Medium'),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('hard', '🌳 Hard'),
                  ],
                ),
              ),

              const Spacer(),

              // Question card
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final shake = sin(_shakeController.value * pi * 4) * 10;
                  return Transform.translate(
                    offset: Offset(shake, 0),
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🤔', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        _currentQuestion,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Answer options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _options.map((option) {
                    Color bgColor = Colors.white;
                    if (_showResult) {
                      if (option == _currentAnswer) {
                        bgColor = Colors.green.shade400;
                      } else if (!_isCorrect) {
                        bgColor = Colors.red.shade200;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _checkAnswer(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$option',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _showResult && option == _currentAnswer
                                  ? Colors.white
                                  : Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Result animation
              if (_showResult && _isCorrect)
                SizedBox(
                  height: 150,
                  child: Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                    controller: _celebrationController,
                    repeat: false,
                  ),
                ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Answered: $_questionsAnswered | Correct: $_score',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String level, String label) {
    final isSelected = _difficulty == level;
    return GestureDetector(
      onTap: () {
        setState(() => _difficulty = level);
        _generateQuestion();
      },
      child: Container(
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
            color: isSelected ? Colors.deepPurple : Colors.white,
          ),
        ),
      ),
    );
  }
}
