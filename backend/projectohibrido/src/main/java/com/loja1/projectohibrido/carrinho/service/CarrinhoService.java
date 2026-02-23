package com.loja1.projectohibrido.carrinho.service;

import com.loja1.projectohibrido.carrinho.dto.AdicionarItemRequest;
import com.loja1.projectohibrido.carrinho.dto.AtualizarQuantidadeRequest;
import com.loja1.projectohibrido.carrinho.dto.CarrinhoDTO;
import com.loja1.projectohibrido.carrinho.dto.ItemCarrinhoDTO;
import com.loja1.projectohibrido.carrinho.entity.Carrinho;
import com.loja1.projectohibrido.carrinho.entity.ItemCarrinho;
import com.loja1.projectohibrido.carrinho.exception.CarrinhoJaConvertidoException;
import com.loja1.projectohibrido.carrinho.exception.CarrinhoNotFoundException;
import com.loja1.projectohibrido.carrinho.exception.CarrinhoVazioException;
import com.loja1.projectohibrido.carrinho.exception.EstoqueInsuficienteException;
import com.loja1.projectohibrido.carrinho.exception.ItemCarrinhoNotFoundException;
import com.loja1.projectohibrido.carrinho.repository.CarrinhoRepository;
import com.loja1.projectohibrido.carrinho.repository.ItemCarrinhoRepository;
import com.loja1.projectohibrido.pedido.dto.PedidoRequestDTO;
import com.loja1.projectohibrido.pedido.dto.PedidoResponseDTO;
import com.loja1.projectohibrido.pedido.service.PedidoService;
import com.loja1.projectohibrido.produto.entity.Produto;
import com.loja1.projectohibrido.produto.repository.ProdutoImagemRepository;
import com.loja1.projectohibrido.produto.repository.ProdutoRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CarrinhoService {

    private final CarrinhoRepository     carrinhoRepo;
    private final ItemCarrinhoRepository  itemRepo;
    private final ProdutoRepository       produtoRepo;
    private final ProdutoImagemRepository produtoImagemRepo; // ← resolve imagem sem alterar Produto.java
    private final PedidoService           pedidoService;

    // ─────────────────────────────────────────────────────────────────────────
    // Criação
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cria um carrinho para utilizador autenticado ou guest.
     * Se já existir um carrinho activo para o utilizador/session, retorna-o
     * sem criar duplicados.
     */
    @Transactional
    public CarrinhoDTO criarCarrinho(Integer idUsuario, String sessionId) {

        // Utilizador autenticado: devolve carrinho activo existente ou cria um novo
        if (idUsuario != null) {
            return carrinhoRepo.findByIdUsuarioAndStatus(idUsuario, "activo")
                    .map(this::toDTO)
                    .orElseGet(() -> toDTO(carrinhoRepo.save(novoCarrinhoAutenticado(idUsuario))));
        }

        // Guest: devolve carrinho activo existente pelo sessionId ou cria com novo sessionId
        String sid = (sessionId != null && !sessionId.isBlank())
                ? sessionId
                : UUID.randomUUID().toString();

        return carrinhoRepo.findBySessionIdAndStatus(sid, "activo")
                .map(this::toDTO)
                .orElseGet(() -> toDTO(carrinhoRepo.save(novoCarrinhoGuest(sid))));
    }

    private Carrinho novoCarrinhoAutenticado(Integer idUsuario) {
        Carrinho c = new Carrinho();
        c.setIdUsuario(idUsuario);
        c.setStatus("activo");
        c.setDataCriacao(LocalDateTime.now());
        c.setItens(new ArrayList<>());
        return c;
    }

    private Carrinho novoCarrinhoGuest(String sessionId) {
        Carrinho c = new Carrinho();
        c.setSessionId(sessionId);
        c.setStatus("activo");
        c.setDataCriacao(LocalDateTime.now());
        c.setItens(new ArrayList<>());
        return c;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Adicionar / Atualizar item
    // ─────────────────────────────────────────────────────────────────────────

    @Transactional
    public CarrinhoDTO adicionarOuAtualizarItem(Integer idCarrinho, AdicionarItemRequest req) {

        Carrinho carrinho = carrinhoRepo.findByIdWithItens(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));

        validarCarrinhoActivo(carrinho);

        // Busca produto directamente pelo ProdutoRepository existente (sem lock aqui —
        // o lock pessimista só é necessário na conversão para pedido, onde o estoque é descontado)
        Produto produto = produtoRepo.findById(req.getIdProduto())
                .orElseThrow(() -> new EntityNotFoundException(
                        "Produto não encontrado: " + req.getIdProduto()));

        Optional<ItemCarrinho> itemExistente = carrinho.getItens().stream()
                .filter(i -> i.getProduto().getIdProduto().equals(req.getIdProduto()))
                .findFirst();

        int quantidadeTotal = itemExistente
                .map(i -> i.getQuantidade() + req.getQuantidade())
                .orElse(req.getQuantidade());

        validarEstoque(produto, quantidadeTotal);

        BigDecimal preco = resolverPreco(produto);

        if (itemExistente.isPresent()) {
            ItemCarrinho item = itemExistente.get();
            item.setQuantidade(quantidadeTotal);
            item.setSubtotal(preco.multiply(BigDecimal.valueOf(quantidadeTotal)));
        } else {
            ItemCarrinho novoItem = new ItemCarrinho();
            novoItem.setCarrinho(carrinho);
            novoItem.setProduto(produto);
            novoItem.setQuantidade(quantidadeTotal);
            novoItem.setSubtotal(preco.multiply(BigDecimal.valueOf(quantidadeTotal)));
            carrinho.getItens().add(novoItem);
        }

        return toDTO(carrinhoRepo.save(carrinho));
    }

    /**
     * Define uma quantidade exata para um item já existente (substitui, não soma).
     */
    @Transactional
    public CarrinhoDTO atualizarQuantidade(Integer idCarrinho, Integer idProduto,
                                           AtualizarQuantidadeRequest req) {

        Carrinho carrinho = carrinhoRepo.findByIdWithItens(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));

        validarCarrinhoActivo(carrinho);

        ItemCarrinho item = carrinho.getItens().stream()
                .filter(i -> i.getProduto().getIdProduto().equals(idProduto))
                .findFirst()
                .orElseThrow(() -> new ItemCarrinhoNotFoundException(idCarrinho, idProduto));

        Produto produto = produtoRepo.findById(idProduto)
                .orElseThrow(() -> new EntityNotFoundException("Produto não encontrado: " + idProduto));

        validarEstoque(produto, req.getQuantidade());

        BigDecimal preco = resolverPreco(produto);
        item.setQuantidade(req.getQuantidade());
        item.setSubtotal(preco.multiply(BigDecimal.valueOf(req.getQuantidade())));

        return toDTO(carrinhoRepo.save(carrinho));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Remoção
    // ─────────────────────────────────────────────────────────────────────────

    @Transactional
    public void removerItem(Integer idCarrinho, Integer idProduto) {

        Carrinho carrinho = carrinhoRepo.findByIdWithItens(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));

        validarCarrinhoActivo(carrinho);

        int removidos = itemRepo.deleteByCarrinhoAndProduto(idCarrinho, idProduto);
        if (removidos == 0) {
            throw new ItemCarrinhoNotFoundException(idCarrinho, idProduto);
        }

        // Regra 4: se era o último item, elimina o carrinho
        long restantes = itemRepo.countByCarrinhoIdCarrinho(idCarrinho);
        if (restantes == 0) {
            carrinhoRepo.delete(carrinho);
        }
    }

    @Transactional
    public void removerCarrinho(Integer idCarrinho) {
        Carrinho carrinho = carrinhoRepo.findById(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));
        itemRepo.deleteAllByCarrinhoId(idCarrinho);
        carrinhoRepo.delete(carrinho);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Conversão para Pedido
    // ─────────────────────────────────────────────────────────────────────────

    @Transactional
    public PedidoResponseDTO converterEmPedido(Integer idCarrinho, PedidoRequestDTO pedidoReq) {

        // Lock pessimista no carrinho — impede dupla conversão concorrente
        Carrinho carrinho = carrinhoRepo.findByIdWithLock(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));

        validarCarrinhoActivo(carrinho);

        // Recarrega os itens via JOIN FETCH (findByIdWithLock não os traz)
        carrinho = carrinhoRepo.findByIdWithItens(idCarrinho)
                .orElseThrow(() -> new CarrinhoNotFoundException(idCarrinho));

        if (carrinho.getItens().isEmpty()) {
            throw new CarrinhoVazioException(idCarrinho);
        }

        // Valida estoque e desconta usando o método existente no ProdutoRepository
        for (ItemCarrinho itemCarrinho : carrinho.getItens()) {
            Integer idProduto = itemCarrinho.getProduto().getIdProduto();
            Produto produto   = produtoRepo.findById(idProduto).orElseThrow(() ->
                    new EntityNotFoundException("Produto não encontrado: " + idProduto));

            if (produto.getQuantidadeEstoque() < itemCarrinho.getQuantidade()) {
                throw new EstoqueInsuficienteException(
                        idProduto,
                        produto.getNomeProduto(),
                        produto.getQuantidadeEstoque(),
                        itemCarrinho.getQuantidade()
                );
            }

            // Usa o método existente no ProdutoRepository para descontar o estoque
            produtoRepo.ajustarEstoque(idProduto, -itemCarrinho.getQuantidade());
        }

        // Delega criação do pedido ao PedidoService (que conhece as suas próprias regras)
        PedidoResponseDTO pedidoDTO = pedidoService.criarPedidoAPartirDoCarrinho(pedidoReq, carrinho);

        // Marca carrinho como convertido — preserva histórico, evita re-uso
        carrinho.setStatus("convertido");
        carrinhoRepo.save(carrinho);

        return pedidoDTO;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mesclagem Guest → Autenticado
    // ─────────────────────────────────────────────────────────────────────────

    @Transactional
    public CarrinhoDTO mesclarCarrinhos(String sessionId, Integer idUsuario) {

        Optional<Carrinho> guestOpt = carrinhoRepo.findBySessionIdAndStatusWithItens(sessionId, "activo");

        // Sem carrinho guest: devolve ou cria o carrinho do utilizador
        if (guestOpt.isEmpty()) {
            return carrinhoRepo.findByIdUsuarioAndStatus(idUsuario, "activo")
                    .map(this::toDTO)
                    .orElseGet(() -> criarCarrinho(idUsuario, null));
        }

        Carrinho guest = guestOpt.get();

        Optional<Carrinho> userCartOpt = carrinhoRepo.findByIdUsuarioAndStatusWithItens(idUsuario, "activo");

        // Sem carrinho de utilizador existente: associa o carrinho guest ao utilizador
        if (userCartOpt.isEmpty()) {
            guest.setIdUsuario(idUsuario);
            guest.setSessionId(null);
            return toDTO(carrinhoRepo.save(guest));
        }

        Carrinho userCart = userCartOpt.get();

        // Ambos existem: mescla itens
        for (ItemCarrinho guestItem : guest.getItens()) {
            Integer idProduto = guestItem.getProduto().getIdProduto();

            Produto produto = produtoRepo.findById(idProduto)
                    .orElseThrow(() -> new EntityNotFoundException("Produto não encontrado: " + idProduto));

            Optional<ItemCarrinho> existingOpt = userCart.getItens().stream()
                    .filter(i -> i.getProduto().getIdProduto().equals(idProduto))
                    .findFirst();

            int novaQtd = guestItem.getQuantidade()
                    + existingOpt.map(ItemCarrinho::getQuantidade).orElse(0);

            // Limita ao estoque disponível em vez de lançar excepção — melhor UX na mesclagem
            novaQtd = Math.min(novaQtd, produto.getQuantidadeEstoque());

            if (novaQtd <= 0) continue; // produto sem estoque: ignorado na mesclagem

            BigDecimal preco = resolverPreco(produto);

            if (existingOpt.isPresent()) {
                ItemCarrinho existing = existingOpt.get();
                existing.setQuantidade(novaQtd);
                existing.setSubtotal(preco.multiply(BigDecimal.valueOf(novaQtd)));
            } else {
                ItemCarrinho novoItem = new ItemCarrinho();
                novoItem.setCarrinho(userCart);
                novoItem.setProduto(produto);
                novoItem.setQuantidade(novaQtd);
                novoItem.setSubtotal(preco.multiply(BigDecimal.valueOf(novaQtd)));
                userCart.getItens().add(novoItem);
            }
        }

        carrinhoRepo.delete(guest);
        return toDTO(carrinhoRepo.save(userCart));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ─────────────────────────────────────────────────────────────────────────

    private void validarCarrinhoActivo(Carrinho carrinho) {
        if ("convertido".equalsIgnoreCase(carrinho.getStatus())) {
            throw new CarrinhoJaConvertidoException(carrinho.getIdCarrinho());
        }
    }

    private void validarEstoque(Produto produto, int quantidadeSolicitada) {
        if (produto.getQuantidadeEstoque() < quantidadeSolicitada) {
            throw new EstoqueInsuficienteException(
                    produto.getIdProduto(),
                    produto.getNomeProduto(),
                    produto.getQuantidadeEstoque(),
                    quantidadeSolicitada
            );
        }
    }

    private BigDecimal resolverPreco(Produto produto) {
        return produto.getPrecoPromocional() != null
                ? produto.getPrecoPromocional()
                : produto.getPreco();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mapeamento Entidade → DTO
    // ─────────────────────────────────────────────────────────────────────────

    private CarrinhoDTO toDTO(Carrinho carrinho) {
        List<ItemCarrinhoDTO> itensDTO = carrinho.getItens() == null
                ? new ArrayList<>()
                : carrinho.getItens().stream()
                          .map(this::toItemDTO)
                          .collect(Collectors.toList());

        BigDecimal total = itensDTO.stream()
                .map(ItemCarrinhoDTO::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CarrinhoDTO(
                carrinho.getIdCarrinho(),
                carrinho.getIdUsuario(),
                carrinho.getSessionId(),
                carrinho.getStatus(),
                carrinho.getDataCriacao(),
                itensDTO,
                total
        );
    }

    private ItemCarrinhoDTO toItemDTO(ItemCarrinho item) {
        Produto p = item.getProduto();

        // Busca a imagem principal directamente via repository —
        // usa o método já existente no ProdutoImagemRepository.
        String imagemPrincipal = produtoImagemRepo
                .findByIdProdutoAndImagemPrincipal(p.getIdProduto(), (short) 1)
                .map(img -> img.getCaminhoImagem())
                .orElse(null);

        return new ItemCarrinhoDTO(
                item.getIdItemCarrinho(),
                p.getIdProduto(),
                p.getNomeProduto(),
                imagemPrincipal,
                resolverPreco(p),
                item.getQuantidade(),
                item.getSubtotal()
        );
    }
}