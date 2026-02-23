// lib/services/pedido_contador_service.dart

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'sessao_service.dart';

/// Service global para gerenciar o contador de pedidos "por finalizar"
/// Consulta o backend Java em vez do banco local.
class PedidoContadorService {
  static final PedidoContadorService instance = PedidoContadorService._internal();
  factory PedidoContadorService() => instance;
  PedidoContadorService._internal();

  final _contadorStreamController = StreamController<int>.broadcast();
  Stream<int> get contadorStream => _contadorStreamController.stream;

  int _contadorAtual = 0;
  int get contadorAtual => _contadorAtual;

  bool _isLoading = false;
  DateTime? _ultimaAtualizacao;

  /// Consulta GET /api/pedidos/status/por%20finalizar e conta os resultados
  Future<void> carregarContador(int idUsuario) async {
    if (_isLoading) {
      print('⏳ [CONTADOR] Já existe um carregamento em andamento');
      return;
    }

    _isLoading = true;

    try {
      print('📊 [CONTADOR] Carregando contador de pedidos (usuário $idUsuario)...');

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.pedidosUrl}/status/${Uri.encodeComponent('por finalizar')}',
            ),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      print('📥 [CONTADOR] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final novoContador = data.length;
        atualizarContador(novoContador);
        _ultimaAtualizacao = DateTime.now();
        print('✅ [CONTADOR] Contador carregado: $novoContador pedidos');
      } else {
        print('⚠️ [CONTADOR] Resposta inesperada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CONTADOR] Erro ao carregar contador: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Cache inteligente: só recarrega se passou mais de 30 segundos
  Future<void> recarregarSeNecessario() async {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario == null) {
      print('⚠️ [CONTADOR] Nenhum usuário logado');
      return;
    }

    final agora = DateTime.now();

    if (_ultimaAtualizacao != null &&
        agora.difference(_ultimaAtualizacao!).inSeconds < 30) {
      print('✅ [CONTADOR] Usando cache ($_contadorAtual)');
      return;
    }

    print('🔄 [CONTADOR] Cache expirado — recarregando...');
    await carregarContador(usuario.idUsuario);
  }

  void atualizarContador(int novoValor) {
    if (_contadorAtual != novoValor) {
      print('📊 [CONTADOR] $_contadorAtual → $novoValor');
      _contadorAtual = novoValor;
      _contadorStreamController.add(_contadorAtual);
      _ultimaAtualizacao = DateTime.now();
    }
  }

  void incrementar() => atualizarContador(_contadorAtual + 1);

  void decrementar() {
    if (_contadorAtual > 0) atualizarContador(_contadorAtual - 1);
  }

  void resetar() {
    print('🔄 [CONTADOR] Resetando contador');
    _contadorAtual = 0;
    _ultimaAtualizacao = null;
    _contadorStreamController.add(0);
  }

  void invalidarCache() {
    print('⚠️ [CONTADOR] Cache invalidado');
    _ultimaAtualizacao = null;
  }

  void dispose() {
    _contadorStreamController.close();
  }
}