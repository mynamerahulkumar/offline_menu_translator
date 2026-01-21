import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A service that handles Text-to-Speech (TTS) and Speech-to-Text (STT)
/// with offline-friendly fallbacks for a kid-friendly chatbot.
class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isHinglishMode = false; // Track current language mode

  // Singleton instance
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // Callbacks
  Function(String)? onSpeechResult;
  Function()? onSpeechStart;
  Function()? onSpeechEnd;
  Function(String)? onError;

  // TTS Settings for kid-friendly voice
  double _speechRate = 0.48; // Slightly slower for clarity
  double _pitch = 1.15; // Natural higher pitch for kids
  double _volume = 1.0;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get isSttAvailable => _isSttInitialized;
  bool get isHinglishMode => _isHinglishMode;

  /// Initialize both TTS and STT services
  Future<void> initialize() async {
    await _initializeTts();
    await _initializeStt();
  }

  /// Initialize Text-to-Speech with kid-friendly settings
  Future<void> _initializeTts() async {
    try {
      // Set up TTS engine
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // Try to find a child-friendly voice
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        // Look for a female or higher-pitched voice
        for (var voice in voices) {
          if (voice is Map) {
            final name = voice['name']?.toString().toLowerCase() ?? '';
            if (name.contains('samantha') ||
                name.contains('karen') ||
                name.contains('female')) {
              await _flutterTts.setVoice({
                'name': voice['name'],
                'locale': voice['locale'],
              });
              break;
            }
          }
        }
      }

      // Set up completion handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((error) {
        _isSpeaking = false;
        onError?.call('TTS Error: $error');
      });

      _isTtsInitialized = true;
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
      onError?.call('Failed to initialize voice: $e');
    }
  }

  /// Switch TTS language for Hinglish/English mode with Indian voice
  Future<void> setLanguageMode(bool isHinglish) async {
    _isHinglishMode = isHinglish;
    try {
      if (isHinglish) {
        // Try to set Hindi language for Hinglish mode
        final languages = await _flutterTts.getLanguages;
        bool hindiAvailable = false;

        for (var lang in languages ?? []) {
          if (lang.toString().toLowerCase().contains('hi')) {
            hindiAvailable = true;
            break;
          }
        }

        if (hindiAvailable) {
          await _flutterTts.setLanguage('hi-IN');

          // Try to find Indian female voice
          final voices = await _flutterTts.getVoices;
          bool foundIndianVoice = false;
          for (var voice in voices ?? []) {
            if (voice is Map) {
              final name = voice['name']?.toString().toLowerCase() ?? '';
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              // Look for Hindi female voices
              if (locale.contains('hi') &&
                  (name.contains('female') ||
                      name.contains('lekha') ||
                      name.contains('aditi'))) {
                await _flutterTts.setVoice({
                  'name': voice['name'],
                  'locale': voice['locale'],
                });
                foundIndianVoice = true;
                debugPrint('Using Indian voice: ${voice['name']}');
                break;
              }
            }
          }
          if (!foundIndianVoice) {
            debugPrint(
              'No Indian female voice found, using default Hindi voice',
            );
          }
          await _flutterTts.setSpeechRate(_speechRate);
        } else {
          // Fallback: Hindi not available, use slower English
          debugPrint(
            'Hindi voice not available, falling back to slower English',
          );
          await _flutterTts.setLanguage('en-US');
          await _flutterTts.setSpeechRate(
            0.40,
          ); // Slower for Hinglish text in English voice
        }
      } else {
        // Set English for English mode
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(_speechRate);
      }
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      debugPrint('Error switching language mode: $e');
      // Fallback to English with slower speed
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.40);
    }
  }

  /// Initialize Speech-to-Text
  Future<void> _initializeStt() async {
    try {
      _isSttInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
          onSpeechEnd?.call();
          // Don't show error for common issues like "no speech detected"
          if (!error.errorMsg.contains('no speech')) {
            onError?.call('Speech recognition error: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onSpeechEnd?.call();
          }
        },
      );

      if (_isSttInitialized) {
        debugPrint('STT initialized successfully');
      } else {
        debugPrint('STT not available on this device');
      }
    } catch (e) {
      debugPrint('Failed to initialize STT: $e');
      _isSttInitialized = false;
    }
  }

  /// Speak the given text (auto-read feature)
  /// Returns a future that completes when speaking is done
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      debugPrint('TTS not initialized');
      return;
    }

    // Stop any ongoing speech first
    await stop();

    try {
      // Clean up text for better speech (remove markdown, emojis, etc.)
      final cleanText = _cleanTextForSpeech(text);

      if (cleanText.isEmpty) return;

      _isSpeaking = true;
      await _flutterTts.speak(cleanText);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('Error speaking: $e');
      onError?.call('Failed to speak: $e');
    }
  }

  /// Stop speaking immediately
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Start listening for speech input
  Future<void> startListening() async {
    if (!_isSttInitialized) {
      onError?.call('Speech recognition not available. Please type instead!');
      return;
    }

    if (_isListening) return;

    // Stop TTS if speaking
    await stop();

    try {
      _isListening = true;
      onSpeechStart?.call();

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onSpeechResult?.call(result.recognizedWords);
            _isListening = false;
            onSpeechEnd?.call();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _isListening = false;
      onSpeechEnd?.call();
      debugPrint('Error starting speech recognition: $e');
      onError?.call('Could not start listening: $e');
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onSpeechEnd?.call();
    }
  }

  /// Clean text for better TTS output
  String _cleanTextForSpeech(String text) {
    String cleaned = text;

    // Convert math symbols to spoken words FIRST
    cleaned = _convertMathToSpeech(cleaned);

    // Remove markdown formatting
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1'); // Bold
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'$1'); // Italic
    cleaned = cleaned.replaceAll(RegExp(r'`(.+?)`'), r'$1'); // Code
    cleaned = cleaned.replaceAll(RegExp(r'#{1,6}\s*'), ''); // Headers
    cleaned = cleaned.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1'); // Links
    cleaned = cleaned.replaceAll(RegExp(r'!\[.*?\]\(.+?\)'), ''); // Images
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), ''); // Code blocks
    cleaned = cleaned.replaceAll(RegExp(r'[-*]\s'), ''); // List bullets

    // Remove common emojis (they don't speak well)
    cleaned = cleaned.replaceAll(
      RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true),
      '',
    );

    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Convert math symbols and expressions to spoken words
  String _convertMathToSpeech(String text) {
    String result = text;

    // Handle fractions first (e.g., 1/2 -> one half)
    result = result.replaceAllMapped(
      RegExp(r'(\d+)\s*/\s*(\d+)'),
      (m) => '${m[1]} divided by ${m[2]}',
    );

    // Handle multiplication with x (e.g., 3x4 or 3 x 4)
    result = result.replaceAllMapped(
      RegExp(r'(\d+)\s*[xX×]\s*(\d+)'),
      (m) => '${m[1]} times ${m[2]}',
    );

    // Handle powers (e.g., 2^3 -> 2 to the power of 3)
    result = result.replaceAllMapped(
      RegExp(r'(\d+)\s*\^\s*(\d+)'),
      (m) => '${m[1]} to the power of ${m[2]}',
    );

    // Basic math symbols
    result = result.replaceAll('+', ' plus ');
    result = result.replaceAll('-', ' minus ');
    result = result.replaceAll('×', ' times ');
    result = result.replaceAll('*', ' times ');
    result = result.replaceAll('÷', ' divided by ');
    result = result.replaceAll('=', ' equals ');
    result = result.replaceAll('%', ' percent ');
    result = result.replaceAll('>', ' is greater than ');
    result = result.replaceAll('<', ' is less than ');
    result = result.replaceAll('≥', ' is greater than or equal to ');
    result = result.replaceAll('≤', ' is less than or equal to ');
    result = result.replaceAll('√', ' square root of ');
    result = result.replaceAll('π', ' pi ');

    // Clean up multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result;
  }

  /// Update speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  /// Update pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await stopListening();
  }
}
