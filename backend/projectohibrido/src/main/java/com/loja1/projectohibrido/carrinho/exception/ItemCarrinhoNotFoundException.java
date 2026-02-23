package com.loja1.projectohibrido.carrinho.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando se tenta atualizar ou remover um produto que
 * não existe no carrinho especificado.
 */
@ResponseStatus(HttpStatus.NOT_FOUND)   // 404
public class ItemCarrinhoNotFoundException extends RuntimeException {

    public ItemCarrinhoNotFoundException(Integer idCarrinho, Integer idProduto) {
        super(String.format(
            "Produto (id=%d) não encontrado no carrinho (id=%d).",
            idProduto, idCarrinho
        ));
    }
}