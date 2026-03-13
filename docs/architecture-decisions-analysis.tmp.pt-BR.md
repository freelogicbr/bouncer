# Analise das Decisoes de Arquitetura - Bouncer MVP

Este documento analisa as decisoes consolidadas em `architecture-decisions.tmp.pt-BR.md`, confrontando-as com o PRD (`prd.pt-BR.md`) e identificando divergencias, simplificacoes deliberadas, riscos e pontos abertos.

## 1. Alinhamento Geral com o PRD

As decisoes estao, na maioria, alinhadas com o PRD. O espirito do MVP foi preservado: ferramenta local, minimalista, stateless no processo, PostgreSQL+pgvector como backend, Python como unica linguagem suportada.

## 2. Divergencias e Simplificacoes Deliberadas

### 2.1 Remocao do content_hash (Decisao 23 vs PRD 14)

O PRD exige "hash ou fingerprint para deteccao de mudanca" como metadado minimo obrigatorio. A decisao removeu `content_hash` do escopo do MVP apos abandonar o modelo de cliente intermediario.

**Impacto**: A deteccao de mudanca passa a depender exclusivamente do mecanismo `dirty` externo (post-commit). Isso e coerente com a simplificacao do fluxo, mas elimina a possibilidade de o Bouncer verificar por conta propria se um arquivo mudou. Se o script externo falhar silenciosamente, nao ha segunda linha de defesa.

**Avaliacao**: Simplificacao aceitavel para MVP de uso pessoal. O post-commit e confiavel o suficiente para um unico usuario.

### 2.2 Remocao de segmentacao textual como fallback (Decisao 4 vs PRD 9)

O PRD menciona "segmentacao textual simples como fallback" para quando a estrutura de funcao/metodo nao puder ser identificada. As decisoes de arquitetura restringiram o escopo estritamente a `function` e `method` via `ast`, sem fallback.

**Impacto**: Arquivos Python sem funcoes ou metodos (scripts lineares, modulos de constantes) simplesmente nao serao indexados. O parser retornara zero referencias para esses arquivos.

**Avaliacao**: Aceitavel. Scripts lineares sao pouco comuns em projetos estruturados e a busca por arquivo via `find_symbol` ainda funciona como alternativa.

### 2.3 Remocao de classes do escopo de indexacao (Decisao 4 vs PRD 9/14)

O PRD fala genericamente de "referencias indexadas" e "tipo do simbolo". As decisoes excluem classes explicitamente, indexando apenas funcoes e metodos.

**Impacto**: Metodos sao indexados, mas a classe que os contem nao. Um agente que busca "classe X" nao encontrara resultado direto, mas encontrara os metodos de X individualmente.

**Avaliacao**: Aceitavel para MVP. Metodos sao a unidade util de navegacao. A classe pode ser inferida pelo `qualified_name` ou path.

### 2.4 Docker descartado como caminho principal (Decisao 1)

Nao mencionado no PRD, mas e uma decisao pratica relevante. Execucao nativa simplifica setup e debug para uso pessoal.

**Avaliacao**: Coerente com o objetivo de simplicidade.

### 2.5 Codigo quebrado descartado (Decisao 6)

`refresh_index` assume conteudo sintaticamente valido. Parse falho retorna erro e nao atualiza. O PRD nao trata este caso explicitamente.

**Avaliacao**: Decisao correta. Indexar codigo quebrado traria complexidade desproporcional. O post-commit garante que o codigo commitado ao menos parseia (salvo casos raros).

### 2.6 Validacao de pertencimento ao Git removida do core (Decisao 11)

O PRD assume workspace Git. As decisoes delegam qualquer validacao de Git ao script externo.

**Avaliacao**: Coerente com a separacao de responsabilidades. O core nao precisa saber de Git.

## 3. Decisoes que Expandem o PRD

### 3.1 Busca hibrida com ranking composto (Decisao 14)

O PRD fala apenas em "busca semantica" e "busca exata". As decisoes detalham um ranking que combina similaridade vetorial com sinais estruturais (match de nome, match de path, penalidade dirty).

**Avaliacao**: Expansao positiva. O PRD era generico demais neste ponto. O ranking composto melhora a qualidade dos resultados sem adicionar complexidade significativa.

