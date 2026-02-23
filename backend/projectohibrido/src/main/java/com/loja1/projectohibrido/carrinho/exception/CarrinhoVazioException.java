package com.loja1.projectohibrido.carrinho.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando se tenta converter em pedido um carrinho que não tem itens.
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)   // 400
public class CarrinhoVazioException extends RuntimeException {

    public CarrinhoVazioException(Integer idCarrinho) {
        super("O carrinho " + idCarrinho + " está vazio e não pode ser convertido em pedido.");
    }
}