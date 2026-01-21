import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class ABCLearningScreen extends StatefulWidget {
  const ABCLearningScreen({super.key});

  @override
  State<ABCLearningScreen> createState() => _ABCLearningScreenState();
}

class _ABCLearningScreenState extends State<ABCLearningScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showHindi = false;

  late AnimationController _letterController;
  late AnimationController _emojiController;
  late AnimationController _bounceController;
  late Animation<double> _letterScale;
  late Animation<double> _emojiScale;
  late Animation<double> _bounceAnimation;

  final List<Map<String, String>> _alphabet = ContentService.alphabet;

  @override
  void initState() {
    super.initState();
    _letterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _letterScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _letterController, curve: Curves.elasticOut),
    );
    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.bounceOut),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() => _isLoading = false);
    _animateCurrentLetter();
  }

  void _animateCurrentLetter() {
    _letterController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      _emojiController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _letterController.dispose();
    _emojiController.dispose();
    _bounceController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _speakLetter() {
    final item = _alphabet[_currentIndex];
    final text = '${item['letter']} for ${item['word']}';
    _speechService.speak(text);
  }

  void _speakHindi() async {
    final item = _alphabet[_currentIndex];
    // Try Hindi TTS, fallback to showing text
    await _speechService.setLanguageMode(true); // true for Hindi mode
    _speechService.speak(item['hindi']!);
    // Always show Hindi text as visual fallback
    setState(() => _showHindi = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showHindi = false);
        _speechService.setLanguageMode(false); // Reset to English
      }
    });
  }

  void _nextLetter() async {
    if (_currentIndex < _alphabet.length - 1) {
      setState(() => _currentIndex++);
      _animateCurrentLetter();
      await _rewardsService.addStars(1, category: 'abc');
    }
  }

  void _previousLetter() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _animateCurrentLetter();
    }
  }

  void _goToLetter(int index) {
    setState(() => _currentIndex = index);
    _animateCurrentLetter();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = _alphabet[_currentIndex];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.deepOrange,
    ];
    final letterColor = colors[_currentIndex % colors.length];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              letterColor.shade300,
              letterColor.shade400,
              letterColor.shade600,
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
                        '🔤 Learn ABC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/26',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      _nextLetter();
                    } else if (details.primaryVelocity! > 0) {
                      _previousLetter();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated letter
                        ScaleTransition(
                          scale: _letterScale,
                          child: Text(
                            item['letter']!,
                            style: TextStyle(
                              fontSize: 150,
                              fontWeight: FontWeight.bold,
                              color: letterColor,
                              shadows: [
                                Shadow(
                                  color: letterColor.withOpacity(0.3),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Animated emoji
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -_bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: ScaleTransition(
                            scale: _emojiScale,
                            child: Text(
                              item['emoji']!,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Word
                        ScaleTransition(
                          scale: _emojiScale,
                          child: Text(
                            '${item['letter']} for ${item['word']}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: letterColor.shade700,
                            ),
                          ),
                        ),

                        // Hindi translation (visual fallback)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showHindi ? 1.0 : 0.0,
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item['hindi']!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: Icons.volume_up,
                              label: 'English',
                              color: Colors.blue,
                              onTap: _speakLetter,
                            ),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              icon: Icons.translate,
                              label: 'हिंदी',
                              color: Colors.orange,
                              onTap: _speakHindi,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Letter selector
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _alphabet.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () => _goToLetter(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _alphabet[index]['letter']!,
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? letterColor : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation arrows
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(
                      icon: Icons.arrow_back_rounded,
                      enabled: _currentIndex > 0,
                      onTap: _previousLetter,
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _currentIndex < _alphabet.length - 1,
                      onTap: _nextLetter,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [BoxShadow(color: Colors.black26, blurRadius: 10)]
              : null,
        ),
        child: Icon(
          icon,
          size: 32,
          color: enabled ? Colors.purple : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
