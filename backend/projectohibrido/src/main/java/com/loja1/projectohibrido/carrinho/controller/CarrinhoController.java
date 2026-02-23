package com.loja1.projectohibrido.carrinho.controller;

import com.loja1.projectohibrido.carrinho.dto.AdicionarItemRequest;
import com.loja1.projectohibrido.carrinho.dto.AtualizarQuantidadeRequest;
import com.loja1.projectohibrido.carrinho.dto.CarrinhoDTO;
import com.loja1.projectohibrido.carrinho.dto.MesclarCarrinhoRequest;
import com.loja1.projectohibrido.carrinho.service.CarrinhoService;
import com.loja1.projectohibrido.pedido.dto.PedidoRequestDTO;
import com.loja1.projectohibrido.pedido.dto.PedidoResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/carrinho")
@RequiredArgsConstructor
public class CarrinhoController {

    private final CarrinhoService carrinhoService;

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Extrai o idUsuario do token JWT via Authentication.
     * Ajuste o cast conforme o tipo do Principal configurado na sua SecurityConfig.
     */
    private Integer getUserId(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) return null;
        // Adapte conforme o UserDetails da sua implementação de segurança
        // Exemplo: return ((UsuarioDetails) auth.getPrincipal()).getIdUsuario();
        return Integer.parseInt(auth.getName());
    }

    // ── Endpoints ─────────────────────────────────────────────────────────────

    /**
     * Cria um novo carrinho.
     * Para utilizadores autenticados usa o idUsuario do token.
     * Para guests usa o cartSessionId do cookie.
     */
    @PostMapping
    public ResponseEntity<CarrinhoDTO> criar(
            Authentication auth,
            @CookieValue(name = "cartSessionId", required = false) String cartSessionId) {

        CarrinhoDTO dto = carrinhoService.criarCarrinho(getUserId(auth), cartSessionId);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    /**
     * Adiciona um novo item ou soma quantidade a item já existente no carrinho.
     */
    @PostMapping("/{idCarrinho}/itens")
    public ResponseEntity<CarrinhoDTO> adicionarItem(
            @PathVariable Integer idCarrinho,
            @Valid @RequestBody AdicionarItemRequest req) {

        return ResponseEntity.ok(carrinhoService.adicionarOuAtualizarItem(idCarrinho, req));
    }

    /**
     * Define uma quantidade exata para um item já existente (substitui, não soma).
     */
    @PutMapping("/{idCarrinho}/itens/{idProduto}")
    public ResponseEntity<CarrinhoDTO> atualizarQuantidade(
            @PathVariable Integer idCarrinho,
            @PathVariable Integer idProduto,
            @Valid @RequestBody AtualizarQuantidadeRequest req) {

        return ResponseEntity.ok(carrinhoService.atualizarQuantidade(idCarrinho, idProduto, req));
    }

    /**
     * Remove um item específico do carrinho.
     * Se for o último item, o carrinho é eliminado automaticamente (Regra 4).
     */
    @DeleteMapping("/{idCarrinho}/itens/{idProduto}")
    public ResponseEntity<Void> removerItem(
            @PathVariable Integer idCarrinho,
            @PathVariable Integer idProduto) {

        carrinhoService.removerItem(idCarrinho, idProduto);
        return ResponseEntity.noContent().build();
    }

    /**
     * Remove o carrinho inteiro.
     */
    @DeleteMapping("/{idCarrinho}")
    public ResponseEntity<Void> removerCarrinho(@PathVariable Integer idCarrinho) {
        carrinhoService.removerCarrinho(idCarrinho);
        return ResponseEntity.noContent().build();
    }

    /**
     * Converte o carrinho em pedido, descontando o estoque.
     */
    @PostMapping("/{idCarrinho}/converter-pedido")
    public ResponseEntity<PedidoResponseDTO> converterEmPedido(
            @PathVariable Integer idCarrinho,
            @Valid @RequestBody PedidoRequestDTO req) {

        PedidoResponseDTO pedidoResponse = carrinhoService.converterEmPedido(idCarrinho, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(pedidoResponse);
    }

    /**
     * Mescla o carrinho guest (cookie) ao carrinho do utilizador recém autenticado.
     * Chamado pelo frontend imediatamente após o login.
     */
    @PostMapping("/mesclar")
    public ResponseEntity<CarrinhoDTO> mesclarCarrinhos(
            Authentication auth,
            @Valid @RequestBody MesclarCarrinhoRequest req) {

        CarrinhoDTO dto = carrinhoService.mesclarCarrinhos(req.getSessionId(), getUserId(auth));
        return ResponseEntity.ok(dto);
    }
}