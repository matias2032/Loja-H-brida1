package com.loja1.projectohibrido.pedido.exception;


import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

// ─── Item não encontrado ──────────────────────────────────────────────────

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ItemPedidoNaoEncontradoException extends RuntimeException {
    public ItemPedidoNaoEncontradoException(Integer id) {
        super("Item do pedido não encontrado: " + id);
    }
}
