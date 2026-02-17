package com.loja1.projectohibrido.pedido.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import lombok.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Getter @Setter
public class PedidoResponseDTO {

    public Integer idPedido;
    public String reference;
    public Integer idUsuario;
    public String telefone;
    public String email;
    public Integer idTipoPagamento;
    public Integer idTipoEntrega;
    public Integer idTipoOrigemPedido;
    public LocalDateTime dataPedido;
    public String statusPedido;
    public BigDecimal total;
    public String enderecoJson;
    public String bairro;
    public String pontoReferencia;
    public BigDecimal troco;
    public List<ItemPedidoResponseDTO> itens;
}
