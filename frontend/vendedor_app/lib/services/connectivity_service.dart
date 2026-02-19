//connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  // Verifica pontualmente se há conexão
  Future<bool> temConexao() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Stream contínuo para listeners
  Stream<bool> get statusStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}