package com.loja1.projectohibrido.pedido.service;


import com.loja1.projectohibrido.pedido.dto.*;
import com.loja1.projectohibrido.pedido.entity.*;
import com.loja1.projectohibrido.pedido.exception.*;
import com.loja1.projectohibrido.pedido.repository.*;
import com.loja1.projectohibrido.produto.entity.Produto;
import com.loja1.projectohibrido.produto.repository.ProdutoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class PedidoService {

    // ─── Repositórios injectados ─────────────────────────────────────────────
    private final PedidoRepository             pedidoRepository;
    private final ItemPedidoRepository         itemPedidoRepository;
    private final PedidoCancelamentoRepository cancelamentoRepository;
    private final ProdutoRepository            produtoRepository;
    private final TipoEntregaRepository        tipoEntregaRepository;

    // ─── Status permitidos para edição ───────────────────────────────────────
    private static final List<String> STATUS_EDITAVEIS = List.of(
        "por finalizar", "pendente", "em preparacao"
    );

    // ════════════════════════════════════════════════════════════════════════
    // a) CRIAÇÃO DO PEDIDO
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Cria um pedido com os itens iniciais.
     *
     * ESTOQUE: desconta imediatamente sem registar movimentação.
     * TRANSAÇÃO: tudo em bloco — se qualquer item falhar, reverte tudo.
     */
@Transactional
public PedidoResponseDTO criarPedido(PedidoRequestDTO dto) {
    log.info("Criando pedido para usuário {}", dto.idUsuario);

    // ── NOVO: desactiva qualquer pedido activo anterior ───────────────────
    pedidoRepository.desativarPedidosDoUsuario(dto.idUsuario);

    Pedido pedido = Pedido.builder()
                .reference(gerarReference())
                .idUsuario(dto.idUsuario)
                .telefone(dto.telefone)
                .email(dto.email)
                .idTipoPagamento(dto.idTipoPagamento)
                .idTipoEntrega(dto.idTipoEntrega)
                .idTipoOrigemPedido(dto.idTipoOrigemPedido)
                .dataPedido(LocalDateTime.now())
                .statusPedido("por finalizar")
                 .ativo(true)          
                .notificacaoVista((short) 0)
                .total(BigDecimal.ZERO)       // recalculado abaixo
                .enderecoJson(dto.enderecoJson)
                .bairro(dto.bairro)
                .pontoReferencia(dto.pontoReferencia)
                .valorPagoManual(BigDecimal.ZERO)
                .troco(BigDecimal.ZERO)
                .ocultoCliente((short) 0)
            
                .build();

        // 2. Persistir pedido para obter ID (necessário para os itens)
        pedido = pedidoRepository.save(pedido);

        // 3. Processar cada item — validar estoque e descontar
        for (ItemPedidoRequestDTO itemDto : dto.itens) {
            adicionarItemInterno(pedido, itemDto.idProduto, itemDto.quantidade);
        }

        // 4. Recalcular total com base nos itens
        pedido.recalcularTotal();
        pedido = pedidoRepository.save(pedido);

        log.info("Pedido {} criado com {} itens | Total: {}",
                pedido.getReference(), pedido.getItens().size(), pedido.getTotal());

        return toResponseDTO(pedido);
    }

    @Transactional(readOnly = true)
public TipoEntregaResponseDTO buscarTipoEntrega(Integer id) {
    TipoEntrega te = tipoEntregaRepository.findById(id)
        .orElseThrow(() -> new RuntimeException("TipoEntrega não encontrado: " + id));
    TipoEntregaResponseDTO dto = new TipoEntregaResponseDTO();
    dto.idTipoEntrega   = te.getIdTipoEntrega();
    dto.nomeTipoEntrega = te.getNomeTipoEntrega();
    dto.precoAdicional  = te.getPrecoAdicional();
    return dto;
}

    @Transactional(readOnly = true)
public Optional<PedidoResponseDTO> buscarPedidoAtivo(Integer idUsuario) {
    return pedidoRepository
            .findByIdUsuarioAndAtivoTrue(idUsuario)
            .map(this::toResponseDTO);
}


// ─── Método novo: desativar pedido ──────────────────────────────────────
@Transactional
public void desativarPedido(Integer idPedido) {
    Pedido pedido = buscarPedidoComItens(idPedido);
    pedido.setAtivo(false);
    pedidoRepository.save(pedido);
    log.info("Pedido {} desactivado", pedido.getReference());
}

    // ════════════════════════════════════════════════════════════════════════
    // b) ADICIONAR ITEM AO PEDIDO
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Adiciona um novo produto a um pedido existente.
     *
     * ESTOQUE: desconta a quantidade solicitada sem registar movimentação.
     * VALIDAÇÃO: pedido deve estar em status editável.
     */
@Transactional
public PedidoResponseDTO adicionarItem(Integer idPedido, ItemPedidoRequestDTO dto) {
    Pedido pedido = buscarPedidoComItens(idPedido);
    validarStatusEditavel(pedido, "adição de item");

    // ── NOVO: garante que só se adicionam itens ao pedido activo ──────────
    if (!Boolean.TRUE.equals(pedido.getAtivo())) {
        throw new StatusPedidoInvalidoException(
            pedido.getStatusPedido(),
            "adição de item — pedido não está activo"
        );
    }

    adicionarItemInterno(pedido, dto.idProduto, dto.quantidade);
    pedido.recalcularTotal();
    pedidoRepository.save(pedido);

    log.info("Item produto {} adicionado ao pedido activo {}", dto.idProduto, idPedido);
    return toResponseDTO(pedido);
}
    // ════════════════════════════════════════════════════════════════════════
    // c) EDITAR QUANTIDADE DE UM ITEM
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Altera a quantidade de um item já existente.
     *
     * ESTOQUE:
     *   - Se aumentar: desconta a diferença do estoque.
     *   - Se reduzir:  devolve a diferença ao estoque.
     *   Nenhum dos casos regista movimentação.
     *
     * TRANSAÇÃO: operação atómica — falha em qualquer ponto reverte tudo.
     */
    @Transactional
    public PedidoResponseDTO editarQuantidadeItem(
            Integer idPedido,
            Integer idItemPedido,
            EditarItemRequestDTO dto) {

        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "edição de item");

        ItemPedido item = itemPedidoRepository
                .findByIdItemPedidoAndPedidoIdPedido(idItemPedido, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemPedido, idPedido));

        Produto produto = item.getProduto();
        int quantidadeAnterior = item.getQuantidade();
        int novaQuantidade     = dto.novaQuantidade;
        int diferenca          = novaQuantidade - quantidadeAnterior;

        if (diferenca > 0) {
            // Aumento: precisa de mais estoque
            garantirEstoqueDisponivel(produto, diferenca);
            ajustarEstoqueSemMovimento(produto, -diferenca);           // desconta
            log.info("Estoque produto {} decrementado em {} (edição de pedido)", produto.getIdProduto(), diferenca);

        } else if (diferenca < 0) {
            // Redução: devolve estoque
            int devolucao = Math.abs(diferenca);
            ajustarEstoqueSemMovimento(produto, devolucao);             // devolve
            log.info("Estoque produto {} incrementado em {} (redução de item)", produto.getIdProduto(), devolucao);
        }
        // diferenca == 0 → nada a fazer no estoque

        item.setQuantidade(novaQuantidade);
        item.recalcularSubtotal();
        itemPedidoRepository.save(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item {} do pedido {} alterado: {} → {} unidades",
                idItemPedido, idPedido, quantidadeAnterior, novaQuantidade);

        return toResponseDTO(pedido);
    }


