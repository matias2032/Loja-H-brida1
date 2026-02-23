import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

/// Controlador singleton que mantém o pedido activo em memória.
/// Usar com ValueListenableBuilder para reagir a mudanças.
class PedidoAtivoController {
  PedidoAtivoController._();
  static final PedidoAtivoController instance = PedidoAtivoController._();

  final PedidoService _service = PedidoService();
  final ValueNotifier<Pedido?> pedidoAtivo = ValueNotifier(null);
  final ValueNotifier<bool> carregando = ValueNotifier(false);

  // Carrega o pedido activo do servidor
  Future<void> carregar(int idUsuario) async {
    carregando.value = true;
    try {
      pedidoAtivo.value = await _service.buscarPedidoAtivo(idUsuario);
    } catch (_) {
      pedidoAtivo.value = null;
    } finally {
      carregando.value = false;
    }
  }

  // Desactiva o pedido activo actual
  Future<void> desativar() async {
    final pedido = pedidoAtivo.value;
    if (pedido == null) return;
    await _service.desativarPedido(pedido.idPedido!);
    pedidoAtivo.value = null;
  }

  // Define um novo pedido activo (após criação)
  void definir(Pedido pedido) {
    pedidoAtivo.value = pedido;
  }

  // Limpa sem chamar o servidor (ex: após cancelamento)
  void limpar() {
    pedidoAtivo.value = null;
  }
}