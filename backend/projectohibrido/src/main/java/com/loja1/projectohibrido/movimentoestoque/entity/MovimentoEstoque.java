package com.loja1.projectohibrido.movimentoestoque.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "movimento_estoque")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class MovimentoEstoque {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_movimento")
    private Integer idMovimento;

    @Column(name = "id_produto", nullable = false)
    private Integer idProduto;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "tipo_movimento", nullable = false, length = 20)
    private String tipoMovimento; // entrada | saida | ajuste

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    @Column(name = "quantidade_anterior", nullable = false)
    private Integer quantidadeAnterior;

    @Column(name = "quantidade_nova", nullable = false)
    private Integer quantidadeNova;

    @Column(name = "motivo", columnDefinition = "TEXT")
    private String motivo;

    @Column(name = "data_movimento", nullable = false)
    private LocalDateTime dataMovimento = LocalDateTime.now();
}