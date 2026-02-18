package com.loja1.projectohibrido.pedido.repository;

import com.loja1.projectohibrido.pedido.entity.TipoEntrega;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TipoEntregaRepository extends JpaRepository<TipoEntrega, Integer> {}