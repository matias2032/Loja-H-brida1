// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/gerenciar_usuarios.dart';

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
      // Abre diretamente a tela de gerenciar usuários
      home: const UsuarioListScreen(),
      // Rotas nomeadas para navegação
      routes: {
        '/gerenciar_usuarios': (context) => const UsuarioListScreen(),
        // Adicione outras rotas conforme necessário:
        // '/cadastro_usuario': (context) => const CadastroUsuarioScreen(),
        // '/detalhes_usuario': (context) => const DetalhesUsuarioScreen(),
      },
    );
  }
}
