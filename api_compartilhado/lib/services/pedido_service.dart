//pedido_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pedido_model.dart';
import 'package:api_compartilhado/api_config.dart';
import 'sessao_service.dart';


class PedidoService {

  // ════════════════════════════════════════════════════════════════════════
  // a) CRIAR PEDIDO
  // POST /api/pedidos
  // ════════════════════════════════════════════════════════════════════════

  Future<Pedido> criarPedido(Pedido pedido) async {
    try {
      final body = pedido.toJsonCreate();

      print('========================================');
      print('🔍 CRIANDO PEDIDO');
      print('📤 Dados enviados:');
      print('   JSON: ${json.encode(body)}');
      print('========================================');

      final response = await http
          .post(
            Uri.parse(ApiConfig.pedidosUrl),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 RESPOSTA:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');
      print('========================================');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Pedido criado com sucesso');
        return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao criar pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no criarPedido: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // b) ADICIONAR ITEM AO PEDIDO
  // POST /api/pedidos/{idPedido}/itens
  // ════════════════════════════════════════════════════════════════════════

Future<Pedido> adicionarItem(int idPedido, ItemPedido item) async {
  try {
    final body = {
      'idProduto': item.idProduto,
      'quantidade': item.quantidade,
    };
      print('========================================');
      print('🔍 ADICIONANDO ITEM AO PEDIDO $idPedido');
      print('📤 Dados enviados: ${json.encode(body)}');
      print('========================================');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/itens'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 RESPOSTA:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');
      print('========================================');

      if (response.statusCode == 200) {
        print('✅ Item adicionado ao pedido');
        return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao adicionar item: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no adicionarItem: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // c) EDITAR QUANTIDADE DE UM ITEM
  // PATCH /api/pedidos/{idPedido}/itens/{idItemPedido}
  // ════════════════════════════════════════════════════════════════════════

  Future<Pedido> editarQuantidadeItem({
    required int idPedido,
    required int idItemPedido,
    required int novaQuantidade,
  }) async {
    try {
      final body = {'novaQuantidade': novaQuantidade};

      print('========================================');
      print('🔍 EDITANDO ITEM $idItemPedido DO PEDIDO $idPedido');
      print('📤 Nova quantidade: $novaQuantidade');
      print('========================================');

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/itens/$idItemPedido'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 RESPOSTA:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');
      print('========================================');

      if (response.statusCode == 200) {
        print('✅ Quantidade do item actualizada');
        return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao editar item: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no editarQuantidadeItem: $e');
      rethrow;
    }
  }

  // Busca o pedido activo do utilizador (null se não houver)
Future<Pedido?> buscarPedidoAtivo(int idUsuario) async {
  try {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.pedidosUrl}/ativo/$idUsuario'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 204) {
      return null; // Nenhum pedido activo
    } else {
      throw Exception('Erro ao buscar pedido activo: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erro no buscarPedidoAtivo: $e');
    rethrow;
  }
}

// Desactiva um pedido
Future<void> desativarPedido(int idPedido) async {
  try {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/desativar'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 204) {
      throw Exception('Erro ao desactivar pedido: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erro no desativarPedido: $e');
    rethrow;
  }
}

  // ════════════════════════════════════════════════════════════════════════
  // d) ELIMINAR ITEM DO PEDIDO
  // DELETE /api/pedidos/{idPedido}/itens/{idItemPedido}
  // ════════════════════════════════════════════════════════════════════════

  Future<Pedido> eliminarItem({
    required int idPedido,
    required int idItemPedido,
  }) async {
    try {
      print('========================================');
      print('🔍 ELIMINANDO ITEM $idItemPedido DO PEDIDO $idPedido');
      print('========================================');

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/itens/$idItemPedido'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      print('📥 RESPOSTA:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');
      print('========================================');

      if (response.statusCode == 200) {
        print('✅ Item eliminado do pedido');
        return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao eliminar item: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no eliminarItem: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // e) CANCELAR PEDIDO
  // POST /api/pedidos/{idPedido}/cancelar
  // ════════════════════════════════════════════════════════════════════════

  Future<void> cancelarPedido({
    required int idPedido,
    required int idUsuarioCancelou,
    String? motivo,
  }) async {
    try {
      final body = {
        'idUsuarioCancelou': idUsuarioCancelou,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      };

      print('========================================');
      print('🔍 CANCELANDO PEDIDO $idPedido');
      print('📤 Dados enviados: ${json.encode(body)}');
      print('========================================');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/cancelar'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 RESPOSTA:');
      print('   - Status: ${response.statusCode}');
      print('========================================');

      if (response.statusCode == 204) {
        print('✅ Pedido cancelado com sucesso');
      } else {
        throw Exception('Erro ao cancelar pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no cancelarPedido: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════════

  // ─── Buscar pedido por ID ────────────────────────────────────────────────

  Future<Pedido> buscarPorId(int idPedido) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Pedido não encontrado: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no buscarPorId: $e');
      rethrow;
    }
  }

  // ─── Listar pedidos por utilizador ──────────────────────────────────────

  Future<List<Pedido>> listarPorUsuario(int idUsuario) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.pedidosUrl}/usuario/$idUsuario'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Pedido.fromJson(e)).toList();
      } else {
        throw Exception('Erro ao listar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarPorUsuario: $e');
      rethrow;
    }
  }

  // ─── Listar pedidos por status ───────────────────────────────────────────

  Future<List<Pedido>> listarPorStatusEUsuario(String status, int idUsuario) async {
  try {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.pedidosUrl}/usuario/$idUsuario/status/${Uri.encodeComponent(status)}',
          ),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => Pedido.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar pedidos por status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erro no listarPorStatusEUsuario: $e');
    rethrow;
  }
}

  Future<Pedido> ativarPedido(int idPedido) async {
  print('🟢 [SERVICE] ativarPedido($idPedido) — chamando backend...');
  try {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/ativar'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    print('📥 [SERVICE] ativarPedido — status: ${response.statusCode}');
    print('📥 [SERVICE] ativarPedido — body: ${response.body}');

    if (response.statusCode == 200) {
      final pedido = Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      print('✅ [SERVICE] Pedido ativado: ${pedido.reference} | ativo: ${pedido.ativo}');
      return pedido;
    } else {
      throw Exception('Erro ao ativar pedido: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [SERVICE] Erro em ativarPedido: $e');
    rethrow;
  }
}

// CORRIGIDO: parâmetro `telefone` adicionado à assinatura
  Future<Pedido> finalizarPedido({
    required int idPedido,
    required int idTipoPagamento,
    double? valorPago,
    int? idTipoEntrega,
    String? nomeCliente,
    String? apelidoCliente,
    String? telefone,        // ← ADICIONADO
    String? enderecoJson,
    String? bairro,
    String? pontoReferencia,
  }) async {
    // CORRIGIDO: todos os campos enviados sempre (sem condicional isNotEmpty)
    // para garantir que valores vazios/null cheguem ao backend e sejam gravados
    final body = <String, dynamic>{
      'idTipoPagamento': idTipoPagamento,
      if (valorPago != null) 'valorPago': valorPago,
      'idTipoEntrega':   idTipoEntrega,
      'nomeCliente':     nomeCliente,
      'apelidoCliente':  apelidoCliente,
      'telefone':        telefone,        // ← ADICIONADO
      'enderecoJson':    enderecoJson,
      'bairro':          bairro,
      'pontoReferencia': pontoReferencia,
    };

    print('📤 [SERVICE] finalizarPedido body: ${json.encode(body)}');

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.pedidosUrl}/$idPedido/finalizar'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 [SERVICE] finalizarPedido — status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final pedido = Pedido.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        print('✅ Pedido finalizado: ${pedido.reference}');
        return pedido;
      } else {
        throw Exception(
            'Erro ao finalizar pedido: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      print('❌ Erro em finalizarPedido: $e');
      rethrow;
    }
  }
  // ─── Listar pedidos "por finalizar" (atalho para a tela principal) ───────

  Future<List<Pedido>> listarPorFinalizar() async {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario == null) throw Exception('Utilizador não autenticado');
    return listarPorStatusEUsuario('por finalizar', usuario.idUsuario);
  }

  Future<Map<String, dynamic>> buscarTipoEntrega(int idTipoEntrega) async {
  print('🚚 [SERVICE] buscarTipoEntrega($idTipoEntrega)');
  try {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.pedidosUrl}/tipos-entrega/$idTipoEntrega'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    print('📥 [SERVICE] tipoEntrega — status: ${response.statusCode} | body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ao buscar tipo entrega: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [SERVICE] Erro em buscarTipoEntrega: $e');
    rethrow;
  }
}

 // ADICIONADO: carrega todos os métodos de pagamento da BD
  // GET /api/pedidos/tipos-pagamento
  Future<List<Map<String, dynamic>>> listarTiposPagamento() async {
    print('💳 [SERVICE] listarTiposPagamento()');
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.pedidosUrl}/tipos-pagamento'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      print('📥 Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar tipos pagamento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro em listarTiposPagamento: $e');
      rethrow;
    }
  }

  Future<List<Pedido>> listarPorFinalizarLojaFisica(int idUsuario) async {
  try {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.pedidosUrl}/usuario/$idUsuario/status/${Uri.encodeComponent('por finalizar')}/origem/2',
          ),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => Pedido.fromJson(e)).toList();
    }
    throw Exception('Erro ao listar: ${response.statusCode}');
  } catch (e) {
    print('❌ Erro em listarPorFinalizarLojaFisica: $e');
    rethrow;
  }
}
}