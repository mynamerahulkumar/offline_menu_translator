import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class NumberLearningScreen extends StatefulWidget {
  const NumberLearningScreen({super.key});

  @override
  State<NumberLearningScreen> createState() => _NumberLearningScreenState();
}

class _NumberLearningScreenState extends State<NumberLearningScreen>
    with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showHindi = false;
  bool _showObjects = false;
  List<Map<String, dynamic>> _numbers = [];

  late AnimationController _numberController;
  late AnimationController _objectsController;
  late AnimationController _pulseController;
  late Animation<double> _numberScale;
  late Animation<double> _objectsAnimation;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _objectsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _numberScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.elasticOut),
    );
    _objectsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _objectsController, curve: Curves.easeOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _contentService.initialize();
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() {
      _numbers = _contentService.getNumbersForAge();
      _isLoading = false;
    });
    _animateCurrentNumber();
  }

  void _animateCurrentNumber() {
    _numberController.forward(from: 0);
    setState(() => _showObjects = false);
    _objectsController.reset();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _objectsController.dispose();
    _pulseController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _speakNumber() {
    final item = _numbers[_currentIndex];
    _speechService.speak('${item['number']}. ${item['word']}');
  }

  void _speakHindi() {
    final item = _numbers[_currentIndex];
    setState(() => _showHindi = true);
    _speechService.speak(item['hindi']);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHindi = false);
    });
  }

  void _showCountingObjects() {
    setState(() => _showObjects = true);
    _objectsController.forward(from: 0);

    final item = _numbers[_currentIndex];
    final count = item['number'] as int;

    // Count out loud
    _countOutLoud(count);
  }

  Future<void> _countOutLoud(int count) async {
    for (int i = 1; i <= count; i++) {
      if (!mounted) return; // Exit early if unmounted
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return; // Check again after delay
      _speechService.speak('$i');
    }
  }

  void _nextNumber() async {
    if (_currentIndex < _numbers.length - 1) {
      setState(() => _currentIndex++);
      _animateCurrentNumber();
      await _rewardsService.addStars(1, category: 'numbers');
    }
  }

  void _previousNumber() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _animateCurrentNumber();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _numbers.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = _numbers[_currentIndex];
    final number = item['number'] as int;
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
      Colors.cyan,
    ];
    final numberColor = colors[number % colors.length];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [numberColor.shade300, numberColor.shade500],
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
                        '🔢 Learn Numbers',
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
                      child: Text(
                        '${_currentIndex + 1}/${_numbers.length}',
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
                    if (details.primaryVelocity! < 0)
                      _nextNumber();
                    else if (details.primaryVelocity! > 0)
                      _previousNumber();
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
                        // Big animated number
                        ScaleTransition(
                          scale: _numberScale,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.05),
                                child: child,
                              );
                            },
                            child: Text(
                              '$number',
                              style: TextStyle(
                                fontSize: 140,
                                fontWeight: FontWeight.bold,
                                color: numberColor,
                                shadows: [
                                  Shadow(
                                    color: numberColor.withOpacity(0.3),
                                    offset: const Offset(4, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Word
                        ScaleTransition(
                          scale: _numberScale,
                          child: Text(
                            item['word'],
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: numberColor.shade700,
                            ),
                          ),
                        ),

                        // Hindi (visual fallback)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showHindi ? 1.0 : 0.0,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item['hindi'],
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Counting objects animation
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showObjects ? 1.0 : 0.0,
                          child: AnimatedBuilder(
                            animation: _objectsAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: numberColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(number, (i) {
                                    final showObject =
                                        i <
                                        (number * _objectsAnimation.value)
                                            .round();
                                    return AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: showObject ? 1.0 : 0.0,
                                      child: AnimatedScale(
                                        scale: showObject ? 1.0 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.elasticOut,
                                        child: Text(
                                          _getObjectEmoji(number),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action buttons
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: Icons.volume_up,
                              label: 'Say',
                              color: Colors.blue,
                              onTap: _speakNumber,
                            ),
                            _buildActionButton(
                              icon: Icons.translate,
                              label: 'हिंदी',
                              color: Colors.orange,
                              onTap: _speakHindi,
                            ),
                            _buildActionButton(
                              icon: Icons.grid_view,
                              label: 'Count',
                              color: Colors.green,
                              onTap: _showCountingObjects,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Number selector
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _numbers.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        _animateCurrentNumber();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 45,
                        height: 45,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_numbers[index]['number']}',
                            style: TextStyle(
                              fontSize: isSelected ? 20 : 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? numberColor : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(
                      icon: Icons.arrow_back_rounded,
                      enabled: _currentIndex > 0,
                      onTap: _previousNumber,
                      color: numberColor,
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _currentIndex < _numbers.length - 1,
                      onTap: _nextNumber,
                      color: numberColor,
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

  String _getObjectEmoji(int number) {
    if (number <= 5) return '🍎';
    if (number <= 10) return '⭐';
    if (number <= 15) return '🌟';
    return '🔵';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
    required Color color,
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
        ),
        child: Icon(
          icon,
          size: 32,
          color: enabled ? color : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
