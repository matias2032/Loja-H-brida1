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
import java.util.Map;

@RestController
@RequestMapping("/api/carrinhos")
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


@PostMapping
public ResponseEntity<CarrinhoDTO> criar(
        Authentication auth,
        @CookieValue(name = "cartSessionId", required = false) String cookieSessionId,
        @RequestHeader(name = "X-Cart-Session-Id", required = false) String headerSessionId,
        @RequestHeader(name = "X-User-Id", required = false) Integer headerUserId) {

    String sessionId = headerSessionId != null ? headerSessionId : cookieSessionId;
    Integer idUsuario = getUserId(auth) != null ? getUserId(auth) : headerUserId;

    CarrinhoDTO dto = carrinhoService.criarCarrinho(idUsuario, sessionId);

    ResponseEntity.BodyBuilder builder = ResponseEntity.status(HttpStatus.CREATED);
    if (dto.getSessionId() != null) {
        builder.header("X-Cart-Session-Id", dto.getSessionId());
    }
    return builder.body(dto);
}

@GetMapping("/activo")
public ResponseEntity<CarrinhoDTO> buscarActivo(
        Authentication auth,
        @CookieValue(name = "cartSessionId", required = false) String cookieSessionId,
        @RequestHeader(name = "X-Cart-Session-Id", required = false) String headerSessionId,
        @RequestHeader(name = "X-User-Id", required = false) Integer headerUserId) {

    String sessionId = headerSessionId != null ? headerSessionId : cookieSessionId;
    
    // Sem JWT: usa o idUsuario enviado pelo frontend no header
    Integer idUsuario = getUserId(auth) != null ? getUserId(auth) : headerUserId;

    CarrinhoDTO dto = carrinhoService.buscarCarrinhoActivo(idUsuario, sessionId);
    if (dto == null) return ResponseEntity.notFound().build();
    return ResponseEntity.ok(dto);
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

    @PatchMapping("/associar-usuario")
public ResponseEntity<CarrinhoDTO> associarUsuario(
        @RequestBody Map<String, Object> body) {

    String sessionId = (String) body.get("sessionId");
    Integer idUsuario = (Integer) body.get("idUsuario");

    if (sessionId == null || idUsuario == null) {
        return ResponseEntity.badRequest().build();
    }

    CarrinhoDTO dto = carrinhoService.associarCarrinhoAoUsuario(sessionId, idUsuario);
    if (dto == null) return ResponseEntity.notFound().build();
    return ResponseEntity.ok(dto);
}
 
@PostMapping("/inicializar")
public ResponseEntity<CarrinhoDTO> inicializarParaUsuario(
        @RequestBody Map<String, Object> body) {

    Integer idUsuario = (Integer) body.get("idUsuario");
    if (idUsuario == null) return ResponseEntity.badRequest().build();

    CarrinhoDTO dto = carrinhoService.criarCarrinho(idUsuario, null);
    
    // dto.getSessionId() é null para carrinhos autenticados — proteger contra NPE
    ResponseEntity.BodyBuilder builder = ResponseEntity.ok();
    if (dto.getSessionId() != null && !dto.getSessionId().isBlank()) {
        builder.header("X-Cart-Session-Id", dto.getSessionId());
    }
    return builder.body(dto);
}

}