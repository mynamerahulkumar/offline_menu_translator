import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model_response.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language mode for chat
enum ChatLanguage { english, hinglish }

/// Chat message model for the kid-friendly chatbot
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Content filter result
enum ContentFilterResult { safe, blocked }

/// A service that handles chat interactions with Gemma AI,
/// with kid-safe system prompts and content filtering.
class ChatService {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  bool _isInitialized = false;
  ChatLanguage _language = ChatLanguage.english;

  final List<ChatMessage> _chatHistory = [];

  bool get isInitialized => _isInitialized;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  ChatLanguage get currentLanguage => _language;

  /// Simple instruction prefix - less is more for on-device models
  String get _instructionPrefix {
    if (_language == ChatLanguage.hinglish) {
      return 'Tum Sparky ho, bacchon ka teacher robot. Hinglish mein jawab do (Hindi+English Roman script). Question: ';
    }
    return 'You are Sparky, a friendly teacher robot for kids. Answer in simple English. Question: ';
  }

  /// Clean up response - remove repeated sentences and limit to 10
  String _cleanupResponse(String response) {
    final sentences = response.split(RegExp(r'[.!?]+'));
    final seen = <String>{};
    final unique = <String>[];

    for (var sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isNotEmpty && !seen.contains(trimmed.toLowerCase())) {
        seen.add(trimmed.toLowerCase());
        unique.add(trimmed);
        if (unique.length >= 10) break; // Max 10 sentences for kids
      }
    }

