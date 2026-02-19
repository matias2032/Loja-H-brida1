package com.loja1.projectohibrido.pedido.dto;

import java.math.BigDecimal;

public class FinalizarPedidoRequestDTO {
    public Integer idTipoPagamento;
    public BigDecimal valorPago;
    public Integer idTipoEntrega;
    public String nomeCliente;
    public String apelidoCliente;
    public String telefone;      // ← FALTA ESTE CAMPO
    public String enderecoJson;
    public String bairro;
    public String pontoReferencia;
}