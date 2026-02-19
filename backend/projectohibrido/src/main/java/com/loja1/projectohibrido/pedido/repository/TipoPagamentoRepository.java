package com.loja1.projectohibrido.pedido.repository;
import com.loja1.projectohibrido.pedido.entity.TipoPagamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TipoPagamentoRepository extends JpaRepository<TipoPagamento, Integer> {}