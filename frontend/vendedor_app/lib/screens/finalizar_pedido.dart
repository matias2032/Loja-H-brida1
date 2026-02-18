import 'package:flutter/material.dart';
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
  final _valorPagoCtrl    = TextEditingController();
  final _nomeCtrl         = TextEditingController();
  final _apelidoCtrl      = TextEditingController();
  final _enderecoCtrl     = TextEditingController();
  final _bairroCtrl       = TextEditingController();
  final _referenciaCtrl   = TextEditingController();


  int _idTipoPagamento = 1;   // padrão: dinheiro
  int _idTipoEntrega   = 1;   // padrão: balcão
  bool _loading = false;
  double _custoDelivery = 0.0;
bool _loadingCusto = false;

  // Custo adicional do delivery — idealmente vindo do backend
  // Por simplicidade, assumido fixo aqui; pode ser buscado via API
 
  bool get _isDinheiro        => _idTipoPagamento == 1;
  bool get _isLojaFisica      => widget.pedido.idTipoOrigemPedido == 2;
  bool get _isDelivery        => _isLojaFisica && _idTipoEntrega == 2;

  double get _totalBase       => widget.pedido.total;
  double get _totalComEntrega => _isDelivery ? _totalBase + _custoDelivery : _totalBase;

  double get _troco {
    if (!_isDinheiro) return 0;
    final pago = double.tryParse(_valorPagoCtrl.text.replaceAll(',', '.')) ?? 0;
    final troco = pago - _totalComEntrega;
    return troco < 0 ? 0 : troco;
  }

@override
void dispose() {
  _valorPagoCtrl.dispose();
  _nomeCtrl.dispose();
  _apelidoCtrl.dispose();
  _enderecoCtrl.dispose();
  _bairroCtrl.dispose();
  _referenciaCtrl.dispose();
  super.dispose();
 }
@override
void initState() {
  super.initState();
  _carregarCustoDelivery();
}

  Future<void> _confirmar() async {
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

    setState(() => _loading = true);
    print('🏁 [FINALIZAR] Confirmando pedido ${widget.pedido.reference}');

    try {
      await _service.finalizarPedido(
  idPedido:               widget.pedido.idPedido!,
  idTipoPagamento:        _idTipoPagamento,
  valorPago:              _isDinheiro
      ? double.tryParse(_valorPagoCtrl.text.replaceAll(',', '.'))
      : null,
  idTipoEntrega:          _isLojaFisica ? _idTipoEntrega : null,
  nomeCliente:            _nomeCtrl.text.trim(),
  apelidoCliente:         _apelidoCtrl.text.trim(),
  enderecoJson:           _enderecoCtrl.text.trim(),
  bairro:                 _bairroCtrl.text.trim(),
  pontoReferencia:        _referenciaCtrl.text.trim(),
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


Future<void> _carregarCustoDelivery() async {
  setState(() => _loadingCusto = true);
  try {
    final data = await _service.buscarTipoEntrega(2);
    setState(() {
      _custoDelivery = (data['precoAdicional'] as num? ?? 0).toDouble();
      print('✅ [FINALIZAR] Custo delivery carregado da BD: $_custoDelivery');
    });
  } catch (e) {
    print('❌ [FINALIZAR] Erro ao carregar custo delivery: $e');
    setState(() => _custoDelivery = 0.0);
  } finally {
    setState(() => _loadingCusto = false);
  }
}

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Finalizar ${widget.pedido.reference ?? ''}',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
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
          ]),

          const SizedBox(height: 20),

          // ── Pagamento ────────────────────────────────────────────────────
          _secao('Método de Pagamento', [
            DropdownButtonFormField<int>(
              value: _idTipoPagamento,
              decoration: _inputDecoration('Tipo de pagamento'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('💵 Dinheiro em espécie')),
                DropdownMenuItem(value: 2, child: Text('💳 Transferência / M-Pesa')),
                DropdownMenuItem(value: 3, child: Text('🏦 Outro')),
              ],
              onChanged: (v) => setState(() => _idTipoPagamento = v!),
            ),
            if (_isDinheiro) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _valorPagoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    const Text('Troco:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('MZN ${_troco.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ]),

          // ── Entrega (apenas Loja Física) ─────────────────────────────────
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

          // ── Dados do cliente (apenas Delivery) ───────────────────────────
          if (_isDelivery) ...[
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
                controller: _bairroCtrl,
                decoration: _inputDecoration('Bairro'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _referenciaCtrl,
                decoration: _inputDecoration('Ponto de referência'),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

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
              color: selected ? const Color(0xFF1A1A2E) : Colors.grey[300]!),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}