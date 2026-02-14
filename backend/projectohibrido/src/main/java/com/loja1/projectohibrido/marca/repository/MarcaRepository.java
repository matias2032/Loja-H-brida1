package com.loja1.projectohibrido.marca.repository;

import com.loja1.projectohibrido.marca.entity.Marca;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MarcaRepository extends JpaRepository<Marca, Integer> {
    Optional<Marca> findByNomeMarca(String nomeMarca);
}