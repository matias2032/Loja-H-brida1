package com.loja1.projectohibrido.carrinho.dto;

import java.math.BigDecimal;

public class ItemCarrinhoDTO {

    private Integer idItemCarrinho;
    private Integer idProduto;
    private String  nomeProduto;
    private String  imagemPrincipal;   // caminho da imagem principal do produto
    private BigDecimal precoUnitario;  // preço aplicado (promocional ou normal) no momento da consulta
    private Integer quantidade;
    private BigDecimal subtotal;

    // ── Constructors ──────────────────────────────────────────────────────────

    public ItemCarrinhoDTO() {}

    public ItemCarrinhoDTO(Integer idItemCarrinho, Integer idProduto, String nomeProduto,
                           String imagemPrincipal, BigDecimal precoUnitario,
                           Integer quantidade, BigDecimal subtotal) {
        this.idItemCarrinho = idItemCarrinho;
        this.idProduto      = idProduto;
        this.nomeProduto    = nomeProduto;
        this.imagemPrincipal = imagemPrincipal;
        this.precoUnitario  = precoUnitario;
        this.quantidade     = quantidade;
        this.subtotal       = subtotal;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Integer getIdItemCarrinho()                          { return idItemCarrinho; }
    public void setIdItemCarrinho(Integer idItemCarrinho)       { this.idItemCarrinho = idItemCarrinho; }

    public Integer getIdProduto()                               { return idProduto; }
    public void setIdProduto(Integer idProduto)                 { this.idProduto = idProduto; }

    public String getNomeProduto()                              { return nomeProduto; }
    public void setNomeProduto(String nomeProduto)              { this.nomeProduto = nomeProduto; }

    public String getImagemPrincipal()                          { return imagemPrincipal; }
    public void setImagemPrincipal(String imagemPrincipal)      { this.imagemPrincipal = imagemPrincipal; }

    public BigDecimal getPrecoUnitario()                        { return precoUnitario; }
    public void setPrecoUnitario(BigDecimal precoUnitario)      { this.precoUnitario = precoUnitario; }

    public Integer getQuantidade()                              { return quantidade; }
    public void setQuantidade(Integer quantidade)               { this.quantidade = quantidade; }

    public BigDecimal getSubtotal()                             { return subtotal; }
    public void setSubtotal(BigDecimal subtotal)                { this.subtotal = subtotal; }
}