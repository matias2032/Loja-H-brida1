import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/produto_model.dart';

class ProdutoService {
  // ===== LISTAR TODOS OS PRODUTOS =====
  Future<List<Produto>> listarProdutos() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.produtosUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Produto.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarProdutos: $e');
      rethrow;
    }
  }

  // ===== LISTAR PRODUTOS ATIVOS =====
  Future<List<Produto>> listarProdutosAtivos() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.produtosUrl}/ativos'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Produto.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar produtos ativos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarProdutosAtivos: $e');
      rethrow;
    }
  }

  // ===== BUSCAR PRODUTO POR ID =====
  Future<Produto> buscarPorId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.produtosUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Produto.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Produto não encontrado: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no buscarPorId: $e');
      rethrow;
    }
  }

  // ===== CRIAR PRODUTO =====
  Future<Produto> criarProduto(Produto produto) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.produtosUrl),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(produto.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Produto criado com sucesso');
        return Produto.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao criar produto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no criarProduto: $e');
      rethrow;
    }
  }

  // ===== ATUALIZAR PRODUTO =====
  Future<Produto> atualizarProduto(int id, Produto produto) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.produtosUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(produto.toJsonCreate()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ Produto atualizado com sucesso');
        return Produto.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Erro ao atualizar produto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no atualizarProduto: $e');
      rethrow;
    }
  }

  // ===== TOGGLE ATIVO/INATIVO =====
  Future<void> toggleAtivo(int id) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.produtosUrl}/$id/toggle-ativo'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        print('✅ Status do produto alterado com sucesso');
      } else {
        throw Exception('Erro ao alternar status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no toggleAtivo: $e');
      rethrow;
    }
  }

  // ===== ASSOCIAR CATEGORIA =====
  Future<void> associarCategoria(int idProduto, int idCategoria) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.produtosUrl}/$idProduto/categorias/$idCategoria'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Categoria associada ao produto');
      } else {
        throw Exception('Erro ao associar categoria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no associarCategoria: $e');
      rethrow;
    }
  }

  // ===== ASSOCIAR MARCA =====
  Future<void> associarMarca(int idProduto, int idMarca) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.produtosUrl}/$idProduto/marcas/$idMarca'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Marca associada ao produto');
      } else {
        throw Exception('Erro ao associar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no associarMarca: $e');
      rethrow;
    }
  }
}