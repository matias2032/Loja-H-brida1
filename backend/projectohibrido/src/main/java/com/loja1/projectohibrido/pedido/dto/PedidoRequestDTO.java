package com.loja1.projectohibrido.pedido.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class PedidoRequestDTO {

    @NotNull(message = "O utilizador é obrigatório")
    public Integer idUsuario;

    @Size(max = 20)
    public String telefone;

    @Email @Size(max = 100)
    public String email;

    @NotNull(message = "O tipo de pagamento é obrigatório")
    public Integer idTipoPagamento;

    public Integer idTipoEntrega;
    public Integer idTipoOrigemPedido;
    public String enderecoJson;
    public String bairro;
    public String pontoReferencia;

    
    @Valid
    public List<ItemPedidoRequestDTO> itens;
}
