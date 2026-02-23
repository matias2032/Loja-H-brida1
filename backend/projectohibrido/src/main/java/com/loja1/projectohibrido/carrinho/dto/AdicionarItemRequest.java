package com.loja1.projectohibrido.carrinho.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public class AdicionarItemRequest {

    @NotNull(message = "O id do produto é obrigatório")
    private Integer idProduto;

    @NotNull(message = "A quantidade é obrigatória")
    @Min(value = 1, message = "A quantidade mínima é 1")
    private Integer quantidade;

    // ── Constructors ──────────────────────────────────────────────────────────

    public AdicionarItemRequest() {}

    public AdicionarItemRequest(Integer idProduto, Integer quantidade) {
        this.idProduto  = idProduto;
        this.quantidade = quantidade;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Integer getIdProduto()                       { return idProduto; }
    public void setIdProduto(Integer idProduto)         { this.idProduto = idProduto; }

    public Integer getQuantidade()                      { return quantidade; }
    public void setQuantidade(Integer quantidade)       { this.quantidade = quantidade; }
}