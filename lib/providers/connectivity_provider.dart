import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/firebase_service.dart';

/// Provider for connectivity status and sync management
class ConnectivityProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isSyncing => _isSyncing;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasOffline = _isOnline == false;
    _isOnline = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (wasOffline && _isOnline) {
      // Reconnected - trigger sync
      _syncOnReconnect();
    }

    notifyListeners();
  }

  Future<void> _syncOnReconnect() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Sync local changes to Firestore
      await FirebaseService.syncToFirestore();
      
      // Sync from Firestore to local
      await FirebaseService.syncFromFirestore();
    } catch (e) {
      debugPrint('[ConnectivityProvider] Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manually trigger sync
  Future<void> sync() async {
    if (!_isOnline) return;
    await _syncOnReconnect();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

