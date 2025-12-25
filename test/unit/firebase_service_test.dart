import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/firebase_service.dart';

void main() {
  group('FirebaseService Tests', () {
    test('isAvailable returns false when not initialized', () {
      // Firebase is not initialized in tests
      expect(FirebaseService.isAvailable, false);
    });

    test('firestore returns null when not initialized', () {
      expect(FirebaseService.firestore, isNull);
    });
  });

  group('FirebaseService Offline Support', () {
    test('Service handles offline gracefully', () {
      // Service should not throw when Firebase is unavailable
      expect(() => FirebaseService.syncFromFirestore(), returnsNormally);
      expect(() => FirebaseService.syncToFirestore(), returnsNormally);
    });
  });
}

