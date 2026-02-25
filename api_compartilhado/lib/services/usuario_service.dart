import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart'; // Ajuste o package conforme seu projeto
import '../models/usuario_model.dart';

class UsuarioService {
  
  /// Helper para converter a String do ApiConfig em Uri
  Uri _uri([String path = '']) => Uri.parse('${ApiConfig.usuariosUrl}$path');

  /// POST /api/usuarios — cria funcionário com senha padrão
  Future<UsuarioModel> criarUsuario({
    required String nome,
    required String apelido,
    required String email,
    String? telefone,
    int idPerfil = 3,
  }) async {
    final body = jsonEncode({
      'nome': nome,
      'apelido': apelido,
      'email': email,
      'senha': '12345678', // Spring Boot faz o hash
      'telefone': telefone,
      'idPerfil': idPerfil,
    });

    final response = await http
        .post(
          _uri(),
          headers: ApiConfig.defaultHeaders,
          body: body,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    // Extrai mensagem de erro do backend
    String erro = 'Erro ao cadastrar usuário (${response.statusCode})';
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      erro = json['message'] ?? json['error'] ?? erro;
    } catch (_) {}

    throw Exception(erro);
  }

  /// GET /api/usuarios — listagem com filtros opcionais
  Future<List<UsuarioModel>> listarUsuarios({int? perfil, int? ativo}) async {
    final params = <String, String>{};
    if (perfil != null) params['perfil'] = '$perfil';
    if (ativo != null) params['ativo'] = '$ativo';

    // Cria a URI base e anexa os query parameters
    final uri = _uri().replace(queryParameters: params.isEmpty ? null : params);

    final response = await http
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((e) => UsuarioModel.fromJson(e)).toList();
    }
    throw Exception('Erro ao listar usuários (${response.statusCode})');
  }

  /// GET /api/usuarios/{id}
  Future<UsuarioModel> buscarPorId(int id) async {
    final response = await http
        .get(_uri('/$id'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Usuário não encontrado (${response.statusCode})');
  }

  /// PATCH /api/usuarios/{id}/toggle-status
  Future<UsuarioModel> toggleStatus(int id) async {
    final response = await http
        .patch(
          _uri('/$id/toggle-status'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao alterar status (${response.statusCode})');
  }

  /// PATCH /api/usuarios/{id}/reset-password
  Future<UsuarioModel> resetarSenha(int id) async {
    final response = await http
        .patch(
          _uri('/$id/reset-password'),
          headers: ApiConfig.defaultHeaders,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao resetar senha (${response.statusCode})');
  }
}