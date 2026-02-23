package com.loja1.projectohibrido.carrinho.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando se tenta operar (adicionar item, remover, converter)
 * sobre um carrinho cujo status já é "convertido".
 * Evita dupla conversão do mesmo carrinho em pedidos distintos.
 */
@ResponseStatus(HttpStatus.CONFLICT)   // 409
public class CarrinhoJaConvertidoException extends RuntimeException {

    public CarrinhoJaConvertidoException(Integer idCarrinho) {
        super("O carrinho " + idCarrinho + " já foi convertido em pedido e não aceita mais operações.");
    }
}