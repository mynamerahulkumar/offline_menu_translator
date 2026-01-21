import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class PoemScreen extends StatefulWidget {
  const PoemScreen({super.key});

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isReading = false;
  int _currentLine = -1;
  String _selectedLanguage = 'all';
  bool _showTransliteration = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final List<Map<String, dynamic>> _poems = ContentService.poems;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredPoems() {
    if (_selectedLanguage == 'all') return _poems;
    return _poems.where((p) => p['language'] == _selectedLanguage).toList();
  }

  Future<void> _readPoem() async {
    final filtered = _getFilteredPoems();
    final poem = filtered[_currentIndex];
    final lines = poem['lines'] as List<String>;

    setState(() {
      _isReading = true;
      _currentLine = -1;
    });

    // Set language for TTS (true for Hindi, false for English)
    if (poem['language'] == 'hindi') {
      await _speechService.setLanguageMode(true);
    } else {
      await _speechService.setLanguageMode(false);
    }

    // Read title
    _speechService.speak(poem['title']);
    await Future.delayed(const Duration(seconds: 2));

    // Read each line with highlighting
    for (int i = 0; i < lines.length; i++) {
      if (!mounted || !_isReading) break;

      setState(() => _currentLine = i);
      _speechService.speak(lines[i]);
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return; // Check again after delay
    }

    if (mounted) {
      setState(() {
        _isReading = false;
        _currentLine = -1;
      });
      // Reset to English mode after reading
      await _speechService.setLanguageMode(false);
      await _rewardsService.addStars(2, category: 'poems');
    }
  }

  void _stopReading() {
    _speechService.stop();
    setState(() {
      _isReading = false;
      _currentLine = -1;
    });
  }

  void _nextPoem() {
    final filtered = _getFilteredPoems();
    if (_currentIndex < filtered.length - 1) {
      _stopReading();
      setState(() => _currentIndex++);
    }
  }

  void _previousPoem() {
    if (_currentIndex > 0) {
      _stopReading();
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = _getFilteredPoems();
    if (filtered.isEmpty) {
      return Scaffold(body: Center(child: Text('No poems found')));
    }

    final poem = filtered[_currentIndex];
    final isHindi = poem['language'] == 'hindi';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isHindi
                ? [Colors.orange.shade300, Colors.deepOrange.shade400]
                : [Colors.purple.shade300, Colors.indigo.shade400],
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
                      onPressed: () {
                        _stopReading();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '🎵 Poems & Rhymes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
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
                        '${_currentIndex + 1}/${filtered.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Language filter
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildLanguageChip('all', '🌍 All'),
                    _buildLanguageChip('english', '🇬🇧 English'),
                    _buildLanguageChip('hindi', '🇮🇳 Hindi'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Poem card
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0)
                      _nextPoem();
                    else if (details.primaryVelocity! > 0)
                      _previousPoem();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                        // Title header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHindi
                                  ? [
                                      Colors.orange.shade100,
                                      Colors.orange.shade50,
                                    ]
                                  : [
                                      Colors.purple.shade100,
                                      Colors.purple.shade50,
                                    ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _bounceAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -_bounceAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Text(
                                  poem['emoji'],
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poem['title'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isHindi
                                            ? Colors.orange.shade800
                                            : Colors.purple.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHindi
                                            ? Colors.orange
                                            : Colors.purple,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isHindi ? 'Hindi' : 'English',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isReading)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Transliteration toggle for Hindi
                        if (isHindi && poem['transliteration'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Show Roman Script'),
                                Switch(
                                  value: _showTransliteration,
                                  onChanged: (v) =>
                                      setState(() => _showTransliteration = v),
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                          ),

                        // Poem lines
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: List.generate(
                                (poem['lines'] as List).length,
                                (index) {
                                  final line = poem['lines'][index];
                                  final translitLine =
                                      isHindi && poem['transliteration'] != null
                                      ? poem['transliteration'][index]
                                      : null;
                                  final isHighlighted = index == _currentLine;

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(30 * (1 - value), 0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isHighlighted
                                            ? (isHindi
                                                  ? Colors.orange.shade100
                                                  : Colors.purple.shade100)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isHighlighted
                                            ? Border.all(
                                                color: isHindi
                                                    ? Colors.orange
                                                    : Colors.purple,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _showTransliteration &&
                                                    translitLine != null
                                                ? translitLine
                                                : line,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isHighlighted ? 20 : 18,
                                              fontWeight: isHighlighted
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isHighlighted
                                                  ? (isHindi
                                                        ? Colors.orange.shade800
                                                        : Colors
                                                              .purple
                                                              .shade800)
                                                  : Colors.grey.shade800,
                                              height: 1.5,
                                            ),
                                          ),
                                          // Show original Hindi below transliteration
                                          if (_showTransliteration &&
                                              translitLine != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                line,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Play controls
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isReading
                                    ? _stopReading
                                    : _readPoem,
                                icon: Icon(
                                  _isReading ? Icons.stop : Icons.play_arrow,
                                ),
                                label: Text(_isReading ? 'Stop' : 'Read Aloud'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isReading
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
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
              ),

              // Navigation
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(
                      icon: Icons.arrow_back_rounded,
                      enabled: _currentIndex > 0,
                      onTap: _previousPoem,
                    ),
                    // Dots indicator
                    Row(
                      children: List.generate(
                        filtered.length.clamp(0, 8),
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentIndex ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _currentIndex < filtered.length - 1,
                      onTap: _nextPoem,
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

  Widget _buildLanguageChip(String language, String label) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () {
        _stopReading();
        setState(() {
          _selectedLanguage = language;
          _currentIndex = 0;
        });
      },
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
            color: isSelected ? Colors.purple : Colors.white,
          ),
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: enabled ? Colors.purple : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