    return unique.join('. ').trim() + (unique.isNotEmpty ? '.' : '');
  }

  /// Blocked words and phrases for content filtering
  static final List<String> _blockedPatterns = [
    // Violence
    r'\b(kill|murder|death|die|blood|gore|weapon|gun|knife|bomb|explode)\b',
    // Inappropriate content
    r'\b(sex|nude|naked|porn|xxx|adult|drugs|alcohol|cigarette|vape)\b',
    // Hate speech
    r'\b(racist|racism|hate|stupid|idiot|dumb|ugly|fat|loser)\b',
    // Personal info requests
    r'\b(address|phone number|social security|credit card|password)\b',
    // Self-harm
    r'\b(suicide|self.?harm|cutting|hurt yourself)\b',
  ];

  /// Load saved language preference
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langValue = prefs.getString('chat_language');
      _language = langValue == 'hinglish'
          ? ChatLanguage.hinglish
          : ChatLanguage.english;
    } catch (e) {
      debugPrint('Error loading language preference: $e');
    }
  }

  /// Set language and reinitialize chat
  Future<void> setLanguage(ChatLanguage language) async {
    if (_language == language) return;

    _language = language;

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'chat_language',
        language == ChatLanguage.hinglish ? 'hinglish' : 'english',
      );
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }

    // Reinitialize chat with new system prompt
    if (_isInitialized) {
      await _reinitializeChat();
    }
  }

  /// Reinitialize chat with current language
  Future<void> _reinitializeChat() async {
    try {
      _chat = await _inferenceModel!.createChat(supportImage: false);
      _chatHistory.clear();
      debugPrint('Chat reinitialized for ${_language.name} mode');
    } catch (e) {
      debugPrint('Error reinitializing chat: $e');
    }
  }

  /// Initialize the chat service with Gemma model
  Future<void> initialize() async {
    try {
      // Load saved language preference first
      await _loadLanguagePreference();

      _inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: 2048, // Increased for better responses
      );

      _chat = await _inferenceModel!.createChat(supportImage: false);

      _isInitialized = true;
      debugPrint('ChatService initialized with kid-safe system prompt');
    } catch (e) {
      debugPrint('Failed to initialize ChatService: $e');
      rethrow;
    }
  }

  /// Filter input for inappropriate content
  ContentFilterResult filterInput(String input) {
    final lowerInput = input.toLowerCase();

    for (final pattern in _blockedPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerInput)) {
        return ContentFilterResult.blocked;
      }
    }

    return ContentFilterResult.safe;
  }

  /// Filter AI response for any inappropriate content that slipped through
  String filterResponse(String response) {
    String filtered = response;

    // Check for blocked patterns in response
    for (final pattern in _blockedPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(filtered)) {
        return "Hmm, let me think of something else! How about we talk about your favorite animal or a fun game? 🌟";
      }
    }

    return filtered;
  }

  /// Send a message and get a streaming response
  Stream<String> sendMessage(String userMessage) async* {
    if (!_isInitialized || _chat == null) {
      yield "Oops! I'm still waking up. Give me a moment! 🤖💤";
      return;
    }

    // Check input for inappropriate content
    final filterResult = filterInput(userMessage);
    if (filterResult == ContentFilterResult.blocked) {
      final response =
          "That's not something I can help with! Let's talk about something more fun instead. What's your favorite color? 🌈";
      _chatHistory.add(ChatMessage(text: userMessage, isUser: true));
      _chatHistory.add(ChatMessage(text: response, isUser: false));
      yield response;
      return;
    }

    // Add to history
    _chatHistory.add(ChatMessage(text: userMessage, isUser: true));

    try {
      // Create message with instruction prefix for proper language and style
      final message = Message(
        text: '$_instructionPrefix$userMessage',
        isUser: true,
      );
      await _chat!.addQueryChunk(message);

      // Stream the response with repetition detection
      final responseStream = _chat!.generateChatResponseAsync();
      final responseBuffer = StringBuffer();
      String lastChunk = '';
      int repeatCount = 0;
      const maxRepeats = 2;

      await for (final response in responseStream) {
        if (response is TextResponse) {
          final token = response.token;

          // Detect repetition - stop if same chunk repeats
          if (token == lastChunk && token.length > 5) {
            repeatCount++;
            if (repeatCount >= maxRepeats) {
              debugPrint('Detected repetition, stopping generation');
              break;
            }
          } else {
            repeatCount = 0;
          }
          lastChunk = token;

          // Check for end markers
          if (token.contains('<end>') ||
              token.contains('<eos>') ||
              token.contains('</s>')) {
            break;
          }

          responseBuffer.write(token);
          yield token;
        } else if (response is ThinkingResponse) {
          debugPrint('Thinking: ${response.content}');
        } else if (response is FunctionCallResponse) {
          debugPrint('Function call: ${response.name}(${response.args})');
        }
      }

      // Handle empty response
      if (responseBuffer.isEmpty) {
        debugPrint('Warning: Empty response from Gemma model');
        final fallback = _language == ChatLanguage.hinglish
            ? "Oops! Mujhe samajh nahi aaya. Kya tum dobara puch sakte ho? 🤔"
            : "Oops! I didn't understand that. Can you ask again? 🤔";
        _chatHistory.add(ChatMessage(text: fallback, isUser: false));
        yield fallback;
        return;
      }

      // Clean up and filter response
      String cleanedResponse = _cleanupResponse(responseBuffer.toString());
      final finalResponse = filterResponse(cleanedResponse);

      // Save to history
      _chatHistory.add(ChatMessage(text: finalResponse, isUser: false));
    } catch (e) {
      debugPrint('Error generating response: $e');
      final errorResponse =
          "Oops! My circuits got a bit confused. Can you try asking again? 🔧";
      _chatHistory.add(ChatMessage(text: errorResponse, isUser: false));
      yield errorResponse;
    }
  }

  /// Get a quick greeting for new chat
  String getGreeting() {
    if (_language == ChatLanguage.hinglish) {
      final greetings = [
        "Namaste dost! Main Sparky hoon, tumhara robot buddy! 🤖 Aaj kya baat karein?",
        "Hello friend! Main Sparky! Tumse milke bahut khushi hui! 🌟 Kya interesting baatein karein?",
        "Arre! Sparky here, adventure ke liye ready! 🚀 Kya chal raha hai?",
        "Beep boop! Hi dost! Main Sparky hoon aur tumse chat karne ke liye excited hoon! 🎉 Kya explore karein?",
      ];
      return greetings[DateTime.now().millisecond % greetings.length];
    }
    final greetings = [
      "Hi there, friend! I'm Sparky, your robot buddy! 🤖 What would you like to talk about today?",
      "Hello! I'm Sparky! I'm so happy to see you! 🌟 What fun things should we chat about?",
      "Hey there! Sparky here, ready for an adventure! 🚀 What's on your mind?",
      "Beep boop! Hi friend! I'm Sparky and I can't wait to chat with you! 🎉 What should we explore together?",
    ];
    return greetings[DateTime.now().millisecond % greetings.length];
  }

  /// Clear chat history (for new conversation)
  void clearHistory() {
    _chatHistory.clear();
  }

  /// Dispose resources
  void dispose() {
    _chat = null;
    _inferenceModel = null;
    _isInitialized = false;
  }
}
