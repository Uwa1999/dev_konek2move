import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityProvider extends ChangeNotifier {
  Set<ConnectivityResult> _status = {};
  bool _isChecking = true;
  bool _hasRealInternet = false;
  bool _uiReady = false;

  /// 🔑 KEY FIX
  bool _hasEverConnected = false;

  bool get isChecking => _isChecking;
  bool get hasRealInternet => _hasRealInternet;
  bool get uiReady => _uiReady;
  bool get hasEverConnected => _hasEverConnected;

  bool get hasSignal => _status.isNotEmpty;
  bool get hasNoSignal =>
      _status.isEmpty || _status.contains(ConnectivityResult.none);

  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityProvider() {
    _init();
  }

  void markUiReady() {
    if (_uiReady) return;
    _uiReady = true;
    notifyListeners();
  }

  /// 🔁 RETRY BUTTON
  Future<void> retryConnection() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    final results = await _connectivity.checkConnectivity();
    _status = results.toSet();

    await _checkInternet();

    _isChecking = false;
    notifyListeners();
  }

  Future<void> _init() async {
    _isChecking = true;
    notifyListeners();

    final results = await _connectivity.checkConnectivity();
    _status = results.toSet();

    await _checkInternet();

    _isChecking = false;
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      _status = results.toSet();
      await _checkInternet();
      notifyListeners();
    });
  }

  /// 🌐 REAL INTERNET CHECK (ANDROID SAFE)
  Future<void> _checkInternet() async {
    try {
      final res = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));

      _hasRealInternet = res.statusCode == 204;

      /// 🔑 ONCE SUCCESS → ALLOW FUTURE WARNINGS
      if (_hasRealInternet) {
        _hasEverConnected = true;
      }
    } catch (_) {
      _hasRealInternet = false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

