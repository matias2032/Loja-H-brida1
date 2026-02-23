package com.loja1.projectohibrido.carrinho.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Lançada quando a quantidade solicitada (no carrinho ou na conversão para pedido)
 * excede o estoque disponível do produto.
 */
@ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)   // 422
public class EstoqueInsuficienteException extends RuntimeException {

    private final Integer idProduto;
    private final String  nomeProduto;
    private final Integer estoqueDisponivel;
    private final Integer quantidadeSolicitada;

    // ── Constructor completo (recomendado na conversão para pedido) ────────────

    public EstoqueInsuficienteException(Integer idProduto, String nomeProduto,
                                        Integer estoqueDisponivel,
                                        Integer quantidadeSolicitada) {
        super(String.format(
            "Estoque insuficiente para o produto '%s' (id=%d). " +
            "Disponível: %d | Solicitado: %d",
            nomeProduto, idProduto, estoqueDisponivel, quantidadeSolicitada
        ));
        this.idProduto             = idProduto;
        this.nomeProduto           = nomeProduto;
        this.estoqueDisponivel     = estoqueDisponivel;
        this.quantidadeSolicitada  = quantidadeSolicitada;
    }

    // ── Constructor simplificado (usado em validações rápidas) ───────────────

    public EstoqueInsuficienteException(String mensagem) {
        super(mensagem);
        this.idProduto            = null;
        this.nomeProduto          = null;
        this.estoqueDisponivel    = null;
        this.quantidadeSolicitada = null;
    }

    // ── Getters ───────────────────────────────────────────────────────────────

    public Integer getIdProduto()               { return idProduto; }
    public String  getNomeProduto()             { return nomeProduto; }
    public Integer getEstoqueDisponivel()       { return estoqueDisponivel; }
    public Integer getQuantidadeSolicitada()    { return quantidadeSolicitada; }
}