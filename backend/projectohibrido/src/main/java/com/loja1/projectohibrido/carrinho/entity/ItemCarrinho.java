package com.loja1.projectohibrido.carrinho.entity;

import com.loja1.projectohibrido.produto.entity.Produto;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "item_carrinho")
public class ItemCarrinho {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item_carrinho")
    private Integer idItemCarrinho;

    // ── Relacionamentos — causavam "getProduto() / getQuantidade() is undefined"
    // porque a entidade original não tinha @Data nem getters manuais ──────────
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_carrinho")
    private Carrinho carrinho;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_produto")
    private Produto produto;

    @Column(name = "quantidade", nullable = false)
    private Integer quantidade;

    @Column(name = "subtotal", nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotal;
}