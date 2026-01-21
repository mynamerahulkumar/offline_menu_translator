import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:srp_ai_app/data/chat_service.dart';
import 'package:srp_ai_app/data/speech_service.dart';
import 'package:srp_ai_app/ui/widgets/robot_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatBubble> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _autoReadEnabled = true;
  ChatLanguage _currentLanguage = ChatLanguage.english;

  late AnimationController _listeningAnimController;

  @override
  void initState() {
    super.initState();

    _listeningAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize speech service
      await _speechService.initialize();

      // Set up speech callbacks
      _speechService.onSpeechResult = (result) {
        if (result.isNotEmpty) {
          _textController.text = result;
          _sendMessage();
        }
      };

      _speechService.onSpeechStart = () {
        setState(() => _isListening = true);
        _listeningAnimController.repeat();
      };

      _speechService.onSpeechEnd = () {
        setState(() => _isListening = false);
        _listeningAnimController.stop();
        _listeningAnimController.reset();
      };

      _speechService.onError = (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };

      // Initialize chat service
      await _chatService.initialize();

      // Get current language preference
      setState(() {
        _currentLanguage = _chatService.currentLanguage;
      });

      // Set TTS voice based on language
      await _speechService.setLanguageMode(
        _currentLanguage == ChatLanguage.hinglish,
      );

      // Add greeting message
      final greeting = _chatService.getGreeting();
      setState(() {
        _messages.add(_ChatBubble(text: greeting, isUser: false));
        _isLoading = false;
      });

      // Auto-read greeting
      if (_autoReadEnabled) {
        await _speechService.speak(greeting);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLanguage() async {
    final newLanguage = _currentLanguage == ChatLanguage.english
        ? ChatLanguage.hinglish
        : ChatLanguage.english;

    setState(() {
      _currentLanguage = newLanguage;
      _isTyping = true;
    });

    // Update chat service with new language
    await _chatService.setLanguage(newLanguage);

    // Switch TTS voice to Hindi/English
    await _speechService.setLanguageMode(newLanguage == ChatLanguage.hinglish);

    // Clear messages and show new greeting
    final greeting = _chatService.getGreeting();
    setState(() {
      _messages.clear();
      _messages.add(_ChatBubble(text: greeting, isUser: false));
      _isTyping = false;
    });

    // Show confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLanguage == ChatLanguage.hinglish
                ? '🇮🇳 Hinglish mode ON - Ab main Hinglish mein baat karunga!'
                : '🇬🇧 English mode ON - I will now respond in English!',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newLanguage == ChatLanguage.hinglish
              ? Colors.orange
              : Colors.blue,
        ),
      );
    }

    // Auto-read new greeting
    if (_autoReadEnabled) {
      await _speechService.speak(greeting);
    }
  }

  @override
  void dispose() {
    _listeningAnimController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _speechService.dispose();
    _chatService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Stop speaking if currently speaking
    await _speechService.stop();

    setState(() {
      _messages.add(_ChatBubble(text: text, isUser: true));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Add placeholder for AI response
    setState(() {
      _messages.add(_ChatBubble(text: '', isUser: false, isTyping: true));
    });
    _scrollToBottom();

    // Stream the response
    final responseBuffer = StringBuffer();
    await for (final token in _chatService.sendMessage(text)) {
      responseBuffer.write(token);
      setState(() {
        _messages.last = _ChatBubble(
          text: responseBuffer.toString(),
          isUser: false,
        );
      });
      _scrollToBottom();
    }

    setState(() => _isTyping = false);

    // Auto-read the response
    if (_autoReadEnabled && responseBuffer.isNotEmpty) {
      setState(() => _isSpeaking = true);
      await _speechService.speak(responseBuffer.toString());
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
    } else {
      await _speechService.startListening();
    }
  }

  Future<void> _stopSpeaking() async {
    await _speechService.stop();
    setState(() => _isSpeaking = false);
  }

  /// Get topic-based emoji for animation based on message content
  String _getTopicEmoji(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('dinosaur') || lower.contains('dino')) return '🦕';
    if (lower.contains('animal') ||
        lower.contains('dog') ||
        lower.contains('cat') ||
        lower.contains('pet'))
      return '🐾';
    if (lower.contains('space') ||
        lower.contains('star') ||
        lower.contains('moon') ||
        lower.contains('planet'))
      return '🚀';
    if (lower.contains('math') ||
        lower.contains('number') ||
        lower.contains('count') ||
        lower.contains('add'))
      return '🔢';
    if (lower.contains('color') ||
        lower.contains('rainbow') ||
        lower.contains('paint'))
      return '🌈';
    if (lower.contains('music') ||
        lower.contains('song') ||
        lower.contains('sing'))
      return '🎵';
    if (lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('fruit'))
      return '🍕';
    if (lower.contains('game') ||
        lower.contains('play') ||
        lower.contains('fun'))
      return '🎮';
    if (lower.contains('book') ||
        lower.contains('read') ||
        lower.contains('story'))
      return '📚';
    if (lower.contains('school') ||
        lower.contains('learn') ||
        lower.contains('study'))
      return '🎒';
    if (lower.contains('weather') ||
        lower.contains('rain') ||
        lower.contains('sun'))
      return '☀️';
    if (lower.contains('ocean') ||
        lower.contains('sea') ||
        lower.contains('fish'))
      return '🐠';
    if (lower.contains('bird') || lower.contains('fly')) return '🦜';
    if (lower.contains('tree') ||
        lower.contains('plant') ||
        lower.contains('flower'))
      return '🌻';
    if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey'))
      return '👋';
    return '✨';
  }

  /// Get Lottie animation URL based on message topic
  String? _getTopicLottieUrl(String message) {
    final lower = message.toLowerCase();
    // Free Lottie animations from lottiefiles.com (public CDN)
    if (lower.contains('dinosaur') || lower.contains('dino')) {
      return 'https://assets3.lottiefiles.com/packages/lf20_xlmz9xwm.json'; // Dinosaur
    }
    if (lower.contains('animal') ||
        lower.contains('dog') ||
        lower.contains('cat') ||
        lower.contains('pet')) {
      return 'https://assets9.lottiefiles.com/packages/lf20_syqnfe7c.json'; // Cute animals
    }
    if (lower.contains('space') ||
        lower.contains('star') ||
        lower.contains('moon') ||
        lower.contains('planet')) {
      return 'https://assets2.lottiefiles.com/packages/lf20_xvrofzfk.json'; // Rocket
    }
    if (lower.contains('math') ||
        lower.contains('number') ||
        lower.contains('count') ||
        lower.contains('add')) {
      return 'https://assets1.lottiefiles.com/packages/lf20_fcfjwiyb.json'; // Numbers
    }
    if (lower.contains('music') ||
        lower.contains('song') ||
        lower.contains('sing')) {
      return 'https://assets8.lottiefiles.com/packages/lf20_ikk4jhps.json'; // Music notes
    }
    if (lower.contains('book') ||
        lower.contains('read') ||
        lower.contains('story')) {
      return 'https://assets3.lottiefiles.com/packages/lf20_4XmSkB.json'; // Book
    }
    if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey')) {
      return 'https://assets9.lottiefiles.com/packages/lf20_puciaact.json'; // Waving hand
    }
    return null; // No animation for other topics (use emoji fallback)
  }

  /// Build Lottie animation widget with fallback to emoji
  Widget _buildTopicAnimation(String message, String emoji) {
    final lottieUrl = _getTopicLottieUrl(message);

    if (lottieUrl != null) {
      return SizedBox(
        width: 60,
        height: 60,
        child: Lottie.network(
          lottieUrl,
          repeat: true,
          animate: true,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji if Lottie fails
            return Text(emoji, style: const TextStyle(fontSize: 28));
          },
        ),
      );
    }

    // Fallback to animated emoji
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade200,
              Colors.purple.shade200,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Chat Messages
              Expanded(
                child: _isLoading ? _buildLoadingState() : _buildChatList(),
              ),

              // Input Area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini Robot Avatar
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),

          // Title and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sparky',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  _isTyping
                      ? 'Thinking...'
                      : _isSpeaking
                      ? 'Speaking...'
                      : 'Online',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Language toggle button
          IconButton(
            onPressed: _toggleLanguage,
            tooltip: _currentLanguage == ChatLanguage.english
                ? 'Switch to Hinglish'
                : 'Switch to English',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _currentLanguage == ChatLanguage.hinglish
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentLanguage == ChatLanguage.hinglish
                      ? Colors.orange
                      : Colors.blue,
                ),
              ),
              child: Text(
                _currentLanguage == ChatLanguage.english ? 'EN' : 'HI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _currentLanguage == ChatLanguage.hinglish
                      ? Colors.orange.shade800
                      : Colors.blue.shade800,
                ),
              ),
            ),
          ),

          // Auto-read toggle
          IconButton(
            onPressed: () {
              setState(() => _autoReadEnabled = !_autoReadEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _autoReadEnabled ? '🔊 Auto-read ON' : '🔇 Auto-read OFF',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              _autoReadEnabled ? Icons.volume_up : Icons.volume_off,
              color: _autoReadEnabled ? Colors.purple : Colors.grey,
            ),
          ),

          // Stop speaking button (when speaking)
          if (_isSpeaking)
            IconButton(
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop_circle, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RobotAvatar(size: 150, isAnimating: true),
          const SizedBox(height: 24),
          Text(
            'Sparky is waking up...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(_ChatBubble message) {
    final isUser = message.isUser;
    final topicEmoji = !isUser && message.text.isNotEmpty
        ? _getTopicEmoji(message.text)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Robot avatar for AI messages
          if (!isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble with topic emoji
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Animated Lottie/emoji for AI responses based on topic
                if (topicEmoji != null && !message.isTyping)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildTopicAnimation(message.text, topicEmoji),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.purple.shade500 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.isTyping && message.text.isEmpty
                      ? _buildTypingIndicator()
                      : isUser
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                        ),
                ),
              ],
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('😊', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 150)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Listening indicator with robot avatar
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _listeningAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_listeningAnimController.value * 0.2),
                        child: child,
                      );
                    },
                    child: const RobotAvatar(size: 80, isListening: true),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "I'm listening... 👂",
                    style: TextStyle(
                      color: Colors.purple.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Voice input button
              GestureDetector(
                onTap: _isTyping ? null : _toggleListening,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.red.shade400, Colors.orange.shade400]
                          : [Colors.purple.shade400, Colors.blue.shade400],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text input (keyboard fallback)
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !_isTyping && !_isListening,
                  decoration: InputDecoration(
                    hintText: 'Type or tap the mic to talk...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: _isTyping || _isListening ? null : _sendMessage,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade400],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
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

/// Simple chat bubble data class
class _ChatBubble {
  final String text;
  final bool isUser;
  final bool isTyping;

  _ChatBubble({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}
