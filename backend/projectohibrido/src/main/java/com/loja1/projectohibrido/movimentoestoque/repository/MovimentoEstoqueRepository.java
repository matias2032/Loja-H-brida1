package com.loja1.projectohibrido.movimentoestoque.repository;

import com.loja1.projectohibrido.movimentoestoque.entity.MovimentoEstoque;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MovimentoEstoqueRepository extends JpaRepository<MovimentoEstoque, Integer> {
    List<MovimentoEstoque> findByIdProdutoOrderByDataMovimentoDesc(Integer idProduto);

List<MovimentoEstoque> findAllByOrderByDataMovimentoDesc();

@Query("SELECT m FROM MovimentoEstoque m WHERE m.dataMovimento BETWEEN :inicio AND :fim ORDER BY m.dataMovimento DESC")
List<MovimentoEstoque> findByPeriodo(
    @Param("inicio") LocalDateTime inicio,
    @Param("fim") LocalDateTime fim
);

}