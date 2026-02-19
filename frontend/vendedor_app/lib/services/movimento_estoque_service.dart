import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../models/movimento_estoque_model.dart';

class MovimentoEstoqueService {
  // ✅ getter em vez de const — compatível com ApiConfig.baseUrl
  static String get _baseUrl => ApiConfig.movimentosEstoqueUrl;

  Future<MovimentoEstoque> registrar(MovimentoEstoque movimento) async {
    print('📦 [MovimentoEstoque] Registrando | produto=${movimento.idProduto} '
        'tipo=${movimento.tipoMovimento} '
        'anterior=${movimento.quantidadeAnterior} → nova=${movimento.quantidadeNova}');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(movimento.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        print('✅ [MovimentoEstoque] Registrado com sucesso');
        return MovimentoEstoque.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception(
            '❌ [MovimentoEstoque] Erro ao registrar: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [MovimentoEstoque] Falha: $e');
      rethrow;
    }
  }

  Future<List<MovimentoEstoque>> listarPorProduto(int idProduto) async {
    print('🔍 [MovimentoEstoque] Listando movimentos do produto=$idProduto');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/produto/$idProduto'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => MovimentoEstoque.fromJson(j)).toList();
      } else {
        throw Exception('Erro ao listar movimentos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [MovimentoEstoque] Falha ao listar: $e');
      rethrow;
    }
  }

  Future<List<MovimentoEstoque>> listarTodos() async {
  print('🔍 [MovimentoEstoque] Listando todos os movimentos');
  try {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: ApiConfig.defaultHeaders,
    ).timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((j) => MovimentoEstoque.fromJson(j)).toList();
    } else {
      throw Exception('Erro ao listar movimentos: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [MovimentoEstoque] Falha ao listar todos: $e');
    rethrow;
  }
}

Future<List<MovimentoEstoque>> listarPorPeriodo(DateTime inicio, DateTime fim) async {
  print('🔍 [MovimentoEstoque] Período: $inicio → $fim');
  try {
    final uri = Uri.parse('$_baseUrl/periodo').replace(queryParameters: {
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
    });

    final response = await http.get(
      uri,
      headers: ApiConfig.defaultHeaders,
    ).timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((j) => MovimentoEstoque.fromJson(j)).toList();
    } else {
      throw Exception('Erro ao listar por período: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [MovimentoEstoque] Falha ao listar por período: $e');
    rethrow;
  }
}
}