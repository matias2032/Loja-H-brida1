import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart'; // Certifique-se que o caminho está correto
import '../models/carrinho_model.dart';
import '../models/pedido_model.dart';
import 'sessao_service.dart';
class CarrinhoService {
  
  /// Helper para montar a URI. 

  Uri _uri(String path) => Uri.parse('${ApiConfig.carrinhosUrl}$path');

  // ── Criar carrinho ──────────────────────────────────────────────────────
Future<CarrinhoModel> criarCarrinho() async {
  final token = SessaoService.instance.token;
  final sessionId = SessaoService.instance.cartSessionId;
  final idUsuario = SessaoService.instance.idUsuario;

  final res = await http.post(
    _uri(''),
    headers: {
      ...ApiConfig.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
      if (sessionId != null) 'X-Cart-Session-Id': sessionId,
      if (idUsuario != null) 'X-User-Id': '$idUsuario', // ← novo
    },
  ).timeout(ApiConfig.timeout);

  if (res.statusCode == 201) {
    final model = CarrinhoModel.fromJson(
        json.decode(utf8.decode(res.bodyBytes)));

    final novoSessionId = res.headers['x-cart-session-id'];
    if (novoSessionId != null && novoSessionId.isNotEmpty) {
      await SessaoService.instance.salvarCartSessionId(novoSessionId);
    }
    // Com X-User-Id no header, o backend já cria com id_usuario directamente
    // /associar-usuario já não é necessário neste caminho
    return model;
  }
  throw Exception('Erro ao criar carrinho: ${res.statusCode}');
}
  // ── Adicionar / atualizar item ──────────────────────────────────────────
  Future<CarrinhoModel> adicionarItem(
      int idCarrinho, int idProduto, int quantidade) async {
    final res = await http.post(
      _uri('/$idCarrinho/itens'),
      headers: ApiConfig.defaultHeaders,
      body: json.encode({'idProduto': idProduto, 'quantidade': quantidade}),
    ).timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      return CarrinhoModel.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Erro ao adicionar item: ${res.statusCode}');
  }

  // ── Remover item ────────────────────────────────────────────────────────
  Future<void> removerItem(int idCarrinho, int idProduto) async {
    final res = await http.delete(
      _uri('/$idCarrinho/itens/$idProduto'),
      headers: ApiConfig.defaultHeaders,
    ).timeout(ApiConfig.timeout);

    if (res.statusCode != 204) {
      throw Exception('Erro ao remover item: ${res.statusCode}');
    }
  }

  // ── Converter em pedido (checkout) ──────────────────────────────────────
  Future<Pedido> converterEmPedido(
      int idCarrinho, Map<String, dynamic> pedidoReq) async {
    final res = await http.post(
      _uri('/$idCarrinho/converter-pedido'),
      headers: ApiConfig.defaultHeaders,
      body: json.encode(pedidoReq),
    ).timeout(ApiConfig.timeout);

    if (res.statusCode == 201) {
      return Pedido.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Erro ao converter carrinho: ${res.statusCode}');
  }

  // ── Buscar carrinho por ID ──────────────────────────────────────────────
  Future<CarrinhoModel> buscarCarrinho(int idCarrinho) async {
    final res = await http.get(
      _uri('/$idCarrinho'),
      headers: ApiConfig.defaultHeaders,
    ).timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      return CarrinhoModel.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Erro ao buscar carrinho: ${res.statusCode}');
  }


Future<CarrinhoModel?> buscarCarrinhoActivo() async {
  final token = SessaoService.instance.token;
  final sessionId = SessaoService.instance.cartSessionId;
  final idUsuario = SessaoService.instance.idUsuario;

  final res = await http.get(
    _uri('/activo'),
    headers: {
      ...ApiConfig.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
      if (sessionId != null) 'X-Cart-Session-Id': sessionId,
      if (idUsuario != null) 'X-User-Id': '$idUsuario', // ← novo
    },
  ).timeout(ApiConfig.timeout);

  if (res.statusCode == 200) {
    return CarrinhoModel.fromJson(json.decode(utf8.decode(res.bodyBytes)));
  }
  if (res.statusCode == 404) return null;
  throw Exception('Erro ao buscar carrinho activo: ${res.statusCode}');
}
  // ── Atualizar quantidade de item ────────────────────────────────────────
  Future<CarrinhoModel> atualizarQuantidade(
      int idCarrinho, int idProduto, int quantidade) async {
    final res = await http.put(
      _uri('/$idCarrinho/itens/$idProduto'),
      headers: ApiConfig.defaultHeaders,
      body: json.encode({'quantidade': quantidade}),
    ).timeout(ApiConfig.timeout);

    if (res.statusCode == 200) {
      return CarrinhoModel.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    }

    // Tratamento de estoque insuficiente (Opcional, conforme sua lógica)
    if (res.statusCode == 409 || res.statusCode == 422) {
      final body = json.decode(utf8.decode(res.bodyBytes));
      // final disponivel = (body['estoqueDisponivel'] ?? body['quantidadeEstoque'] ?? 0) as int;
      // Trate aqui ou lance uma exceção customizada
    }

    throw Exception('Erro ao atualizar quantidade: ${res.statusCode}');
  }
}