package com.loja1.projectohibrido.usuario.service;
import com.loja1.projectohibrido.usuario.dto.request.UsuarioCreateRequest;
import com.loja1.projectohibrido.usuario.dto.request.UsuarioUpdateRequest;
import com.loja1.projectohibrido.usuario.dto.response.UsuarioResponse;
import com.loja1.projectohibrido.usuario.entity.Usuario;
import com.loja1.projectohibrido.usuario.exception.BusinessException;
import com.loja1.projectohibrido.usuario.exception.ResourceNotFoundException;
import com.loja1.projectohibrido.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    // Senha padrão para reset
    private static final String SENHA_PADRAO = "12345678";

    /**
     * Lista todos os usuários (EXCETO ADMINS - idperfil = 1)
     * Com filtros opcionais de perfil e status
     */
    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarUsuarios(Integer idPerfil, Integer ativo) {
        log.info("Listando usuários com filtros - Perfil: {}, Ativo: {}", idPerfil, ativo);

        List<Usuario> usuarios;

        // Aplica os filtros conforme os parâmetros recebidos
        if (idPerfil != null && ativo != null) {
            usuarios = usuarioRepository.findByPerfilAndAtivoExceptAdmins(idPerfil, ativo);
        } else if (idPerfil != null) {
            usuarios = usuarioRepository.findByPerfilExceptAdmins(idPerfil);
        } else if (ativo != null) {
            usuarios = usuarioRepository.findByAtivoExceptAdmins(ativo);
        } else {
            usuarios = usuarioRepository.findAllExceptAdmins();
        }

        return usuarios.stream()
                .map(UsuarioResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Busca usuário por ID
     */
    @Transactional(readOnly = true)
    public UsuarioResponse buscarPorId(Integer id) {
        log.info("Buscando usuário por ID: {}", id);
        
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));

        return UsuarioResponse.fromEntity(usuario);
    }

    /**
     * Cria novo usuário
     */
    @Transactional
    public UsuarioResponse criarUsuario(UsuarioCreateRequest request) {
        log.info("Criando novo usuário com email: {}", request.getEmail());

        // Validação: Email já existe?
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException("Já existe um usuário cadastrado com este email");
        }

        // Validação: Não permitir criar usuário com perfil de Admin (idperfil = 1)
        if (request.getIdPerfil() == 1) {
            throw new BusinessException("Não é permitido criar usuários com perfil de Administrador via este endpoint");
        }

        // Cria a entidade
        Usuario usuario = Usuario.builder()
                .nome(request.getNome())
                .apelido(request.getApelido())
                .email(request.getEmail())
                .senhaHash(passwordEncoder.encode(request.getSenha()))
                .telefone(request.getTelefone())
                .idPerfil(request.getIdPerfil())
                .idProvincia(request.getIdProvincia())
                .idCidade(request.getIdCidade())
                .ativo(1) // Sempre inicia como ativo
                .primeiraSenha(1) // Marcado como primeira senha
                .build();

        Usuario usuarioSalvo = usuarioRepository.save(usuario);
        log.info("Usuário criado com sucesso. ID: {}", usuarioSalvo.getIdUsuario());

        return UsuarioResponse.fromEntity(usuarioSalvo);
    }

    /**
     * Atualiza usuário existente
     */
    @Transactional
    public UsuarioResponse atualizarUsuario(Integer id, UsuarioUpdateRequest request) {
        log.info("Atualizando usuário ID: {}", id);

        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));

        // Validação: Não permitir atualizar para perfil Admin
// DEPOIS
if (request.getIdPerfil() == 1 && !usuario.getIdPerfil().equals(1)) {
    throw new BusinessException("Não é permitido alterar usuário para perfil de Administrador");
}

        // Validação: Email já existe em outro usuário?
        if (!usuario.getEmail().equals(request.getEmail()) 
                && usuarioRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException("Já existe outro usuário cadastrado com este email");
        }

        // Atualiza os dados
        usuario.setNome(request.getNome());
        usuario.setApelido(request.getApelido());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        usuario.setIdPerfil(request.getIdPerfil());
        usuario.setIdProvincia(request.getIdProvincia());
        usuario.setIdCidade(request.getIdCidade());

        Usuario usuarioAtualizado = usuarioRepository.save(usuario);
        log.info("Usuário atualizado com sucesso. ID: {}", id);

        return UsuarioResponse.fromEntity(usuarioAtualizado);
    }

    /**
     * Alterna o status (ativo/inativo) do usuário
     * SOFT DELETE - Nunca deleta fisicamente
     */
    @Transactional
    public UsuarioResponse toggleStatus(Integer id) {
        log.info("Alternando status do usuário ID: {}", id);

        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));

        // Validação: Não permitir desativar administradores
        if (usuario.getIdPerfil() == 1) {
            throw new BusinessException("Não é permitido desativar usuários administradores");
        }

        // Alterna o status
        usuario.toggleStatus();
        Usuario usuarioAtualizado = usuarioRepository.save(usuario);

        log.info("Status do usuário ID: {} alterado para: {}", id, 
                usuarioAtualizado.getAtivo() == 1 ? "ATIVO" : "INATIVO");

        return UsuarioResponse.fromEntity(usuarioAtualizado);
    }

    /**
     * Reseta a senha do usuário para a senha padrão (12345678)
     */
    @Transactional
    public UsuarioResponse resetarSenha(Integer id) {
        log.info("Resetando senha do usuário ID: {}", id);

        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));

        // Reseta para senha padrão
        usuario.setSenhaHash(passwordEncoder.encode(SENHA_PADRAO));
        usuario.setPrimeiraSenha(1); // Marca como primeira senha para forçar troca

        Usuario usuarioAtualizado = usuarioRepository.save(usuario);
        log.info("Senha resetada com sucesso para o usuário ID: {}", id);

        return UsuarioResponse.fromEntity(usuarioAtualizado);
    }

    /**
     * Método auxiliar para validar se usuário existe
     */
    private Usuario buscarUsuarioOuFalhar(Integer id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));
    }
}