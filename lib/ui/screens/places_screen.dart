import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showFact = false;

  late AnimationController _cardController;
  late AnimationController _factController;
  late Animation<double> _cardScale;
  late Animation<double> _factSlide;

  final List<Map<String, String>> _places = ContentService.places;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _factController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _factSlide = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _factController, curve: Curves.easeOut));

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    setState(() => _isLoading = false);
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _factController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _speakPlace() {
    final place = _places[_currentIndex];
    _speechService.speak(
      '${place['name']} in ${place['city']}. ${place['fact']}',
    );
  }

  void _speakHindi() {
    final place = _places[_currentIndex];
    _speechService.speak('In Hindi, it is called ${place['hindi']}');
  }

  void _toggleFact() {
    setState(() => _showFact = !_showFact);
    if (_showFact) {
      _factController.forward(from: 0);
    }
  }

  void _nextPlace() async {
    if (_currentIndex < _places.length - 1) {
      setState(() {
        _currentIndex++;
        _showFact = false;
      });
      _cardController.forward(from: 0);
      await _rewardsService.addStars(1, category: 'places');
    }
  }

  void _previousPlace() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFact = false;
      });
      _cardController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final place = _places[_currentIndex];
    final colors = [
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.teal,
      Colors.deepPurple,
      Colors.green,
    ];
    final cardColor = colors[_currentIndex % colors.length];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade300,
              Colors.deepOrange.shade400,
              Colors.red.shade400,
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
                        '🏛️ Famous Places of India',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
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
                        '${_currentIndex + 1}/${_places.length}',
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

              // Main card
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0)
                      _nextPlace();
                    else if (details.primaryVelocity! > 0)
                      _previousPlace();
                  },
                  onTap: _toggleFact,
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top colored section
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cardColor.shade300,
                                  cardColor.shade500,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    place['emoji']!,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          place['city']!,
                                          style: const TextStyle(
                                            fontSize: 16,
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
                          ),

                          // Content section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Place name
                                  Text(
                                    place['name']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: cardColor.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Hindi name
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      place['hindi']!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Fun fact
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: _showFact ? 1.0 : 0.0,
                                    child: AnimatedBuilder(
                                      animation: _factSlide,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            _showFact ? 0 : _factSlide.value,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              '💡',
                                              style: TextStyle(fontSize: 28),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                place['fact']!,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (!_showFact)
                                    Text(
                                      'Tap to see fun fact! 👆',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),

                                  const Spacer(),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildActionButton(
                                        icon: Icons.volume_up,
                                        label: 'Listen',
                                        color: Colors.blue,
                                        onTap: _speakPlace,
                                      ),
                                      const SizedBox(width: 12),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Place indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_places.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
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
                      onTap: _previousPlace,
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _currentIndex < _places.length - 1,
                      onTap: _nextPlace,
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
        ),
        child: Icon(
          icon,
          size: 32,
          color: enabled ? Colors.deepOrange : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
