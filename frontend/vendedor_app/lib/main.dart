// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/gerenciar_usuarios.dart';
import 'screens/detalhes_usuario.dart';
import 'screens/categorias_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      
      // ✅ Abre diretamente a tela de CATEGORIAS
      home: const CategoriasListScreen(),
      
      // Rotas nomeadas
      onGenerateRoute: (settings) {
        // Rota para detalhes do usuário (recebe ID como argumento)
        if (settings.name == '/detalhes_usuario') {
          final usuarioId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DetalhesUsuarioScreen(usuarioId: usuarioId),
          );
        }
        
        // Outras rotas
        switch (settings.name) {
          case '/gerenciar_usuarios':
            return MaterialPageRoute(
              builder: (context) => const UsuarioListScreen(),
            );
          
          case '/categorias':
            return MaterialPageRoute(
              builder: (context) => const CategoriasListScreen(),
            );
          
          // Adicione outras rotas conforme necessário:
          // case '/cadastro_usuario':
          //   return MaterialPageRoute(
          //     builder: (context) => const CadastroUsuarioScreen(),
          //   );
          
          default:
            return MaterialPageRoute(
              builder: (context) => const CategoriasListScreen(),
            );
        }
      },
    );
  }
}