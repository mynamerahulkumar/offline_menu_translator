import 'package:flutter/material.dart';
import 'package:srp_ai_app/data/downloader_datasource.dart';
import 'package:srp_ai_app/data/content_service.dart';
import 'package:srp_ai_app/domain/download_model.dart';
import 'package:srp_ai_app/ui/screens/home_screen.dart';
import 'package:srp_ai_app/ui/screens/age_selection_screen.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusMessage = 'Checking for AI model...';
  bool _isDownloading = false;
  bool _isError = false;
  String? _errorMessage;

  late final GemmaDownloaderDataSource _downloaderDataSource;
  late AnimationController _pulseController;

  // Fun messages to show during download
  final List<String> _funMessages = [
    '🤖 Teaching robot how to be friendly...',
    '🧠 Loading brain cells...',
    '✨ Sprinkling some magic...',
    '🎨 Painting colorful thoughts...',
    '🚀 Preparing for adventure...',
    '🌈 Gathering rainbow power...',
    '🎪 Setting up the fun tent...',
    '🎵 Tuning up the voice box...',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use Gemma 3 1B model in .task format (compatible with flutter_gemma 0.12.2)
    // This model is ~500MB and works well on budget phones
    _downloaderDataSource = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl:
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
        modelFilename: 'gemma3-1b-it-int4.task',
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _checkAndDownloadModel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAndDownloadModel() async {
    try {
      setState(() {
        _statusMessage = 'Checking for AI model...';
        _isError = false;
      });

      final isModelInstalled = await _downloaderDataSource
          .checkModelExistence();

      if (isModelInstalled) {
        setState(() {
          _statusMessage = 'Model found! Setting up...';
        });
        await _initializeModel();
      } else {
        await _downloadModel();
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _statusMessage = 'Oops! Something went wrong 😢';
      });
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = _funMessages[0];
    });

    // Rotate fun messages during download
    _startMessageRotation();

    try {
      await _downloaderDataSource.downloadModel(
        token: accessToken,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _statusMessage = '✅ Download complete! Installing...';
        _isDownloading = false;
      });

      await _initializeModel();
    } catch (e) {
      setState(() {
        _isError = true;
        _isDownloading = false;
        _errorMessage = e.toString();
        _statusMessage = 'Download failed 😢';
      });
    }
  }

  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!_isDownloading || !mounted) return false;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _funMessages.length;
        _statusMessage = _funMessages[_currentMessageIndex];
      });
      return true;
    });
  }

  Future<void> _initializeModel() async {
    try {
      setState(() {
        _statusMessage = '🔧 Installing AI brain...';
      });

      final modelPath = await _downloaderDataSource.getFilePath();

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(modelPath).install();

      setState(() {
        _statusMessage = '🎉 All ready! Let\'s have fun!';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Check if age group is already selected
        final contentService = ContentService();
        await contentService.initialize();

        final Widget targetScreen;
        if (contentService.ageGroup == AgeGroup.toddler &&
            contentService.activityTimes.isEmpty) {
          // First time user - go to age selection
          targetScreen = const AgeSelectionScreen();
        } else {
          // Returning user - go to home
          targetScreen = const HomeScreen();
        }

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => targetScreen));
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _statusMessage = 'Failed to setup AI 😢';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade400,
              Colors.purple.shade500,
              Colors.pink.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Robot Character
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isError
                            ? const Text('😢', style: TextStyle(fontSize: 80))
                            : const Text('🤖', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Status Message
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress Bar
                  if (_isDownloading || _progress > 0 && _progress < 1.0)
                    Column(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.greenAccent.shade400,
                                  ),
                                  minHeight: 20,
                                ),
                                Center(
                                  child: Text(
                                    '${(_progress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Downloading AI model... This might take a while!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                  // Error State
                  if (_isError) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _checkAndDownloadModel,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],

                  // Loading Indicator (when not downloading but processing)
                  if (!_isDownloading && !_isError && _progress == 0)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
