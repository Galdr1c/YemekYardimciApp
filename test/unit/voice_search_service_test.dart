import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/voice_search_service.dart';

void main() {
  group('VoiceSearchService Tests', () {
    late VoiceSearchService service;

    setUp(() {
      service = VoiceSearchService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not initialized', () {
      expect(service.isInitialized, false);
      expect(service.isListening, false);
      expect(service.lastResult, '');
    });

    test('processCommand recognizes calculateCalories command', () {
      final command1 = service.processCommand('kalori hesapla');
      expect(command1, VoiceCommand.calculateCalories);

      final command2 = service.processCommand('kalori hesaplama');
      expect(command2, VoiceCommand.calculateCalories);

      final command3 = service.processCommand('fotoğraf çek');
      expect(command3, VoiceCommand.calculateCalories);

      final command4 = service.processCommand('kamera aç');
      expect(command4, VoiceCommand.calculateCalories);
    });

    test('processCommand treats other text as search', () {
      final command1 = service.processCommand('yumurta peynir');
      expect(command1, VoiceCommand.search);

      final command2 = service.processCommand('tavuk pilav');
      expect(command2, VoiceCommand.search);

      final command3 = service.processCommand('tarif ara');
      expect(command3, VoiceCommand.search);
    });

    test('processCommand is case insensitive', () {
      final command1 = service.processCommand('KALORI HESAPLA');
      expect(command1, VoiceCommand.calculateCalories);

      final command2 = service.processCommand('Yumurta Peynir');
      expect(command2, VoiceCommand.search);
    });

    test('processCommand handles empty string', () {
      final command = service.processCommand('');
      expect(command, VoiceCommand.search);
    });

    test('processCommand trims whitespace', () {
      final command1 = service.processCommand('  kalori hesapla  ');
      expect(command1, VoiceCommand.calculateCalories);

      final command2 = service.processCommand('  yumurta peynir  ');
      expect(command2, VoiceCommand.search);
    });
  });
}

