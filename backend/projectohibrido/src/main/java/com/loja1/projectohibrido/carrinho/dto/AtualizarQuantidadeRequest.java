package com.loja1.projectohibrido.carrinho.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * Usado quando o utilizador quer definir uma quantidade exata para um item
 * já existente no carrinho (diferente de AdicionarItemRequest que SOMA).
 */
public class AtualizarQuantidadeRequest {

    @NotNull(message = "A quantidade é obrigatória")
    @Min(value = 1, message = "A quantidade mínima é 1")
    private Integer quantidade;

    // ── Constructors ──────────────────────────────────────────────────────────

    public AtualizarQuantidadeRequest() {}

    public AtualizarQuantidadeRequest(Integer quantidade) {
        this.quantidade = quantidade;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Integer getQuantidade()                  { return quantidade; }
    public void setQuantidade(Integer quantidade)   { this.quantidade = quantidade; }
}