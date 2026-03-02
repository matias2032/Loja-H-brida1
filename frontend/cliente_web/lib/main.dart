// lib/main.dart
import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_config.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.baseUrlAsync.then((_) {
    print("✅ API Config carregada com sucesso!");
  }).catchError((error) {
    print("❌ Erro ao carregar API Config: $error");
  }); // ← resolve e faz cache ANTES do app arrancar
  ApiConfig.printConfig();      // ← confirma no console o IP resolvido
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestão',
      debugShowCheckedModeBanner: false,
      
      // ===== TEMA =====
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
      
      // ===== TELA INICIAL =====
      initialRoute: '/menu',
      onGenerateRoute: RouteGenerator.generateRoute,
    
      );
  }
}

