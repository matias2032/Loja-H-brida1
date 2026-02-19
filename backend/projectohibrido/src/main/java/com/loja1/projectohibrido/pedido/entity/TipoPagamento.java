package com.loja1.projectohibrido.pedido.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "tipo_pagamento")
public class TipoPagamento {

    @Id
    @Column(name = "idtipo_pagamento")
    private Integer idTipoPagamento;

    @Column(name = "tipo_pagamento", nullable = false, length = 50)
    private String tipoPagamento;

    public TipoPagamento() {}

    public Integer getIdTipoPagamento() { return idTipoPagamento; }
    public String getTipoPagamento()    { return tipoPagamento; }
}