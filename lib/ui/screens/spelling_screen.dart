import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:srp_ai_app/data/rewards_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';

class SpellingPracticeScreen extends StatefulWidget {
  const SpellingPracticeScreen({super.key});

  @override
  State<SpellingPracticeScreen> createState() => _SpellingPracticeScreenState();
}

class _SpellingPracticeScreenState extends State<SpellingPracticeScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();
  final TextEditingController _inputController = TextEditingController();
  final Random _random = Random();

  int _score = 0;
  int _wordsCompleted = 0;
  String _currentWord = '';
  String _currentHint = '';
  String _currentEmoji = '';
  bool _showResult = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  String _difficulty = 'easy';

  late AnimationController _celebrationController;

  // Word lists by difficulty
  static const Map<String, List<Map<String, String>>> wordLists = {
    'easy': [
      {'word': 'CAT', 'hint': 'A furry pet that says meow', 'emoji': '🐱'},
      {'word': 'DOG', 'hint': 'A pet that barks', 'emoji': '🐕'},
      {'word': 'SUN', 'hint': 'It shines in the sky during day', 'emoji': '☀️'},
      {'word': 'BALL', 'hint': 'You throw and catch this', 'emoji': '⚽'},
      {'word': 'FISH', 'hint': 'It swims in water', 'emoji': '🐟'},
      {'word': 'BIRD', 'hint': 'It has wings and can fly', 'emoji': '🐦'},
      {'word': 'TREE', 'hint': 'It has leaves and grows tall', 'emoji': '🌳'},
      {'word': 'BOOK', 'hint': 'You read stories in this', 'emoji': '📚'},
      {'word': 'STAR', 'hint': 'It twinkles in the night sky', 'emoji': '⭐'},
      {'word': 'MOON', 'hint': 'You see it at night in the sky', 'emoji': '🌙'},
    ],
    'medium': [
      {'word': 'APPLE', 'hint': 'A red or green fruit', 'emoji': '🍎'},
      {'word': 'HAPPY', 'hint': 'Feeling good and joyful', 'emoji': '😊'},
      {'word': 'WATER', 'hint': 'You drink this when thirsty', 'emoji': '💧'},
      {'word': 'HOUSE', 'hint': 'A place where you live', 'emoji': '🏠'},
      {
        'word': 'FLOWER',
        'hint': 'A colorful plant that smells nice',
        'emoji': '🌸',
      },
      {
        'word': 'RAINBOW',
        'hint': 'Colorful arc in the sky after rain',
        'emoji': '🌈',
      },
      {'word': 'SCHOOL', 'hint': 'Where you go to learn', 'emoji': '🏫'},
      {'word': 'FRIEND', 'hint': 'Someone you play with', 'emoji': '👫'},
      {'word': 'ORANGE', 'hint': 'A round citrus fruit', 'emoji': '🍊'},
      {'word': 'BANANA', 'hint': 'A yellow curved fruit', 'emoji': '🍌'},
    ],
    'hard': [
      {
        'word': 'ELEPHANT',
        'hint': 'The biggest land animal with a trunk',
        'emoji': '🐘',
      },
      {
        'word': 'BUTTERFLY',
        'hint': 'An insect with colorful wings',
        'emoji': '🦋',
      },
      {
        'word': 'DINOSAUR',
        'hint': 'Giant reptiles from long ago',
        'emoji': '🦕',
      },
      {'word': 'BEAUTIFUL', 'hint': 'Very pretty or lovely', 'emoji': '✨'},
      {
        'word': 'ADVENTURE',
        'hint': 'An exciting journey or experience',
        'emoji': '🗺️',
      },
      {'word': 'CHOCOLATE', 'hint': 'A sweet brown candy', 'emoji': '🍫'},
      {
        'word': 'ASTRONAUT',
        'hint': 'A person who travels to space',
        'emoji': '👨‍🚀',
      },
      {
        'word': 'PLAYGROUND',
        'hint': 'Where you go to play on swings',
        'emoji': '🎢',
      },
      {
        'word': 'PENGUIN',
        'hint': 'A black and white bird that cannot fly',
        'emoji': '🐧',
      },
      {
        'word': 'GIRAFFE',
        'hint': 'Tallest animal with a long neck',
        'emoji': '🦒',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() => _isLoading = false);
    _pickNewWord();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _inputController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _pickNewWord() {
    final words = wordLists[_difficulty]!;
    final wordData = words[_random.nextInt(words.length)];

    setState(() {
      _currentWord = wordData['word']!;
      _currentHint = wordData['hint']!;
      _currentEmoji = wordData['emoji']!;
      _showResult = false;
      _inputController.clear();
    });

    // Speak the word
    _speechService.speak('Can you spell ${_currentWord}? ${_currentHint}');
  }

  void _speakWord() {
    _speechService.speak(_currentWord);
  }

  void _speakLetterByLetter() {
    final letters = _currentWord.split('').join(', ');
    _speechService.speak('$_currentWord is spelled: $letters');
  }

  Future<void> _checkSpelling() async {
    final userInput = _inputController.text.trim().toUpperCase();
    final correct = userInput == _currentWord;

    setState(() {
      _isCorrect = correct;
      _showResult = true;
      _wordsCompleted++;
      if (correct) _score++;
    });

    if (correct) {
      _celebrationController.forward(from: 0);
      await _speechService.speak(
        'Perfect! You spelled $_currentWord correctly! 🎉',
      );
      await _rewardsService.addStars(2, category: 'spelling');
    } else {
      await _speechService.speak(
        'Not quite! The correct spelling is ${_currentWord.split('').join(', ')}. Try the next word!',
      );
    }

    // Wait and show next word
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      _pickNewWord();
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
              Colors.green.shade300,
              Colors.teal.shade300,
              Colors.cyan.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                          '🐝 Spelling Bee',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

                  const SizedBox(height: 16),

                  // Difficulty selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDifficultyChip('easy', '🌱 Easy'),
                      const SizedBox(width: 8),
                      _buildDifficultyChip('medium', '🌿 Medium'),
                      const SizedBox(width: 8),
                      _buildDifficultyChip('hard', '🌳 Hard'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Word card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                        Text(
                          _currentEmoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Audio buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _speakWord,
                              icon: const Icon(Icons.volume_up),
                              label: const Text('Hear Word'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _speakLetterByLetter,
                              icon: const Icon(Icons.abc),
                              label: const Text('Spell It'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Input field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _inputController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _checkSpelling(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Check button
                  ElevatedButton(
                    onPressed: _checkSpelling,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Check Spelling ✓',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result display
                  if (_showResult)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isCorrect ? '🎉 Correct!' : '❌ Not quite!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          if (!_isCorrect)
                            Text(
                              'The correct spelling is: $_currentWord',
                              style: const TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    ),

                  // Celebration animation
                  if (_showResult && _isCorrect)
                    SizedBox(
                      height: 120,
                      child: Lottie.network(
                        'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                        controller: _celebrationController,
                        repeat: false,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Stats
                  Text(
                    'Words: $_wordsCompleted | Correct: $_score',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
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

  Widget _buildDifficultyChip(String level, String label) {
    final isSelected = _difficulty == level;
    return GestureDetector(
      onTap: () {
        setState(() => _difficulty = level);
        _pickNewWord();
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
            color: isSelected ? Colors.teal : Colors.white,
          ),
        ),
      ),
    );
  }
}
