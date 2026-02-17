package com.loja1.projectohibrido.pedido.repository;


// import com.loja1.projectohibrido.pedido.entity.ItemPedido;
import com.loja1.projectohibrido.pedido.entity.Pedido;
// import com.loja1.projectohibrido.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Integer> {

    Optional<Pedido> findByReference(String reference);

    List<Pedido> findByIdUsuarioOrderByDataPedidoDesc(Integer idUsuario);

    List<Pedido> findByStatusPedidoOrderByDataPedidoDesc(String status);

    @Query("SELECT p FROM Pedido p LEFT JOIN FETCH p.itens WHERE p.idPedido = :id")
    Optional<Pedido> findByIdComItens(@Param("id") Integer id);
}