@Transactional
public PedidoResponseDTO finalizarPedido(Integer idPedido, FinalizarPedidoRequestDTO dto) {
    Pedido pedido = buscarPedidoComItens(idPedido);
    log.info("[FINALIZAR] Pedido {} — início da finalização", pedido.getReference());

    if ("finalizado".equalsIgnoreCase(pedido.getStatusPedido()) ||
        "cancelado".equalsIgnoreCase(pedido.getStatusPedido())) {
        throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), "finalização");
    }

    // ── 1. Tipo de pagamento ─────────────────────────────────────────────
    pedido.setIdTipoPagamento(dto.idTipoPagamento);
    log.info("[FINALIZAR] Pagamento: idTipoPagamento={}", dto.idTipoPagamento);

    // ── 2. Troco (apenas dinheiro — idTipoPagamento == 1) ────────────────
    BigDecimal totalFinal = pedido.getTotal();

    if (dto.idTipoPagamento == 1) {
        if (dto.valorPago == null || dto.valorPago.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Valor pago é obrigatório para pagamento em dinheiro");
        }
        pedido.setValorPagoManual(dto.valorPago);
        BigDecimal troco = dto.valorPago.subtract(totalFinal);
        pedido.setTroco(troco.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : troco);
        log.info("[FINALIZAR] Dinheiro — pago: {} | troco: {}", dto.valorPago, pedido.getTroco());
    } else {
        pedido.setValorPagoManual(BigDecimal.ZERO);
        pedido.setTroco(BigDecimal.ZERO);
        log.info("[FINALIZAR] Pagamento sem troco (tipo {})", dto.idTipoPagamento);
    }

    // ── 3. Entrega (apenas Loja Física — idTipoOrigemPedido == 2) ────────
    if (Integer.valueOf(2).equals(pedido.getIdTipoOrigemPedido())) {
        int idEntrega = dto.idTipoEntrega != null ? dto.idTipoEntrega : 1;
        pedido.setIdTipoEntrega(idEntrega);
        log.info("[FINALIZAR] Loja Física — idTipoEntrega={}", idEntrega);

if (idEntrega == 2) {
    TipoEntrega tipoEntrega = tipoEntregaRepository.findById(idEntrega)
        .orElseThrow(() -> new RuntimeException("TipoEntrega não encontrado: " + idEntrega));

    BigDecimal adicional = tipoEntrega.getPrecoAdicional() != null
        ? tipoEntrega.getPrecoAdicional() : BigDecimal.ZERO;

    totalFinal = totalFinal.add(adicional);
    pedido.setTotal(totalFinal);
    log.info("[FINALIZAR] Delivery — adicional: {} | total final: {}", adicional, totalFinal);

    // Recalcula troco com total atualizado (se dinheiro)
    if (dto.idTipoPagamento == 1 && dto.valorPago != null) {
        BigDecimal trocoAtualizado = dto.valorPago.subtract(totalFinal);
        pedido.setTroco(trocoAtualizado.compareTo(BigDecimal.ZERO) < 0
            ? BigDecimal.ZERO : trocoAtualizado);
        log.info("[FINALIZAR] Troco recalculado após delivery: {}", pedido.getTroco());
    }

    pedido.setNomeCliente(dto.nomeCliente);
    pedido.setApelidoCliente(dto.apelidoCliente);
    pedido.setEnderecoJson(dto.enderecoJson);
    pedido.setBairro(dto.bairro);
    pedido.setPontoReferencia(dto.pontoReferencia);
    log.info("[FINALIZAR] Cliente: {} {} | adicional vindo da BD: {}",
             dto.nomeCliente, dto.apelidoCliente, adicional);
}}

    // ── 4. Finalizar ─────────────────────────────────────────────────────
    pedido.setStatusPedido("finalizado");
    pedido.setAtivo(false);
    pedido.setDataFinalizacao(LocalDateTime.now());
    pedido.setDataFimPedido(LocalDateTime.now());
    pedidoRepository.save(pedido);

    log.info("[FINALIZAR] Pedido {} finalizado com sucesso | total: {}", 
             pedido.getReference(), pedido.getTotal());

    return toResponseDTO(pedido);
}

    // ════════════════════════════════════════════════════════════════════════
    // d) ELIMINAR ITEM DO PEDIDO
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Remove um item do pedido e devolve a sua quantidade ao estoque.
     *
     * ESTOQUE: devolução imediata sem movimentação.
     */
    @Transactional
    public PedidoResponseDTO eliminarItem(Integer idPedido, Integer idItemPedido) {
        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "eliminação de item");

        ItemPedido item = itemPedidoRepository
                .findByIdItemPedidoAndPedidoIdPedido(idItemPedido, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemPedido, idPedido));

        Produto produto = item.getProduto();
        int quantidadeDevolver = item.getQuantidade();

        // Devolve ao estoque sem registar movimento
        ajustarEstoqueSemMovimento(produto, quantidadeDevolver);

        pedido.getItens().remove(item);
        itemPedidoRepository.delete(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item {} eliminado do pedido {}. Estoque produto {} restaurado em {}",
                idItemPedido, idPedido, produto.getIdProduto(), quantidadeDevolver);

        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // e) CANCELAR PEDIDO
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Cancela o pedido integralmente e restaura o estoque de todos os itens.
     *
     * ESTOQUE: restaurado ao valor original (antes da criação do pedido)
     *          sem registar qualquer movimentação.
     *
     * TRANSAÇÃO: atómica — ou cancela tudo ou não cancela nada.
     */
    @Transactional
    public void cancelarPedido(Integer idPedido, CancelamentoPedidoRequestDTO dto) {
        Pedido pedido = buscarPedidoComItens(idPedido);

        if ("cancelado".equalsIgnoreCase(pedido.getStatusPedido())) {
            throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), "cancelamento");
        }

        // 1. Restaurar estoque de cada item sem movimentação
        for (ItemPedido item : pedido.getItens()) {
            Produto produto = item.getProduto();
            ajustarEstoqueSemMovimento(produto, item.getQuantidade());
            log.info("Cancelamento pedido {}: estoque produto {} restaurado em {}",
                    idPedido, produto.getIdProduto(), item.getQuantidade());
        }

        // 2. Actualizar status do pedido
        pedido.setStatusPedido("cancelado");
         pedido.setAtivo(false);   
        pedido.setDataFimPedido(LocalDateTime.now());
        pedidoRepository.save(pedido);

        // 3. Registar o cancelamento na tabela dedicada
        PedidoCancelamento cancelamento = PedidoCancelamento.builder()
                .pedido(pedido)
                .motivo(dto.motivo)
                .idUsuarioCancelou(dto.idUsuarioCancelou)
                .dataCancelamento(LocalDateTime.now())
                .build();

        cancelamentoRepository.save(cancelamento);

        log.info("Pedido {} cancelado por usuário {}", pedido.getReference(), dto.idUsuarioCancelou);
    }

    // ════════════════════════════════════════════════════════════════════════
    // CONSULTAS
    // ════════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public PedidoResponseDTO buscarPorId(Integer idPedido) {
        return toResponseDTO(buscarPedidoComItens(idPedido));
    }

    @Transactional(readOnly = true)
    public List<PedidoResponseDTO> listarPorUsuario(Integer idUsuario) {
        return pedidoRepository
                .findByIdUsuarioOrderByDataPedidoDesc(idUsuario)
                .stream()
                .map(this::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PedidoResponseDTO> listarPorStatus(String status) {
        return pedidoRepository
                .findByStatusPedidoOrderByDataPedidoDesc(status)
                .stream()
                .map(this::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional
public PedidoResponseDTO ativarPedido(Integer idPedido) {
    Pedido pedido = buscarPedidoComItens(idPedido);

    log.info("[ATIVAR] Pedido {} — solicitação de ativação. Usuário: {}", 
             pedido.getReference(), pedido.getIdUsuario());

    // Desativa todos os outros pedidos do mesmo usuário
    int desativados = pedidoRepository.desativarPedidosDoUsuario(pedido.getIdUsuario());
    log.info("[ATIVAR] {} pedido(s) anteriores desativados para usuário {}", 
             desativados, pedido.getIdUsuario());

    // Ativa o pedido solicitado
    pedido.setAtivo(true);
    pedidoRepository.save(pedido);

    log.info("[ATIVAR] Pedido {} marcado como ativo com sucesso", pedido.getReference());

    return toResponseDTO(pedido);
}

    // ════════════════════════════════════════════════════════════════════════
    // MÉTODOS PRIVADOS — LÓGICA INTERNA
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Lógica interna reutilizada em criarPedido() e adicionarItem().
     * Valida estoque, cria o ItemPedido e desconta o estoque.
     */
    private void adicionarItemInterno(Pedido pedido, Integer idProduto, Integer quantidade) {
        Produto produto = produtoRepository.findById(idProduto)
                .orElseThrow(() -> new RuntimeException("Produto não encontrado: " + idProduto));

        garantirEstoqueDisponivel(produto, quantidade);

        // Preço efectivo: promocional se existir, senão normal
        BigDecimal precoUnitario = produto.getPrecoPromocional() != null
                ? produto.getPrecoPromocional()
                : produto.getPreco();

        ItemPedido item = ItemPedido.builder()
                .pedido(pedido)
                .produto(produto)
                .quantidade(quantidade)
                .precoUnitario(precoUnitario)
                .subtotal(precoUnitario.multiply(BigDecimal.valueOf(quantidade)))
                .build();

        itemPedidoRepository.save(item);
        pedido.getItens().add(item);

        // Desconta estoque sem registar movimentação
        ajustarEstoqueSemMovimento(produto, -quantidade);

        log.info("Item criado — produto '{}' | qty: {} | preço: {}",
                produto.getNomeProduto(), quantidade, precoUnitario);
    }

    /**
     * Ajusta o estoque directamente na entidade e persiste.
     * NÃO regista movimento na tabela movimento_estoque.
     *
     * @param delta positivo = acrescenta | negativo = desconta
     */
 private void ajustarEstoqueSemMovimento(Produto produto, int delta) {
    int estoqueActual = produto.getQuantidadeEstoque();
    int novaQuantidade = estoqueActual + delta;

    if (novaQuantidade < 0) {
        throw new EstoqueInsuficienteException(
            produto.getNomeProduto(),
            estoqueActual,
            Math.abs(delta)
        );
    }

    // Update atómico directo — flushAutomatically garante que o pedido
    // é persistido ANTES, clearAutomatically limpa o cache DEPOIS
    produtoRepository.ajustarEstoque(produto.getIdProduto(), delta);

    // Actualiza a instância em memória para validações na mesma transacção
    produto.setQuantidadeEstoque(novaQuantidade);

    log.debug("Estoque produto {} ajustado: {} → {} (delta: {})",
        produto.getIdProduto(), estoqueActual, novaQuantidade, delta);
}

    /**
     * Verifica se há quantidade suficiente disponível no estoque
     * antes de tentar qualquer operação.
     */
    private void garantirEstoqueDisponivel(Produto produto, int quantidadeSolicitada) {
        if (produto.getQuantidadeEstoque() < quantidadeSolicitada) {
            throw new EstoqueInsuficienteException(
                produto.getNomeProduto(),
                produto.getQuantidadeEstoque(),
                quantidadeSolicitada
            );
        }
    }

    /**
     * Valida se o status do pedido permite a operação solicitada.
     */
    private void validarStatusEditavel(Pedido pedido, String operacao) {
        if (!STATUS_EDITAVEIS.contains(pedido.getStatusPedido())) {
            throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), operacao);
        }
    }

    /**
     * Busca pedido com itens carregados em uma única query (evita N+1).
     */
    private Pedido buscarPedidoComItens(Integer idPedido) {
        return pedidoRepository.findByIdComItens(idPedido)
                .orElseThrow(() -> new PedidoNaoEncontradoException(idPedido));
    }

    /**
     * Gera uma referência única para o pedido.
     */
    private String gerarReference() {
        return "PED-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    // ════════════════════════════════════════════════════════════════════════
    // MAPEAMENTO ENTITY → DTO
    // ════════════════════════════════════════════════════════════════════════

    private PedidoResponseDTO toResponseDTO(Pedido pedido) {
        PedidoResponseDTO dto = new PedidoResponseDTO();
        dto.idPedido          = pedido.getIdPedido();
        dto.reference         = pedido.getReference();
        dto.idUsuario         = pedido.getIdUsuario();
        dto.telefone          = pedido.getTelefone();
        dto.email             = pedido.getEmail();
        dto.idTipoPagamento   = pedido.getIdTipoPagamento();
        dto.idTipoEntrega     = pedido.getIdTipoEntrega();
        dto.idTipoOrigemPedido= pedido.getIdTipoOrigemPedido();
        dto.dataPedido        = pedido.getDataPedido();
        dto.statusPedido      = pedido.getStatusPedido();
        dto.total             = pedido.getTotal();
        dto.enderecoJson      = pedido.getEnderecoJson();
        dto.bairro            = pedido.getBairro();
        dto.pontoReferencia   = pedido.getPontoReferencia();
        dto.troco             = pedido.getTroco();
        dto.ativo = pedido.getAtivo();
        dto.valorPagoManual = pedido.getValorPagoManual();
        dto.nomeCliente     = pedido.getNomeCliente();
        dto.apelidoCliente  = pedido.getApelidoCliente();
        dto.itens = pedido.getItens().stream()
                .map(this::toItemResponseDTO)
                .collect(Collectors.toList());

        return dto;
    }

    private ItemPedidoResponseDTO toItemResponseDTO(ItemPedido item) {
        ItemPedidoResponseDTO dto = new ItemPedidoResponseDTO();
        dto.idItemPedido  = item.getIdItemPedido();
        dto.idProduto     = item.getProduto().getIdProduto();
        dto.nomeProduto   = item.getProduto().getNomeProduto();
        dto.quantidade    = item.getQuantidade();
        dto.precoUnitario = item.getPrecoUnitario();
        dto.subtotal      = item.getSubtotal();
        return dto;
    }
}