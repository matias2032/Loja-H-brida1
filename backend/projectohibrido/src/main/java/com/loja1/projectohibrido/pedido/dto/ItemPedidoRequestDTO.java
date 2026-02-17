package com.loja1.projectohibrido.pedido.dto;

import jakarta.validation.constraints.*;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class ItemPedidoRequestDTO {

    @NotNull(message = "O produto é obrigatório")
    public Integer idProduto;

    @NotNull @Min(value = 1, message = "A quantidade mínima é 1")
    public Integer quantidade;
}
