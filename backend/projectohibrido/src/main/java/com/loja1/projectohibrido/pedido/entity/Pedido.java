package com.loja1.projectohibrido.pedido.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pedido")
public class Pedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pedido")
    private Integer idPedido;

    @Column(name = "reference", nullable = false, unique = true, length = 100)
    private String reference;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "telefone", length = 20)
    private String telefone;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "idtipo_pagamento", nullable = false)
    private Integer idTipoPagamento;

    @Column(name = "idtipo_entrega")
    private Integer idTipoEntrega;

    @Column(name = "idtipo_origem_pedido")
    private Integer idTipoOrigemPedido;

    @Column(name = "data_pedido", nullable = false)
    private LocalDateTime dataPedido;

    @Column(name = "data_fim_pedido")
    private LocalDateTime dataFimPedido;

    @Column(name = "status_pedido", length = 50)
    private String statusPedido;

    @Column(name = "notificacao_vista")
    private Short notificacaoVista;

    @Column(name = "total", nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Column(name = "endereco_json", columnDefinition = "TEXT")
    private String enderecoJson;

    @Column(name = "valor_pago_manual", precision = 10, scale = 2)
    private BigDecimal valorPagoManual;

    @Column(name = "data_finalizacao")
    private LocalDateTime dataFinalizacao;

    @Column(name = "bairro", length = 100)
    private String bairro;

    @Column(name = "ponto_referencia", columnDefinition = "TEXT")
    private String pontoReferencia;

    @Column(name = "troco", precision = 10, scale = 2)
    private BigDecimal troco;

    @Column(name = "oculto_cliente")
    private Short ocultoCliente;

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL,
               orphanRemoval = true, fetch = FetchType.LAZY)
    private List<ItemPedido> itens = new ArrayList<>();

    // ─── Construtor vazio (obrigatório pelo JPA) ─────────────────────────────
    public Pedido() {}

    // ─── Builder estático (substitui @Builder do Lombok) ─────────────────────
    public static Builder builder() { return new Builder(); }

    public static class Builder {
        private final Pedido p = new Pedido();
        public Builder reference(String v)           { p.reference = v;           return this; }
        public Builder idUsuario(Integer v)          { p.idUsuario = v;           return this; }
        public Builder telefone(String v)            { p.telefone = v;            return this; }
        public Builder email(String v)               { p.email = v;               return this; }
        public Builder idTipoPagamento(Integer v)    { p.idTipoPagamento = v;     return this; }
        public Builder idTipoEntrega(Integer v)      { p.idTipoEntrega = v;       return this; }
        public Builder idTipoOrigemPedido(Integer v) { p.idTipoOrigemPedido = v;  return this; }
        public Builder dataPedido(LocalDateTime v)   { p.dataPedido = v;          return this; }
        public Builder statusPedido(String v)        { p.statusPedido = v;        return this; }
        public Builder notificacaoVista(Short v)     { p.notificacaoVista = v;    return this; }
        public Builder total(BigDecimal v)           { p.total = v;               return this; }
        public Builder enderecoJson(String v)        { p.enderecoJson = v;        return this; }
        public Builder bairro(String v)              { p.bairro = v;              return this; }
        public Builder pontoReferencia(String v)     { p.pontoReferencia = v;     return this; }
        public Builder valorPagoManual(BigDecimal v) { p.valorPagoManual = v;     return this; }
        public Builder troco(BigDecimal v)           { p.troco = v;               return this; }
        public Builder ocultoCliente(Short v)        { p.ocultoCliente = v;       return this; }
        public Pedido build()                        { return p; }
    }

    // ─── Helper ──────────────────────────────────────────────────────────────
    public void recalcularTotal() {
        this.total = itens.stream()
                .map(ItemPedido::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    // ─── Getters ─────────────────────────────────────────────────────────────
    public Integer      getIdPedido()            { return idPedido; }
    public String       getReference()           { return reference; }
    public Integer      getIdUsuario()           { return idUsuario; }
    public String       getTelefone()            { return telefone; }
    public String       getEmail()               { return email; }
    public Integer      getIdTipoPagamento()     { return idTipoPagamento; }
    public Integer      getIdTipoEntrega()       { return idTipoEntrega; }
    public Integer      getIdTipoOrigemPedido()  { return idTipoOrigemPedido; }
    public LocalDateTime getDataPedido()         { return dataPedido; }
    public LocalDateTime getDataFimPedido()      { return dataFimPedido; }
    public String       getStatusPedido()        { return statusPedido; }
    public Short        getNotificacaoVista()    { return notificacaoVista; }
    public BigDecimal   getTotal()               { return total; }
    public String       getEnderecoJson()        { return enderecoJson; }
    public BigDecimal   getValorPagoManual()     { return valorPagoManual; }
    public LocalDateTime getDataFinalizacao()    { return dataFinalizacao; }
    public String       getBairro()              { return bairro; }
    public String       getPontoReferencia()     { return pontoReferencia; }
    public BigDecimal   getTroco()               { return troco; }
    public Short        getOcultoCliente()       { return ocultoCliente; }
    public List<ItemPedido> getItens()           { return itens; }

    // ─── Setters ─────────────────────────────────────────────────────────────
    public void setIdPedido(Integer v)            { this.idPedido = v; }
    public void setReference(String v)            { this.reference = v; }
    public void setIdUsuario(Integer v)           { this.idUsuario = v; }
    public void setTelefone(String v)             { this.telefone = v; }
    public void setEmail(String v)                { this.email = v; }
    public void setIdTipoPagamento(Integer v)     { this.idTipoPagamento = v; }
    public void setIdTipoEntrega(Integer v)       { this.idTipoEntrega = v; }
    public void setIdTipoOrigemPedido(Integer v)  { this.idTipoOrigemPedido = v; }
    public void setDataPedido(LocalDateTime v)    { this.dataPedido = v; }
    public void setDataFimPedido(LocalDateTime v) { this.dataFimPedido = v; }
    public void setStatusPedido(String v)         { this.statusPedido = v; }
    public void setNotificacaoVista(Short v)      { this.notificacaoVista = v; }
    public void setTotal(BigDecimal v)            { this.total = v; }
    public void setEnderecoJson(String v)         { this.enderecoJson = v; }
    public void setValorPagoManual(BigDecimal v)  { this.valorPagoManual = v; }
    public void setDataFinalizacao(LocalDateTime v){ this.dataFinalizacao = v; }
    public void setBairro(String v)               { this.bairro = v; }
    public void setPontoReferencia(String v)      { this.pontoReferencia = v; }
    public void setTroco(BigDecimal v)            { this.troco = v; }
    public void setOcultoCliente(Short v)         { this.ocultoCliente = v; }
    public void setItens(List<ItemPedido> v)      { this.itens = v; }
}