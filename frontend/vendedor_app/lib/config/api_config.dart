// lib/config/api_config.dart

class ApiConfig {
  // =================================================================
  // 🔧 CONFIGURAÇÃO BASEADA NO SEU IPCONFIG
  // =================================================================
  
  // Backend local (Chrome/Desktop/Windows)
  static const String _devBaseUrl = 'http://localhost:8080';
  
  // Backend para Emulador Android
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';
  
  // Backend para dispositivo físico conectado no WiFi (192.168.1.x)
  static const String _deviceUrl = 'http://192.168.1.3:8080'; // ✅ SEU IP REAL
  
  // Backend para dispositivo via Hotspot Mobile (se compartilhar internet do PC)
  static const String _hotspotUrl = 'http://192.168.137.1:8080';
  
  // Backend em produção
  static const String _prodBaseUrl = 'https://api.suaempresa.com';
  
  // =================================================================
  // 🎯 CONTROLE QUAL AMBIENTE USAR
  // =================================================================
  
  static const bool _isProduction = false;
  static const bool _isAndroidEmulator = false;  // true se testar no emulador
  static const bool _isPhysicalDevice = false;   // true se testar no celular via WiFi
  static const bool _isHotspot = false;          // true se celular conectar no hotspot do PC
  
  // URL base selecionada automaticamente
  static String get baseUrl {
    if (_isProduction) {
      return _prodBaseUrl;
    } else if (_isAndroidEmulator) {
      return _androidEmulatorUrl;
    } else if (_isHotspot) {
      return _hotspotUrl;
    } else if (_isPhysicalDevice) {
      return _deviceUrl;
    } else {
      return _devBaseUrl; // localhost (padrão)
    }
  }
  
  // =================================================================
  // 📍 ENDPOINTS DA API
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
  
  
  // URLs completas
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
  
  // =================================================================
  // ⚙️ CONFIGURAÇÕES ADICIONAIS
  // =================================================================
  
  static const Duration timeout = Duration(seconds: 30);
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // =================================================================
  // 🔍 DEBUG - Mostra configuração atual
  // =================================================================
  
  static void printConfig() {
    print('╔═══════════════════════════════════════╗');
    print('║       CONFIGURAÇÃO DA API             ║');
    print('╠═══════════════════════════════════════╣');
    print('║ Base URL: $baseUrl');
    print('║ Produção: $_isProduction');
    print('║ Emulador Android: $_isAndroidEmulator');
    print('║ Dispositivo Físico: $_isPhysicalDevice');
    print('║ Hotspot: $_isHotspot');
    print('╚═══════════════════════════════════════╝');
  }
}