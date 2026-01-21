import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:srp_ai_app/data/chat_service.dart';
import 'package:srp_ai_app/data/rewards_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final RewardsService _rewardsService = RewardsService();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isReading = false;
  String _currentStory = '';
  String _selectedTheme = '';
  int _storiesRead = 0;

  late AnimationController _readingController;

  // Story themes with emojis and prompts
  static const List<Map<String, dynamic>> storyThemes = [
    {
      'id': 'adventure',
      'title': 'Adventure',
      'emoji': '🗺️',
      'color': Colors.orange,
      'prompt':
          'Tell a short adventure story for children about exploring a magical forest.',
      'lottie': 'https://assets3.lottiefiles.com/packages/lf20_khrclx93.json',
    },
    {
      'id': 'animals',
      'title': 'Animal Friends',
      'emoji': '🦁',
      'color': Colors.amber,
      'prompt':
          'Tell a short story for children about a brave little animal who makes new friends.',
      'lottie': 'https://assets9.lottiefiles.com/packages/lf20_yvxyrlit.json',
    },
    {
      'id': 'space',
      'title': 'Space Journey',
      'emoji': '🚀',
      'color': Colors.indigo,
      'prompt':
          'Tell a short story for children about a fun adventure in outer space.',
      'lottie': 'https://assets9.lottiefiles.com/packages/lf20_lxvza1jw.json',
    },
    {
      'id': 'fairy',
      'title': 'Fairy Tale',
      'emoji': '🧚',
      'color': Colors.pink,
      'prompt':
          'Tell a short magical fairy tale for children with a happy ending.',
      'lottie': 'https://assets1.lottiefiles.com/packages/lf20_aen8fLnM.json',
    },
    {
      'id': 'dino',
      'title': 'Dinosaur World',
      'emoji': '🦕',
      'color': Colors.green,
      'prompt': 'Tell a short fun story for children about friendly dinosaurs.',
      'lottie': 'https://assets5.lottiefiles.com/packages/lf20_ymbmfxzt.json',
    },
    {
      'id': 'ocean',
      'title': 'Under the Sea',
      'emoji': '🐠',
      'color': Colors.cyan,
      'prompt':
          'Tell a short story for children about an underwater adventure with sea creatures.',
      'lottie': 'https://assets9.lottiefiles.com/packages/lf20_w1yrmz5j.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _readingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _rewardsService.initialize();
    await _chatService.initialize();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _readingController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _generateStory(Map<String, dynamic> theme) async {
    setState(() {
      _isGenerating = true;
      _selectedTheme = theme['id'];
      _currentStory = '';
    });

    try {
      final buffer = StringBuffer();
      await for (final chunk in _chatService.sendMessage(theme['prompt'])) {
        buffer.write(chunk);
        if (mounted) {
          setState(() {
            _currentStory = buffer.toString();
          });
        }
      }

      setState(() {
        _isGenerating = false;
      });

      // Auto-read the story
      _readStory();
    } catch (e) {
      setState(() {
        _currentStory = _getFallbackStory(theme['id']);
        _isGenerating = false;
      });
      _readStory();
    }
  }

  String _getFallbackStory(String themeId) {
    final fallbackStories = {
      'adventure':
          '''Once upon a time, in a magical forest, there lived a curious little rabbit named Remy. 
      
One sunny day, Remy found a glowing map under an old oak tree! The map showed the way to a hidden treasure.

With a hop and a skip, Remy followed the path through the forest. Along the way, Remy helped a lost butterfly find its way home.

At the end of the path, Remy found the treasure - a box full of golden acorns! But the real treasure was the new butterfly friend.

Remy shared the acorns with all the forest friends, and everyone had a wonderful feast!

The End! 🌟''',

      'animals':
          '''In a cozy corner of the jungle, there lived a shy little elephant named Ellie.

Ellie wanted friends but was too shy to say hello. One day, she heard a tiny voice - it was a little mouse named Max!

"Would you like to be friends?" asked Max. Ellie nodded happily.

Together, they played hide and seek, splashed in puddles, and shared yummy fruits.

Soon, other animals joined too - a giraffe, a monkey, and a parrot! Ellie wasn't shy anymore.

Ellie learned that making friends just takes a simple hello!

The End! 🐘''',

      'space':
          '''Young astronaut Astrid zoomed through space in her sparkly rocket ship!

She flew past the smiling Moon, who waved hello. She flew past the striped planet Jupiter, who played peek-a-boo behind its rings.

Then Astrid met a friendly alien named Zip! Zip had green skin and three eyes, and loved to giggle.

"Want to see something amazing?" asked Zip. They flew to a planet made entirely of candy!

They shared lollipop trees and chocolate mountains, then Astrid headed home with her new friend.

The End! 🚀''',

      'fairy': '''In a tiny mushroom house lived a kind fairy named Flora.

Flora had sparkly wings and a magical wand that could make flowers bloom!

One day, a sad little caterpillar came to her door. "I want to be beautiful," it said.

Flora sprinkled magic dust and said kind words. "You are already beautiful inside!"

Days later, the caterpillar became a gorgeous butterfly with rainbow wings!

"Your kindness made me beautiful!" said the butterfly, as they danced in the sunshine together.

The End! 🦋''',

      'dino':
          '''In a land long, long ago, there lived a baby dinosaur named Dippy.

Dippy was a Diplodocus with a super long neck! But Dippy couldn't reach the yummy leaves at the top of the trees.

One day, Dippy met a friendly Pterodactyl named Perry. "I'll fly up and shake the leaves down for you!" said Perry.

Leaves rained down like confetti, and Dippy had the best feast ever!

In return, Dippy let Perry slide down his long neck like a slide. Wheee!

They became the best of friends forever.

The End! 🦕''',

      'ocean':
          '''Deep under the sparkling blue sea lived a little fish named Finn.

Finn had bright orange scales and loved to explore! One day, Finn found a mysterious cave.

Inside, a grumpy octopus named Ollie was stuck in a net! "Help me please!" said Ollie.

Finn quickly nibbled through the net with his tiny teeth. Ollie was free!

"Thank you, little fish!" said Ollie. To thank Finn, Ollie showed a secret treasure - a cave full of glowing pearls!

Now Finn and Ollie explore the ocean together, the best of friends!

The End! 🌊''',
    };

    return fallbackStories[themeId] ?? fallbackStories['adventure']!;
  }

  Future<void> _readStory() async {
    if (_currentStory.isEmpty) return;

    setState(() => _isReading = true);

    await _speechService.speak(_currentStory);

    if (mounted) {
      setState(() {
        _isReading = false;
        _storiesRead++;
      });
      await _rewardsService.addStars(3, category: 'story');

      _showCompletionDialog();
    }
  }

  void _stopReading() {
    _speechService.stop();
    setState(() => _isReading = false);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Lottie.network(
                'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                repeat: false,
              ),
            ),
            const Text(
              '📚 Story Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You earned 3 stars! ⭐⭐⭐',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStory = '';
                _selectedTheme = '';
              });
            },
            child: const Text('More Stories'),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade300,
              Colors.deepPurple.shade400,
              Colors.indigo.shade500,
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
                      onPressed: () {
                        _stopReading();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        '📖 Story Time',
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
                          const Text('📚', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            '$_storiesRead',
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

              Expanded(
                child: _currentStory.isEmpty
                    ? _buildThemeSelector()
                    : _buildStoryView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a story theme:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: storyThemes.length,
              itemBuilder: (context, index) {
                final theme = storyThemes[index];
                return _buildThemeCard(theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme) {
    final isGenerating = _isGenerating && _selectedTheme == theme['id'];

    return GestureDetector(
      onTap: isGenerating ? null : () => _generateStory(theme),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (theme['color'] as Color).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGenerating)
              const CircularProgressIndicator()
            else
              Text(theme['emoji'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              theme['title'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme['color'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryView() {
    final theme = storyThemes.firstWhere(
      (t) => t['id'] == _selectedTheme,
      orElse: () => storyThemes[0],
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Theme header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (theme['color'] as Color).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(theme['emoji'], style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 8),
                Text(
                  theme['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reading animation
          if (_isReading)
            SizedBox(
              height: 80,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_tszzqucv.json',
                controller: _readingController,
              ),
            ),

          // Story content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _currentStory,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isReading ? _stopReading : _readStory,
                icon: Icon(_isReading ? Icons.stop : Icons.play_arrow),
                label: Text(_isReading ? 'Stop' : 'Read Aloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReading ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _stopReading();
                  setState(() {
                    _currentStory = '';
                    _selectedTheme = '';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('New Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
