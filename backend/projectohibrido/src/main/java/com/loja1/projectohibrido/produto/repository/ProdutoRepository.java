package com.loja1.projectohibrido.produto.repository;

import com.loja1.projectohibrido.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {
    
    // ✅ MUDANÇA: Integer → Short
    List<Produto> findByAtivo(Short ativo);
  @Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("UPDATE Produto p SET p.quantidadeEstoque = p.quantidadeEstoque + :delta WHERE p.idProduto = :idProduto")
void ajustarEstoque(@Param("idProduto") Integer idProduto, @Param("delta") int delta);

// Produtos sem vendas no período
@Query("""
    SELECT p.idProduto, p.nomeProduto, p.quantidadeEstoque, p.preco
    FROM Produto p
    WHERE p.ativo = 1
      AND p.idProduto NOT IN (
          SELECT DISTINCT i.produto.idProduto
          FROM ItemPedido i
          WHERE i.pedido.dataPedido >= :dataInicio
            AND i.pedido.statusPedido NOT IN ('cancelado', 'por finalizar')
      )
    """)
List<Object[]> produtosSemVendas(@Param("dataInicio") LocalDateTime dataInicio);
}