### 3.2 Filtros em search_code (Decisao 15)

O PRD nao menciona filtros. As decisoes adicionam `path_prefix`, `file_path` e `symbol_kind` como filtros opcionais.

**Avaliacao**: Expansao positiva e de baixo custo de implementacao. Permite que agentes refinem buscas sem sobrecarregar o contexto.

### 3.3 Paginacao em get_neighbors (Decisao 21)

O PRD nao menciona paginacao. As decisoes a introduzem para evitar respostas grandes.

**Avaliacao**: Coerente com o principio de respostas pequenas. Boa decisao.

### 3.4 find_symbol exige linguagem explicita (Decisao 18)

O PRD nao especifica este requisito. Como o MVP suporta apenas Python, isso e quase irrelevante agora, mas prepara para extensao futura.

**Avaliacao**: Overhead minimo, beneficio futuro. Aceitavel.

## 4. Pontos que Merecem Atencao

### 4.1 Resolucao de chamadas externas (Decisao 20)

A resolucao de chamadas externas depende de referencias "ja conhecidas no workspace". Isso significa que a ordem de indexacao dos arquivos importa: se A chama B mas B ainda nao foi indexado, a relacao nao sera registrada.

**Risco**: Na primeira indexacao completa do workspace, muitas relacoes serao perdidas dependendo da ordem. Re-rodar o refresh resolve, mas o script precisa saber disso.

**Mitigacao sugerida**: Documentar que a primeira indexacao deve rodar em duas passadas (ou aceitar incompletude na primeira passada e confiar que commits subsequentes preencham as lacunas).

### 4.2 Funcoes aninhadas (Decisao 4)

Funcoes aninhadas nao sao indexadas. Em Python, closures e funcoes auxiliares internas sao comuns.

**Risco**: Baixo. Funcoes aninhadas sao tipicamente detalhes de implementacao, nao pontos de entrada que um agente buscaria.

### 4.3 Valores de top_k e paginacao (Decisao 22)

Nao consolidados. Precisam ser definidos antes da implementacao para evitar decisoes ad hoc no codigo.

**Sugestao**: Defaults razoaveis seriam `top_k=10` para search_code, `top_k=5` para find_symbol, `page_size=10` para get_neighbors.

### 4.4 Estrutura de modulos (Decisao 12)

A separacao logica foi listada mas nao estruturada em diretorios. Precisa virar uma arvore de diretorios concreta antes do inicio da implementacao.

### 4.5 Formato exato das respostas MCP

O PRD define saida minima obrigatoria (Secao 8.3). As decisoes adicionam `reference_id` e detalham os campos. Falta definir o schema JSON exato de cada tool. Isso pode ser feito durante a implementacao, mas deve ser validado contra o PRD antes de ser considerado pronto.

## 5. Consistencia Interna das Decisoes

As 23 decisoes sao internamente consistentes. Nao ha contradicoes entre elas. O fluxo logico e coerente:

1. Configuracao define workspace (10, 11)
2. Script externo detecta mudanca e aciona refresh (7, 8)
3. Refresh le arquivo, parseia, extrai referencias e chamadas, gera embeddings, persiste (1, 2, 3, 4, 5, 6, 13, 20)
4. Busca consulta indice com ranking hibrido (14, 15, 16, 17, 18)
5. Vizinhanca navega o grafo de chamadas (19, 21)
6. Respostas sao compactas e paginadas (22)

## 6. Resumo

| Aspecto | Status |
|---|---|
| Alinhamento com PRD | Alto, com simplificacoes deliberadas documentadas |
| Consistencia interna | Total |
| Simplificacoes vs PRD | 6 pontos, todos justificaveis para MVP pessoal |
| Expansoes vs PRD | 4 pontos, todos positivos |
| Riscos relevantes | Ordem de indexacao inicial, valores de paginacao indefinidos |
| Pontos abertos para implementacao | Estrutura de diretorios, schemas JSON, defaults de paginacao |

As decisoes formam uma base solida para iniciar a implementacao. Os pontos abertos sao todos resolviveis durante o desenvolvimento sem necessidade de revisao arquitetural.
