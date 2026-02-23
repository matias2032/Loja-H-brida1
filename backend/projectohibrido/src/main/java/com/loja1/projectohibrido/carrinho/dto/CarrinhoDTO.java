package com.loja1.projectohibrido.carrinho.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class CarrinhoDTO {

    private Integer idCarrinho;
    private Integer idUsuario;
    private String sessionId;
    private String status;
    private LocalDateTime dataCriacao;
    private List<ItemCarrinhoDTO> itens;
    private BigDecimal totalCarrinho;

    // ── Constructors ──────────────────────────────────────────────────────────

    public CarrinhoDTO() {}

    public CarrinhoDTO(Integer idCarrinho, Integer idUsuario, String sessionId,
                       String status, LocalDateTime dataCriacao,
                       List<ItemCarrinhoDTO> itens, BigDecimal totalCarrinho) {
        this.idCarrinho    = idCarrinho;
        this.idUsuario     = idUsuario;
        this.sessionId     = sessionId;
        this.status        = status;
        this.dataCriacao   = dataCriacao;
        this.itens         = itens;
        this.totalCarrinho = totalCarrinho;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Integer getIdCarrinho()                    { return idCarrinho; }
    public void setIdCarrinho(Integer idCarrinho)     { this.idCarrinho = idCarrinho; }

    public Integer getIdUsuario()                     { return idUsuario; }
    public void setIdUsuario(Integer idUsuario)       { this.idUsuario = idUsuario; }

    public String getSessionId()                      { return sessionId; }
    public void setSessionId(String sessionId)        { this.sessionId = sessionId; }

    public String getStatus()                         { return status; }
    public void setStatus(String status)              { this.status = status; }

    public LocalDateTime getDataCriacao()                       { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao)       { this.dataCriacao = dataCriacao; }

    public List<ItemCarrinhoDTO> getItens()                     { return itens; }
    public void setItens(List<ItemCarrinhoDTO> itens)           { this.itens = itens; }

    public BigDecimal getTotalCarrinho()                        { return totalCarrinho; }
    public void setTotalCarrinho(BigDecimal totalCarrinho)      { this.totalCarrinho = totalCarrinho; }
}