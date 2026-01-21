import 'dart:math';
import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen>
    with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  int _selectedTable = 2;
  int _maxTable = 10;
  bool _isLoading = true;
  bool _isPracticeMode = false;
  int _practiceNumber = 0;
  int? _selectedAnswer;
  bool? _isAnswerCorrect;
  int _score = 0;
  int _practiceCount = 0;

  late AnimationController _tableController;
  late AnimationController _correctController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tableController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _correctController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _tableController, curve: Curves.elasticOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _contentService.initialize();
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() {
      _maxTable = _contentService.getMaxTableForAge();
      _isLoading = false;
    });
    _tableController.forward();
  }

  @override
  void dispose() {
    _tableController.dispose();
    _correctController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _speakTable() async {
    for (int i = 1; i <= 10; i++) {
      if (!mounted) return; // Exit early if unmounted
      final text = '$_selectedTable times $i equals ${_selectedTable * i}';
      _speechService.speak(text);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return; // Check again after delay
    }
  }

  void _speakSingleRow(int multiplier) {
    final result = _selectedTable * multiplier;
    _speechService.speak('$_selectedTable times $multiplier equals $result');
  }

  void _startPractice() {
    setState(() {
      _isPracticeMode = true;
      _score = 0;
      _practiceCount = 0;
    });
    _generatePracticeQuestion();
  }

  void _generatePracticeQuestion() {
    setState(() {
      _practiceNumber = Random().nextInt(10) + 1;
      _selectedAnswer = null;
      _isAnswerCorrect = null;
    });
  }

  void _checkAnswer(int answer) async {
    final correct = _selectedTable * _practiceNumber;
    final isCorrect = answer == correct;

    setState(() {
      _selectedAnswer = answer;
      _isAnswerCorrect = isCorrect;
      _practiceCount++;
      if (isCorrect) _score++;
    });

    if (isCorrect) {
      _correctController.forward(from: 0);
      _speechService.speak('Correct! Well done!');
      await _rewardsService.addStars(1, category: 'tables');
    } else {
      _speechService.speak('Oops! The answer is $correct');
    }

    // Next question after delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _practiceCount < 10) {
      _generatePracticeQuestion();
    } else if (mounted) {
      _showPracticeResult();
    }
  }

  void _showPracticeResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _score >= 8
                  ? '🌟'
                  : _score >= 5
                  ? '👍'
                  : '💪',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score/10',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _score >= 8
                  ? 'Excellent!'
                  : _score >= 5
                  ? 'Good job!'
                  : 'Keep practicing!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isPracticeMode = false);
            },
            child: const Text('Back to Table'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startPractice();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  List<int> _generateOptions(int correctAnswer) {
    final options = <int>{correctAnswer};
    final random = Random();
    while (options.length < 4) {
      final offset = random.nextInt(20) - 10;
      final option = correctAnswer + offset;
      if (option > 0 && option != correctAnswer) {
        options.add(option);
      }
    }
    final list = options.toList()..shuffle();
    return list;
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
              Colors.deepPurple.shade600,
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
                        '✖️ Multiplication Tables',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isPracticeMode)
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

              // Table selector
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _maxTable - 1,
                  itemBuilder: (context, index) {
                    final table = index + 2;
                    final isSelected = table == _selectedTable;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTable = table;
                          _isPracticeMode = false;
                        });
                        _tableController.forward(from: 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$table',
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.indigo : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Main content
              Expanded(
                child: _isPracticeMode
                    ? _buildPracticeMode()
                    : _buildTableView(),
              ),

              // Bottom buttons
              if (!_isPracticeMode)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _speakTable,
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Read Aloud'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startPractice,
                          icon: const Icon(Icons.quiz),
                          label: const Text('Practice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Table of $_selectedTable',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table rows
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  final multiplier = index + 1;
                  final result = _selectedTable * multiplier;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(50 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _speakSingleRow(multiplier),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? Colors.grey.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_selectedTable',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                            const Text(' × ', style: TextStyle(fontSize: 22)),
                            Text(
                              '$multiplier',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade600,
                              ),
                            ),
                            const Text(' = ', style: TextStyle(fontSize: 22)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$result',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.volume_up, color: Colors.grey.shade400),
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
    );
  }

  Widget _buildPracticeMode() {
    final correctAnswer = _selectedTable * _practiceNumber;
    final options = _generateOptions(correctAnswer);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress
          Text(
            'Question ${_practiceCount + 1} of 10',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Question
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_selectedTable',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(' × ', style: TextStyle(fontSize: 48)),
              Text(
                '$_practiceNumber',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Text(' = ', style: TextStyle(fontSize: 48)),
              const Text(
                '?',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Answer options
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.0,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == correctAnswer;

              Color bgColor = Colors.blue.shade50;
              Color borderColor = Colors.blue.shade200;
              Color textColor = Colors.blue.shade700;

              if (_selectedAnswer != null) {
                if (isCorrect) {
                  bgColor = Colors.green.shade100;
                  borderColor = Colors.green;
                  textColor = Colors.green.shade700;
                } else if (isSelected) {
                  bgColor = Colors.red.shade100;
                  borderColor = Colors.red;
                  textColor = Colors.red.shade700;
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$option',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (_selectedAnswer != null && isCorrect)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        if (_selectedAnswer != null && isSelected && !isCorrect)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '✗',
                              style: TextStyle(fontSize: 28, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Result feedback
          if (_isAnswerCorrect != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isAnswerCorrect! ? '🎉 Correct!' : '❌ Try again!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isAnswerCorrect! ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
