
//base_service.dart
import 'connectivity_service.dart';

class BaseService {
  final ConnectivityService _connectivity = ConnectivityService();

  // Chamar antes de qualquer operação HTTP
  Future<void> verificarConexao() async {
    final conectado = await _connectivity.temConexao();
    if (!conectado) {
      throw SemConexaoException();
    }
  }
}

class SemConexaoException implements Exception {
  final String mensagem = 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
}