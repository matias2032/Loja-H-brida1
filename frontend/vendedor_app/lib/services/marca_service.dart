// lib/services/marca_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/marca_model.dart';

class MarcaService {
  // ===== LISTAR TODAS AS MARCAS =====
  Future<List<Marca>> listarMarcas() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.marcasUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Marca.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar marcas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no listarMarcas: $e');
      rethrow;
    }
  }

  // ===== BUSCAR MARCA POR ID =====
  Future<Marca> buscarMarcaPorId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.marcasUrl}/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Marca.fromJson(json.decode(response.body));
      } else {
        throw Exception('Marca não encontrada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no buscarMarcaPorId: $e');
      rethrow;
    }
  }
}