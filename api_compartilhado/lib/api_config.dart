import 'package:flutter/foundation.dart';

class ApiConfig {
  // =================================================================
  // 🌍 CONFIGURAÇÃO DE SERVIDORES
  // =================================================================
  
  static const String _prodBaseUrl = 'https://api.suaempresa.com';
static const String _webDevUrl = 'http://192.168.1.11:8080';
  static const String _androidDevUrl = 'http://192.168.1.9:8080'; // ✅ Teu IP Real

  /// Retorna a URL base correta dependendo da plataforma e do modo (Debug/Release)
  static String get baseUrl {
    if (kReleaseMode) {
      return _prodBaseUrl;
    }

    // Se estiver a correr no Navegador (Projeto Web)
    if (kIsWeb) {
      return _webDevUrl;
    } 
    
    // Se estiver a correr no Android (Emulador ou Dispositivo Físico)
    // Nota: Se usares o emulador padrão do Android, podes trocar para 'http://10.0.2.2:8080'
    return _androidDevUrl;
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