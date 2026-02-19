import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pedido_model.dart';
import '../services/pedido_service.dart';

class FinalizarPedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const FinalizarPedidoScreen({Key? key, required this.pedido}) : super(key: key);

  @override
  State<FinalizarPedidoScreen> createState() => _FinalizarPedidoScreenState();
}

class _FinalizarPedidoScreenState extends State<FinalizarPedidoScreen> {
  final PedidoService _service = PedidoService();

  final _valorPagoCtrl  = TextEditingController();
  final _nomeCtrl       = TextEditingController();
  final _apelidoCtrl    = TextEditingController();
  final _enderecoCtrl   = TextEditingController();
  final _bairroCtrl     = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _telefoneCtrl   = TextEditingController();

  int _idTipoPagamento = 1; // padrão: dinheiro
  int _idTipoEntrega   = 1; // padrão: balcão
  bool _loading        = false;
  bool _loadingCusto   = false;

  double _custoDelivery = 0.0;

  // ADICIONADO: lista de métodos de pagamento carregados da BD
  List<Map<String, dynamic>> _tiposPagamento = [];
  bool _loadingPagamento = false;

  bool get _isDinheiro   => _idTipoPagamento == 1;
  bool get _isLojaFisica => widget.pedido.idTipoOrigemPedido != 1; // null ou 2 → mostra
  bool get _isDelivery   => _idTipoEntrega == 2;

  double get _totalBase       => widget.pedido.total;
  double get _totalComEntrega => _isDelivery ? _totalBase + _custoDelivery : _totalBase;

  double get _troco {
    if (!_isDinheiro) return 0;
    final pago = double.tryParse(_valorPagoCtrl.text.replaceAll(',', '.')) ?? 0;
    final troco = pago - _totalComEntrega;
    return troco < 0 ? 0 : troco;
  }

  @override
  void initState() {
    super.initState();
    print('🏁 [FINALIZAR] idTipoOrigemPedido: ${widget.pedido.idTipoOrigemPedido}');
    print('🏁 [FINALIZAR] isLojaFisica: $_isLojaFisica');
    _carregarCustoDelivery();
    _carregarTiposPagamento(); // ADICIONADO
  }

