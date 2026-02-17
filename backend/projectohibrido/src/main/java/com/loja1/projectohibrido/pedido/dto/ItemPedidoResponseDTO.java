package com.loja1.projectohibrido.pedido.dto;

import java.math.BigDecimal;
import lombok.*;

@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
public class ItemPedidoResponseDTO {

    public Integer idItemPedido;
    public Integer idProduto;
    public String nomeProduto;
    public Integer quantidade;
    public BigDecimal precoUnitario;
    public BigDecimal subtotal;
}