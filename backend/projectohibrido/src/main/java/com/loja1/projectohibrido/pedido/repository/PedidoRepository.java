package com.loja1.projectohibrido.pedido.repository;


// import com.loja1.projectohibrido.pedido.entity.ItemPedido;
import com.loja1.projectohibrido.pedido.entity.Pedido;
// import com.loja1.projectohibrido.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
// import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Integer> {

    Optional<Pedido> findByReference(String reference);

    List<Pedido> findByIdUsuarioOrderByDataPedidoDesc(Integer idUsuario);

    List<Pedido> findByStatusPedidoOrderByDataPedidoDesc(String status);

@Query("SELECT p FROM Pedido p LEFT JOIN FETCH p.itens i LEFT JOIN FETCH i.produto WHERE p.idPedido = :id")
Optional<Pedido> findByIdComItens(@Param("id") Integer id);

    // Busca o pedido activo de um utilizador (máximo 1 por causa do índice único)
Optional<Pedido> findByIdUsuarioAndAtivoTrue(Integer idUsuario);

// Desactiva todos os pedidos activos de um utilizador (usado antes de criar novo)
@Modifying
@Query("UPDATE Pedido p SET p.ativo = FALSE WHERE p.idUsuario = :idUsuario AND p.ativo = TRUE")
int desativarPedidosDoUsuario(@Param("idUsuario") Integer idUsuario);

// Evolução de vendas por dia
@Query("""
    SELECT CAST(p.dataPedido AS date) AS data, SUM(p.total) AS totalVendas
    FROM Pedido p
    WHERE p.dataPedido >= :dataInicio
      AND p.statusPedido NOT IN ('cancelado', 'por finalizar')
    GROUP BY CAST(p.dataPedido AS date)
    ORDER BY CAST(p.dataPedido AS date)
    """)
List<Object[]> evolucaoVendasPorDia(@Param("dataInicio") LocalDateTime dataInicio);

// Desempenho por usuário
@Query("""
    SELECT u.nome, u.apelido,
           COUNT(p.idPedido), SUM(p.total),
           COUNT(DISTINCT CAST(p.dataPedido AS date))
    FROM Pedido p
    JOIN Usuario u ON u.idUsuario = p.idUsuario
    WHERE p.dataPedido >= :dataInicio
      AND p.statusPedido NOT IN ('cancelado', 'por finalizar')
    GROUP BY u.idUsuario, u.nome, u.apelido
    ORDER BY SUM(p.total) DESC
    """)
List<Object[]> desempenhoUsuarios(@Param("dataInicio") LocalDateTime dataInicio);

// Adicionar este método ao PedidoRepository
List<Pedido> findByIdUsuarioAndStatusPedidoOrderByDataPedidoDesc(Integer idUsuario, String statusPedido);
}

