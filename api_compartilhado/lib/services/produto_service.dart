import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto_model.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../models/produto_imagem_model.dart';
import 'package:api_compartilhado/api_config.dart';


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
    final body = produto.toJsonUpdate(); // ✅ USAR ESTE MÉTODO
    
    print('========================================');
    print('🔍 ATUALIZANDO PRODUTO ID: $id');
    print('📤 Dados que serão enviados:');
    print('   JSON completo: ${json.encode(body)}');
    print('========================================');
    
    final response = await http.put(
      Uri.parse('${ApiConfig.produtosUrl}/$id'),
      headers: ApiConfig.defaultHeaders,
      body: json.encode(body),
    ).timeout(ApiConfig.timeout);


    print('📥 RESPOSTA:');
    print('   - Status: ${response.statusCode}');
    print('   - Body: ${response.body}');
    print('========================================');

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

// lib/services/produto_service.dart
// ✅ ADICIONAR estes métodos na classe ProdutoService:

  // ===== ADICIONAR IMAGEM =====
  Future<void> adicionarImagem({
    required int idProduto,
    required File imagemFile,
    String? legenda,
    bool imagemPrincipal = false,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.produtosUrl}/$idProduto/imagens'),
      );

      // Adicionar a imagem
      var imagem = await http.MultipartFile.fromPath(
        'imagem',
        imagemFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(imagem);

      // Adicionar campos
      if (legenda != null && legenda.isNotEmpty) {
        request.fields['legenda'] = legenda;
      }
      request.fields['imagemPrincipal'] = imagemPrincipal ? '1' : '0';

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Imagem adicionada com sucesso');
      } else {
        throw Exception('Erro ao adicionar imagem: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no adicionarImagem: $e');
      rethrow;
    }
  }

  // ===== LISTAR IMAGENS DO PRODUTO =====
  Future<List<ProdutoImagem>> listarImagensDoProduto(int idProduto) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.produtosUrl}/$idProduto/imagens'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ProdutoImagem.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar imagens: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarImagensDoProduto: $e');
      rethrow;
    }
  }

  // ===== DEFINIR IMAGEM PRINCIPAL =====
  Future<void> definirImagemPrincipal(int idProduto, int idImagem) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.produtosUrl}/$idProduto/imagens/$idImagem/principal'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Imagem principal definida');
      } else {
        throw Exception('Erro ao definir imagem principal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no definirImagemPrincipal: $e');
      rethrow;
    }
  }

  // ===== REMOVER IMAGEM =====
  Future<void> removerImagem(int idImagem) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.produtosUrl}/imagens/$idImagem'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Imagem removida com sucesso');
      } else {
        throw Exception('Erro ao remover imagem: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no removerImagem: $e');
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