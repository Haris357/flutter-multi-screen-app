import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` so the rest of the app does not
/// import the plugin directly. Exposes a "true means online" boolean and a
/// stream of online/offline changes.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Returns `true` if any network interface is currently active.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Emits `true` whenever the device becomes online and `false` when it
  /// goes offline. Distinct values only — no duplicates.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map(_isOnline)
      .distinct();
}
