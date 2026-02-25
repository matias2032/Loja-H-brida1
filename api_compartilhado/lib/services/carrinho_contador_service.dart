import 'dart:async';
import 'sessao_service.dart';
import 'carrinho_service.dart';

class CarrinhoContadorService {
  CarrinhoContadorService._();
  static final instance = CarrinhoContadorService._();

  final _controller = StreamController<int>.broadcast();
  Stream<int> get contadorStream => _controller.stream;

  int _contadorAtual = 0;
  int get contadorAtual => _contadorAtual;

  // Guarda o idCarrinho activo para ser reutilizado sem nova chamada
  int? _idCarrinhoAtivo;
  int? get idCarrinhoAtivo => _idCarrinhoAtivo;

  bool _cacheValido = false;
  final _service = CarrinhoService();

  void invalidarCache() => _cacheValido = false;

Future<void> recarregarSeNecessario() async {
  if (_cacheValido) return;
  try {
    final carrinho = await _service.buscarCarrinhoActivo(); // ← GET em vez de POST
    _idCarrinhoAtivo = carrinho?.idCarrinho;
    _contadorAtual = carrinho?.totalItens ?? 0;
    _cacheValido = true;
    _controller.add(_contadorAtual);
  } catch (_) {
    _controller.add(0);
  }
}

  void dispose() => _controller.close();
}