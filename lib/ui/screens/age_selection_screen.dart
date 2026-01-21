import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/ui/screens/home_screen.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen>
    with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  AgeGroup? _selectedGroup;
  bool _isLoading = true;

  late AnimationController _bounceController;
  late AnimationController _scaleController;
  late Animation<double> _bounceAnimation;

  final List<Map<String, dynamic>> _ageGroups = [
    {
      'group': AgeGroup.toddler,
      'title': 'Little Explorer',
      'subtitle': '4-6 years',
      'emoji': '🧒',
      'color': Colors.pink,
      'description': 'ABCs, 1-10, Simple words',
      'icon': Icons.child_care,
    },
    {
      'group': AgeGroup.junior,
      'title': 'Smart Kid',
      'subtitle': '7-9 years',
      'emoji': '👦',
      'color': Colors.blue,
      'description': 'Tables, Stories, Puzzles',
      'icon': Icons.school,
    },
    {
      'group': AgeGroup.senior,
      'title': 'Super Learner',
      'subtitle': '10-12 years',
      'emoji': '🧑',
      'color': Colors.purple,
      'description': 'Advanced math, GK, Quizzes',
      'icon': Icons.psychology,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _initializeService();
  }

  Future<void> _initializeService() async {
    await _contentService.initialize();
    setState(() {
      _isLoading = false;
      _selectedGroup = _contentService.ageGroup;
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _selectAgeGroup(AgeGroup group) async {
    setState(() => _selectedGroup = group);
    await _contentService.setAgeGroup(group);

    // Animate selection
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
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
              Colors.indigo.shade400,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated header
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bounceAnimation.value),
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    // Animated stars
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 32)),
                        SizedBox(width: 8),
                        Text('🌟', style: TextStyle(fontSize: 48)),
                        SizedBox(width: 8),
                        Text('✨', style: TextStyle(fontSize: 32)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How old are you?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick your age group to start learning! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Age group cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _ageGroups.length,
                  itemBuilder: (context, index) {
                    final ageData = _ageGroups[index];
                    final isSelected = _selectedGroup == ageData['group'];

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 200)),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: GestureDetector(
                        onTap: () => _selectAgeGroup(ageData['group']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (ageData['color'] as Color)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (ageData['color'] as Color).withOpacity(
                                  0.4,
                                ),
                                blurRadius: isSelected ? 20 : 10,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Emoji avatar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : (ageData['color'] as Color).withOpacity(
                                          0.1,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    ageData['emoji'],
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ageData['title'],
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : ageData['color'],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ageData['subtitle'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ageData['description'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Check icon
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: ageData['color'],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _selectedGroup != null ? 1.0 : 0.5,
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _selectedGroup != null
                          ? () => _selectAgeGroup(_selectedGroup!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Let\'s Go! ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('🚀', style: TextStyle(fontSize: 24)),
                        ],
                      ),
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
}
