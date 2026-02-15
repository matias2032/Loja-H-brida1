package com.loja1.projectohibrido.marca.repository;

import com.loja1.projectohibrido.categoria.entity.CategoriaMarca;
import com.loja1.projectohibrido.marca.entity.Marca;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface MarcaRepository extends JpaRepository<Marca, Integer> {
    Optional<Marca> findByNomeMarca(String nomeMarca);

//     // Busca todas as associações de uma marca específica
// List<CategoriaMarca> findByIdMarcaId(Integer idMarca);
}

