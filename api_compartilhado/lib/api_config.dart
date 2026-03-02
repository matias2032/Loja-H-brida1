import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static const String _prodBaseUrl = 'https://api.suaempresa.com';
  static const int _porta = 8080;

  static String? _baseUrlCache;

  static Future<String> get baseUrlAsync async {
    if (_baseUrlCache != null) return _baseUrlCache!;

    if (kReleaseMode) {
      _baseUrlCache = _prodBaseUrl;
      return _baseUrlCache!;
    }

    if (kIsWeb) {
      // No browser, a página serve do mesmo host — usa window.location.hostname
      _baseUrlCache = 'http://${Uri.base.host}:$_porta';
      return _baseUrlCache!;
    }

    // Mobile: descobre o IP da máquina na rede local
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            _baseUrlCache = 'http://${addr.address}:$_porta';
            return _baseUrlCache!;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter IP local: $e');
    }_baseUrlCache = 'http://localhost:$_porta';
    return _baseUrlCache!;
  }

  // Mantém o getter síncrono para compatibilidade — usa o cache ou fallback
  static String get baseUrl {
    if (_baseUrlCache != null) return _baseUrlCache!;
    if (kReleaseMode) return _prodBaseUrl;
    if (kIsWeb) return 'http://${Uri.base.host}:$_porta'; // ← auto no browser
    return 'http://localhost:$_porta'; // fallback até o async resolver
  }
  // =================================================================
  // 📍 ENDPOINTS (Caminhos Relativos)
  // =================================================================
  
  static const String usuarios = '/api/usuarios';
  static const String login = '/api/auth/login';
  static const String perfis = '/api/perfis';
  static const String provincias = '/api/provincias';
  static const String cidades = '/api/cidades';
  static const String categorias = '/api/categorias';
  static const String marcas = '/api/marcas';
  static const String pedidos = '/api/pedidos';
  static const String produtos = '/api/produtos';
  static const String carrinhos = '/api/carrinhos';
  static const String movimentosEstoque = '/api/movimentos_estoque';
  static const String dashboard = '/api/v1/dashboard';

  // =================================================================
  // 🔗 URLS COMPLETAS (Getters)
  // =================================================================
  
  static String get usuariosUrl => '$baseUrl$usuarios';
  static String get loginUrl => '$baseUrl$login';
  static String get perfisUrl => '$baseUrl$perfis';
  static String get provinciasUrl => '$baseUrl$provincias';
  static String get cidadesUrl => '$baseUrl$cidades';
  static String get categoriasUrl => '$baseUrl$categorias';
  static String get marcasUrl => '$baseUrl$marcas';
  static String get pedidosUrl => '$baseUrl$pedidos';
  static String get produtosUrl => '$baseUrl$produtos';
  static String get carrinhosUrl => '$baseUrl$carrinhos';
  static String get movimentosEstoqueUrl => '$baseUrl$movimentosEstoque';
  static String get dashboardUrl => '$baseUrl$dashboard';

  // =================================================================
  // ⚙️ CONFIGURAÇÕES ADICIONAIS
  // =================================================================
  
  static const Duration timeout = Duration(seconds: 30);
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Útil para verificar no console se a URL está correta ao iniciar o app
  static void printConfig() {
    debugPrint('🚀 API CONFIG: Correndo em ${kIsWeb ? "Web" : "Mobile/Android"}');
    debugPrint('🔗 Base URL ativa: $baseUrl');
  }
}