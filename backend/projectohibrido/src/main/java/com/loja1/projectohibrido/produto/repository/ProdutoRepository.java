package com.loja1.projectohibrido.produto.repository;

import com.loja1.projectohibrido.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {
    
    // ✅ MUDANÇA: Integer → Short
    List<Produto> findByAtivo(Short ativo);
  @Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("UPDATE Produto p SET p.quantidadeEstoque = p.quantidadeEstoque + :delta WHERE p.idProduto = :idProduto")
void ajustarEstoque(@Param("idProduto") Integer idProduto, @Param("delta") int delta);
}