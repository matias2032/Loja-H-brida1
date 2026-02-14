package com.loja1.projectohibrido.categoria.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "categoria")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Categoria {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_categoria")
    private Integer idCategoria;
    
    @Column(name = "nome_categoria", nullable = false, length = 100)
    private String nomeCategoria;
    
    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;
}