package com.loja1.projectohibrido.pedido.repository;

import com.loja1.projectohibrido.pedido.entity.ItemPedido;
// import com.loja1.projectohibrido.pedido.entity.Pedido;
// import com.loja1.projectohibrido.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
@Repository
public interface ItemPedidoRepository extends JpaRepository<ItemPedido, Integer> {

    List<ItemPedido> findByPedidoIdPedido(Integer idPedido);

    Optional<ItemPedido> findByIdItemPedidoAndPedidoIdPedido(Integer idItem, Integer idPedido);

    /**
     * Retorna a quantidade total já reservada de um produto
     * em pedidos activos (não cancelados, não finalizados).
     * Útil para verificações de estoque em cenários concorrentes.
     */
    @Query("""
        SELECT COALESCE(SUM(i.quantidade), 0)
        FROM ItemPedido i
        WHERE i.produto.idProduto = :idProduto
          AND i.pedido.statusPedido NOT IN ('cancelado', 'finalizado')
          AND i.pedido.idPedido <> :idPedidoExcluir
        """)
    Integer totalReservadoParaProduto(
        @Param("idProduto") Integer idProduto,
        @Param("idPedidoExcluir") Integer idPedidoExcluir
    );
}

