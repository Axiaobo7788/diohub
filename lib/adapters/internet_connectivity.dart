import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:diohub/utils/fire_and_forget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline, restored }

/// Instance-based network status monitor. Create via [internetConnectivityProvider],
/// call [startMonitoring] once, and [dispose] when done (provider handles dispose).
class InternetConnectivity {
  InternetConnectivity() {
    _statusListener = _networkController.stream.listen((final NetworkStatus s) {
      _status = s;
    });
  }

  final StreamController<NetworkStatus> _networkController =
      StreamController<NetworkStatus>.broadcast();
  late final StreamSubscription<NetworkStatus> _statusListener;
  NetworkStatus _status = NetworkStatus.online;

  Stream<NetworkStatus> get networkStream => _networkController.stream;
  NetworkStatus get status => _status;

  /// Starts listening to connectivity changes and performs initial check.
  /// Safe to call once; call from provider creation.
  void startMonitoring() {
    fireAndForget(() => _runMonitoring(), label: 'Connectivity monitor');
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _runMonitoring() async {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((final List<ConnectivityResult> statuses) async {
      final ConnectivityResult result = statuses.last;
      if (result != ConnectivityResult.none) {
        _networkController.add(NetworkStatus.restored);
        await Future<void>.delayed(const Duration(seconds: 5));
        _networkController.add(NetworkStatus.online);
      } else {
        _networkController.add(NetworkStatus.offline);
      }
    });
    final results = await Connectivity().checkConnectivity();
    if (results.last == ConnectivityResult.none) {
      _networkController.add(NetworkStatus.offline);
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_statusListener.cancel());
    unawaited(_networkController.close());
  }
}

/// Provides a single [InternetConnectivity] instance. Monitoring starts on first read.
/// Disposed when the provider is invalidated.
final Provider<InternetConnectivity> internetConnectivityProvider =
    Provider<InternetConnectivity>((final Ref ref) {
  final instance = InternetConnectivity();
  instance.startMonitoring();
  ref.onDispose(instance.dispose);
  return instance;
});
