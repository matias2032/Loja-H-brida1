package com.loja1.projectohibrido.pedido.dto;

import java.math.BigDecimal;

public class FinalizarPedidoRequestDTO {

    // Sempre obrigatório
    public Integer idTipoPagamento;

    // Só para dinheiro (idTipoPagamento == 1)
    public BigDecimal valorPago;          // valor recebido do cliente

    // Só para Loja Física (idTipoOrigemPedido == 2)
    public Integer idTipoEntrega;         // 1 = balcão, 2 = delivery

    // Opcionais — dados do cliente para delivery
    public String nomeCliente;
    public String apelidoCliente;
    public String enderecoJson;
    public String bairro;
    public String pontoReferencia;
  
}