import 'package:flutter/material.dart';
import 'screens/gerenciar_usuarios.dart';
import 'screens/detalhes_usuario.dart';
import 'screens/categorias_list_screen.dart';
import 'screens/marcas_list_screen.dart';
import 'screens/produto_list_screen.dart';
import 'screens/menu.dart';                         // ✅ NOVO
import 'screens/detalhes_produto.dart';             // ✅ NOVO
import 'screens/movimento_estoque.dart';
import 'screens/tela_login.dart';
import 'screens/primeira_troca_senha.dart';
import 'screens/dashboard.dart';
import 'screens/alterar_senha.dart';
import 'screens/carrinho_screen.dart';
import 'screens/criar_pedido.dart';
import 'screens/editar_usuario.dart';


class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      //Rotas acedidas usando um Parâmetro, exemplo:idsusuario, idproduto, etc.
           case '/detalhes_usuario':
        if (args is int) {
          return MaterialPageRoute(builder: (_) => DetalhesUsuarioScreen(usuarioId: args));
        }
        return _errorRoute();

      case '/detalhes_produto':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => DetalhesProdutoScreen(
              produto: args['produto'],
              marcas: args['marcas'] ?? [],
              categorias: args['categorias'] ?? [],
            ),
          );

                  }
        return _errorRoute();

         case '/criar_pedido':
        if (args is int) {
          return MaterialPageRoute(builder: (_) => CriarPedidoScreen(idCarrinho: args));
        }
        return _errorRoute();

  //Rotas Simples
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardVendasScreen());

       case '/primeira_troca_senha':
            return MaterialPageRoute(
              builder: (context) => const PrimeiraTrocaSenhaScreen(),
            );

     
          // USUÁRIOS
          case '/usuarios':
          case '/gerenciar_usuarios':
            return MaterialPageRoute(
              builder: (context) => const UsuarioListScreen(),
            );

            
              case '/editar_usuario':
                return MaterialPageRoute(
                  builder: (_) => const EditarUsuarioScreen(),
                );
              
              case '/alterar_senha':
                return MaterialPageRoute(
                  builder: (_) => const AlterarSenhaScreen(),
                );

          // CATEGORIAS
          case '/categorias':
            return MaterialPageRoute(
              builder: (context) => const CategoriasListScreen(),
            );

          // MARCAS
          case '/marcas':
            return MaterialPageRoute(
              builder: (context) => const MarcasListScreen(),
            );

          // PRODUTOS (gestão interna)
          case '/produtos':
            return MaterialPageRoute(
              builder: (context) => const ProdutoListScreen(),
            );


          // ✅ MENU — catálogo de produtos activos para criação de pedidos
          case '/menu':
            return MaterialPageRoute(
              builder: (context) => const MenuScreen(),
            );

          // ✅carrinho activo
            case '/carrinho':
            return MaterialPageRoute(
              builder: (context) => const CarrinhoScreen(),
            );

case '/movimentos_estoque':
  return MaterialPageRoute(
    builder: (context) => const MovimentoEstoqueListScreen(),
  );


      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Rota não encontrada')));
    });
  }
}