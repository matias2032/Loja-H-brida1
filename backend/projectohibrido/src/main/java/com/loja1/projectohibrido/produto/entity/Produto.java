package com.loja1.projectohibrido.produto.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "produto")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Produto {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_produto")
    private Integer idProduto;
    
    @Column(name = "nome_produto", nullable = false, length = 200)
    private String nomeProduto;
    
    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;
    
    @Column(name = "preco", nullable = false, precision = 10, scale = 2)
    private BigDecimal preco;
    
    @Column(name = "quantidade_estoque", nullable = false)
    private Integer quantidadeEstoque = 0;
    
    @Column(name = "preco_promocional", precision = 10, scale = 2)
    private BigDecimal precoPromocional;
    
    // ✅ MUDANÇA: Integer → Short (para compatibilidade com SMALLINT do PostgreSQL)
    @Column(name = "ativo", nullable = false)
    private Short ativo = 1; // 1 = ativo, 0 = inativo (soft delete)
    
    @Column(name = "data_cadastro", nullable = false)
    private LocalDateTime dataCadastro = LocalDateTime.now();
}