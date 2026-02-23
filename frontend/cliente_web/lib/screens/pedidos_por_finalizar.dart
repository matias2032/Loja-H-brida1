import 'package:flutter/material.dart';
import '../controllers/pedido_ativo_controller.dart';
import '../widgets/pedido_ativo_banner.dart';
import 'finalizar_pedido.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class PedidosPorFinalizarScreen extends StatefulWidget {
  const PedidosPorFinalizarScreen({Key? key}) : super(key: key);

  @override
  State<PedidosPorFinalizarScreen> createState() =>
      _PedidosPorFinalizarScreenState();
}

class _PedidosPorFinalizarScreenState
    extends State<PedidosPorFinalizarScreen> {
  final PedidoService _pedidoService = PedidoService();

  List<Pedido> _pedidos = [];
  bool _isLoading = true;
  String? _erro;
    bool _operacaoEmAndamento = false;  

  @override
  void initState() {
    super.initState();
    _carregarPedidos();
  }

  // ════════════════════════════════════════════════════════════════════════
  // DADOS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _carregarPedidos() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final lista = await _pedidoService.listarPorStatus('por finalizar');
      if (mounted) {
        setState(() {
          _pedidos = lista;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro ao carregar pedidos: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACÇÕES
  // ════════════════════════════════════════════════════════════════════════

Future<void> _cancelarPedido(Pedido pedido) async {
  if (_operacaoEmAndamento) return;  // ← ADICIONAR

  final confirmado = await _mostrarDialogoCancelamento(pedido);
  if (!confirmado) return;

  setState(() => _operacaoEmAndamento = true);  // ← ADICIONAR

  try {
    await _pedidoService.cancelarPedido(
      idPedido: pedido.idPedido!,
      idUsuarioCancelou: 1,
      motivo: 'Cancelado pelo operador',
    );
    if (pedido.ativo) PedidoAtivoController.instance.limpar();  // ← ADICIONAR
    _mostrarSnack('Pedido ${pedido.reference} cancelado', Colors.orange);
    await _carregarPedidos();
  } catch (e) {
    _mostrarSnack('Erro ao cancelar: $e', Colors.red);
  } finally {
    if (mounted) setState(() => _operacaoEmAndamento = false);  // ← ADICIONAR
  }
}

 Future<void> _toggleAtivacao(Pedido pedido) async {
  if (_operacaoEmAndamento) return;

  print('🔄 [TOGGLE] Clicado — ${pedido.reference} | ativo: ${pedido.ativo}');
  setState(() => _operacaoEmAndamento = true);

  try {
    if (pedido.ativo) {
      print('🔴 [TOGGLE] Desativando pedido ${pedido.idPedido}...');
      await _pedidoService.desativarPedido(pedido.idPedido!);
      PedidoAtivoController.instance.limpar();
      print('✅ [TOGGLE] Controller limpo após desativação');
      _mostrarSnack('Pedido ${pedido.reference} desativado', Colors.grey);
    } else {
      print('🟢 [TOGGLE] Ativando pedido ${pedido.idPedido}...');
      final pedidoAtualizado = await _pedidoService.ativarPedido(pedido.idPedido!);
      print('✅ [TOGGLE] Backend confirmou: ativo=${pedidoAtualizado.ativo}');
      PedidoAtivoController.instance.definir(pedidoAtualizado);
      _mostrarSnack('Pedido ${pedido.reference} ativado', Colors.green);
    }

    await _carregarPedidos();
  } catch (e) {
    print('❌ [TOGGLE] Erro: $e');
    _mostrarSnack('Erro ao alterar ativação: $e', Colors.red);
  } finally {
    if (mounted) setState(() => _operacaoEmAndamento = false);
  }
}

  Future<bool> _mostrarDialogoCancelamento(Pedido pedido) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cancelar Pedido'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Referência: ${pedido.reference ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Total: MZN ${pedido.total.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                Text('Itens: ${pedido.totalItens}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'O estoque será restaurado automaticamente.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar Pedido'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _mostrarSnack(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _editarQuantidade(Pedido pedido, ItemPedido item, int novaQtd) async {
  if (_operacaoEmAndamento || novaQtd < 1) return;

  setState(() => _operacaoEmAndamento = true);

  try {
    await _pedidoService.editarQuantidadeItem(
      idPedido: pedido.idPedido!,
      idItemPedido: item.idItemPedido!,
      novaQuantidade: novaQtd,
    );
    _mostrarSnack('Quantidade atualizada', Colors.green);
    await _carregarPedidos();
    // Atualiza controller se for o pedido ativo
    if (pedido.ativo) {
      final atualizado = await _pedidoService.buscarPorId(pedido.idPedido!);
      PedidoAtivoController.instance.definir(atualizado);
    }
  } catch (e) {
    _mostrarSnack('Erro: $e', Colors.red);
  } finally {
    if (mounted) setState(() => _operacaoEmAndamento = false);
  }
}

Future<void> _eliminarItem(Pedido pedido, ItemPedido item) async {
  if (_operacaoEmAndamento) return;

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Eliminar Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.nomeProduto,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Quantidade: ${item.quantidade}'),
          Text('Subtotal: MZN ${item.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          if (pedido.itens.length == 1)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Último item: o pedido será cancelado automaticamente.',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O estoque será restituído automaticamente.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmado != true) return;

  setState(() => _operacaoEmAndamento = true);

  try {
    if (pedido.itens.length == 1) {
      // Último item → cancela o pedido inteiro
      await _pedidoService.cancelarPedido(
        idPedido: pedido.idPedido!,
        idUsuarioCancelou: 1,
        motivo: 'Cancelado automaticamente (último item removido)',
      );
      if (pedido.ativo) PedidoAtivoController.instance.limpar();
      _mostrarSnack('Pedido cancelado (último item removido)', Colors.orange);
    } else {
      // Remove apenas o item
      await _pedidoService.eliminarItem(
        idPedido: pedido.idPedido!,
        idItemPedido: item.idItemPedido!,
      );
      _mostrarSnack('Item eliminado', Colors.green);
      // Atualiza controller se for o pedido ativo
      if (pedido.ativo) {
        final atualizado = await _pedidoService.buscarPorId(pedido.idPedido!);
        PedidoAtivoController.instance.definir(atualizado);
      }
    }
    await _carregarPedidos();
  } catch (e) {
    _mostrarSnack('Erro: $e', Colors.red);
  } finally {
    if (mounted) setState(() => _operacaoEmAndamento = false);
  }
}

Future<void> _abrirFinalizarPedido(Pedido pedido) async {
  print('🏁 [NAV] Pedido: ${pedido.reference}');
  print('🏁 [NAV] idTipoOrigemPedido: ${pedido.idTipoOrigemPedido}'); // ← confirma o valor
  print('🏁 [NAV] idTipoEntrega: ${pedido.idTipoEntrega}');

 final finalizado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => FinalizarPedidoScreen(pedido: pedido),
    ),
  );

  // Verifique se o widget ainda está na árvore antes de recarregar ou limpar
  if (finalizado == true && mounted) {
    print('✅ [NAV] Pedido finalizado — recarregando lista');
    PedidoAtivoController.instance.limpar();
    await _carregarPedidos();
  }
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
        title: const Text(
          'Pedidos por Finalizar',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _carregarPedidos,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
          body: Stack(
      children: [
        _buildBody(),
        PedidoAtivoBanner(
          onDesativado: _carregarPedidos,
        ),
      ],
    ),
     );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('A carregar pedidos...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregarPedidos,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhum pedido por finalizar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os pedidos criados aparecerão aqui.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) => _buildCardPedido(_pedidos[index]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CARD DO PEDIDO
  // ════════════════════════════════════════════════════════════════════════

Widget _buildCardPedido(Pedido pedido) {
  return Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: pedido.ativo ? Colors.green[300]! : Colors.grey[200]!,
        width: pedido.ativo ? 2 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Cabeçalho com toggle ─────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (pedido.ativo ? Colors.green : const Color(0xFF1A1A2E))
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pedido.ativo ? Icons.check_circle : Icons.receipt_outlined,
                  color: pedido.ativo ? Colors.green : const Color(0xFF1A1A2E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.reference ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        )),
                    const SizedBox(height: 3),
                    Text(
                      pedido.dataPedido != null
                          ? _formatarData(pedido.dataPedido!)
                          : '—',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // ── Toggle de ativação ──
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: pedido.ativo,
                  onChanged: _operacaoEmAndamento
                      ? null
                      : (_) => _toggleAtivacao(pedido),
                  activeColor: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 14),

          // ─── Itens com controlos ──────────────────────────────────
          if (pedido.itens.isNotEmpty) ...[
            ...pedido.itens.map((item) => _buildLinhaItemEditavel(pedido, item)),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),
          ],

          // ─── Total + Ações ─────────────────────────────────────
          Row(
            children: [
              // Botão Cancelar (Ação secundária à esquerda)
              OutlinedButton.icon(
                onPressed: _operacaoEmAndamento
                    ? null
                    : () => _cancelarPedido(pedido),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const Spacer(),
              // Grupo Total + Finalizar (Foco visual à direita)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  Text('MZN ${pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      )),
                ],
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _operacaoEmAndamento
                    ? null
                    : () => _abrirFinalizarPedido(pedido),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Finalizar', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBadgeStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 12, color: Colors.amber[700]),
          const SizedBox(width: 4),
          Text(
            'Por finalizar',
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildLinhaItemEditavel(Pedido pedido, ItemPedido item) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        // ── Botão diminuir ──
        _botaoQuantidadePequeno(
          icon: Icons.remove,
          onTap: item.quantidade > 1 && !_operacaoEmAndamento
              ? () => _editarQuantidade(pedido, item, item.quantidade - 1)
              : null,
        ),
        const SizedBox(width: 8),

        // ── Campo de quantidade editável ──
        GestureDetector(
          onTap: _operacaoEmAndamento
              ? null
              : () => _mostrarDialogoEditarQuantidade(pedido, item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '${item.quantidade}x',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ── Botão aumentar ──
        _botaoQuantidadePequeno(
          icon: Icons.add,
          onTap: !_operacaoEmAndamento
              ? () => _editarQuantidade(pedido, item, item.quantidade + 1)
              : null,
        ),
        const SizedBox(width: 12),

        // ── Nome do produto ──
        Expanded(
          child: Text(
            item.nomeProduto,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // ── Subtotal ──
        Text(
          'MZN ${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),

        // ── Botão eliminar ──
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: Colors.red,
          onPressed:
              _operacaoEmAndamento ? null : () => _eliminarItem(pedido, item),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );
}

Widget _botaoQuantidadePequeno({required IconData icon, VoidCallback? onTap}) {
  final habilitado = onTap != null;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: habilitado ? const Color(0xFF1A1A2E) : Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon,
          size: 16, color: habilitado ? Colors.white : Colors.grey[500]),
    ),
  );
}

Future<void> _mostrarDialogoEditarQuantidade(
    Pedido pedido, ItemPedido item) async {
  final controller = TextEditingController(text: item.quantidade.toString());

  final novaQtd = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar Quantidade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.nomeProduto,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantidade',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final qtd = int.tryParse(controller.text);
            if (qtd != null && qtd > 0) {
              Navigator.pop(ctx, qtd);
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  if (novaQtd != null && novaQtd != item.quantidade) {
    await _editarQuantidade(pedido, item, novaQtd);
  }
}

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diff = agora.difference(data);

    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}