  @override
  void dispose() {
    _valorPagoCtrl.dispose();
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _enderecoCtrl.dispose();
    _bairroCtrl.dispose();
    _referenciaCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  // ── Carrega custo de delivery da BD ────────────────────────────────────────

  Future<void> _carregarCustoDelivery() async {
    setState(() => _loadingCusto = true);
    try {
      final data = await _service.buscarTipoEntrega(2);
      setState(() {
        _custoDelivery = (data['precoAdicional'] as num? ?? 0).toDouble();
        print('✅ Custo delivery: $_custoDelivery');
      });
    } catch (e) {
      print('❌ Erro ao carregar custo delivery: $e');
      setState(() => _custoDelivery = 0.0);
    } finally {
      setState(() => _loadingCusto = false);
    }
  }

  // ADICIONADO: carrega métodos de pagamento da BD
  Future<void> _carregarTiposPagamento() async {
    setState(() => _loadingPagamento = true);
    try {
      final lista = await _service.listarTiposPagamento();
      setState(() {
        _tiposPagamento = lista;
        // garante que o valor padrão existe na lista carregada
        if (_tiposPagamento.isNotEmpty &&
            !_tiposPagamento.any((t) => t['idTipoPagamento'] == _idTipoPagamento)) {
          _idTipoPagamento = _tiposPagamento.first['idTipoPagamento'] as int;
        }
      });
    } catch (e) {
      print('❌ Erro ao carregar tipos de pagamento: $e');
    } finally {
      setState(() => _loadingPagamento = false);
    }
  }

  // ── Confirmação ────────────────────────────────────────────────────────────

  Future<void> _confirmar() async {

      print('========================================');
  print('🏁 [CONFIRMAR] Pedido: ${widget.pedido.reference}');
  print('🏁 [CONFIRMAR] idTipoOrigemPedido: ${widget.pedido.idTipoOrigemPedido}');
  print('🏁 [CONFIRMAR] isLojaFisica: $_isLojaFisica');
  print('🏁 [CONFIRMAR] idTipoEntrega: $_idTipoEntrega | isDelivery: $_isDelivery');
  print('🏁 [CONFIRMAR] idTipoPagamento: $_idTipoPagamento | isDinheiro: $_isDinheiro');
  print('🏁 [CONFIRMAR] totalBase: $_totalBase | custoDelivery: $_custoDelivery | totalFinal: $_totalComEntrega');
  print('🏁 [CONFIRMAR] nomeCliente: ${_nomeCtrl.text.trim()}');
  print('🏁 [CONFIRMAR] apelidoCliente: ${_apelidoCtrl.text.trim()}');
  print('🏁 [CONFIRMAR] telefone: ${_telefoneCtrl.text.trim()}');
  print('🏁 [CONFIRMAR] bairro: ${_bairroCtrl.text.trim()}');
  print('🏁 [CONFIRMAR] pontoReferencia: ${_referenciaCtrl.text.trim()}');
  print('========================================');
    // Validação: dinheiro
    if (_isDinheiro) {
      final pago = double.tryParse(_valorPagoCtrl.text.replaceAll(',', '.')) ?? 0;
      if (pago <= 0) {
        _snack('Insira o valor recebido', Colors.red);
        return;
      }
      if (pago < _totalComEntrega) {
        _snack('Valor insuficiente para cobrir o total', Colors.red);
        return;
      }
    }

    // Validação: campos obrigatórios para delivery
    if (_isDelivery) {
      if (_bairroCtrl.text.trim().isEmpty) {
        _snack('Bairro é obrigatório para Delivery', Colors.red);
        return;
      }
      if (_referenciaCtrl.text.trim().isEmpty) {
        _snack('Ponto de referência é obrigatório para Delivery', Colors.red);
        return;
      }
    }

    setState(() => _loading = true);
    print('🏁 [FINALIZAR] Confirmando pedido ${widget.pedido.reference}');

    try {
      await _service.finalizarPedido(
        idPedido:        widget.pedido.idPedido!,
        idTipoPagamento: _idTipoPagamento,
        valorPago: _isDinheiro
            ? double.tryParse(_valorPagoCtrl.text.replaceAll(',', '.'))
            : null,
        idTipoEntrega:   _idTipoEntrega,
        nomeCliente:     _nomeCtrl.text.trim(),
        apelidoCliente:  _apelidoCtrl.text.trim(),
        telefone:        _telefoneCtrl.text.trim(), // ADICIONADO
        enderecoJson:    _enderecoCtrl.text.trim(),
        bairro:          _bairroCtrl.text.trim(),
        pontoReferencia: _referenciaCtrl.text.trim(),
      );
      print('✅ [FINALIZAR] Sucesso');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('❌ [FINALIZAR] Erro: $e');
      _snack('Erro ao finalizar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Finalizar ${widget.pedido.reference ?? ''}',
          style: const TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Resumo ──────────────────────────────────────────────────────
          _secao('Resumo do Pedido', [
            _linhaInfo('Referência', widget.pedido.reference ?? '—'),
            _linhaInfo('Itens', '${widget.pedido.totalItens}'),
            _linhaInfo('Subtotal', 'MZN ${_totalBase.toStringAsFixed(2)}'),
            if (_isDelivery)
              _linhaInfo('Entrega', '+ MZN ${_custoDelivery.toStringAsFixed(2)}'),
            _linhaInfo('Total', 'MZN ${_totalComEntrega.toStringAsFixed(2)}',
                destaque: true),
            _linhaInfo(
              'Origem',
              widget.pedido.idTipoOrigemPedido == 1
                  ? 'Online'
                  : widget.pedido.idTipoOrigemPedido == 2
                      ? 'Loja Física'
                      : 'Não definida',
            ),
          ]),

          const SizedBox(height: 20),

          // ── Pagamento ────────────────────────────────────────────────────
          _secao('Método de Pagamento', [
            // CORRIGIDO: dropdown alimentado pela BD; fallback para loading
            _loadingPagamento
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _tiposPagamento.isEmpty ? null : _idTipoPagamento,
                    decoration: _inputDecoration('Tipo de pagamento'),
                    items: _tiposPagamento.map((t) {
                      return DropdownMenuItem<int>(
                        value: t['idTipoPagamento'] as int,
                        child: Text(t['tipoPagamento'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _idTipoPagamento = v);
                    },
                  ),

            // Troco — apenas para dinheiro (idTipoPagamento == 1)
            if (_isDinheiro) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _valorPagoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Valor recebido (MZN)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Troco:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'MZN ${_troco.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ]),

          // ── Tipo de Entrega (apenas Loja Física) ─────────────────────────
          if (_isLojaFisica) ...[
            const SizedBox(height: 20),
            _secao('Tipo de Entrega', [
              Row(
                children: [
                  Expanded(
                    child: _botaoEntrega(
                      label: '🏪 No Balcão',
                      selected: _idTipoEntrega == 1,
                      onTap: () => setState(() => _idTipoEntrega = 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _botaoEntrega(
                      label: '🛵 Delivery',
                      selected: _idTipoEntrega == 2,
                      onTap: () => setState(() => _idTipoEntrega = 2),
                    ),
                  ),
                ],
              ),
            ]),
          ],

          // ── Dados do Cliente — Balcão (opcional) ─────────────────────────
          // CORRIGIDO: campos nome, apelido e telefone aparecem também para balcão
          if (_isLojaFisica && !_isDelivery) ...[
            const SizedBox(height: 20),
            _secao('Dados do Cliente (opcional)', [
              TextField(
                controller: _nomeCtrl,
                decoration: _inputDecoration('Nome'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apelidoCtrl,
                decoration: _inputDecoration('Apelido'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Telefone'),
              ),
            ]),
          ],

          // ── Dados do Cliente — Delivery (bairro e ref. obrigatórios) ─────
          if (_isDelivery) ...[
            const SizedBox(height: 20),
            _secao('Dados do Cliente', [
              TextField(
                controller: _nomeCtrl,
                decoration: _inputDecoration('Nome'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apelidoCtrl,
                decoration: _inputDecoration('Apelido'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Telefone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bairroCtrl,
                decoration: _inputDecoration('Bairro *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _referenciaCtrl,
                decoration: _inputDecoration('Ponto de referência *'),
              ),
            ]),
          ],

          const SizedBox(height: 32),

          // ── Botão confirmar ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmar Finalização',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS DE UI
  // ════════════════════════════════════════════════════════════════════════

  Widget _secao(String titulo, List<Widget> filhos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          ...filhos,
        ],
      ),
    );
  }

  Widget _linhaInfo(String label, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(valor,
              style: TextStyle(
                fontWeight: destaque ? FontWeight.bold : FontWeight.w500,
                fontSize: destaque ? 16 : 14,
                color: destaque ? Colors.green : const Color(0xFF1A1A2E),
              )),
        ],
      ),
    );
  }

  Widget _botaoEntrega({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A2E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  selected ? const Color(0xFF1A1A2E) : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}