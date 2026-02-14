package com.loja1.projectohibrido.categoria.repository;

import com.loja1.projectohibrido.categoria.entity.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, Integer> {
    Optional<Categoria> findByNomeCategoria(String nomeCategoria);
}