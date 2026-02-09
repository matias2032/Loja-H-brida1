# 🛒 Módulo de Usuários - E-commerce Backend (Spring Boot)

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Endpoints da API](#endpoints-da-api)
- [Regras de Negócio](#regras-de-negócio)
- [Instalação e Configuração](#instalação-e-configuração)
- [Testes com cURL](#testes-com-curl)
- [Segurança](#segurança)

---

## 🎯 Visão Geral

Módulo completo de gestão de usuários para E-commerce, implementado com **Spring Boot 3**, seguindo as melhores práticas de desenvolvimento e arquitetura em camadas.

### ✨ Funcionalidades Principais

- ✅ CRUD completo de usuários
- ✅ Soft Delete (ativação/desativação)
- ✅ Filtros por perfil e status
- ✅ Reset de senha para padrão
- ✅ Proteção de administradores
- ✅ Criptografia BCrypt
- ✅ Validações robustas
- ✅ Tratamento de exceções global

---

## 🏗 Arquitetura

```
┌─────────────┐
│  Controller │  (Camada de Apresentação - REST API)
└──────┬──────┘
       │
┌──────▼──────┐
│   Service   │  (Camada de Negócio - Lógica)
└──────┬──────┘
       │
┌──────▼──────┐
│ Repository  │  (Camada de Dados - JPA)
└──────┬──────┘
       │
┌──────▼──────┐
│   Database  │  (PostgreSQL)
└─────────────┘
```

### Tecnologias Utilizadas

- **Spring Boot 3.2.0**
- **Spring Data JPA**
- **PostgreSQL**
- **Lombok**
- **BCrypt** (Spring Security Crypto)
- **Bean Validation**

---

## 📁 Estrutura do Projeto

```
com.ecommerce.usuario/
│
├── config/
│   └── SecurityConfig.java           # Configuração BCrypt
│
├── controller/
│   └── UsuarioController.java        # Endpoints REST
│
├── dto/
│   ├── request/
│   │   ├── UsuarioCreateRequest.java # DTO de criação
│   │   └── UsuarioUpdateRequest.java # DTO de atualização
│   └── response/
│       └── UsuarioResponse.java      # DTO de resposta
│
├── entity/
│   └── Usuario.java                  # Entidade JPA
│
├── exception/
│   ├── BusinessException.java        # Exceção de negócio
│   ├── ResourceNotFoundException.java
│   └── GlobalExceptionHandler.java   # Tratamento global
│
├── repository/
│   └── UsuarioRepository.java        # Acesso a dados
│
└── service/
    └── UsuarioService.java           # Lógica de negócio
```

---

## 🚀 Endpoints da API

### Base URL: `http://localhost:8080/api/usuarios`

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/api/usuarios` | Lista usuários (com filtros) |
| `GET` | `/api/usuarios/{id}` | Busca usuário por ID |
| `POST` | `/api/usuarios` | Cria novo usuário |
| `PUT` | `/api/usuarios/{id}` | Atualiza usuário |
| `PATCH` | `/api/usuarios/{id}/toggle-status` | Ativa/Desativa usuário |
| `PATCH` | `/api/usuarios/{id}/reset-password` | Reseta senha |

### 📌 Detalhamento dos Endpoints

#### 1️⃣ **GET /api/usuarios** - Listar Usuários

**Query Parameters (opcionais):**
- `perfil` - Filtrar por ID do perfil (2=Funcionário, 3=Cliente)
- `ativo` - Filtrar por status (0=Inativo, 1=Ativo)

**Exemplos:**
```bash
GET /api/usuarios                    # Todos (exceto admins)
GET /api/usuarios?ativo=1            # Apenas ativos
GET /api/usuarios?perfil=3           # Apenas clientes
GET /api/usuarios?perfil=2&ativo=1   # Funcionários ativos
```

**Resposta (200 OK):**
```json
[
  {
    "idUsuario": 5,
    "nome": "João Silva",
    "apelido": "João",
    "email": "joao@email.com",
    "telefone": "+258843216789",
    "ativo": 1,
    "statusDescricao": "Ativo",
    "dataCadastro": "2026-02-01 10:30:00",
    "idProvincia": 2,
    "idCidade": 10,
    "idPerfil": 3,
    "primeiraSenha": 1
  }
]
```

#### 2️⃣ **GET /api/usuarios/{id}** - Buscar por ID

**Resposta (200 OK):**
```json
{
  "idUsuario": 5,
  "nome": "João Silva",
  "apelido": "João",
  "email": "joao@email.com",
  "telefone": "+258843216789",
  "ativo": 1,
  "statusDescricao": "Ativo",
  "dataCadastro": "2026-02-01 10:30:00",
  "idProvincia": 2,
  "idCidade": 10,
  "idPerfil": 3,
  "primeiraSenha": 1
}
```

**Erro (404 Not Found):**
```json
{
  "timestamp": "2026-02-09T14:30:00",
  "status": 404,
  "error": "Recurso não encontrado",
  "message": "Usuário não encontrado com ID: 999",
  "path": "/api/usuarios/999"
}
```

#### 3️⃣ **POST /api/usuarios** - Criar Usuário

**Request Body:**
```json
{
  "nome": "Maria Santos",
  "apelido": "Maria",
  "email": "maria@email.com",
  "senha": "senha123456",
  "telefone": "+258849876543",
  "idPerfil": 3,
  "idProvincia": 1,
  "idCidade": 5
}
```

**Resposta (201 Created):**
```json
{
  "idUsuario": 10,
  "nome": "Maria Santos",
  "apelido": "Maria",
  "email": "maria@email.com",
  "telefone": "+258849876543",
  "ativo": 1,
  "statusDescricao": "Ativo",
  "dataCadastro": "2026-02-09 14:35:00",
  "idProvincia": 1,
  "idCidade": 5,
  "idPerfil": 3,
  "primeiraSenha": 1
}
```

**Erro (400 Bad Request):**
```json
{
  "timestamp": "2026-02-09T14:35:00",
  "status": 400,
  "error": "Erro de validação",
  "message": "Campos inválidos",
  "errors": {
    "email": "Email inválido",
    "senha": "A senha deve ter no mínimo 8 caracteres"
  }
}
```

#### 4️⃣ **PUT /api/usuarios/{id}** - Atualizar Usuário

**Request Body:**
```json
{
  "nome": "Maria Santos Costa",
  "apelido": "Maria",
  "email": "maria.santos@email.com",
  "telefone": "+258849876543",
  "idPerfil": 2,
  "idProvincia": 1,
  "idCidade": 5
}
```

**Resposta (200 OK):** Retorna o usuário atualizado

#### 5️⃣ **PATCH /api/usuarios/{id}/toggle-status** - Alternar Status

**Resposta (200 OK):**
```json
{
  "idUsuario": 10,
  "nome": "Maria Santos",
  "apelido": "Maria",
  "email": "maria@email.com",
  "ativo": 0,
  "statusDescricao": "Inativo",
  ...
}
```

#### 6️⃣ **PATCH /api/usuarios/{id}/reset-password** - Resetar Senha

Reseta a senha para **12345678** (criptografada com BCrypt).

**Resposta (200 OK):** Retorna o usuário com `primeiraSenha: 1`

---

## 🔒 Regras de Negócio

### ⚠️ Regras Críticas

1. **Soft Delete Obrigatório**
   - ❌ NUNCA usar `DELETE` físico
   - ✅ Usar campo `ativo` (0=Inativo, 1=Ativo)

2. **Proteção de Administradores**
   - ❌ Não listar usuários com `idperfil = 1`
   - ❌ Não permitir criar usuários com perfil Admin
   - ❌ Não permitir desativar administradores
   - ❌ Não permitir alterar para perfil Admin

3. **Validações de Email**
   - ✅ Email deve ser único no sistema
   - ✅ Validação de formato de email

4. **Segurança de Senha**
   - ✅ Mínimo 8 caracteres
   - ✅ Hash BCrypt (12 rounds)
   - ✅ Senha padrão: `12345678`
   - ✅ Campo `senha_hash` NUNCA exposto na API

5. **Validações de Criação/Atualização**
   - Nome, apelido, email são obrigatórios
   - Perfil é obrigatório
   - Província e cidade são opcionais

---

## ⚙️ Instalação e Configuração

### 1️⃣ Pré-requisitos

- Java 17+
- Maven 3.8+
- PostgreSQL 14+

### 2️⃣ Configurar Banco de Dados

```sql
-- Criar banco de dados
CREATE DATABASE ecommerce;

-- Executar o schema fornecido (arquivo SQL completo)
```

### 3️⃣ Configurar application.properties

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/ecommerce
spring.datasource.username=seu_usuario
spring.datasource.password=sua_senha
```

### 4️⃣ Compilar e Executar

```bash
# Compilar
mvn clean install

# Executar
mvn spring-boot:run
```

A API estará disponível em: `http://localhost:8080`

---

## 🧪 Testes com cURL

### Criar Usuário
```bash
curl -X POST http://localhost:8080/api/usuarios \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Teste Silva",
    "apelido": "Teste",
    "email": "teste@email.com",
    "senha": "senha12345678",
    "telefone": "+258840000000",
    "idPerfil": 3,
    "idProvincia": 1,
    "idCidade": 5
  }'
```

### Listar Clientes Ativos
```bash
curl http://localhost:8080/api/usuarios?perfil=3&ativo=1
```

### Desativar Usuário
```bash
curl -X PATCH http://localhost:8080/api/usuarios/5/toggle-status
```

### Resetar Senha
```bash
curl -X PATCH http://localhost:8080/api/usuarios/5/reset-password
```

---

## 🔐 Segurança

### ✅ Implementações de Segurança

1. **Criptografia de Senha**
   - BCrypt com 12 rounds
   - Senha NUNCA armazenada em texto plano

2. **Proteção de Dados Sensíveis**
   - Campo `senha_hash` NUNCA retornado na API
   - DTOs separados para Request/Response

3. **Validações**
   - Bean Validation em todos os DTOs
   - Validações customizadas no Service

4. **Tratamento de Exceções**
   - Mensagens de erro padronizadas
   - Logs detalhados para auditoria

### ⚠️ Próximos Passos de Segurança

- [ ] Implementar autenticação JWT
- [ ] Adicionar autorização por perfil (RBAC)
- [ ] Rate limiting
- [ ] Auditoria completa (logs de todas as ações)
- [ ] HTTPS obrigatório em produção

---

## 📝 Notas Importantes

### ⚠️ Senha Padrão

A senha padrão **12345678** é usada apenas para:
- Reset de senha
- Ambientes de desenvolvimento

**EM PRODUÇÃO:** Implementar um sistema de recuperação de senha seguro (email, SMS, etc.)

### 🔍 Perfis de Usuário

- **ID 1:** Administrador (protegido)
- **ID 2:** Funcionário/Gerente
- **ID 3:** Cliente

### 🧹 Soft Delete

**NUNCA** use `DELETE FROM usuario`. Use sempre o toggle-status:
```bash
PATCH /api/usuarios/{id}/toggle-status
```

---

## 👨‍💻 Desenvolvido com

- ☕ Java 17
- 🍃 Spring Boot 3.2.0
- 🐘 PostgreSQL
- 🔨 Lombok
- 🔐 BCrypt

---

## 📞 Suporte

Em caso de dúvidas ou problemas:
1. Verifique os logs da aplicação
2. Consulte a documentação do Spring Boot
3. Revise as regras de negócio

**Bom desenvolvimento! 🚀**