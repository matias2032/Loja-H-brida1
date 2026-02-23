package com.loja1.projectohibrido.carrinho.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando não é encontrado nenhum carrinho com os critérios fornecidos
 * (id, sessionId ou idUsuario + status).
 */
@ResponseStatus(HttpStatus.NOT_FOUND)   // 404
public class CarrinhoNotFoundException extends RuntimeException {

    public CarrinhoNotFoundException(Integer idCarrinho) {
        super("Carrinho não encontrado com id: " + idCarrinho);
    }

    public CarrinhoNotFoundException(String campo, String valor) {
        super(String.format("Carrinho não encontrado com %s: '%s'", campo, valor));
    }
}