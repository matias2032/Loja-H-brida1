package com.loja1.projectohibrido.pedido.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "tipo_entrega")
public class TipoEntrega {

    @Id
    @Column(name = "idtipo_entrega")
    private Integer idTipoEntrega;

    @Column(name = "nome_tipo_entrega", length = 50)
    private String nomeTipoEntrega;

    @Column(name = "preco_adicional", precision = 10, scale = 2)
    private BigDecimal precoAdicional;

    public TipoEntrega() {}

    public Integer getIdTipoEntrega()      { return idTipoEntrega; }
    public String getNomeTipoEntrega()     { return nomeTipoEntrega; }
    public BigDecimal getPrecoAdicional()  { return precoAdicional; }
}