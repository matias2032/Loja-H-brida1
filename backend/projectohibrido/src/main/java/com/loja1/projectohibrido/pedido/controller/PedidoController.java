package com.loja1.projectohibrido.pedido.controller;


import com.loja1.projectohibrido.pedido.dto.*;
import com.loja1.projectohibrido.pedido.service.PedidoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
public class PedidoController {

    private final PedidoService pedidoService;

    // ─── a) Criar pedido ─────────────────────────────────────────────────────

    /**
     * POST /api/pedidos
     * Cria um pedido com os itens iniciais.
     * Desconta estoque imediatamente sem movimentação.
     */
    @PostMapping
    public ResponseEntity<PedidoResponseDTO> criarPedido(
            @Valid @RequestBody PedidoRequestDTO dto) {

        PedidoResponseDTO response = pedidoService.criarPedido(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // ─── b) Adicionar item ────────────────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/itens
     * Adiciona um novo produto ao pedido existente.
     */
    @PostMapping("/{idPedido}/itens")
    public ResponseEntity<PedidoResponseDTO> adicionarItem(
            @PathVariable Integer idPedido,
            @Valid @RequestBody ItemPedidoRequestDTO dto) {

        PedidoResponseDTO response = pedidoService.adicionarItem(idPedido, dto);
        return ResponseEntity.ok(response);
    }

    // ─── c) Editar quantidade de item ─────────────────────────────────────────

    /**
     * PATCH /api/pedidos/{idPedido}/itens/{idItemPedido}
     * Altera a quantidade de um item específico.
     * Ajusta estoque na diferença (sem movimentação).
     */
    @PatchMapping("/{idPedido}/itens/{idItemPedido}")
    public ResponseEntity<PedidoResponseDTO> editarQuantidadeItem(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemPedido,
            @Valid @RequestBody EditarItemRequestDTO dto) {

        PedidoResponseDTO response = pedidoService.editarQuantidadeItem(idPedido, idItemPedido, dto);
        return ResponseEntity.ok(response);
    }

    // ─── d) Eliminar item ─────────────────────────────────────────────────────

    /**
     * DELETE /api/pedidos/{idPedido}/itens/{idItemPedido}
     * Remove o item e devolve a quantidade ao estoque (sem movimentação).
     */
    @DeleteMapping("/{idPedido}/itens/{idItemPedido}")
    public ResponseEntity<PedidoResponseDTO> eliminarItem(
            @PathVariable Integer idPedido,
            @PathVariable Integer idItemPedido) {

        PedidoResponseDTO response = pedidoService.eliminarItem(idPedido, idItemPedido);
        return ResponseEntity.ok(response);
    }

    // ─── e) Cancelar pedido ───────────────────────────────────────────────────

    /**
     * POST /api/pedidos/{idPedido}/cancelar
     * Cancela o pedido integralmente e restaura todo o estoque (sem movimentação).
     */
    @PostMapping("/{idPedido}/cancelar")
    public ResponseEntity<Void> cancelarPedido(
            @PathVariable Integer idPedido,
            @Valid @RequestBody CancelamentoPedidoRequestDTO dto) {

        pedidoService.cancelarPedido(idPedido, dto);
        return ResponseEntity.noContent().build();
    }

    // ─── Consultas ────────────────────────────────────────────────────────────

    /**
     * GET /api/pedidos/{idPedido}
     */
    @GetMapping("/{idPedido}")
    public ResponseEntity<PedidoResponseDTO> buscarPorId(
            @PathVariable Integer idPedido) {

        return ResponseEntity.ok(pedidoService.buscarPorId(idPedido));
    }

    /**
     * GET /api/pedidos/usuario/{idUsuario}
     */
    @GetMapping("/usuario/{idUsuario}")
    public ResponseEntity<List<PedidoResponseDTO>> listarPorUsuario(
            @PathVariable Integer idUsuario) {

        return ResponseEntity.ok(pedidoService.listarPorUsuario(idUsuario));
    }

    /**
     * GET /api/pedidos/status/{status}
     * Ex: /api/pedidos/status/por%20finalizar
     */
    @GetMapping("/status/{status}")
    public ResponseEntity<List<PedidoResponseDTO>> listarPorStatus(
            @PathVariable String status) {

        return ResponseEntity.ok(pedidoService.listarPorStatus(status));
    }

    // GET /api/pedidos/ativo/{idUsuario}
@GetMapping("/ativo/{idUsuario}")
public ResponseEntity<PedidoResponseDTO> buscarPedidoAtivo(
        @PathVariable Integer idUsuario) {

    return pedidoService.buscarPedidoAtivo(idUsuario)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.noContent().build()); // 204 se não há activo
}

// POST /api/pedidos/{idPedido}/desativar
@PostMapping("/{idPedido}/desativar")
public ResponseEntity<Void> desativarPedido(
        @PathVariable Integer idPedido) {

    pedidoService.desativarPedido(idPedido);
    return ResponseEntity.noContent().build();
}
}