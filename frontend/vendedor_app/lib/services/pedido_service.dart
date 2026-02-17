//pedido_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pedido_model.dart';

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

  Future<List<Pedido>> listarPorStatus(String status) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.pedidosUrl}/status/${Uri.encodeComponent(status)}',
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
      print('❌ Erro no listarPorStatus: $e');
      rethrow;
    }
  }

  // ─── Listar pedidos "por finalizar" (atalho para a tela principal) ───────

  Future<List<Pedido>> listarPorFinalizar() async {
    return listarPorStatus('por finalizar');
  }
}