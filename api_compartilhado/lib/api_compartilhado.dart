library api_compartilhado;

// 1. Exporta a configuração da API
export 'api_config.dart';

// 2. Exporta todos os Models (ajuste os nomes conforme seus arquivos reais)
export 'models/produto_model.dart';
export 'models/marca_model.dart';
export 'models/categoria_model.dart';
export 'models/pedido_model.dart';
export 'models/usuario_model.dart';
export 'models/movimento_estoque_model.dart';
export 'models/resultado_autenticacao.dart';
export 'models/produto_imagem_model.dart';
export 'models/carrinho_model.dart';

  

// 3. Exporta todos os Services
export 'services/produto_service.dart';
export 'services/marca_service.dart';
export 'services/categoria_service.dart';
export 'services/pedido_contador_service.dart';
export 'services/sessao_service.dart';
export 'services/pedido_service.dart';
export 'services/usuario_service.dart';
export 'services/movimento_estoque_service.dart';
export 'services/base_service.dart';
export 'services/connectivity_service.dart';
export 'services/servico_autenticacao.dart';
export 'services/estoque_alerta_service.dart';
export 'services/carrinho_service.dart';
export 'services/carrinho_contador_service.dart';


