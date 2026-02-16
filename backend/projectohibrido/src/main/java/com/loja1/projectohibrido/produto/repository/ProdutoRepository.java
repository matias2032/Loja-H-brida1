package com.loja1.projectohibrido.produto.repository;

import com.loja1.projectohibrido.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {
    
    // ✅ MUDANÇA: Integer → Short
    List<Produto> findByAtivo(Short ativo);
}