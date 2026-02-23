// lib/services/estoque_alerta_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_compartilhado/api_config.dart';

enum NivelAlerta { nenhum, laranja, vermelho, ruptura }

class ProdutoAlerta {
  final int id;
  final String nome;
  final int quantidade;
  final NivelAlerta nivel;

  ProdutoAlerta({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.nivel,
  });
}

class EstoqueAlertaService extends ChangeNotifier {
  static final EstoqueAlertaService instance = EstoqueAlertaService._();
  EstoqueAlertaService._();

  List<ProdutoAlerta> _alertas = [];
  DateTime? _ultimoAlertaPopup;
  Timer? _timerVerificacao;
  bool _alertaVisivel = false;

  List<ProdutoAlerta> get alertas => _alertas;
  bool get temAlertas => _alertas.isNotEmpty;
  int get totalAlertas => _alertas.length;
  bool get alertaVisivel => _alertaVisivel;

  List<ProdutoAlerta> get alertasCriticos => _alertas
      .where((a) => a.nivel == NivelAlerta.vermelho || a.nivel == NivelAlerta.ruptura)
      .toList();

  bool get temAlertasCriticos => alertasCriticos.isNotEmpty;

  NivelAlerta get nivelMaisCritico {
    if (_alertas.any((a) => a.nivel == NivelAlerta.ruptura)) return NivelAlerta.ruptura;
    if (_alertas.any((a) => a.nivel == NivelAlerta.vermelho)) return NivelAlerta.vermelho;
    if (_alertas.any((a) => a.nivel == NivelAlerta.laranja))  return NivelAlerta.laranja;
    return NivelAlerta.nenhum;
  }

  Color get corAlerta {
    switch (nivelMaisCritico) {
      case NivelAlerta.ruptura: return const Color(0xFF8B0000);
      case NivelAlerta.vermelho: return Colors.red;
      case NivelAlerta.laranja:  return Colors.orange;
      case NivelAlerta.nenhum:   return Colors.green;
    }
  }

  Future<void> inicializar() async {
    await _carregarUltimoAlerta();
    await verificarEstoque();

    _timerVerificacao = Timer.periodic(
      const Duration(minutes: 5),
      (_) => verificarEstoque(),
    );
  }

  /// Consulta GET /api/produtos (todos) e filtra localmente estoque < 20
  Future<void> verificarEstoque() async {
    try {
      print('🔍 [ESTOQUE] Verificando estoque via backend...');

      final response = await http
          .get(
            Uri.parse(ApiConfig.produtosUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        print('⚠️ [ESTOQUE] Resposta inesperada: ${response.statusCode}');
        return;
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      final alertasAntigos = Map.fromEntries(
        _alertas.map((a) => MapEntry(a.id, a.nivel)),
      );

      _alertas = data
          .where((p) =>
              p['ativo'] == 1 &&
              p['quantidadeEstoque'] != null &&
              (p['quantidadeEstoque'] as int) < 20)
          .map((p) {
        final qtd = p['quantidadeEstoque'] as int;
        NivelAlerta nivel;
        if (qtd == 0) {
          nivel = NivelAlerta.ruptura;
        } else if (qtd < 10) {
          nivel = NivelAlerta.vermelho;
        } else {
          nivel = NivelAlerta.laranja;
        }
        return ProdutoAlerta(
          id: p['idProduto'] as int,
          nome: p['nomeProduto'] as String,
          quantidade: qtd,
          nivel: nivel,
        );
      }).toList()
        ..sort((a, b) => a.quantidade.compareTo(b.quantidade));

      print('📦 [ESTOQUE] ${_alertas.length} produto(s) com estoque baixo.');

      if (temAlertasCriticos) {
        final agora = DateTime.now();
        final passaram2Horas = _ultimoAlertaPopup == null ||
            agora.difference(_ultimoAlertaPopup!).inHours >= 2;

        final novoCritico = _alertas.any((alerta) {
          final nivelAnterior = alertasAntigos[alerta.id];
          return (alerta.nivel == NivelAlerta.vermelho ||
                  alerta.nivel == NivelAlerta.ruptura) &&
              (nivelAnterior == null || nivelAnterior == NivelAlerta.laranja);
        });

        if (passaram2Horas || novoCritico) {
          _alertaVisivel = true;
          print('🚨 [ESTOQUE] Popup de alerta activado.');
        }
      } else {
        _alertaVisivel = false;
      }

      notifyListeners();
    } catch (e) {
      print('❌ [ESTOQUE] Erro ao verificar estoque: $e');
    }
  }

  Future<void> marcarComoLido() async {
    _alertaVisivel = false;
    _ultimoAlertaPopup = DateTime.now();
    await _salvarUltimoAlerta();
    notifyListeners();
  }

  Future<void> _carregarUltimoAlerta() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('ultimo_alerta_popup');
    if (ts != null) _ultimoAlertaPopup = DateTime.parse(ts);
  }

  Future<void> _salvarUltimoAlerta() async {
    final prefs = await SharedPreferences.getInstance();
    if (_ultimoAlertaPopup != null) {
      await prefs.setString(
          'ultimo_alerta_popup', _ultimoAlertaPopup!.toIso8601String());
    }
  }

  @override
  void dispose() {
    _timerVerificacao?.cancel();
    super.dispose();
  }
}