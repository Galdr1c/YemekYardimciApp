import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service for voice search with Turkish language support
class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastResult = '';

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastResult => _lastResult;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize(
        onError: (error) {
          print('[VoiceSearchService] Error: $error');
        },
        onStatus: (status) {
          print('[VoiceSearchService] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      _isInitialized = available;
      return available;
    } catch (e) {
      print('[VoiceSearchService] Initialization error: $e');
      return false;
    }
  }

  /// Check and request microphone permission
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // User has permanently denied permission
      return false;
    }

    return false;
  }

  /// Start listening for speech (Turkish)
  Future<void> startListening({
    required Function(String result) onResult,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Ses tanıma başlatılamadı');
        return;
      }
    }

    // Check microphone permission
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      onError?.call('Mikrofon izni gerekli');
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      _lastResult = '';

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastResult = result.recognizedWords;
            _isListening = false;
            onResult(result.recognizedWords);
          }
        },
        localeId: 'tr_TR', // Turkish locale
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
      );
    } catch (e) {
      _isListening = false;
      onError?.call('Dinleme hatası: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// Process voice command and return action type
  VoiceCommand? processCommand(String recognizedText) {
    final text = recognizedText.toLowerCase().trim();

    // Check for commands
    if (text.contains('kalori hesapla') || 
        text.contains('kalori hesaplama') ||
        text.contains('fotoğraf çek') ||
        text.contains('kamera aç')) {
      return VoiceCommand.calculateCalories;
    }

    // Default: treat as search query
    return VoiceCommand.search;
  }

  /// Cleanup resources
  void dispose() {
    stopListening();
    _speech.cancel();
  }
}

/// Voice command types
enum VoiceCommand {
  search,
  calculateCalories,
}

